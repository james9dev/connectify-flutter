part of 'explore_bloc.dart';

enum ExploreStatus { initial, loading, success, failure }

class ExploreState extends Equatable {
  final ExploreStatus status;
  final List<Member> members;
  final Member? selectedMember;

  const ExploreState({this.status = ExploreStatus.initial, this.members = const [], this.selectedMember});

  ExploreState copyWith({ExploreStatus? status, List<Member>? members, Member? selectedMember}) {
    return ExploreState(status: status ?? this.status, members: members ?? this.members, selectedMember: selectedMember);
  }

  @override
  List<Object?> get props => [status, members, selectedMember];
}
