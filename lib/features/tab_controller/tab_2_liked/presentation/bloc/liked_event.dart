part of 'liked_bloc.dart';

abstract class LikedEvent extends Equatable {
  const LikedEvent();

  @override
  List<Object?> get props => [];
}

class LikedStarted extends LikedEvent {
  const LikedStarted();
}

class LikedSegmentChanged extends LikedEvent {
  const LikedSegmentChanged(this.segment);

  final LikedSegment segment;

  @override
  List<Object?> get props => [segment];
}

class LikedRefreshRequested extends LikedEvent {
  const LikedRefreshRequested({this.segment});

  final LikedSegment? segment;

  @override
  List<Object?> get props => [segment];
}
