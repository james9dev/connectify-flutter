import 'package:bloc/bloc.dart';
import 'package:connectify/features/onboarding/profile_basic/domain/entities/profile_basic_info_command.dart';
import 'package:connectify/features/onboarding/profile_basic/domain/profile_basic_repository.dart';
import 'package:connectify/features/onboarding/profile_basic/presentation/bloc/profile_basic_info_event.dart';
import 'package:connectify/features/onboarding/profile_basic/presentation/bloc/profile_basic_info_state.dart';

class ProfileBasicInfoBloc extends Bloc<ProfileBasicInfoEvent, ProfileBasicInfoState> {
  final ProfileBasicRepository _profileBasicRepository;

  ProfileBasicInfoBloc({required ProfileBasicRepository profileBasicRepository}) : _profileBasicRepository = profileBasicRepository, super(const ProfileBasicInfoState()) {
    on<ProfileBasicInfoCatalogRequested>(_onCatalogRequested);
    on<ProfileBasicInfoNicknameChanged>(_onNicknameChanged);
    on<ProfileBasicInfoBioChanged>(_onBioChanged);
    on<ProfileBasicInfoGenderChanged>(_onGenderChanged);
    on<ProfileBasicInfoBirthDateChanged>(_onBirthDateChanged);
    on<ProfileBasicInfoRegionChanged>(_onRegionChanged);
    on<ProfileBasicInfoProfileTagToggled>(_onProfileTagToggled);
    on<ProfileBasicInfoPreferredTagToggled>(_onPreferredTagToggled);
    on<ProfileBasicInfoSubmitted>(_onSubmitted);
    on<ProfileBasicInfoNoticeCleared>(_onNoticeCleared);
    on<ProfileBasicInfoValidationRequested>(_onValidationRequested);
  }

  Future<void> _onCatalogRequested(ProfileBasicInfoCatalogRequested event, Emitter<ProfileBasicInfoState> emit) async {
    if (state.catalogStatus == ProfileBasicInfoCatalogStatus.loading) {
      return;
    }

    emit(state.copyWith(catalogStatus: ProfileBasicInfoCatalogStatus.loading, catalogErrorMessage: null));

    try {
      final catalog = await _profileBasicRepository.getProfileTagCatalog();
      final regions = await _profileBasicRepository.getProfileRegions();

      if (regions.isEmpty) {
        throw Exception('지역 목록이 비어 있습니다. 잠시 후 다시 시도해주세요.');
      }

      emit(state.copyWith(catalogStatus: ProfileBasicInfoCatalogStatus.success, catalog: catalog, regions: regions, catalogErrorMessage: null));
    } catch (error) {
      emit(
        state.copyWith(
          catalogStatus: ProfileBasicInfoCatalogStatus.failure,
          catalogErrorMessage: _toErrorMessage(error, fallback: '기본정보 옵션을 불러오지 못했습니다. 잠시 후 다시 시도해주세요.'),
        ),
      );
    }
  }

  void _onNicknameChanged(ProfileBasicInfoNicknameChanged event, Emitter<ProfileBasicInfoState> emit) {
    emit(state.copyWith(nickname: event.nickname));
  }

  void _onBioChanged(ProfileBasicInfoBioChanged event, Emitter<ProfileBasicInfoState> emit) {
    emit(state.copyWith(bio: event.bio));
  }

  void _onGenderChanged(ProfileBasicInfoGenderChanged event, Emitter<ProfileBasicInfoState> emit) {
    emit(state.copyWith(gender: event.gender));
  }

  void _onBirthDateChanged(ProfileBasicInfoBirthDateChanged event, Emitter<ProfileBasicInfoState> emit) {
    emit(state.copyWith(birthDate: event.birthDate));
  }

  void _onRegionChanged(ProfileBasicInfoRegionChanged event, Emitter<ProfileBasicInfoState> emit) {
    emit(state.copyWith(region: event.region));
  }

