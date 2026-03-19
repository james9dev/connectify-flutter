import 'dart:ui' show lerpDouble;
import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:connectify/core/di/di.dart';
import 'package:connectify/features/member_profile/presentation/view/member_profile_detail_view.dart';
import 'package:connectify/features/tab_controller/tab_1_explore/domain/member_repository.dart';
import 'package:connectify/features/tab_controller/tab_1_explore/presentation/bloc/explore_bloc.dart';
import 'package:connectify/shared/models/member.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

const Color _accentYellow = Color(0xFFFFC629);
const Color _pageBackground = Color(0xFFFFF8E7);
const Color _surface = Color(0xFFFFFEF9);
const Color _ink = Color(0xFF14130F);
const Color _muted = Color(0xFF6B675D);
const Color _line = Color(0xFFE4DCC0);

bool _canRequestDate(MyDateRequestStatus? status) {
  return status == null || status == MyDateRequestStatus.canceled;
}

class ExplorePage extends StatelessWidget {
  const ExplorePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(create: (_) => ExploreBloc(getIt<MemberRepository>())..add(ExploreLoaded()), child: const ExploreView());
  }
}

class ExploreView extends StatefulWidget {
  const ExploreView({super.key});

  @override
  State<ExploreView> createState() => _ExploreViewState();
}

class _ExploreViewState extends State<ExploreView> {
  static const double _collapseTriggerOffset = 120;
  double _collapseProgress = 0;

  void _handleDetailScroll(double offset) {
    final nextProgress = (offset / _collapseTriggerOffset).clamp(0.0, 1.0);
    if ((nextProgress - _collapseProgress).abs() < 0.01) {
      return;
    }

    setState(() {
      _collapseProgress = nextProgress;
    });
  }

