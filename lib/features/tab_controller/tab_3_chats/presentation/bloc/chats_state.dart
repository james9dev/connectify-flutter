part of 'chats_bloc.dart';

enum ChatSegment { sent, received, rooms }

enum DateRequestStatusFilter { all, requested, accepted, rejected }

enum ChatFetchStatus { initial, loading, success, failure }

class ChatsState extends Equatable {
  const ChatsState({
    this.selectedSegment = ChatSegment.sent,
    this.sentFilter = DateRequestStatusFilter.all,
    this.receivedFilter = DateRequestStatusFilter.all,
    this.sentStatus = ChatFetchStatus.initial,
    this.receivedStatus = ChatFetchStatus.initial,
    this.sentRequests = const <DateRequest>[],
    this.receivedRequests = const <DateRequest>[],
    this.actionInProgressIds = const <int>{},
    this.sentErrorMessage,
    this.receivedErrorMessage,
    this.noticeMessage,
  });

  static const _unset = Object();

  final ChatSegment selectedSegment;
  final DateRequestStatusFilter sentFilter;
  final DateRequestStatusFilter receivedFilter;
  final ChatFetchStatus sentStatus;
  final ChatFetchStatus receivedStatus;
  final List<DateRequest> sentRequests;
  final List<DateRequest> receivedRequests;
  final Set<int> actionInProgressIds;
  final String? sentErrorMessage;
  final String? receivedErrorMessage;
  final String? noticeMessage;

  ChatsState copyWith({
    ChatSegment? selectedSegment,
    DateRequestStatusFilter? sentFilter,
    DateRequestStatusFilter? receivedFilter,
    ChatFetchStatus? sentStatus,
    ChatFetchStatus? receivedStatus,
    List<DateRequest>? sentRequests,
    List<DateRequest>? receivedRequests,
    Set<int>? actionInProgressIds,
    Object? sentErrorMessage = _unset,
    Object? receivedErrorMessage = _unset,
    Object? noticeMessage = _unset,
  }) {
    return ChatsState(
      selectedSegment: selectedSegment ?? this.selectedSegment,
      sentFilter: sentFilter ?? this.sentFilter,
      receivedFilter: receivedFilter ?? this.receivedFilter,
      sentStatus: sentStatus ?? this.sentStatus,
      receivedStatus: receivedStatus ?? this.receivedStatus,
      sentRequests: sentRequests ?? this.sentRequests,
      receivedRequests: receivedRequests ?? this.receivedRequests,
      actionInProgressIds: actionInProgressIds ?? this.actionInProgressIds,
      sentErrorMessage: identical(sentErrorMessage, _unset) ? this.sentErrorMessage : sentErrorMessage as String?,
      receivedErrorMessage: identical(receivedErrorMessage, _unset) ? this.receivedErrorMessage : receivedErrorMessage as String?,
      noticeMessage: identical(noticeMessage, _unset) ? this.noticeMessage : noticeMessage as String?,
    );
  }

  @override
  List<Object?> get props => [
    selectedSegment,
    sentFilter,
    receivedFilter,
    sentStatus,
    receivedStatus,
    sentRequests,
    receivedRequests,
    actionInProgressIds,
    sentErrorMessage,
    receivedErrorMessage,
    noticeMessage,
  ];
}
