import 'package:connectify/features/onboarding/profile_basic/domain/profile_basic_repository.dart';
import 'package:connectify/features/onboarding/profile_basic/domain/entities/profile_basic_info_command.dart';
import 'package:connectify/features/onboarding/profile_basic/presentation/bloc/profile_basic_info_bloc.dart';
import 'package:connectify/features/onboarding/profile_basic/presentation/bloc/profile_basic_info_event.dart';
import 'package:connectify/features/onboarding/profile_basic/presentation/bloc/profile_basic_info_state.dart';
import 'package:connectify/features/onboarding/profile_photo/domain/entities/profile_photo_draft.dart';
import 'package:connectify/features/onboarding/profile_photo/presentation/view/profile_photo_page.dart';
import 'package:connectify/shared/authentication/bloc/authentication_bloc.dart';
import 'package:connectify/shared/models/member.dart';
import 'package:connectify/shared/models/profile_tag_catalog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

enum _ProfileBasicStep { basic, tags, bio }

const Color _accentYellow = Color(0xFFFFC629);
const Color _pageBackground = Colors.white; //Color(0xFFFFF6CC);

class ProfileBasicInfoPage extends StatefulWidget {
  const ProfileBasicInfoPage({super.key});

  static Route<void> route() {
    return MaterialPageRoute<void>(
      builder: (context) => BlocProvider(
        create: (_) => ProfileBasicInfoBloc(profileBasicRepository: context.read<ProfileBasicRepository>())..add(const ProfileBasicInfoCatalogRequested()),
        child: const ProfileBasicInfoPage(),
      ),
    );
  }

  @override
  State<ProfileBasicInfoPage> createState() => _ProfileBasicInfoPageState();
}

