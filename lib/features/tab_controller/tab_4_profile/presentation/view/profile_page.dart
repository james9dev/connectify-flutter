import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:connectify/core/di/di.dart';
import 'package:connectify/features/onboarding/profile_photo/presentation/widgets/profile_photo_mosaic_layout.dart';
import 'package:connectify/features/onboarding/profile_photo/presentation/widgets/profile_photo_picker_helper.dart';
import 'package:connectify/features/tab_controller/tab_4_profile/domain/profile_repository.dart';
import 'package:connectify/features/tab_controller/tab_4_profile/presentation/bloc/profile_bloc.dart';
import 'package:connectify/features/tab_controller/tab_4_profile/presentation/bloc/profile_event.dart';
import 'package:connectify/features/tab_controller/tab_4_profile/presentation/bloc/profile_state.dart';
import 'package:connectify/shared/authentication/bloc/authentication_bloc.dart';
import 'package:connectify/shared/models/member.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

const Color _accentYellow = Color(0xFFFFC629);
const Color _pageBackground = Color(0xFFFFF8E7);
const Color _surface = Color(0xFFFFFEF9);
const Color _ink = Color(0xFF14130F);
const Color _muted = Color(0xFF6B675D);
const Color _line = Color(0xFFE4DCC0);

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(create: (_) => ProfileBloc(getIt<ProfileRepository>())..add(ProfileLoaded()), child: const ProfileView());
  }
}

class ProfileView extends StatelessWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    final authUser = context.select((AuthenticationBloc bloc) => bloc.state.user);

    return Scaffold(
      backgroundColor: _pageBackground,
      body: SafeArea(
        child: BlocConsumer<ProfileBloc, ProfileState>(
          listenWhen: (previous, current) {
            final uploadDone =
                previous.photoUploadStatus != current.photoUploadStatus &&
                (current.photoUploadStatus == ProfilePhotoUploadStatus.success || current.photoUploadStatus == ProfilePhotoUploadStatus.failure);
            final deleteDone =
                previous.photoDeleteStatus != current.photoDeleteStatus &&
                (current.photoDeleteStatus == ProfilePhotoDeleteStatus.success || current.photoDeleteStatus == ProfilePhotoDeleteStatus.failure);
            final reorderDone =
                previous.photoReorderStatus != current.photoReorderStatus &&
                (current.photoReorderStatus == ProfilePhotoReorderStatus.success || current.photoReorderStatus == ProfilePhotoReorderStatus.failure);
            final updateDone =
                previous.profileUpdateStatus != current.profileUpdateStatus &&
                (current.profileUpdateStatus == ProfileUpdateStatus.success || current.profileUpdateStatus == ProfileUpdateStatus.failure);
            return uploadDone || deleteDone || reorderDone || updateDone;
          },
          listener: (context, state) {
            if (state.photoUploadStatus == ProfilePhotoUploadStatus.success) {
              _showSnackBar(context, '프로필 사진 업로드가 완료되었습니다.');
            }

            if (state.photoUploadStatus == ProfilePhotoUploadStatus.failure) {
              _showSnackBar(context, state.photoUploadErrorMessage ?? '프로필 사진 업로드에 실패했습니다.');
            }

            if (state.photoDeleteStatus == ProfilePhotoDeleteStatus.success) {
              _showSnackBar(context, '프로필 사진이 삭제되었습니다.');
            }

            if (state.photoDeleteStatus == ProfilePhotoDeleteStatus.failure) {
              _showSnackBar(context, state.photoDeleteErrorMessage ?? '프로필 사진 삭제에 실패했습니다.');
            }

            if (state.photoReorderStatus == ProfilePhotoReorderStatus.success) {
              _showSnackBar(context, '프로필 사진 순서가 변경되었습니다.');
            }

            if (state.photoReorderStatus == ProfilePhotoReorderStatus.failure) {
              _showSnackBar(context, state.photoReorderErrorMessage ?? '프로필 사진 순서 변경에 실패했습니다.');
            }

            if (state.profileUpdateStatus == ProfileUpdateStatus.success) {
              _showSnackBar(context, '프로필 수정이 저장되었습니다.');
            }

            if (state.profileUpdateStatus == ProfileUpdateStatus.failure) {
              _showSnackBar(context, state.profileUpdateErrorMessage ?? '프로필 수정에 실패했습니다.');
            }
          },
          builder: (context, state) {
            if (state.status == ProfileStatus.loading && authUser == null) {
              return const Center(child: CircularProgressIndicator());
            }

            final user = state.profile ?? authUser;
            if (user == null) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('프로필 정보를 불러오지 못했습니다.'),
                    const SizedBox(height: 10),
                    OutlinedButton(onPressed: () => context.read<ProfileBloc>().add(ProfileLoaded()), child: const Text('다시 시도')),
                  ],
                ),
              );
            }

            return Column(
              children: [
                _TopBar(onSettingsPressed: () => _showSnackBar(context, '설정 화면은 준비 중입니다.'), onLogoutPressed: () => context.read<AuthenticationBloc>().add(AuthenticationLogoutPressed())),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(14, 10, 14, 20),
                    child: _ProfileDashboard(
                      member: user,
                      isUploading: state.photoUploadStatus == ProfilePhotoUploadStatus.inProgress,
                      isDeleting: state.photoDeleteStatus == ProfilePhotoDeleteStatus.inProgress,
                      isReordering: state.photoReorderStatus == ProfilePhotoReorderStatus.inProgress,
                      reorderStatus: state.photoReorderStatus,
                      isSaving: state.profileUpdateStatus == ProfileUpdateStatus.inProgress,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.onSettingsPressed, required this.onLogoutPressed});

  final VoidCallback onSettingsPressed;
  final VoidCallback onLogoutPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              '마이페이지',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: _ink),
            ),
          ),
          IconButton(tooltip: '설정', onPressed: onSettingsPressed, icon: const Icon(Icons.settings_outlined)),
          IconButton(tooltip: '로그아웃', onPressed: onLogoutPressed, icon: const Icon(Icons.logout)),
        ],
      ),
    );
  }
}

