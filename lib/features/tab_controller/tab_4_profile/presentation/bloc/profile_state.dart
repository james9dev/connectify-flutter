import 'package:connectify/shared/models/member.dart';
import 'package:equatable/equatable.dart';

class ProfileState extends Equatable {
  final Member? profile;

  const ProfileState({this.profile});

  ProfileState copyWith({Member? profile}) {
    return ProfileState(profile: this.profile);
  }

  @override
  List<Object?> get props => [profile];
}
