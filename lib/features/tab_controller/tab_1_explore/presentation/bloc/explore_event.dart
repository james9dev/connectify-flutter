part of 'explore_bloc.dart';

abstract class ExploreEvent extends Equatable {
  const ExploreEvent();

  @override
  List<Object?> get props => [];
}

class ExploreLoaded extends ExploreEvent {}

class MemberSelected extends ExploreEvent {
  final Member? member;
  const MemberSelected(this.member);

  @override
  List<Object?> get props => [member];
}
