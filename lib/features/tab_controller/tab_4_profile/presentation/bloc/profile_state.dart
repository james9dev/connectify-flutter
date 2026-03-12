import 'package:connectify/shared/models/member.dart';
import 'package:equatable/equatable.dart';

enum ProfileStatus { initial, loading, success, failure }

class ProfileState extends Equatable {
  final ProfileStatus status;
  final Member? profile;
  static const _unset = Object();

  const ProfileState({this.status = ProfileStatus.initial, this.profile});

  ProfileState copyWith({ProfileStatus? status, Object? profile = _unset}) {
    return ProfileState(status: status ?? this.status, profile: identical(profile, _unset) ? this.profile : profile as Member?);
  }

  @override
  List<Object?> get props => [status, profile];
}
