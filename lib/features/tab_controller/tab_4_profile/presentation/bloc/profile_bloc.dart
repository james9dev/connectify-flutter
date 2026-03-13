import 'package:connectify/features/tab_controller/tab_4_profile/domain/profile_repository.dart';
import 'package:connectify/features/tab_controller/tab_4_profile/presentation/bloc/profile_event.dart';
import 'package:connectify/features/tab_controller/tab_4_profile/presentation/bloc/profile_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final ProfileRepository repository;

  ProfileBloc(this.repository) : super(const ProfileState()) {
    on<ProfileLoaded>(_onLoaded);
    on<ProfilePhotoUploadRequested>(_onPhotoUploadRequested);
  }

  Future<void> _onLoaded(ProfileLoaded event, Emitter<ProfileState> emit) async {
    emit(state.copyWith(status: ProfileStatus.loading));
    try {
      final profile = await repository.getProfile();
      emit(state.copyWith(status: ProfileStatus.success, profile: profile));
    } catch (_) {
      emit(state.copyWith(status: ProfileStatus.failure));
    }
  }

  Future<void> _onPhotoUploadRequested(ProfilePhotoUploadRequested event, Emitter<ProfileState> emit) async {
    if (state.photoUploadStatus == ProfilePhotoUploadStatus.inProgress) {
      return;
    }

    emit(state.copyWith(photoUploadStatus: ProfilePhotoUploadStatus.inProgress, photoUploadErrorMessage: null));

    try {
      final updatedProfile = await repository.uploadProfilePhoto(imageBytes: event.imageBytes, fileName: event.fileName, contentType: event.contentType);
      emit(state.copyWith(status: ProfileStatus.success, profile: updatedProfile, photoUploadStatus: ProfilePhotoUploadStatus.success, photoUploadErrorMessage: null));
    } catch (error) {
      emit(state.copyWith(photoUploadStatus: ProfilePhotoUploadStatus.failure, photoUploadErrorMessage: _toErrorMessage(error)));
    }
  }

  String _toErrorMessage(Object error) {
    final raw = error.toString().trim();
    if (raw.isEmpty) {
      return '사진 업로드 중 오류가 발생했습니다.';
    }

    if (raw.startsWith('Exception: ')) {
      return raw.replaceFirst('Exception: ', '');
    }

    return raw;
  }
}