  void _onProfileTagToggled(ProfileBasicInfoProfileTagToggled event, Emitter<ProfileBasicInfoState> emit) {
    if (state.isSubmitting) {
      return;
    }

    final copiedMap = _copyProfileTagMap(state.selectedProfileTagIdsByCategory);
    final selectedTagIds = copiedMap.putIfAbsent(event.categoryId, () => <int>{});

    if (selectedTagIds.contains(event.tagId)) {
      selectedTagIds.remove(event.tagId);
      if (selectedTagIds.isEmpty) {
        copiedMap.remove(event.categoryId);
      }
      emit(state.copyWith(selectedProfileTagIdsByCategory: copiedMap));
      return;
    }

    if (selectedTagIds.length >= state.maxProfileTagsPerCategory) {
      emit(state.copyWith(noticeMessage: '카테고리별 태그는 최대 ${state.maxProfileTagsPerCategory}개까지 선택할 수 있습니다.'));
      return;
    }

    selectedTagIds.add(event.tagId);
    emit(state.copyWith(selectedProfileTagIdsByCategory: copiedMap));
  }

  void _onPreferredTagToggled(ProfileBasicInfoPreferredTagToggled event, Emitter<ProfileBasicInfoState> emit) {
    if (state.isSubmitting) {
      return;
    }

    final updated = Set<int>.from(state.selectedPreferredTagIds);

    if (updated.contains(event.tagId)) {
      updated.remove(event.tagId);
      emit(state.copyWith(selectedPreferredTagIds: updated));
      return;
    }

    if (updated.length >= state.maxPreferredTags) {
      emit(state.copyWith(noticeMessage: '선호 태그는 최대 ${state.maxPreferredTags}개까지 선택할 수 있습니다.'));
      return;
    }

    updated.add(event.tagId);
    emit(state.copyWith(selectedPreferredTagIds: updated));
  }

  Future<void> _onSubmitted(ProfileBasicInfoSubmitted event, Emitter<ProfileBasicInfoState> emit) async {
    emit(state.copyWith(showValidationErrors: true, submitErrorMessage: null));

    if (!state.isFormValid) {
      return;
    }

    final birthDate = state.birthDate;
    final gender = state.gender;
    final region = state.region?.trim();
    if (birthDate == null || gender == null || region == null || region.isEmpty) {
      return;
    }

    final birthyear = birthDate.year.toString().padLeft(4, '0');
    final birthday = '${birthDate.month.toString().padLeft(2, '0')}${birthDate.day.toString().padLeft(2, '0')}';

    emit(state.copyWith(submitStatus: ProfileBasicInfoSubmitStatus.inProgress, submitErrorMessage: null));

    try {
      final preferredTagIds = state.selectedPreferredTagIds.toList(growable: false)..sort();

      final command = ProfileBasicInfoCommand(
        nickName: state.nickname.trim(),
        gender: gender,
        birthyear: birthyear,
        birthday: birthday,
        region: region,
        bio: state.bio.trim(),
        profileTagIds: state.selectedProfileTagIds,
        preferredTagIds: preferredTagIds,
      );

      await _profileBasicRepository.submitProfileBasicInfo(command);

      emit(state.copyWith(submitStatus: ProfileBasicInfoSubmitStatus.success, submitErrorMessage: null));
    } catch (error) {
      emit(
        state.copyWith(
          submitStatus: ProfileBasicInfoSubmitStatus.failure,
          submitErrorMessage: _toErrorMessage(error, fallback: '기본정보 저장 중 오류가 발생했습니다.'),
        ),
      );
    }
  }

  void _onNoticeCleared(ProfileBasicInfoNoticeCleared event, Emitter<ProfileBasicInfoState> emit) {
    emit(state.copyWith(noticeMessage: null));
  }

  void _onValidationRequested(ProfileBasicInfoValidationRequested event, Emitter<ProfileBasicInfoState> emit) {
    emit(state.copyWith(showValidationErrors: true));
  }

  Map<int, Set<int>> _copyProfileTagMap(Map<int, Set<int>> source) {
    final copied = <int, Set<int>>{};
    for (final entry in source.entries) {
      copied[entry.key] = Set<int>.from(entry.value);
    }
    return copied;
  }

  String _toErrorMessage(Object error, {required String fallback}) {
    final raw = error.toString().trim();
    if (raw.isEmpty) {
      return fallback;
    }

    if (raw.startsWith('Exception: ')) {
      return raw.replaceFirst('Exception: ', '');
    }

    return raw;
  }
}
