import 'package:connectify/features/onboarding/profile_photo/domain/entities/profile_photo_draft.dart';
import 'package:equatable/equatable.dart';

enum ProfilePhotoSubmitStatus { initial, inProgress, success, failure }

class ProfilePhotoState extends Equatable {
  static const int maxPhotos = 6;
  static const _unset = Object();

  final List<ProfilePhotoDraft> draftPhotos;
  final ProfilePhotoSubmitStatus submitStatus;
  final String? submitErrorMessage;
  final int uploadedCount;
  final int totalUploadCount;

  const ProfilePhotoState({
    this.draftPhotos = const <ProfilePhotoDraft>[],
    this.submitStatus = ProfilePhotoSubmitStatus.initial,
    this.submitErrorMessage,
    this.uploadedCount = 0,
    this.totalUploadCount = 0,
  });

  bool get isSubmitting => submitStatus == ProfilePhotoSubmitStatus.inProgress;

  bool get canComplete => draftPhotos.isNotEmpty && !isSubmitting;

  ProfilePhotoState copyWith({List<ProfilePhotoDraft>? draftPhotos, ProfilePhotoSubmitStatus? submitStatus, Object? submitErrorMessage = _unset, int? uploadedCount, int? totalUploadCount}) {
    return ProfilePhotoState(
      draftPhotos: draftPhotos ?? this.draftPhotos,
      submitStatus: submitStatus ?? this.submitStatus,
      submitErrorMessage: identical(submitErrorMessage, _unset) ? this.submitErrorMessage : submitErrorMessage as String?,
      uploadedCount: uploadedCount ?? this.uploadedCount,
      totalUploadCount: totalUploadCount ?? this.totalUploadCount,
    );
  }

  @override
  List<Object?> get props => [draftPhotos, submitStatus, submitErrorMessage, uploadedCount, totalUploadCount];
}
