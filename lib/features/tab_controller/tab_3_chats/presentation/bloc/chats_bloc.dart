import 'package:bloc/bloc.dart';
import 'package:connectify/features/tab_controller/tab_3_chats/domain/chat_repository.dart';
import 'package:connectify/features/tab_controller/tab_3_chats/domain/entities/date_request.dart';
import 'package:equatable/equatable.dart';

part 'chats_event.dart';
part 'chats_state.dart';

class ChatsBloc extends Bloc<ChatsEvent, ChatsState> {
  ChatsBloc(this._chatRepository) : super(const ChatsState()) {
    on<ChatsLoaded>(_onLoaded);
    on<ChatSegmentChanged>(_onSegmentChanged);
    on<SentFilterChanged>(_onSentFilterChanged);
    on<ReceivedFilterChanged>(_onReceivedFilterChanged);
    on<SentRequestsRefreshRequested>(_onSentRefreshRequested);
    on<ReceivedRequestsRefreshRequested>(_onReceivedRefreshRequested);
    on<DateRequestCanceledPressed>(_onDateRequestCanceledPressed);
    on<DateRequestAcceptedPressed>(_onDateRequestAcceptedPressed);
    on<DateRequestRejectedPressed>(_onDateRequestRejectedPressed);
    on<ChatsNoticeCleared>(_onNoticeCleared);
  }

  final ChatRepository _chatRepository;

  Future<void> _onLoaded(ChatsLoaded event, Emitter<ChatsState> emit) async {
    await _loadBySegment(emit, state.selectedSegment, forceReload: true);
  }

  Future<void> _onSegmentChanged(ChatSegmentChanged event, Emitter<ChatsState> emit) async {
    if (state.selectedSegment == event.segment) {
      return;
    }

    emit(state.copyWith(selectedSegment: event.segment));
    await _loadBySegment(emit, event.segment, forceReload: false);
  }

  Future<void> _onSentFilterChanged(SentFilterChanged event, Emitter<ChatsState> emit) async {
    if (state.sentFilter == event.filter) {
      return;
    }
    emit(state.copyWith(sentFilter: event.filter));
    await _loadSentRequests(emit, forceReload: true);
  }

  Future<void> _onReceivedFilterChanged(ReceivedFilterChanged event, Emitter<ChatsState> emit) async {
    if (state.receivedFilter == event.filter) {
      return;
    }
    emit(state.copyWith(receivedFilter: event.filter));
    await _loadReceivedRequests(emit, forceReload: true);
  }

  Future<void> _onSentRefreshRequested(SentRequestsRefreshRequested event, Emitter<ChatsState> emit) async {
    await _loadSentRequests(emit, forceReload: true);
  }

  Future<void> _onReceivedRefreshRequested(ReceivedRequestsRefreshRequested event, Emitter<ChatsState> emit) async {
    await _loadReceivedRequests(emit, forceReload: true);
  }

  Future<void> _onDateRequestCanceledPressed(DateRequestCanceledPressed event, Emitter<ChatsState> emit) async {
    if (state.actionInProgressIds.contains(event.dateRequestId)) {
      return;
    }

    emit(state.copyWith(actionInProgressIds: <int>{...state.actionInProgressIds, event.dateRequestId}));

    try {
      await _chatRepository.cancelDateRequest(dateRequestId: event.dateRequestId);
      emit(state.copyWith(noticeMessage: '보낸 데이트 요청을 취소했어요.'));
      await _loadSentRequests(emit, forceReload: true);
    } catch (_) {
      emit(state.copyWith(noticeMessage: '보낸 데이트 요청 취소에 실패했습니다.'));
    } finally {
      final nextActionInProgress = <int>{...state.actionInProgressIds}..remove(event.dateRequestId);
      emit(state.copyWith(actionInProgressIds: nextActionInProgress));
    }
  }

