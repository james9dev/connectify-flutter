import 'package:connectify/features/onboarding/profile_basic/domain/entities/profile_basic_info_command.dart';
import 'package:connectify/features/onboarding/profile_photo/domain/entities/profile_photo_draft.dart';
import 'package:connectify/features/onboarding/profile_photo/domain/profile_photo_repository.dart';
import 'package:connectify/features/onboarding/profile_photo/presentation/bloc/profile_photo_event.dart';
import 'package:connectify/features/onboarding/profile_photo/presentation/bloc/profile_photo_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ProfilePhotoBloc extends Bloc<ProfilePhotoEvent, ProfilePhotoState> {
  final ProfilePhotoRepository repository;
  final String kakaoAccessToken;
  final ProfileBasicInfoCommand basicInfoCommand;

  ProfilePhotoBloc({required this.repository, required this.kakaoAccessToken, required this.basicInfoCommand, List<ProfilePhotoDraft> initialDraftPhotos = const <ProfilePhotoDraft>[]})
    : super(ProfilePhotoState(draftPhotos: initialDraftPhotos.take(ProfilePhotoState.maxPhotos).map((photo) => photo.clone()).toList(growable: false))) {
    on<ProfilePhotoDraftAdded>(_onDraftAdded);
    on<ProfilePhotoDraftRemoved>(_onDraftRemoved);
    on<ProfilePhotoSubmitRequested>(_onSubmitRequested);
  }

  void _onDraftAdded(ProfilePhotoDraftAdded event, Emitter<ProfilePhotoState> emit) {
    if (state.isSubmitting || state.draftPhotos.length >= ProfilePhotoState.maxPhotos) {
      return;
    }

    final nextDrafts = <ProfilePhotoDraft>[...state.draftPhotos, event.draft.clone()];
    emit(state.copyWith(draftPhotos: nextDrafts, submitStatus: ProfilePhotoSubmitStatus.initial, submitErrorMessage: null, uploadedCount: 0, totalUploadCount: 0));
  }

  void _onDraftRemoved(ProfilePhotoDraftRemoved event, Emitter<ProfilePhotoState> emit) {
    if (state.isSubmitting || event.index < 0 || event.index >= state.draftPhotos.length) {
      return;
    }

    final nextDrafts = <ProfilePhotoDraft>[...state.draftPhotos]..removeAt(event.index);
    emit(state.copyWith(draftPhotos: nextDrafts, submitStatus: ProfilePhotoSubmitStatus.initial, submitErrorMessage: null, uploadedCount: 0, totalUploadCount: 0));
  }

  Future<void> _onSubmitRequested(ProfilePhotoSubmitRequested event, Emitter<ProfilePhotoState> emit) async {
    if (state.isSubmitting) {
      return;
    }

    final pendingDrafts = state.draftPhotos.map((photo) => photo.clone()).toList(growable: false);
    if (pendingDrafts.isEmpty) {
      emit(state.copyWith(submitStatus: ProfilePhotoSubmitStatus.failure, submitErrorMessage: '최소 1장의 사진을 등록해주세요.'));
      return;
    }

    emit(state.copyWith(submitStatus: ProfilePhotoSubmitStatus.inProgress, submitErrorMessage: null, uploadedCount: 0, totalUploadCount: pendingDrafts.length));

    try {
      await repository.completeOnboarding(
        kakaoAccessToken: kakaoAccessToken,
        basicInfoCommand: basicInfoCommand,
        draftPhotos: pendingDrafts,
        onUploadProgress: (uploadedCount, totalCount) {
          emit(state.copyWith(submitStatus: ProfilePhotoSubmitStatus.inProgress, uploadedCount: uploadedCount, totalUploadCount: totalCount));
        },
      );
      emit(
        state.copyWith(
          draftPhotos: const <ProfilePhotoDraft>[],
          submitStatus: ProfilePhotoSubmitStatus.success,
          submitErrorMessage: null,
          uploadedCount: pendingDrafts.length,
          totalUploadCount: pendingDrafts.length,
        ),
      );
    } catch (error) {
      final uploadedCount = error is ProfilePhotoOnboardingException ? error.uploadedCount : 0;
      final totalCount = error is ProfilePhotoOnboardingException ? error.totalCount : pendingDrafts.length;
      final remainingDrafts = pendingDrafts.skip(uploadedCount).map((photo) => photo.clone()).toList(growable: false);
      final errorMessage = _toErrorMessage(error);
      final message = uploadedCount > 0 && remainingDrafts.isNotEmpty ? '일부 사진만 업로드되었습니다. 남은 ${remainingDrafts.length}장을 다시 시도해주세요. $errorMessage' : errorMessage;

      emit(state.copyWith(draftPhotos: remainingDrafts, submitStatus: ProfilePhotoSubmitStatus.failure, submitErrorMessage: message, uploadedCount: uploadedCount, totalUploadCount: totalCount));
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
