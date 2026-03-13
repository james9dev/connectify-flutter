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
