part of 'explore_bloc.dart';

abstract class ExploreEvent extends Equatable {
  const ExploreEvent();

  @override
  List<Object?> get props => [];
}

class ExploreLoaded extends ExploreEvent {}

class MemberSelected extends ExploreEvent {
  final int? memberId;
  const MemberSelected(this.memberId);

  @override
  List<Object?> get props => [memberId];
}

class MemberLikePressed extends ExploreEvent {
  final int memberId;

  const MemberLikePressed(this.memberId);

  @override
  List<Object?> get props => [memberId];
}

class PhotoLikePressed extends ExploreEvent {
  final int memberId;
  final int pictureId;

  const PhotoLikePressed({required this.memberId, required this.pictureId});

  @override
  List<Object?> get props => [memberId, pictureId];
}

class MatchRequestPressed extends ExploreEvent {
  final int memberId;

  const MatchRequestPressed(this.memberId);

  @override
  List<Object?> get props => [memberId];
}

class MemberReported extends ExploreEvent {
  final int memberId;

  const MemberReported(this.memberId);

  @override
  List<Object?> get props => [memberId];
}

class MemberHidden extends ExploreEvent {
  final int memberId;

  const MemberHidden(this.memberId);

  @override
  List<Object?> get props => [memberId];
}

class ExploreNoticeCleared extends ExploreEvent {
  const ExploreNoticeCleared();
}
