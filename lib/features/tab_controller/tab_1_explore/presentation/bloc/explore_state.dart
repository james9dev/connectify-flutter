part of 'explore_bloc.dart';

enum ExploreStatus { initial, loading, success, failure }

class ExploreState extends Equatable {
  final ExploreStatus status;
  final List<Member> members;
  final Member? selectedMember;
  static const _unset = Object();

  const ExploreState({this.status = ExploreStatus.initial, this.members = const [], this.selectedMember});

  ExploreState copyWith({ExploreStatus? status, List<Member>? members, Object? selectedMember = _unset}) {
    return ExploreState(status: status ?? this.status, members: members ?? this.members, selectedMember: identical(selectedMember, _unset) ? this.selectedMember : selectedMember as Member?);
  }

  @override
  List<Object?> get props => [status, members, selectedMember];
}
