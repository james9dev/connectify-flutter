import 'dart:ui' show lerpDouble;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:connectify/core/di/di.dart';
import 'package:connectify/features/tab_controller/tab_1_explore/domain/member_repository.dart';
import 'package:connectify/features/tab_controller/tab_1_explore/presentation/bloc/explore_bloc.dart';
import 'package:connectify/shared/models/member.dart';
import 'package:dots_indicator/dots_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

const Color _accentYellow = Color(0xFFFFC629);
const Color _pageBackground = Color(0xFFFFF8E7);
const Color _surface = Color(0xFFFFFEF9);
const Color _ink = Color(0xFF14130F);
const Color _muted = Color(0xFF6B675D);
const Color _line = Color(0xFFE4DCC0);

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
      isMatchRequested: state.requestedMatchMemberIds.contains(selectedMember.id),
      likedPhotoIds: likedPhotoIds,
      onMemberLikePressed: () => context.read<ExploreBloc>().add(MemberLikePressed(selectedMember.id)),
      onMatchRequestPressed: () => context.read<ExploreBloc>().add(MatchRequestPressed(selectedMember.id)),
      onPhotoLikePressed: (pictureId) => context.read<ExploreBloc>().add(PhotoLikePressed(memberId: selectedMember.id, pictureId: pictureId)),
      onReportPressed: () => context.read<ExploreBloc>().add(MemberReported(selectedMember.id)),
      onHidePressed: () => context.read<ExploreBloc>().add(MemberHidden(selectedMember.id)),
      onRetryPressed: () => context.read<ExploreBloc>().add(MemberSelected(selectedMember.id)),
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

class _MemberDetailCard extends StatefulWidget {
  const _MemberDetailCard({
    super.key,
    required this.member,
    required this.detailStatus,
    required this.isMemberLiked,
    required this.isMatchRequested,
    required this.likedPhotoIds,
    required this.onMemberLikePressed,
    required this.onMatchRequestPressed,
    required this.onPhotoLikePressed,
    required this.onReportPressed,
    required this.onHidePressed,
    required this.onRetryPressed,
    required this.onDetailScroll,
  });

  final Member member;
  final ExploreMemberDetailStatus detailStatus;
  final bool isMemberLiked;
  final bool isMatchRequested;
  final Set<int> likedPhotoIds;
  final VoidCallback onMemberLikePressed;
  final VoidCallback onMatchRequestPressed;
  final ValueChanged<int> onPhotoLikePressed;
  final VoidCallback onReportPressed;
  final VoidCallback onHidePressed;
  final VoidCallback onRetryPressed;
  final ValueChanged<double> onDetailScroll;

  @override
  State<_MemberDetailCard> createState() => _MemberDetailCardState();
}

