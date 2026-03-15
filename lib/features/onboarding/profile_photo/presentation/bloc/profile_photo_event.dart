import 'package:connectify/features/onboarding/profile_photo/domain/entities/profile_photo_draft.dart';
import 'package:equatable/equatable.dart';

abstract class ProfilePhotoEvent extends Equatable {
  const ProfilePhotoEvent();

  @override
  List<Object?> get props => [];
}

class ProfilePhotoDraftAdded extends ProfilePhotoEvent {
  final ProfilePhotoDraft draft;

  const ProfilePhotoDraftAdded({required this.draft});

  @override
  List<Object?> get props => [draft];
}

class ProfilePhotoDraftRemoved extends ProfilePhotoEvent {
  final int index;

  const ProfilePhotoDraftRemoved({required this.index});

  @override
  List<Object?> get props => [index];
}

class ProfilePhotoSubmitRequested extends ProfilePhotoEvent {
  const ProfilePhotoSubmitRequested();
}