  Future<void> _onDateRequestAcceptedPressed(DateRequestAcceptedPressed event, Emitter<ChatsState> emit) async {
    if (state.actionInProgressIds.contains(event.dateRequestId)) {
      return;
    }

    emit(state.copyWith(actionInProgressIds: <int>{...state.actionInProgressIds, event.dateRequestId}));

    try {
      await _chatRepository.acceptDateRequest(dateRequestId: event.dateRequestId);
      emit(state.copyWith(noticeMessage: '데이트 요청을 수락했어요.'));
      await _loadReceivedRequests(emit, forceReload: true);
    } catch (_) {
      emit(state.copyWith(noticeMessage: '데이트 요청 수락에 실패했습니다.'));
    } finally {
      final nextActionInProgress = <int>{...state.actionInProgressIds}..remove(event.dateRequestId);
      emit(state.copyWith(actionInProgressIds: nextActionInProgress));
    }
  }

  Future<void> _onDateRequestRejectedPressed(DateRequestRejectedPressed event, Emitter<ChatsState> emit) async {
    if (state.actionInProgressIds.contains(event.dateRequestId)) {
      return;
    }

    emit(state.copyWith(actionInProgressIds: <int>{...state.actionInProgressIds, event.dateRequestId}));

    try {
      await _chatRepository.rejectDateRequest(dateRequestId: event.dateRequestId);
      emit(state.copyWith(noticeMessage: '데이트 요청을 거절했어요.'));
      await _loadReceivedRequests(emit, forceReload: true);
    } catch (_) {
      emit(state.copyWith(noticeMessage: '데이트 요청 거절에 실패했습니다.'));
    } finally {
      final nextActionInProgress = <int>{...state.actionInProgressIds}..remove(event.dateRequestId);
      emit(state.copyWith(actionInProgressIds: nextActionInProgress));
    }
  }

  void _onNoticeCleared(ChatsNoticeCleared event, Emitter<ChatsState> emit) {
    emit(state.copyWith(noticeMessage: null));
  }

  Future<void> _loadBySegment(Emitter<ChatsState> emit, ChatSegment segment, {required bool forceReload}) async {
    switch (segment) {
      case ChatSegment.sent:
        await _loadSentRequests(emit, forceReload: forceReload);
      case ChatSegment.received:
        await _loadReceivedRequests(emit, forceReload: forceReload);
      case ChatSegment.rooms:
        return;
    }
  }

  Future<void> _loadSentRequests(Emitter<ChatsState> emit, {required bool forceReload}) async {
    if (!forceReload && state.sentStatus != ChatFetchStatus.initial) {
      return;
    }

    emit(state.copyWith(sentStatus: ChatFetchStatus.loading, sentErrorMessage: null));
    try {
      final requests = await _chatRepository.getSentDateRequests(status: _mapFilterToStatus(state.sentFilter));
      emit(state.copyWith(sentStatus: ChatFetchStatus.success, sentRequests: requests, sentErrorMessage: null));
    } catch (error) {
      emit(state.copyWith(sentStatus: ChatFetchStatus.failure, sentErrorMessage: _normalizeErrorMessage(error)));
    }
  }

  Future<void> _loadReceivedRequests(Emitter<ChatsState> emit, {required bool forceReload}) async {
    if (!forceReload && state.receivedStatus != ChatFetchStatus.initial) {
      return;
    }

    emit(state.copyWith(receivedStatus: ChatFetchStatus.loading, receivedErrorMessage: null));
    try {
      final requests = await _chatRepository.getReceivedDateRequests(status: _mapFilterToStatus(state.receivedFilter));
      emit(state.copyWith(receivedStatus: ChatFetchStatus.success, receivedRequests: requests, receivedErrorMessage: null));
    } catch (error) {
      emit(state.copyWith(receivedStatus: ChatFetchStatus.failure, receivedErrorMessage: _normalizeErrorMessage(error)));
    }
  }

  DateRequestStatus? _mapFilterToStatus(DateRequestStatusFilter filter) {
    switch (filter) {
      case DateRequestStatusFilter.all:
        return null;
      case DateRequestStatusFilter.requested:
        return DateRequestStatus.requested;
      case DateRequestStatusFilter.accepted:
        return DateRequestStatus.accepted;
      case DateRequestStatusFilter.rejected:
        return DateRequestStatus.rejected;
    }
  }

  String _normalizeErrorMessage(Object error) {
    final raw = error.toString().trim();
    if (raw.isEmpty) {
      return '목록을 불러오지 못했어요.';
    }
    if (raw.startsWith('Exception: ')) {
      return raw.replaceFirst('Exception: ', '');
    }
    return raw;
  }
}
