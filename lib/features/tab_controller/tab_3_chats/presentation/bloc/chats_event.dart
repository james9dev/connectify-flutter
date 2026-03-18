part of 'chats_bloc.dart';

abstract class ChatsEvent extends Equatable {
  const ChatsEvent();

  @override
  List<Object?> get props => [];
}

class ChatsLoaded extends ChatsEvent {
  const ChatsLoaded();
}

class ChatSegmentChanged extends ChatsEvent {
  const ChatSegmentChanged(this.segment);

  final ChatSegment segment;

  @override
  List<Object?> get props => [segment];
}

class SentFilterChanged extends ChatsEvent {
  const SentFilterChanged(this.filter);

  final DateRequestStatusFilter filter;

  @override
  List<Object?> get props => [filter];
}

class ReceivedFilterChanged extends ChatsEvent {
  const ReceivedFilterChanged(this.filter);

  final DateRequestStatusFilter filter;

  @override
  List<Object?> get props => [filter];
}

class SentRequestsRefreshRequested extends ChatsEvent {
  const SentRequestsRefreshRequested();
}

class ReceivedRequestsRefreshRequested extends ChatsEvent {
  const ReceivedRequestsRefreshRequested();
}

class DateRequestAcceptedPressed extends ChatsEvent {
  const DateRequestAcceptedPressed(this.dateRequestId);

  final int dateRequestId;

  @override
  List<Object?> get props => [dateRequestId];
}

class DateRequestRejectedPressed extends ChatsEvent {
  const DateRequestRejectedPressed(this.dateRequestId);

  final int dateRequestId;

  @override
  List<Object?> get props => [dateRequestId];
}

class ChatsNoticeCleared extends ChatsEvent {
  const ChatsNoticeCleared();
}
