import 'package:connectify/core/di/di.dart';
import 'package:connectify/features/member_profile/presentation/view/member_profile_detail_page.dart';
import 'package:connectify/features/tab_controller/tab_3_chats/domain/chat_repository.dart';
import 'package:connectify/features/tab_controller/tab_3_chats/domain/entities/date_request.dart';
import 'package:connectify/features/tab_controller/tab_3_chats/presentation/bloc/chats_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

const Color _accentYellow = Color(0xFFFFC629);
const Color _pageBackground = Color(0xFFFFF8E7);
const Color _surface = Color(0xFFFFFEF9);
const Color _ink = Color(0xFF14130F);
const Color _muted = Color(0xFF6B675D);
const Color _line = Color(0xFFE4DCC0);

class ChatsPage extends StatelessWidget {
  const ChatsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(create: (_) => ChatsBloc(getIt<ChatRepository>())..add(const ChatsLoaded()), child: const _ChatsView());
  }
}

class _ChatsView extends StatelessWidget {
  const _ChatsView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageBackground,
      appBar: AppBar(
        backgroundColor: _pageBackground,
        elevation: 0,
        centerTitle: false,
        title: const Text(
          'Chat',
          style: TextStyle(fontWeight: FontWeight.w900, color: _ink),
        ),
      ),
      body: SafeArea(
        top: false,
        child: BlocConsumer<ChatsBloc, ChatsState>(
          listenWhen: (previous, current) => previous.noticeMessage != current.noticeMessage,
          listener: (context, state) {
            if (state.noticeMessage == null) {
              return;
            }
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(content: Text(state.noticeMessage!)));
            context.read<ChatsBloc>().add(const ChatsNoticeCleared());
          },
          builder: (context, state) {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 2, 14, 10),
                  child: _ChatSegmentTabs(selectedSegment: state.selectedSegment, onSegmentSelected: (segment) => context.read<ChatsBloc>().add(ChatSegmentChanged(segment))),
                ),
                Expanded(child: _buildSegmentBody(context, state)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSegmentBody(BuildContext context, ChatsState state) {
    switch (state.selectedSegment) {
      case ChatSegment.sent:
        return _DateRequestListSection(
          title: '내가 데이트 요청한 내역',
          filter: state.sentFilter,
          status: state.sentStatus,
          requests: state.sentRequests,
          errorMessage: state.sentErrorMessage,
          emptyMessage: '보낸 데이트 요청 내역이 없어요.',
          onFilterChanged: (nextFilter) => context.read<ChatsBloc>().add(SentFilterChanged(nextFilter)),
          onRefresh: () async => context.read<ChatsBloc>().add(const SentRequestsRefreshRequested()),
          itemBuilder: (request) => _SentDateRequestCard(
            request: request,
            onTap: () => _openMemberProfilePage(context, memberId: request.receiverMemberId, fallbackName: request.receiverNickName),
          ),
        );
      case ChatSegment.received:
        return _DateRequestListSection(
          title: '나에게 데이트 요청된 내역',
          filter: state.receivedFilter,
          status: state.receivedStatus,
          requests: state.receivedRequests,
          errorMessage: state.receivedErrorMessage,
          emptyMessage: '받은 데이트 요청 내역이 없어요.',
          onFilterChanged: (nextFilter) => context.read<ChatsBloc>().add(ReceivedFilterChanged(nextFilter)),
          onRefresh: () async => context.read<ChatsBloc>().add(const ReceivedRequestsRefreshRequested()),
          itemBuilder: (request) => _ReceivedDateRequestCard(
            request: request,
            isActionInProgress: state.actionInProgressIds.contains(request.id),
            onAcceptPressed: () => context.read<ChatsBloc>().add(DateRequestAcceptedPressed(request.id)),
            onRejectPressed: () => context.read<ChatsBloc>().add(DateRequestRejectedPressed(request.id)),
            onTap: () => _openMemberProfilePage(context, memberId: request.requesterMemberId, fallbackName: request.requesterNickName),
          ),
        );
      case ChatSegment.rooms:
        return const _ChatRoomPlaceholder();
    }
  }

  Future<void> _openMemberProfilePage(BuildContext context, {required int memberId, required String fallbackName}) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => MemberProfileDetailPage(
          memberId: memberId,
          fallbackName: fallbackName,
          loadMember: (id) => getIt<ChatRepository>().getMemberProfile(memberId: id),
        ),
      ),
    );
  }
}

