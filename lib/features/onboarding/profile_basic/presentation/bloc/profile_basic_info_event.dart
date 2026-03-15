import 'package:connectify/shared/models/member.dart';
import 'package:equatable/equatable.dart';

abstract class ProfileBasicInfoEvent extends Equatable {
  const ProfileBasicInfoEvent();

  @override
  List<Object?> get props => [];
}

class ProfileBasicInfoCatalogRequested extends ProfileBasicInfoEvent {
  const ProfileBasicInfoCatalogRequested();
}

class ProfileBasicInfoNicknameChanged extends ProfileBasicInfoEvent {
  final String nickname;

  const ProfileBasicInfoNicknameChanged(this.nickname);

  @override
  List<Object?> get props => [nickname];
}

class ProfileBasicInfoBioChanged extends ProfileBasicInfoEvent {
  final String bio;

  const ProfileBasicInfoBioChanged(this.bio);

  @override
  List<Object?> get props => [bio];
}

class ProfileBasicInfoGenderChanged extends ProfileBasicInfoEvent {
  final GenderType? gender;

  const ProfileBasicInfoGenderChanged(this.gender);

  @override
  List<Object?> get props => [gender];
}

class ProfileBasicInfoBirthDateChanged extends ProfileBasicInfoEvent {
  final DateTime? birthDate;

  const ProfileBasicInfoBirthDateChanged(this.birthDate);

  @override
  List<Object?> get props => [birthDate];
}

class ProfileBasicInfoRegionChanged extends ProfileBasicInfoEvent {
  final String? region;

  const ProfileBasicInfoRegionChanged(this.region);

  @override
  List<Object?> get props => [region];
}

class ProfileBasicInfoProfileTagToggled extends ProfileBasicInfoEvent {
  final int categoryId;
  final int tagId;

  const ProfileBasicInfoProfileTagToggled({required this.categoryId, required this.tagId});

  @override
  List<Object?> get props => [categoryId, tagId];
}

class ProfileBasicInfoPreferredTagToggled extends ProfileBasicInfoEvent {
  final int tagId;

  const ProfileBasicInfoPreferredTagToggled(this.tagId);

  @override
  List<Object?> get props => [tagId];
}

class ProfileBasicInfoSubmitted extends ProfileBasicInfoEvent {
  const ProfileBasicInfoSubmitted();
}

class ProfileBasicInfoNoticeCleared extends ProfileBasicInfoEvent {
  const ProfileBasicInfoNoticeCleared();
}

class ProfileBasicInfoValidationRequested extends ProfileBasicInfoEvent {
  const ProfileBasicInfoValidationRequested();
}
