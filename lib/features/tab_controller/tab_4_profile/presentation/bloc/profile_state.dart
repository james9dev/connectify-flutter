import 'package:connectify/shared/models/member.dart';
import 'package:equatable/equatable.dart';

enum ProfileStatus { initial, loading, success, failure }

enum ProfilePhotoUploadStatus { initial, inProgress, success, failure }

enum ProfilePhotoDeleteStatus { initial, inProgress, success, failure }

enum ProfilePhotoReorderStatus { initial, inProgress, success, failure }

enum ProfileUpdateStatus { initial, inProgress, success, failure }

class ProfileState extends Equatable {
  final ProfileStatus status;
  final Member? profile;
  final ProfilePhotoUploadStatus photoUploadStatus;
  final String? photoUploadErrorMessage;
  final ProfilePhotoDeleteStatus photoDeleteStatus;
  final String? photoDeleteErrorMessage;
  final ProfilePhotoReorderStatus photoReorderStatus;
  final String? photoReorderErrorMessage;
  final ProfileUpdateStatus profileUpdateStatus;
  final String? profileUpdateErrorMessage;
  static const _unset = Object();

  const ProfileState({
    this.status = ProfileStatus.initial,
    this.profile,
    this.photoUploadStatus = ProfilePhotoUploadStatus.initial,
    this.photoUploadErrorMessage,
    this.photoDeleteStatus = ProfilePhotoDeleteStatus.initial,
    this.photoDeleteErrorMessage,
    this.photoReorderStatus = ProfilePhotoReorderStatus.initial,
    this.photoReorderErrorMessage,
    this.profileUpdateStatus = ProfileUpdateStatus.initial,
    this.profileUpdateErrorMessage,
  });

  ProfileState copyWith({
    ProfileStatus? status,
    Object? profile = _unset,
    ProfilePhotoUploadStatus? photoUploadStatus,
    Object? photoUploadErrorMessage = _unset,
    ProfilePhotoDeleteStatus? photoDeleteStatus,
    Object? photoDeleteErrorMessage = _unset,
    ProfilePhotoReorderStatus? photoReorderStatus,
    Object? photoReorderErrorMessage = _unset,
    ProfileUpdateStatus? profileUpdateStatus,
    Object? profileUpdateErrorMessage = _unset,
  }) {
    return ProfileState(
      status: status ?? this.status,
      profile: identical(profile, _unset) ? this.profile : profile as Member?,
      photoUploadStatus: photoUploadStatus ?? this.photoUploadStatus,
      photoUploadErrorMessage: identical(photoUploadErrorMessage, _unset) ? this.photoUploadErrorMessage : photoUploadErrorMessage as String?,
      photoDeleteStatus: photoDeleteStatus ?? this.photoDeleteStatus,
      photoDeleteErrorMessage: identical(photoDeleteErrorMessage, _unset) ? this.photoDeleteErrorMessage : photoDeleteErrorMessage as String?,
      photoReorderStatus: photoReorderStatus ?? this.photoReorderStatus,
      photoReorderErrorMessage: identical(photoReorderErrorMessage, _unset) ? this.photoReorderErrorMessage : photoReorderErrorMessage as String?,
      profileUpdateStatus: profileUpdateStatus ?? this.profileUpdateStatus,
      profileUpdateErrorMessage: identical(profileUpdateErrorMessage, _unset) ? this.profileUpdateErrorMessage : profileUpdateErrorMessage as String?,
    );
  }

  @override
  List<Object?> get props => [
    status,
    profile,
    photoUploadStatus,
    photoUploadErrorMessage,
    photoDeleteStatus,
    photoDeleteErrorMessage,
    photoReorderStatus,
    photoReorderErrorMessage,
    profileUpdateStatus,
    profileUpdateErrorMessage,
  ];
}