  void _expandTopAreaIfNeeded() {
    if (_collapseProgress <= 0) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _collapseProgress <= 0) {
        return;
      }
      setState(() {
        _collapseProgress = 0;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final listBottomGap = lerpDouble(12, 6, _collapseProgress)!;
    final listVerticalPadding = lerpDouble(10, 4, _collapseProgress)!;

    return Scaffold(
      backgroundColor: _pageBackground,
      body: SafeArea(
        child: BlocConsumer<ExploreBloc, ExploreState>(
          listenWhen: (previous, current) => previous.noticeMessage != current.noticeMessage,
          listener: (context, state) {
            if (state.noticeMessage == null) {
              return;
            }

            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(content: Text(state.noticeMessage!)));
            context.read<ExploreBloc>().add(const ExploreNoticeCleared());
          },
          builder: (context, state) {
            if (state.status == ExploreStatus.loading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state.status == ExploreStatus.failure) {
              return const Center(child: Text('회원 정보를 불러오지 못했습니다.'));
            }

            if (state.members.isEmpty) {
              return const _ExploreEmptyView();
            }

            return Column(
              children: [
                _ExploreHeader(memberCount: state.members.length, selectedName: state.selectedMember?.name, collapseProgress: _collapseProgress),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  padding: EdgeInsets.fromLTRB(12, 0, 12, listBottomGap),
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: listVerticalPadding),
                    decoration: BoxDecoration(
                      color: _surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _line),
                      boxShadow: const [BoxShadow(color: Color(0x1A000000), blurRadius: 10, offset: Offset(0, 4))],
                    ),
                    child: _ProfileList(members: state.members, selectedMemberId: state.selectedMemberId, collapseProgress: _collapseProgress),
                  ),
                ),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 260),
                    child: _buildDetailArea(context, state, onDetailScroll: _handleDetailScroll),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildDetailArea(BuildContext context, ExploreState state, {required ValueChanged<double> onDetailScroll}) {
    if (state.selectedMemberId == null) {
      _expandTopAreaIfNeeded();
      return const _DetailPlaceholder();
    }

    final selectedMember = state.selectedMember;
    if (selectedMember == null || state.memberDetailStatus == ExploreMemberDetailStatus.loading) {
      _expandTopAreaIfNeeded();
      return const _DetailLoadingCard();
    }

    final likedPhotoIds = <int>{
      ...selectedMember.profile.pictures.where((picture) => picture.pictureLikeStatus).map((picture) => picture.id),
      ...(state.likedPhotoIdsByMember[selectedMember.id] ?? const <int>{}),
    };
    final isMemberLiked = selectedMember.profile.memberLikeStatus || state.likedMemberIds.contains(selectedMember.id);

    return _MemberDetailCard(
      key: ValueKey('member-detail-${selectedMember.id}'),
      member: selectedMember,
      detailStatus: state.memberDetailStatus,
      isMemberLiked: isMemberLiked,
      isMatchRequestEnabled: _canRequestDate(selectedMember.profile.myDateRequestStatus),
      likedPhotoIds: likedPhotoIds,
      onMemberLikePressed: () => context.read<ExploreBloc>().add(MemberLikePressed(selectedMember.id)),
      onMatchRequestPressed: () => context.read<ExploreBloc>().add(MatchRequestPressed(selectedMember.id)),
      onPhotoLikePressed: (pictureId) => context.read<ExploreBloc>().add(PhotoLikePressed(memberId: selectedMember.id, pictureId: pictureId)),
      onReportPressed: () => context.read<ExploreBloc>().add(MemberReported(selectedMember.id)),
      onHidePressed: () => context.read<ExploreBloc>().add(MemberHidden(selectedMember.id)),
      onRetryPressed: () => context.read<ExploreBloc>().add(MemberSelected(selectedMember.id)),
      onRefresh: () {
        final completer = Completer<void>();
        context.read<ExploreBloc>().add(MemberDetailRefreshRequested(memberId: selectedMember.id, completer: completer));
        return completer.future;
      },
      onDetailScroll: onDetailScroll,
    );
  }
}

class _ExploreHeader extends StatelessWidget {
  const _ExploreHeader({required this.memberCount, required this.selectedName, required this.collapseProgress});

  final int memberCount;
  final String? selectedName;
  final double collapseProgress;

  @override
  Widget build(BuildContext context) {
    final heightFactor = lerpDouble(1, 0, collapseProgress)!;
    final topPadding = lerpDouble(10, 0, collapseProgress)!;
    final bottomPadding = lerpDouble(10, 2, collapseProgress)!;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      opacity: lerpDouble(1, 0, collapseProgress)!,
      child: Padding(
        padding: EdgeInsets.fromLTRB(12, topPadding, 12, bottomPadding),
        child: ClipRect(
          child: Align(
            alignment: Alignment.topCenter,
            heightFactor: heightFactor,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFFFFDF74), Color(0xFFFFF0B8)]),
                boxShadow: const [BoxShadow(color: Color(0x2A000000), blurRadius: 14, offset: Offset(0, 6))],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '오늘의 추천',
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: _ink),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          selectedName == null ? '프로필을 선택해 상세 정보를 확인해보세요.' : '$selectedName 님의 상세 프로필을 보고 있어요.',
                          style: const TextStyle(fontSize: 13, color: _muted, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.8), borderRadius: BorderRadius.circular(999)),
                    child: Text(
                      '$memberCount명',
                      style: const TextStyle(fontWeight: FontWeight.w900, color: _ink),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileList extends StatelessWidget {
  const _ProfileList({required this.members, required this.selectedMemberId, required this.collapseProgress});

  final List<Member> members;
  final int? selectedMemberId;
  final double collapseProgress;

  @override
  Widget build(BuildContext context) {
    const avatarRadius = 36.0;
    const itemWidth = 74.0;
    final itemGap = lerpDouble(10, 6, collapseProgress)!;
    final nameVisibility = lerpDouble(1, 0, collapseProgress)!;
    final nameAreaHeight = lerpDouble(18, 0, collapseProgress)!;
    final nameGap = lerpDouble(7, 0, collapseProgress)!;
    final listHeight = lerpDouble(118, 88, collapseProgress)!;

    return SizedBox(
      height: listHeight,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: members.length,
        separatorBuilder: (_, __) => SizedBox(width: itemGap),
        itemBuilder: (context, index) {
          final member = members[index];
          final isSelected = selectedMemberId == member.id;
          final avatarUrl = member.profile.primaryPicture?.imageUrl;

          return GestureDetector(
            onTap: () {
              context.read<ExploreBloc>().add(MemberSelected(isSelected ? null : member.id));
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOutCubic,
                  padding: const EdgeInsets.all(3.5),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected ? _accentYellow : Colors.transparent,
                    border: isSelected ? Border.all(color: const Color(0xFFF3C100), width: 1.2) : null,
                  ),
                  child: CircleAvatar(
                    radius: avatarRadius,
                    backgroundColor: const Color(0xFFF5F1E5),
                    backgroundImage: avatarUrl != null ? CachedNetworkImageProvider(avatarUrl) : null,
                    child: avatarUrl == null ? const Icon(Icons.person_outline) : null,
                  ),
                ),
                SizedBox(height: nameGap),
                SizedBox(
                  width: itemWidth,
                  height: nameAreaHeight,
                  child: ClipRect(
                    child: Align(
                      alignment: Alignment.topCenter,
                      heightFactor: nameVisibility,
                      child: Opacity(
                        opacity: nameVisibility,
                        child: Text(
                          member.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 13, color: isSelected ? _ink : const Color(0xFF4D4A40), fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _MemberDetailCard extends StatelessWidget {
  const _MemberDetailCard({
    super.key,
    required this.member,
    required this.detailStatus,
    required this.isMemberLiked,
    required this.isMatchRequestEnabled,
    required this.likedPhotoIds,
    required this.onMemberLikePressed,
    required this.onMatchRequestPressed,
    required this.onPhotoLikePressed,
    required this.onReportPressed,
    required this.onHidePressed,
    required this.onRetryPressed,
    required this.onRefresh,
    required this.onDetailScroll,
  });

  final Member member;
  final ExploreMemberDetailStatus detailStatus;
  final bool isMemberLiked;
  final bool isMatchRequestEnabled;
  final Set<int> likedPhotoIds;
  final VoidCallback onMemberLikePressed;
  final VoidCallback onMatchRequestPressed;
  final ValueChanged<int> onPhotoLikePressed;
  final VoidCallback onReportPressed;
  final VoidCallback onHidePressed;
  final VoidCallback onRetryPressed;
  final RefreshCallback onRefresh;
  final ValueChanged<double> onDetailScroll;

  @override
  Widget build(BuildContext context) {
    return MemberProfileDetailView(
      key: ValueKey('member-detail-${member.id}'),
      member: member,
      isMemberLiked: isMemberLiked,
      isMatchRequestEnabled: isMatchRequestEnabled,
      likedPhotoIds: likedPhotoIds,
      onMemberLikePressed: onMemberLikePressed,
      onMatchRequestPressed: onMatchRequestPressed,
      onPhotoLikePressed: onPhotoLikePressed,
      onReportPressed: onReportPressed,
      onHidePressed: onHidePressed,
      onRetryPressed: onRetryPressed,
      onRefresh: onRefresh,
      showRetryAction: detailStatus == ExploreMemberDetailStatus.failure,
      onDetailScroll: onDetailScroll,
    );
  }
}

class _DetailLoadingCard extends StatelessWidget {
  const _DetailLoadingCard();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Container(
              key: const ValueKey('detail-loading'),
              margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: _surface,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: _line),
                boxShadow: const [BoxShadow(color: Color(0x22000000), blurRadius: 14, offset: Offset(0, 6))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  _SkeletonBox(height: 220),
                  SizedBox(height: 16),
                  _SkeletonBox(height: 24, width: 180),
                  SizedBox(height: 8),
                  _SkeletonBox(height: 14, width: 120),
                  SizedBox(height: 16),
                  _SkeletonBox(height: 44),
                  SizedBox(height: 12),
                  _SkeletonBox(height: 64),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _DetailPlaceholder extends StatelessWidget {
  const _DetailPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('detail-placeholder'),
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: _line),
        boxShadow: const [BoxShadow(color: Color(0x22000000), blurRadius: 14, offset: Offset(0, 6))],
      ),
      child: const Center(
        child: Padding(
          padding: EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.touch_app_rounded, size: 36, color: _muted),
              SizedBox(height: 10),
              Text(
                '상단 프로필을 선택하면\n상세 정보를 볼 수 있어요.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, color: _muted, fontWeight: FontWeight.w700, height: 1.45),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExploreEmptyView extends StatelessWidget {
  const _ExploreEmptyView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 26),
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: _line),
          ),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.sentiment_neutral_rounded, size: 42, color: _muted),
              SizedBox(height: 12),
              Text(
                '오늘 소개할 회원이 없어요.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 17, color: _ink, fontWeight: FontWeight.w800),
              ),
              SizedBox(height: 6),
              Text(
                '잠시 후 다시 확인하면 새로운 추천이 표시됩니다.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: _muted, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SkeletonBox extends StatelessWidget {
  const _SkeletonBox({required this.height, this.width});

  final double height;
  final double? width;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width ?? double.infinity,
      height: height,
      decoration: BoxDecoration(color: const Color(0xFFEAE5D3), borderRadius: BorderRadius.circular(12)),
    );
  }
}