class _ChatSegmentTabs extends StatelessWidget {
  const _ChatSegmentTabs({required this.selectedSegment, required this.onSegmentSelected});

  final ChatSegment selectedSegment;
  final ValueChanged<ChatSegment> onSegmentSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _line),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ChatSegmentButton(label: '보낸 요청', isSelected: selectedSegment == ChatSegment.sent, onTap: () => onSegmentSelected(ChatSegment.sent)),
          ),
          Expanded(
            child: _ChatSegmentButton(label: '받은 요청', isSelected: selectedSegment == ChatSegment.received, onTap: () => onSegmentSelected(ChatSegment.received)),
          ),
          Expanded(
            child: _ChatSegmentButton(label: '대화 목록', isSelected: selectedSegment == ChatSegment.rooms, onTap: () => onSegmentSelected(ChatSegment.rooms)),
          ),
        ],
      ),
    );
  }
}

class _ChatSegmentButton extends StatelessWidget {
  const _ChatSegmentButton({required this.label, required this.isSelected, required this.onTap});

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      margin: const EdgeInsets.all(3),
      decoration: BoxDecoration(color: isSelected ? _accentYellow : Colors.transparent, borderRadius: BorderRadius.circular(999)),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: isSelected ? _ink : _muted),
          ),
        ),
      ),
    );
  }
}

class _DateRequestListSection extends StatelessWidget {
  const _DateRequestListSection({
    required this.title,
    required this.filter,
    required this.status,
    required this.requests,
    required this.errorMessage,
    required this.emptyMessage,
    required this.onFilterChanged,
    required this.onRefresh,
    required this.itemBuilder,
  });

  final String title;
  final DateRequestStatusFilter filter;
  final ChatFetchStatus status;
  final List<DateRequest> requests;
  final String? errorMessage;
  final String emptyMessage;
  final ValueChanged<DateRequestStatusFilter> onFilterChanged;
  final Future<void> Function() onRefresh;
  final Widget Function(DateRequest request) itemBuilder;

  @override
  Widget build(BuildContext context) {
    if (status == ChatFetchStatus.loading && requests.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (status == ChatFetchStatus.failure && requests.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              errorMessage ?? '목록을 불러오지 못했어요.',
              style: const TextStyle(color: _muted, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            OutlinedButton(onPressed: onRefresh, child: const Text('다시 시도')),
          ],
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w800, color: _ink, fontSize: 16),
              ),
              const SizedBox(height: 8),
              _DateRequestFilterTabs(selectedFilter: filter, onFilterChanged: onFilterChanged),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: onRefresh,
            child: requests.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      const SizedBox(height: 90),
                      Center(
                        child: Text(
                          emptyMessage,
                          style: const TextStyle(color: _muted, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  )
                : ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                    padding: const EdgeInsets.fromLTRB(14, 0, 14, 20),
                    itemCount: requests.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) => itemBuilder(requests[index]),
                  ),
          ),
        ),
      ],
    );
  }
}

class _DateRequestFilterTabs extends StatelessWidget {
  const _DateRequestFilterTabs({required this.selectedFilter, required this.onFilterChanged});

  final DateRequestStatusFilter selectedFilter;
  final ValueChanged<DateRequestStatusFilter> onFilterChanged;

  @override
  Widget build(BuildContext context) {
    const allFilters = <DateRequestStatusFilter>[DateRequestStatusFilter.all, DateRequestStatusFilter.requested, DateRequestStatusFilter.accepted, DateRequestStatusFilter.rejected];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final filter in allFilters) ...[
            ChoiceChip(
              label: Text(_filterLabel(filter)),
              selected: selectedFilter == filter,
              onSelected: (_) => onFilterChanged(filter),
              selectedColor: _accentYellow,
              side: const BorderSide(color: _line),
              backgroundColor: _surface,
              labelStyle: TextStyle(color: selectedFilter == filter ? _ink : _muted, fontWeight: FontWeight.w700),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }

  String _filterLabel(DateRequestStatusFilter filter) {
    switch (filter) {
      case DateRequestStatusFilter.all:
        return '전체';
      case DateRequestStatusFilter.requested:
        return '대기';
      case DateRequestStatusFilter.accepted:
        return '수락';
      case DateRequestStatusFilter.rejected:
        return '거절';
    }
  }
}

class _SentDateRequestCard extends StatelessWidget {
  const _SentDateRequestCard({required this.request, required this.onTap});