class _ProfileBasicInfoPageState extends State<ProfileBasicInfoPage> {
  _ProfileBasicStep _currentStep = _ProfileBasicStep.basic;
  List<ProfilePhotoDraft> _photoDrafts = const <ProfilePhotoDraft>[];

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) {
          return;
        }
        _handleBackNavigation();
      },
      child: BlocConsumer<ProfileBasicInfoBloc, ProfileBasicInfoState>(
        listenWhen: (previous, current) {
          final noticeChanged = previous.noticeMessage != current.noticeMessage;
          return noticeChanged;
        },
        listener: (context, state) {
          final messenger = ScaffoldMessenger.of(context);

          if (state.noticeMessage != null) {
            messenger
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(content: Text(state.noticeMessage!)));
            context.read<ProfileBasicInfoBloc>().add(const ProfileBasicInfoNoticeCleared());
          }
        },
        builder: (context, state) {
          return Scaffold(
            backgroundColor: _pageBackground,
            appBar: AppBar(
              backgroundColor: _accentYellow,
              foregroundColor: Colors.black,
              elevation: 0,
              leading: _buildLeading(context),
              title: Text('프로필 기본정보 입력 (${_currentStep.index + 1}/3)', style: const TextStyle(fontWeight: FontWeight.w800)),
            ),
            body: _buildBody(context, state),
            bottomNavigationBar: SafeArea(
              minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: _accentYellow,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                ),
                onPressed: state.isCatalogReady && !state.isSubmitting ? () => _handlePrimaryAction(context, state) : null,
                child: state.isSubmitting ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Text('다음'),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLeading(BuildContext context) {
    if (_currentStep == _ProfileBasicStep.basic) {
      return IconButton(icon: const Icon(Icons.close), onPressed: _confirmCancelSignUp);
    }

    return IconButton(icon: const Icon(Icons.arrow_back), onPressed: _goToPreviousStep);
  }

  Widget _buildBody(BuildContext context, ProfileBasicInfoState state) {
    if (state.catalogStatus == ProfileBasicInfoCatalogStatus.initial || state.catalogStatus == ProfileBasicInfoCatalogStatus.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.catalogStatus == ProfileBasicInfoCatalogStatus.failure) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(state.catalogErrorMessage ?? '기본정보 옵션을 불러오지 못했습니다. 잠시 후 다시 시도해주세요.', textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: _accentYellow, foregroundColor: Colors.black),
                onPressed: () => context.read<ProfileBasicInfoBloc>().add(const ProfileBasicInfoCatalogRequested()),
                child: const Text('다시 시도'),
              ),
            ],
          ),
        ),
      );
    }

    final catalog = state.catalog;
    if (catalog == null) {
      return const Center(child: Text('태그 정보를 찾지 못했습니다.'));
    }

    return IndexedStack(
      index: _currentStep.index,
      children: [
        _Step1BasicInfo(state: state, regions: state.regions),
        _Step2ProfileTags(state: state, catalog: catalog),
        _Step3Bio(state: state),
      ],
    );
  }

  void _handlePrimaryAction(BuildContext context, ProfileBasicInfoState state) {
    final bloc = context.read<ProfileBasicInfoBloc>();

    switch (_currentStep) {
      case _ProfileBasicStep.basic:
        if (!state.isStep1Valid) {
          bloc.add(const ProfileBasicInfoValidationRequested());
          return;
        }
        setState(() {
          _currentStep = _ProfileBasicStep.tags;
        });
        return;
      case _ProfileBasicStep.tags:
        if (!state.isStep2Valid) {
          bloc.add(const ProfileBasicInfoValidationRequested());
          return;
        }
        setState(() {
          _currentStep = _ProfileBasicStep.bio;
        });
        return;
      case _ProfileBasicStep.bio:
        if (!state.isFormValid) {
          bloc.add(const ProfileBasicInfoValidationRequested());
          return;
        }
        final pendingKakaoAccessToken = context.read<AuthenticationBloc>().state.pendingKakaoAccessToken;
        if (pendingKakaoAccessToken == null || pendingKakaoAccessToken.isEmpty) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(const SnackBar(content: Text('카카오 인증 정보가 만료되었습니다. 다시 로그인해주세요.')));
          context.read<AuthenticationBloc>().add(AuthenticationLogoutPressed());
          return;
        }

        final command = _buildProfileBasicInfoCommand(state);
        if (command == null) {
          bloc.add(const ProfileBasicInfoValidationRequested());
          return;
        }

        _openProfilePhotoPage(command: command, kakaoAccessToken: pendingKakaoAccessToken);
        return;
    }
  }

  void _goToPreviousStep() {
    setState(() {
      if (_currentStep == _ProfileBasicStep.bio) {
        _currentStep = _ProfileBasicStep.tags;
      } else if (_currentStep == _ProfileBasicStep.tags) {
        _currentStep = _ProfileBasicStep.basic;
      }
    });
  }

  Future<void> _confirmCancelSignUp() async {
    final shouldCancel = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('가입을 중단할까요?'),
          content: const Text('입력 중인 프로필 정보가 저장되지 않습니다.'),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('계속 입력')),
            FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('중단하기')),
          ],
        );
      },
    );

    if (shouldCancel == true && mounted) {
      context.read<AuthenticationBloc>().add(AuthenticationLogoutPressed());
    }
  }

  Future<void> _handleBackNavigation() async {
    if (_currentStep == _ProfileBasicStep.basic) {
      await _confirmCancelSignUp();
      return;
    }

    _goToPreviousStep();
  }

  ProfileBasicInfoCommand? _buildProfileBasicInfoCommand(ProfileBasicInfoState state) {
    final birthDate = state.birthDate;
    final gender = state.gender;
    final region = state.region?.trim();
    if (birthDate == null || gender == null || region == null || region.isEmpty) {
      return null;
    }

    final birthyear = birthDate.year.toString().padLeft(4, '0');
    final birthday = '${birthDate.month.toString().padLeft(2, '0')}${birthDate.day.toString().padLeft(2, '0')}';
    final preferredTagIds = state.selectedPreferredTagIds.toList(growable: false)..sort();

    return ProfileBasicInfoCommand(
      nickName: state.nickname.trim(),
      gender: gender,
      birthyear: birthyear,
      birthday: birthday,
      region: region,
      bio: state.bio.trim(),
      profileTagIds: state.selectedProfileTagIds,
      preferredTagIds: preferredTagIds,
    );
  }

  Future<void> _openProfilePhotoPage({required ProfileBasicInfoCommand command, required String kakaoAccessToken}) async {
    final result = await Navigator.of(context).push<List<ProfilePhotoDraft>?>(ProfilePhotoPage.route(kakaoAccessToken: kakaoAccessToken, basicInfoCommand: command, initialDraftPhotos: _photoDrafts));

    if (!mounted || result == null) {
      return;
    }

    setState(() {
      _photoDrafts = result.map((photo) => photo.clone()).toList(growable: false);
    });
  }
}

class _Step1BasicInfo extends StatelessWidget {
  const _Step1BasicInfo({required this.state, required this.regions});

