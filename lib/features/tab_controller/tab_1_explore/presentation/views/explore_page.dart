import 'package:cached_network_image/cached_network_image.dart';
import 'package:connectify/core/di/di.dart';
import 'package:connectify/features/tab_controller/tab_1_explore/domain/member_repository.dart';
import 'package:connectify/features/tab_controller/tab_1_explore/presentation/bloc/explore_bloc.dart';
import 'package:connectify/shared/models/member.dart';
import 'package:dots_indicator/dots_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

const Color _accentYellow = Color(0xFFFFC629);
const Color _pageBackground = Color(0xFFFFF6CC);

class ExplorePage extends StatelessWidget {
  const ExplorePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(create: (_) => ExploreBloc(getIt<MemberRepository>())..add(ExploreLoaded()), child: const ExploreView());
  }
}

class ExploreView extends StatelessWidget {
  const ExploreView({super.key});

  @override
  Widget build(BuildContext context) {
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
                const Padding(
                  padding: EdgeInsets.fromLTRB(20, 12, 20, 4),
                  child: Row(
                    children: [
                      Text(
                        '오늘의 소개',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.black87),
                      ),
                    ],
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.fromLTRB(20, 0, 20, 12),
                  child: Row(
                    children: [
                      Text(
                        '마음에 드는 상대에게 좋아요를 보내보세요.',
                        style: TextStyle(fontSize: 14, color: Colors.black54, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                _ProfileList(members: state.members, selectedMemberId: state.selectedMemberId),
                const SizedBox(height: 14),
                Expanded(
                  child: AnimatedSwitcher(duration: const Duration(milliseconds: 260), child: _buildDetailArea(context, state)),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildDetailArea(BuildContext context, ExploreState state) {
    if (state.selectedMemberId == null) {
      return const _DetailPlaceholder();
    }

    final selectedMember = state.selectedMember;
    if (selectedMember == null || state.memberDetailStatus == ExploreMemberDetailStatus.loading) {
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
    );
  }
}

class _ProfileList extends StatelessWidget {
  const _ProfileList({required this.members, required this.selectedMemberId});

  final List<Member> members;
  final int? selectedMemberId;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 116,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: members.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final member = members[index];
          final isSelected = selectedMemberId == member.id;
          final avatarUrl = member.profile.primaryPicture?.imageUrl;

          return GestureDetector(
            onTap: () {
              context.read<ExploreBloc>().add(MemberSelected(isSelected ? null : member.id));
            },
            child: Column(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(shape: BoxShape.circle, color: isSelected ? _accentYellow : Colors.transparent),
                  child: CircleAvatar(
                    radius: 36,
                    backgroundColor: Colors.white,
                    backgroundImage: avatarUrl != null ? CachedNetworkImageProvider(avatarUrl) : null,
                    child: avatarUrl == null ? const Icon(Icons.person_outline) : null,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: 74,
                  child: Text(
                    member.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600),
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

    return Container(
      key: ValueKey(member.id),
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [BoxShadow(color: Color(0x26000000), blurRadius: 14, offset: Offset(0, 6))],
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPhotoCarousel(context, pictures, isCurrentPhotoLiked),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${member.name}, ${member.profile.age()}',
                    style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.black87),
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
            const SizedBox(height: 2),
            Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 16, color: Colors.black54),
                const SizedBox(width: 4),
                Text(member.profile.location ?? '지역 미설정', style: const TextStyle(fontSize: 14, color: Colors.black54)),
              ],
            ),
            const SizedBox(height: 14),
            Text(member.profile.bio?.trim().isNotEmpty == true ? member.profile.bio! : '자기소개가 아직 없어요.', style: const TextStyle(fontSize: 15, color: Colors.black87, height: 1.45)),
            const SizedBox(height: 14),
            if (member.profile.profileTagIds.isNotEmpty)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: member.profile.profileTagIds
                    .map((tag) {
                      final label = tag.name?.trim().isNotEmpty == true ? tag.name! : '태그 #${tag.id}';
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(color: const Color(0xFFFFF0B8), borderRadius: BorderRadius.circular(999)),
                        child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                      );
                    })
                    .toList(growable: false),
              ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: widget.isMemberLiked ? Colors.redAccent : Colors.black87,
                      side: BorderSide(color: widget.isMemberLiked ? Colors.redAccent : const Color(0xFFDDDDD8)),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      textStyle: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    onPressed: widget.onMemberLikePressed,
                    icon: Icon(widget.isMemberLiked ? Icons.favorite : Icons.favorite_border),
                    label: Text('회원 좋아요'),
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
                    label: Text(widget.isMatchRequested ? '요청 완료' : '매칭 요청'),
                  ),
                ),
              ],
            ),
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
    );
  }

  Widget _buildPhotoCarousel(BuildContext context, List<ProfilePicture> pictures, bool isCurrentPhotoLiked) {
    final pictureCount = pictures.length;
    final safePage = pictureCount == 0 ? 0 : _currentPage.clamp(0, pictureCount - 1);
    final indicatorPosition = pictureCount > 0 ? _currentPage.clamp(0, pictureCount - 1).toDouble() : 0.0;

    return SizedBox(
      height: 360,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
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
              Positioned(
                bottom: 10,
                right: 10,
                child: DecoratedBox(
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.9), shape: BoxShape.circle),
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
                bottom: 10,
                child: DotsIndicator(
                  dotsCount: pictureCount,
                  position: indicatorPosition,
                  decorator: const DotsDecorator(color: Color(0xB3FFFFFF), activeColor: _accentYellow, size: Size(7, 7), activeSize: Size(8, 8)),
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
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [BoxShadow(color: Color(0x26000000), blurRadius: 14, offset: Offset(0, 6))],
      ),
      child: const Center(child: CircularProgressIndicator()),
    );
  }
}

class _DetailPlaceholder extends StatelessWidget {
  const _DetailPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('detail-placeholder'),
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [BoxShadow(color: Color(0x26000000), blurRadius: 14, offset: Offset(0, 6))],
      ),
      child: const Center(child: Text('상단에서 회원을 선택해 상세 정보를 확인하세요.')),
    );
  }
}

class _ExploreEmptyView extends StatelessWidget {
  const _ExploreEmptyView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          '오늘 소개할 회원이 없어요.\n조금 뒤에 다시 확인해 주세요.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, color: Colors.black54, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
