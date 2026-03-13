import 'package:connectify/shared/models/member.dart';
import 'package:equatable/equatable.dart';

enum ProfileStatus { initial, loading, success, failure }

enum ProfilePhotoUploadStatus { initial, inProgress, success, failure }

class ProfileState extends Equatable {
  final ProfileStatus status;
  final Member? profile;
  final ProfilePhotoUploadStatus photoUploadStatus;
  final String? photoUploadErrorMessage;
  static const _unset = Object();

  const ProfileState({this.status = ProfileStatus.initial, this.profile, this.photoUploadStatus = ProfilePhotoUploadStatus.initial, this.photoUploadErrorMessage});

  ProfileState copyWith({ProfileStatus? status, Object? profile = _unset, ProfilePhotoUploadStatus? photoUploadStatus, Object? photoUploadErrorMessage = _unset}) {
    return ProfileState(
      status: status ?? this.status,
      profile: identical(profile, _unset) ? this.profile : profile as Member?,
      photoUploadStatus: photoUploadStatus ?? this.photoUploadStatus,
      photoUploadErrorMessage: identical(photoUploadErrorMessage, _unset) ? this.photoUploadErrorMessage : photoUploadErrorMessage as String?,
    );
  }

  @override
  List<Object?> get props => [status, profile, photoUploadStatus, photoUploadErrorMessage];
}