class _ProfileDashboard extends StatefulWidget {
  const _ProfileDashboard({required this.member, required this.isUploading, required this.isDeleting, required this.isReordering, required this.reorderStatus, required this.isSaving});

  final Member member;
  final bool isUploading;
  final bool isDeleting;
  final bool isReordering;
  final ProfilePhotoReorderStatus reorderStatus;
  final bool isSaving;

  @override
  State<_ProfileDashboard> createState() => _ProfileDashboardState();
}

class _ProfileDashboardState extends State<_ProfileDashboard> {
  static final ImagePicker _imagePicker = ImagePicker();

  List<ProfilePicture>? _localPictures;

  Member get member => widget.member;

  bool get _isBusy => widget.isUploading || widget.isDeleting || widget.isReordering || widget.isSaving;

  @override
  void initState() {
    super.initState();
    _syncPicturesFromMember();
  }

  @override
  void didUpdateWidget(covariant _ProfileDashboard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.reorderStatus != widget.reorderStatus && widget.reorderStatus == ProfilePhotoReorderStatus.failure) {
      setState(_syncPicturesFromMember);
      return;
    }
    if (!_sameServerPictureVersion(oldWidget.member.profile.pictures, widget.member.profile.pictures)) {
      setState(_syncPicturesFromMember);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pictures = _localPictures ?? member.profile.orderedPictures;
    final primaryPhotoUrl = pictures.isNotEmpty ? pictures.first.imageUrl : member.profile.primaryPicture?.imageUrl;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _HeroCard(member: member, primaryPhotoUrl: primaryPhotoUrl, onEditPressed: _isBusy ? null : _openEditProfileSheet),
        const SizedBox(height: 12),
        const _SummaryCard(todayIntroCount: 0, matchCount: 0),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: _line),
            boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 10, offset: Offset(0, 4))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      '사진 관리',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _ink),
                    ),
                  ),
                  if (_isBusy) const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2.2)),
                ],
              ),
              const SizedBox(height: 10),
              Stack(
                children: [
                  ProfilePhotoMosaicLayout<ProfilePicture>(
                    photos: pictures,
                    imageBuilder: (context, picture) {
                      return CachedNetworkImage(
                        imageUrl: picture.imageUrl,
                        fit: BoxFit.cover,
                        placeholder: (context, _) => const ColoredBox(
                          color: Color(0xFFF0F0ED),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                        errorWidget: (context, _, _) => const ColoredBox(
                          color: Color(0xFFF0F0ED),
                          child: Center(child: Icon(Icons.broken_image_outlined)),
                        ),
                      );
                    },
                    onAddPressed: _isBusy ? null : () => _pickAndUploadPhoto(currentCount: pictures.length),
                    onDeletePressed: _isBusy
                        ? null
                        : (index) {
                            if (index < 0 || index >= pictures.length) {
                              return;
                            }
                            _confirmDeletePhoto(pictures[index].id);
                          },
                    enableReorder: !_isBusy,
                    onReorder: _isBusy ? null : _reorderLocalPictures,
                  ),
                  if (_isBusy) const Positioned.fill(child: ColoredBox(color: Color(0x33000000))),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: _line),
            boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 10, offset: Offset(0, 4))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '내 프로필 정보',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _ink),
              ),
              const SizedBox(height: 10),
              _InfoRow(label: '지역', value: member.profile.location ?? '-'),
              _InfoRow(label: '직무', value: member.profile.job ?? '-'),
              _InfoRow(label: '회사', value: member.profile.company ?? '-'),
              _InfoRow(label: '학교', value: member.profile.educationInstitution ?? '-'),
              _InfoRow(label: '학력', value: member.profile.educationGraduation ?? '-'),
              const SizedBox(height: 20),
              const Text(
                '소개',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _muted),
              ),
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: const Color(0xFFFFF2C2), borderRadius: BorderRadius.circular(10)),
                child: Text(member.profile.bio?.trim().isNotEmpty == true ? member.profile.bio! : '소개글이 아직 없습니다.'),
              ),
              if (member.profile.profileTagIds.isNotEmpty) ...[
                const SizedBox(height: 20),
                const Text(
                  '프로필 태그',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _muted),
                ),
                const SizedBox(height: 6),
                _TagWrap(tags: member.profile.profileTagIds, backgroundColor: const Color(0xFFFFEEB2)),
              ],
              const SizedBox(height: 20),
              const Text(
                '선호 태그',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _muted),
              ),
              const SizedBox(height: 6),
              if (member.profile.preferredTagIds.isEmpty)
                const Text(
                  '선호 태그가 아직 없습니다.',
                  style: TextStyle(fontSize: 13, color: _muted, fontWeight: FontWeight.w600),
                )
              else
                _TagWrap(tags: member.profile.preferredTagIds, backgroundColor: const Color(0xFFE8EEF8)),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _openEditProfileSheet() async {
    final profile = member.profile;
    final nickNameController = TextEditingController(text: profile.nickName ?? member.name);
    final regionController = TextEditingController(text: profile.location ?? '');
    final bioController = TextEditingController(text: profile.bio ?? '');

    final shouldSave = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.fromLTRB(16, 8, 16, 16 + MediaQuery.of(context).viewInsets.bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('내 프로필 수정', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              TextField(
                controller: nickNameController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(labelText: '닉네임'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: regionController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(labelText: '지역'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: bioController,
                minLines: 3,
                maxLines: 5,
                decoration: const InputDecoration(labelText: '소개글'),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: FilledButton.styleFrom(backgroundColor: _accentYellow, foregroundColor: _ink),
                  child: const Text('저장'),
                ),
              ),
            ],
          ),
        );
      },
    );

    if (!mounted || shouldSave != true) {
      return;
    }

    context.read<ProfileBloc>().add(ProfileBasicInfoSaveRequested(nickName: nickNameController.text, region: regionController.text, bio: bioController.text));
  }

  void _syncPicturesFromMember() {
    _localPictures = List<ProfilePicture>.from(member.profile.orderedPictures);
  }

  bool _sameServerPictureVersion(List<ProfilePicture> left, List<ProfilePicture> right) {
    if (left.length != right.length) {
      return false;
    }

    for (var i = 0; i < left.length; i++) {
      final l = left[i];
      final r = right[i];
      if (l.id != r.id || l.order != r.order || l.isPrimary != r.isPrimary || l.imageUrl != r.imageUrl) {
        return false;
      }
    }
    return true;
  }

  void _reorderLocalPictures(int fromIndex, int toIndex) {
    final current = List<ProfilePicture>.from(_localPictures ?? member.profile.orderedPictures);
    if (fromIndex < 0 || toIndex < 0 || fromIndex >= current.length || toIndex >= current.length || fromIndex == toIndex) {
      return;
    }

    final moved = current.removeAt(fromIndex);
    current.insert(toIndex, moved);
    final movedPictureId = moved.id;
    setState(() {
      _localPictures = current;
    });
    context.read<ProfileBloc>().add(ProfilePhotoReorderRequested(pictureId: movedPictureId, targetOrder: toIndex));
  }

  Future<void> _pickAndUploadPhoto({required int currentCount}) async {
    if (currentCount >= 6) {
      _showSnackBar('사진은 최대 6장까지 등록할 수 있어요.');
      return;
    }

    try {
      final picked = await _imagePicker.pickImage(source: ImageSource.gallery);
      if (!mounted || picked == null) {
        return;
      }

      final cropped = await ProfilePhotoPickerHelper.cropImageToFourByFive(picked.path);
      if (!mounted || cropped == null) {
        return;
      }

      final bytes = await File(cropped.path).readAsBytes();
      if (!mounted) {
        return;
      }

      if (bytes.isEmpty) {
        _showSnackBar('선택한 사진을 읽을 수 없습니다.');
        return;
      }

      await ProfilePhotoPickerHelper.validateImageBytes(bytes);
      if (!mounted) {
        return;
      }

      final fileName = 'profile_manage_${DateTime.now().millisecondsSinceEpoch}.jpg';
      context.read<ProfileBloc>().add(ProfilePhotoUploadRequested(imageBytes: bytes, fileName: fileName, contentType: 'image/jpeg'));
    } catch (error) {
      if (!mounted) {
        return;
      }
      final message = '$error';
      _showSnackBar(message.startsWith('Exception: ') ? message.replaceFirst('Exception: ', '') : '사진 선택 중 오류가 발생했습니다.');
    }
  }

  Future<void> _confirmDeletePhoto(int pictureId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('사진 삭제'),
          content: const Text('선택한 사진을 삭제할까요?'),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('취소')),
            FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('삭제')),
          ],
        );
      },
    );

    if (!mounted || confirmed != true) {
      return;
    }

    context.read<ProfileBloc>().add(ProfilePhotoDeleteRequested(pictureId: pictureId));
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.member, required this.primaryPhotoUrl, required this.onEditPressed});

  final Member member;
  final String? primaryPhotoUrl;
  final VoidCallback? onEditPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFFFFDF74), Color(0xFFFFF0B8)]),
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [BoxShadow(color: Color(0x26000000), blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: Colors.white,
            backgroundImage: primaryPhotoUrl != null ? CachedNetworkImageProvider(primaryPhotoUrl!) : null,
            child: primaryPhotoUrl == null ? const Icon(Icons.person_outline, size: 30) : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.profile.nickName?.trim().isNotEmpty == true ? member.profile.nickName! : member.name,
                  style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w900, color: _ink),
                ),
                const SizedBox(height: 2),
                Text(
                  '${member.profile.age()}세 • ${member.profile.location ?? '지역 미설정'}',
                  style: const TextStyle(color: _muted, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 10),
                FilledButton.icon(
                  onPressed: onEditPressed,
                  style: FilledButton.styleFrom(backgroundColor: Colors.black87, foregroundColor: Colors.white, visualDensity: VisualDensity.compact),
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('프로필 수정'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.todayIntroCount, required this.matchCount});

  final int todayIntroCount;
  final int matchCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _line),
        boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: Row(
        children: [
          Expanded(
            child: _SummaryMetric(title: '오늘의 소개', value: '$todayIntroCount', caption: '집계 기준: 앱 활동'),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _SummaryMetric(title: '매칭', value: '$matchCount', caption: '누적 매칭 수'),
          ),
        ],
      ),
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  const _SummaryMetric({required this.title, required this.value, required this.caption});

  final String title;
  final String value;
  final String caption;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(color: const Color(0xFFFFF4CB), borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 13, color: _muted, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 24, color: _ink, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 2),
          Text(
            caption,
            style: const TextStyle(fontSize: 12, color: _muted, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 62,
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, color: _muted, fontWeight: FontWeight.w700),
            ),
          ),
          Expanded(
            child: Text(value.trim().isNotEmpty ? value : '-', style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

class _TagWrap extends StatelessWidget {
  const _TagWrap({required this.tags, required this.backgroundColor});

  final List<ProfileTagSummary> tags;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: tags
          .map((tag) {
            final label = tag.name?.trim().isNotEmpty == true ? tag.name! : '태그 #${tag.id}';
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(color: backgroundColor, borderRadius: BorderRadius.circular(999)),
              child: Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: _ink),
              ),
            );
          })
          .toList(growable: false),
    );
  }
}