class _MemberDetailCardState extends State<_MemberDetailCard> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void didUpdateWidget(covariant _MemberDetailCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.member.id != widget.member.id) {
      _currentPage = 0;
      if (_pageController.hasClients) {
        _pageController.jumpToPage(0);
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final member = widget.member;
    final pictures = member.profile.orderedPictures;
    final pictureCount = pictures.length;
    final safePage = pictureCount == 0 ? 0 : _currentPage.clamp(0, pictureCount - 1);
    final currentPicture = pictureCount == 0 ? null : pictures[safePage];
    final isCurrentPhotoLiked = currentPicture != null && widget.likedPhotoIds.contains(currentPicture.id);
    final hasExtraInfo = _hasExtraInfo(member);

    return Container(
      key: ValueKey(member.id),
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 18),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: _line),
        boxShadow: const [BoxShadow(color: Color(0x24000000), blurRadius: 18, offset: Offset(0, 8))],
      ),
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          // 상세 컨텐츠의 세로 스크롤만 상단 축소/확장 트리거로 사용한다.
          final isVertical = notification.metrics.axis == Axis.vertical;
          final isRootScrollable = notification.depth == 0;
          if (!isVertical || !isRootScrollable) {
            return false;
          }

          widget.onDetailScroll(notification.metrics.pixels < 0 ? 0 : notification.metrics.pixels);
          return false;
        },
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPhotoCarousel(context, pictures, isCurrentPhotoLiked),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${member.name}, ${member.profile.age()}',
                          style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: _ink, height: 1.0),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.location_on_outlined, size: 16, color: _muted),
                            const SizedBox(width: 4),
                            Text(
                              member.profile.location ?? '지역 미설정',
                              style: const TextStyle(fontSize: 14, color: _muted, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_horiz),
                    onSelected: (value) {
                      if (value == 'report') {
                        widget.onReportPressed();
                        return;
                      }
                      if (value == 'hide') {
                        widget.onHidePressed();
                      }
                    },
                    itemBuilder: (context) => const [PopupMenuItem(value: 'report', child: Text('신고')), PopupMenuItem(value: 'hide', child: Text('숨김'))],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: widget.isMemberLiked ? Colors.redAccent : Colors.black87,
                        side: BorderSide(color: widget.isMemberLiked ? Colors.redAccent : const Color(0xFFD4CCB1)),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        textStyle: const TextStyle(fontWeight: FontWeight.w700),
                        backgroundColor: Colors.white,
                      ),
                      onPressed: widget.onMemberLikePressed,
                      icon: Icon(widget.isMemberLiked ? Icons.favorite : Icons.favorite_border),
                      label: Text(widget.isMemberLiked ? '좋아요 취소' : '회원 좋아요'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: _accentYellow,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        textStyle: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      onPressed: widget.isMatchRequested ? null : widget.onMatchRequestPressed,
                      icon: Icon(widget.isMatchRequested ? Icons.check_circle : Icons.send_outlined),
                      label: Text(widget.isMatchRequested ? '요청 완료' : '데이트 요청'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildBioSection(member),
              if (hasExtraInfo) ...[const SizedBox(height: 14), _buildExtraInfoSection(member)],
              if (member.profile.profileTagIds.isNotEmpty) ...[
                const SizedBox(height: 14),
                _buildTagSection(title: '프로필 태그', tags: member.profile.profileTagIds, backgroundColor: const Color(0xFFFFEEB2)),
              ],
              if (member.profile.preferredTagIds.isNotEmpty) ...[
                const SizedBox(height: 12),
                _buildTagSection(title: '선호 태그', tags: member.profile.preferredTagIds, backgroundColor: const Color(0xFFE8EEF8)),
              ],
              if (widget.detailStatus == ExploreMemberDetailStatus.failure) ...[
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(onPressed: widget.onRetryPressed, icon: const Icon(Icons.refresh), label: const Text('상세 다시 불러오기')),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  bool _hasExtraInfo(Member member) {
    final profile = member.profile;
    return profile.job?.trim().isNotEmpty == true ||
        profile.company?.trim().isNotEmpty == true ||
        profile.educationInstitution?.trim().isNotEmpty == true ||
        profile.educationGraduation?.trim().isNotEmpty == true;
  }

  Widget _buildExtraInfoSection(Member member) {
    final rows = <({String label, String value})>[];
    final profile = member.profile;

    if (profile.job?.trim().isNotEmpty == true) {
      rows.add((label: '직무', value: profile.job!.trim()));
    }
    if (profile.company?.trim().isNotEmpty == true) {
      rows.add((label: '회사', value: profile.company!.trim()));
    }
    if (profile.educationInstitution?.trim().isNotEmpty == true) {
      rows.add((label: '학교', value: profile.educationInstitution!.trim()));
    }
    if (profile.educationGraduation?.trim().isNotEmpty == true) {
      rows.add((label: '학력', value: profile.educationGraduation!.trim()));
    }

    if (rows.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _line),
      ),
      child: Column(
        children: rows
            .map(
              (row) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 56,
                      child: Text(
                        row.label,
                        style: const TextStyle(fontSize: 13, color: _muted, fontWeight: FontWeight.w700),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        row.value,
                        style: const TextStyle(fontSize: 14, color: _ink, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(growable: false),
      ),
    );
  }

  Widget _buildBioSection(Member member) {
    final bio = member.profile.bio?.trim();
    final hasBio = bio != null && bio.isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF6D4),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEEDC9D)),
      ),
      child: Text(
        hasBio ? bio : '아직 자기소개를 작성하지 않았어요.',
        style: const TextStyle(fontSize: 15, color: _ink, height: 1.5, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildTagSection({required String title, required List<ProfileTagSummary> tags, required Color backgroundColor}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 13, color: _muted, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: tags
              .map((tag) {
                final label = tag.name?.trim().isNotEmpty == true ? tag.name! : '태그 #${tag.id}';
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(color: backgroundColor, borderRadius: BorderRadius.circular(999)),
                  child: Text(
                    label,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: _ink),
                  ),
                );
              })
              .toList(growable: false),
        ),
      ],
    );
  }

  Widget _buildPhotoCarousel(BuildContext context, List<ProfilePicture> pictures, bool isCurrentPhotoLiked) {
    final pictureCount = pictures.length;
    final safePage = pictureCount == 0 ? 0 : _currentPage.clamp(0, pictureCount - 1);
    final indicatorPosition = pictureCount > 0 ? _currentPage.clamp(0, pictureCount - 1).toDouble() : 0.0;

    return SizedBox(
      height: 388,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (pictures.isEmpty)
              const ColoredBox(
                color: Color(0xFFF0F0ED),
                child: Center(child: Icon(Icons.image_not_supported_outlined, size: 38, color: Colors.black54)),
              )
            else
              PageView.builder(
                controller: _pageController,
                itemCount: pictureCount,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemBuilder: (context, index) {
                  return CachedNetworkImage(
                    imageUrl: pictures[index].imageUrl,
                    fit: BoxFit.cover,
                    placeholder: (context, _) => const ColoredBox(
                      color: Color(0xFFF0F0ED),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    errorWidget: (context, _, _) => const ColoredBox(
                      color: Color(0xFFF0F0ED),
                      child: Center(child: Icon(Icons.broken_image_outlined, size: 36)),
                    ),
                  );
                },
              ),
            if (pictures.isNotEmpty)
              const Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0x00000000), Color(0x70000000)]),
                    ),
                    child: SizedBox(height: 110),
                  ),
                ),
              ),
            if (pictures.isNotEmpty)
              Positioned(
                top: 12,
                right: 12,
                child: DecoratedBox(
                  decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.45), borderRadius: BorderRadius.circular(999)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    child: Text(
                      '${safePage + 1}/$pictureCount',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12),
                    ),
                  ),
                ),
              ),
            if (pictures.isNotEmpty)
              Positioned(
                bottom: 12,
                right: 12,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.93),
                    shape: BoxShape.circle,
                    border: Border.all(color: isCurrentPhotoLiked ? const Color(0xFFFFC4CF) : const Color(0xFFD9D9D6)),
                    boxShadow: const [BoxShadow(color: Color(0x26000000), blurRadius: 10, offset: Offset(0, 3))],
                  ),
                  child: IconButton(
                    onPressed: () => widget.onPhotoLikePressed(pictures[safePage].id),
                    iconSize: 24,
                    color: isCurrentPhotoLiked ? Colors.redAccent : Colors.black87,
                    icon: Icon(isCurrentPhotoLiked ? Icons.favorite : Icons.favorite_border),
                  ),
                ),
              ),
            if (pictures.isNotEmpty)
              Positioned(
                left: 0,
                right: 0,
                bottom: 16,
                child: DotsIndicator(
                  dotsCount: pictureCount,
                  position: indicatorPosition,
                  decorator: const DotsDecorator(
                    color: Color(0x99FFFFFF),
                    activeColor: _accentYellow,
                    size: Size(7, 7),
                    activeSize: Size(16, 7),
                    activeShape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(999))),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _DetailLoadingCard extends StatelessWidget {
  const _DetailLoadingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
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
