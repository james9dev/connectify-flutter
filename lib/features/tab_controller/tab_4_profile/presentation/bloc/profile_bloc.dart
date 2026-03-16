import 'package:connectify/features/tab_controller/tab_4_profile/domain/profile_repository.dart';
import 'package:connectify/features/tab_controller/tab_4_profile/presentation/bloc/profile_event.dart';
import 'package:connectify/features/tab_controller/tab_4_profile/presentation/bloc/profile_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final ProfileRepository repository;

  ProfileBloc(this.repository) : super(const ProfileState()) {
    on<ProfileLoaded>(_onLoaded);
    on<ProfilePhotoUploadRequested>(_onPhotoUploadRequested);
    on<ProfilePhotoDeleteRequested>(_onPhotoDeleteRequested);
    on<ProfilePhotoReorderRequested>(_onPhotoReorderRequested);
    on<ProfileBasicInfoSaveRequested>(_onProfileBasicInfoSaveRequested);
  }

  Future<void> _onLoaded(ProfileLoaded event, Emitter<ProfileState> emit) async {
    emit(state.copyWith(status: ProfileStatus.loading));
    try {
      final profile = await repository.getProfile();
      emit(
        state.copyWith(
          status: ProfileStatus.success,
          profile: profile,
          photoReorderStatus: ProfilePhotoReorderStatus.initial,
          photoReorderErrorMessage: null,
          profileUpdateStatus: ProfileUpdateStatus.initial,
          profileUpdateErrorMessage: null,
        ),
      );
    } catch (_) {
      emit(state.copyWith(status: ProfileStatus.failure));
    }
  }

  Future<void> _onPhotoUploadRequested(ProfilePhotoUploadRequested event, Emitter<ProfileState> emit) async {
    if (state.photoUploadStatus == ProfilePhotoUploadStatus.inProgress ||
        state.photoDeleteStatus == ProfilePhotoDeleteStatus.inProgress ||
        state.photoReorderStatus == ProfilePhotoReorderStatus.inProgress ||
        state.profileUpdateStatus == ProfileUpdateStatus.inProgress) {
      return;
    }

    emit(
      state.copyWith(
        photoUploadStatus: ProfilePhotoUploadStatus.inProgress,
        photoUploadErrorMessage: null,
        photoDeleteStatus: ProfilePhotoDeleteStatus.initial,
        photoDeleteErrorMessage: null,
        photoReorderStatus: ProfilePhotoReorderStatus.initial,
        photoReorderErrorMessage: null,
        profileUpdateStatus: ProfileUpdateStatus.initial,
        profileUpdateErrorMessage: null,
      ),
    );

    try {
      final updatedProfile = await repository.uploadProfilePhoto(imageBytes: event.imageBytes, fileName: event.fileName, contentType: event.contentType);
      emit(state.copyWith(status: ProfileStatus.success, profile: updatedProfile, photoUploadStatus: ProfilePhotoUploadStatus.success, photoUploadErrorMessage: null));
    } catch (error) {
      emit(state.copyWith(photoUploadStatus: ProfilePhotoUploadStatus.failure, photoUploadErrorMessage: _toErrorMessage(error)));
    }
  }

  Future<void> _onPhotoDeleteRequested(ProfilePhotoDeleteRequested event, Emitter<ProfileState> emit) async {
    if (state.photoUploadStatus == ProfilePhotoUploadStatus.inProgress ||
        state.photoDeleteStatus == ProfilePhotoDeleteStatus.inProgress ||
        state.photoReorderStatus == ProfilePhotoReorderStatus.inProgress ||
        state.profileUpdateStatus == ProfileUpdateStatus.inProgress) {
      return;
    }

    emit(
      state.copyWith(
        photoDeleteStatus: ProfilePhotoDeleteStatus.inProgress,
        photoDeleteErrorMessage: null,
        photoUploadStatus: ProfilePhotoUploadStatus.initial,
        photoUploadErrorMessage: null,
        photoReorderStatus: ProfilePhotoReorderStatus.initial,
        photoReorderErrorMessage: null,
        profileUpdateStatus: ProfileUpdateStatus.initial,
        profileUpdateErrorMessage: null,
      ),
    );

    try {
      final updatedProfile = await repository.deleteProfilePhoto(pictureId: event.pictureId);
      emit(state.copyWith(status: ProfileStatus.success, profile: updatedProfile, photoDeleteStatus: ProfilePhotoDeleteStatus.success, photoDeleteErrorMessage: null));
    } catch (error) {
      emit(state.copyWith(photoDeleteStatus: ProfilePhotoDeleteStatus.failure, photoDeleteErrorMessage: _toErrorMessage(error)));
    }
  }

  Future<void> _onPhotoReorderRequested(ProfilePhotoReorderRequested event, Emitter<ProfileState> emit) async {
    if (state.photoUploadStatus == ProfilePhotoUploadStatus.inProgress ||
        state.photoDeleteStatus == ProfilePhotoDeleteStatus.inProgress ||
        state.photoReorderStatus == ProfilePhotoReorderStatus.inProgress ||
        state.profileUpdateStatus == ProfileUpdateStatus.inProgress) {
      return;
    }

    emit(
      state.copyWith(
        photoReorderStatus: ProfilePhotoReorderStatus.inProgress,
        photoReorderErrorMessage: null,
        photoUploadStatus: ProfilePhotoUploadStatus.initial,
        photoUploadErrorMessage: null,
        photoDeleteStatus: ProfilePhotoDeleteStatus.initial,
        photoDeleteErrorMessage: null,
        profileUpdateStatus: ProfileUpdateStatus.initial,
        profileUpdateErrorMessage: null,
      ),
    );

    try {
      final updatedProfile = await repository.reorderProfilePhoto(pictureId: event.pictureId, targetOrder: event.targetOrder);
      emit(state.copyWith(status: ProfileStatus.success, profile: updatedProfile, photoReorderStatus: ProfilePhotoReorderStatus.success, photoReorderErrorMessage: null));
    } catch (error) {
      emit(state.copyWith(photoReorderStatus: ProfilePhotoReorderStatus.failure, photoReorderErrorMessage: _toErrorMessage(error)));
    }
  }

  Future<void> _onProfileBasicInfoSaveRequested(ProfileBasicInfoSaveRequested event, Emitter<ProfileState> emit) async {
    if (state.photoUploadStatus == ProfilePhotoUploadStatus.inProgress ||
        state.photoDeleteStatus == ProfilePhotoDeleteStatus.inProgress ||
        state.photoReorderStatus == ProfilePhotoReorderStatus.inProgress ||
        state.profileUpdateStatus == ProfileUpdateStatus.inProgress) {
      return;
    }

    final member = state.profile;
    final profile = member?.profile;
    if (member == null || profile == null) {
      emit(state.copyWith(profileUpdateStatus: ProfileUpdateStatus.failure, profileUpdateErrorMessage: '프로필을 불러온 후 다시 시도해주세요.'));
      return;
    }

    final resolvedNickName = event.nickName.trim();
    final resolvedRegion = event.region.trim();
    final resolvedBio = event.bio.trim();

    if (resolvedNickName.isEmpty) {
      emit(state.copyWith(profileUpdateStatus: ProfileUpdateStatus.failure, profileUpdateErrorMessage: '닉네임을 입력해주세요.'));
      return;
    }

    final gender = profile.gender;
    final birthyear = profile.birthyear;
    final birthday = profile.birthday;
    if (gender == null || birthyear == null || birthday == null || resolvedRegion.isEmpty) {
      emit(state.copyWith(profileUpdateStatus: ProfileUpdateStatus.failure, profileUpdateErrorMessage: '필수 프로필 정보가 누락되어 수정할 수 없습니다.'));
      return;
    }

    emit(
      state.copyWith(
        profileUpdateStatus: ProfileUpdateStatus.inProgress,
        profileUpdateErrorMessage: null,
        photoUploadStatus: ProfilePhotoUploadStatus.initial,
        photoDeleteStatus: ProfilePhotoDeleteStatus.initial,
        photoReorderStatus: ProfilePhotoReorderStatus.initial,
        photoReorderErrorMessage: null,
      ),
    );

    try {
      await repository.updateProfileBasicInfo(
        nickName: resolvedNickName,
        gender: gender,
        birthyear: birthyear,
        birthday: birthday,
        region: resolvedRegion,
        bio: resolvedBio,
        profileTagIds: profile.profileTagIds.map((tag) => tag.id).toList(growable: false),
        preferredTagIds: profile.preferredTagIds.map((tag) => tag.id).toList(growable: false),
      );

      final refreshed = await repository.getProfile();
      emit(state.copyWith(status: ProfileStatus.success, profile: refreshed ?? member, profileUpdateStatus: ProfileUpdateStatus.success, profileUpdateErrorMessage: null));
    } catch (error) {
      emit(state.copyWith(profileUpdateStatus: ProfileUpdateStatus.failure, profileUpdateErrorMessage: _toErrorMessage(error)));
    }
  }

  String _toErrorMessage(Object error) {
    final raw = error.toString().trim();
    if (raw.isEmpty) {
      return '사진 처리 중 오류가 발생했습니다.';
    }

    if (raw.startsWith('Exception: ')) {
      return raw.replaceFirst('Exception: ', '');
    }

    return raw;
  }
}