  final DateRequest request;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _line),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _RequestAvatar(initial: request.receiverNickName),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _safeName(request.receiverNickName),
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: _ink),
                        ),
                      ),
                      _RequestStatusChip(status: request.status),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '요청 시각: ${_formatDateTime(request.requestedAt)}',
                    style: const TextStyle(fontSize: 12, color: _muted, fontWeight: FontWeight.w600),
                  ),
                  if (request.requestMessage != null && request.requestMessage!.trim().isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      request.requestMessage!.trim(),
                      style: const TextStyle(fontSize: 12, color: _ink, fontWeight: FontWeight.w600),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReceivedDateRequestCard extends StatelessWidget {
  const _ReceivedDateRequestCard({required this.request, required this.isActionInProgress, required this.onAcceptPressed, required this.onRejectPressed, required this.onTap});

  final DateRequest request;
  final bool isActionInProgress;
  final VoidCallback onAcceptPressed;
  final VoidCallback onRejectPressed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _line),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _RequestAvatar(initial: request.requesterNickName),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _safeName(request.requesterNickName),
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: _ink),
                        ),
                      ),
                      _RequestStatusChip(status: request.status),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '요청 시각: ${_formatDateTime(request.requestedAt)}',
                    style: const TextStyle(fontSize: 12, color: _muted, fontWeight: FontWeight.w600),
                  ),
                  if (request.requestMessage != null && request.requestMessage!.trim().isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      request.requestMessage!.trim(),
                      style: const TextStyle(fontSize: 12, color: _ink, fontWeight: FontWeight.w600),
                    ),
                  ],
                  if (request.status == DateRequestStatus.requested) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: isActionInProgress ? null : onRejectPressed,
                            child: isActionInProgress ? const SizedBox(height: 14, width: 14, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('거절'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: FilledButton(
                            style: FilledButton.styleFrom(backgroundColor: _accentYellow, foregroundColor: _ink),
                            onPressed: isActionInProgress ? null : onAcceptPressed,
                            child: isActionInProgress ? const SizedBox(height: 14, width: 14, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('수락'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RequestAvatar extends StatelessWidget {
  const _RequestAvatar({required this.initial});

  final String initial;

  @override
  Widget build(BuildContext context) {
    final trimmed = initial.trim();
    final avatarText = trimmed.isEmpty ? '?' : trimmed.substring(0, 1);

    return CircleAvatar(
      radius: 22,
      backgroundColor: const Color(0xFFFFE9A6),
      child: Text(
        avatarText,
        style: const TextStyle(fontWeight: FontWeight.w900, color: _ink),
      ),
    );
  }
}

class _RequestStatusChip extends StatelessWidget {
  const _RequestStatusChip({required this.status});

  final DateRequestStatus status;

  @override
  Widget build(BuildContext context) {
    final label = _statusLabel(status);
    final color = _statusColor(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.32)),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: color),
      ),
    );
  }

  String _statusLabel(DateRequestStatus status) {
    switch (status) {
      case DateRequestStatus.requested:
        return '대기';
      case DateRequestStatus.accepted:
        return '수락';
      case DateRequestStatus.rejected:
        return '거절';
    }
  }

  Color _statusColor(DateRequestStatus status) {
    switch (status) {
      case DateRequestStatus.requested:
        return const Color(0xFFB07700);
      case DateRequestStatus.accepted:
        return const Color(0xFF157A43);
      case DateRequestStatus.rejected:
        return const Color(0xFFB12A2A);
    }
  }
}

class _ChatRoomPlaceholder extends StatelessWidget {
  const _ChatRoomPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 26),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.chat_bubble_outline_rounded, size: 54, color: _muted),
            const SizedBox(height: 10),
            const Text(
              '대화 목록은 준비 중입니다.',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _ink),
            ),
            const SizedBox(height: 6),
            Text(
              'Chat room API 작업 완료 후 연결될 예정이에요.',
              textAlign: TextAlign.center,
              style: TextStyle(color: _muted.withValues(alpha: 0.9), fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

String _safeName(String rawName) {
  final trimmed = rawName.trim();
  if (trimmed.isEmpty) {
    return '이름 없음';
  }
  return trimmed;
}

String _formatDateTime(DateTime? dateTime) {
  if (dateTime == null) {
    return '-';
  }

  final local = dateTime.toLocal();
  final month = local.month.toString().padLeft(2, '0');
  final day = local.day.toString().padLeft(2, '0');
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '$month/$day $hour:$minute';
}
