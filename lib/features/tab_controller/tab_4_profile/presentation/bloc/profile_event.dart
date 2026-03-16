import 'package:equatable/equatable.dart';

abstract class ProfileEvent extends Equatable {
  const ProfileEvent();

  @override
  List<Object?> get props => [];
}

class ProfileLoaded extends ProfileEvent {}

class ProfilePhotoUploadRequested extends ProfileEvent {
  final List<int> imageBytes;
  final String fileName;
  final String contentType;

  const ProfilePhotoUploadRequested({required this.imageBytes, required this.fileName, required this.contentType});

  @override
  List<Object?> get props => [imageBytes, fileName, contentType];
}

class ProfilePhotoDeleteRequested extends ProfileEvent {
  final int pictureId;

  const ProfilePhotoDeleteRequested({required this.pictureId});

  @override
  List<Object?> get props => [pictureId];
}

class ProfilePhotoReorderRequested extends ProfileEvent {
  final int pictureId;
  final int targetOrder;

  const ProfilePhotoReorderRequested({required this.pictureId, required this.targetOrder});

  @override
  List<Object?> get props => [pictureId, targetOrder];
}

class ProfileBasicInfoSaveRequested extends ProfileEvent {
  final String nickName;
  final String region;
  final String bio;

  const ProfileBasicInfoSaveRequested({required this.nickName, required this.region, required this.bio});

  @override
  List<Object?> get props => [nickName, region, bio];
}