  final ProfileBasicInfoState state;
  final List<String> regions;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      children: [
        const _SectionTitle('닉네임'),
        TextField(
          maxLength: 20,
          enabled: !state.isSubmitting,
          onChanged: (value) => context.read<ProfileBasicInfoBloc>().add(ProfileBasicInfoNicknameChanged(value)),
          decoration: InputDecoration(hintText: '2~20자로 입력해주세요', errorText: state.showValidationErrors && !state.isNicknameValid ? '닉네임은 2~20자여야 합니다.' : null),
        ),
        const SizedBox(height: 12),
        const _SectionTitle('성별'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ChoiceChip(
              label: const Text('남성'),
              selected: state.gender == GenderType.MALE,
              onSelected: state.isSubmitting ? null : (_) => context.read<ProfileBasicInfoBloc>().add(const ProfileBasicInfoGenderChanged(GenderType.MALE)),
            ),
            ChoiceChip(
              label: const Text('여성'),
              selected: state.gender == GenderType.FEMALE,
              onSelected: state.isSubmitting ? null : (_) => context.read<ProfileBasicInfoBloc>().add(const ProfileBasicInfoGenderChanged(GenderType.FEMALE)),
            ),
          ],
        ),
        if (state.showValidationErrors && state.gender == null) ...[const SizedBox(height: 8), const Text('성별을 선택해주세요.', style: TextStyle(color: Colors.red))],
        const SizedBox(height: 20),
        const _SectionTitle('생년월일'),
        OutlinedButton(
          onPressed: state.isSubmitting ? null : () => _pickBirthDate(context, state.birthDate),
          child: Text(state.birthDate == null ? '생년월일 선택' : '${state.birthDate!.year}.${state.birthDate!.month.toString().padLeft(2, '0')}.${state.birthDate!.day.toString().padLeft(2, '0')}'),
        ),
        if (state.showValidationErrors && state.birthDate == null) ...[const SizedBox(height: 8), const Text('생년월일을 선택해주세요.', style: TextStyle(color: Colors.red))],
        const SizedBox(height: 20),
        const _SectionTitle('지역(시/도)'),
        DropdownButtonFormField<String>(
          value: state.region,
          items: regions.map((region) => DropdownMenuItem(value: region, child: Text(region))).toList(),
          onChanged: state.isSubmitting ? null : (value) => context.read<ProfileBasicInfoBloc>().add(ProfileBasicInfoRegionChanged(value)),
          decoration: InputDecoration(errorText: state.showValidationErrors && (state.region == null || state.region!.isEmpty) ? '지역을 선택해주세요.' : null),
        ),
      ],
    );
  }

  Future<void> _pickBirthDate(BuildContext context, DateTime? currentBirthDate) async {
    final now = DateTime.now();
    final initialDate = currentBirthDate ?? DateTime(now.year - 24, 1, 1);

    final selectedDate = await showDatePicker(context: context, initialDate: initialDate, firstDate: DateTime(1950, 1, 1), lastDate: DateTime(now.year, now.month, now.day));

    if (selectedDate == null || !context.mounted) {
      return;
    }

    context.read<ProfileBasicInfoBloc>().add(ProfileBasicInfoBirthDateChanged(selectedDate));
  }
}

class _Step2ProfileTags extends StatelessWidget {
  const _Step2ProfileTags({required this.state, required this.catalog});

  final ProfileBasicInfoState state;
  final ProfileTagCatalog catalog;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      children: [
        _SectionTitle('프로필 태그 선택 (카테고리별 최대 ${state.maxProfileTagsPerCategory}개)'),
        ...catalog.categories.map(
          (category) => Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category.name,
                  style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.black87),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: category.tags.map((tag) {
                    final selected = state.selectedProfileTagIdsByCategory[category.id]?.contains(tag.id) ?? false;
                    return FilterChip(
                      label: Text(tag.name),
                      selected: selected,
                      onSelected: state.isSubmitting ? null : (_) => context.read<ProfileBasicInfoBloc>().add(ProfileBasicInfoProfileTagToggled(categoryId: category.id, tagId: tag.id)),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
        if (state.showValidationErrors && state.selectedProfileTagIds.isEmpty) ...[const SizedBox(height: 8), const Text('프로필 태그를 1개 이상 선택해주세요.', style: TextStyle(color: Colors.red))],
      ],
    );
  }
}

class _Step3Bio extends StatelessWidget {
  const _Step3Bio({required this.state});

  final ProfileBasicInfoState state;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      children: [
        const _SectionTitle('소개 글 (선택)'),
        TextField(
          minLines: 5,
          maxLines: 7,
          maxLength: 120,
          enabled: !state.isSubmitting,
          onChanged: (value) => context.read<ProfileBasicInfoBloc>().add(ProfileBasicInfoBioChanged(value)),
          decoration: InputDecoration(
            hintText: '나를 소개해보세요 (최대 120자)',
            helperText: '소개 글은 건너뛸 수 있습니다.',
            errorText: state.showValidationErrors && !state.isBioValid ? '소개 글은 최대 120자까지 입력할 수 있습니다.' : null,
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800, color: Colors.black87),
    );
  }
}
