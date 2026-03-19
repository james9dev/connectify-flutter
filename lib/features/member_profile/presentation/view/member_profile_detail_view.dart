import 'package:cached_network_image/cached_network_image.dart';
import 'package:connectify/shared/models/member.dart';
import 'package:dots_indicator/dots_indicator.dart';
import 'package:flutter/material.dart';

const Color _accentYellow = Color(0xFFFFC629);
const Color _surface = Color(0xFFFFFEF9);
const Color _ink = Color(0xFF14130F);
const Color _muted = Color(0xFF6B675D);
const Color _line = Color(0xFFE4DCC0);

class MemberProfileDetailView extends StatefulWidget {
  const MemberProfileDetailView({
    super.key,
    required this.member,
    this.isMemberLiked = false,
    this.isMatchRequestEnabled = true,
    this.likedPhotoIds = const <int>{},
    this.onMemberLikePressed,
    this.onMatchRequestPressed,
    this.onPhotoLikePressed,
    this.onReportPressed,
    this.onHidePressed,
    this.onRetryPressed,
    this.showRetryAction = false,
    this.onRefresh,
    this.onDetailScroll,
    this.margin = const EdgeInsets.fromLTRB(12, 0, 12, 12),
  });

  final Member member;
  final bool isMemberLiked;
  final bool isMatchRequestEnabled;
  final Set<int> likedPhotoIds;
  final VoidCallback? onMemberLikePressed;
  final VoidCallback? onMatchRequestPressed;
  final ValueChanged<int>? onPhotoLikePressed;
  final VoidCallback? onReportPressed;
  final VoidCallback? onHidePressed;
  final VoidCallback? onRetryPressed;
  final bool showRetryAction;
  final RefreshCallback? onRefresh;
  final ValueChanged<double>? onDetailScroll;
  final EdgeInsetsGeometry margin;

  @override
  State<MemberProfileDetailView> createState() => _MemberProfileDetailViewState();
}

class _MemberProfileDetailViewState extends State<MemberProfileDetailView> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void didUpdateWidget(covariant MemberProfileDetailView oldWidget) {
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
    final title = _memberTitle(member);

    final detailContent = NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        final onDetailScroll = widget.onDetailScroll;
        if (onDetailScroll == null) {
          return false;
        }

        final isVertical = notification.metrics.axis == Axis.vertical;
        final isRootScrollable = notification.depth == 0;
        if (!isVertical || !isRootScrollable) {
          return false;
        }

        onDetailScroll(notification.metrics.pixels < 0 ? 0 : notification.metrics.pixels);
        return false;
      },
      child: SingleChildScrollView(
        physics: widget.onRefresh == null ? const BouncingScrollPhysics() : const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
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
                        title,
                        style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: _ink, height: 1.0),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined, size: 16, color: _muted),
                          const SizedBox(width: 4),
                          Text(
                            member.profile.location?.trim().isNotEmpty == true ? member.profile.location!.trim() : '지역 미설정',
                            style: const TextStyle(fontSize: 14, color: _muted, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                _buildMoreMenu(),
              ],
            ),
            _buildActionButtons(),
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
            if (widget.showRetryAction && widget.onRetryPressed != null) ...[
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

    return Container(
      key: ValueKey(member.id),
      margin: widget.margin,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 18),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: _line),
        boxShadow: const [BoxShadow(color: Color(0x24000000), blurRadius: 18, offset: Offset(0, 8))],
      ),
      child: widget.onRefresh == null ? detailContent : RefreshIndicator(onRefresh: widget.onRefresh!, child: detailContent),
    );
  }

  Widget _buildMoreMenu() {
    final hasReport = widget.onReportPressed != null;
    final hasHide = widget.onHidePressed != null;
    if (!hasReport && !hasHide) {
      return const SizedBox.shrink();
    }

    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_horiz),
      onSelected: (value) {
        if (value == 'report') {
          widget.onReportPressed?.call();
          return;
        }
        if (value == 'hide') {
          widget.onHidePressed?.call();
        }
      },
      itemBuilder: (context) {
        final items = <PopupMenuEntry<String>>[];
        if (hasReport) {
          items.add(const PopupMenuItem(value: 'report', child: Text('신고')));
        }
        if (hasHide) {
          items.add(const PopupMenuItem(value: 'hide', child: Text('숨김')));
        }
        return items;
      },
    );
  }

  Widget _buildActionButtons() {
    final hasMemberAction = widget.onMemberLikePressed != null;
    final hasMatchAction = widget.onMatchRequestPressed != null;

    if (!hasMemberAction && !hasMatchAction) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        const SizedBox(height: 12),
        Row(
          children: [
            if (hasMemberAction)
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
            if (hasMemberAction && hasMatchAction) const SizedBox(width: 10),
            if (hasMatchAction)
              Expanded(
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: _accentYellow,
                    disabledBackgroundColor: const Color.fromARGB(255, 171, 169, 167),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    textStyle: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  onPressed: widget.isMatchRequestEnabled ? widget.onMatchRequestPressed : null,
                  icon: const Icon(Icons.send_outlined),
                  label: const Text('데이트 요청'),
                ),
              ),
          ],
        ),
      ],
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
            if (pictures.isNotEmpty && widget.onPhotoLikePressed != null)
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
                    onPressed: () => widget.onPhotoLikePressed?.call(pictures[safePage].id),
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

  String _memberTitle(Member member) {
    final age = _safeAge(member.profile);
    if (age == null) {
      return member.name;
    }
    return '${member.name}, $age';
  }

  int? _safeAge(Profile profile) {
    final birthyear = profile.birthyear;
    final birthday = profile.birthday;
    if (birthyear == null || birthday == null || birthday.length < 4) {
      return null;
    }

    final year = int.tryParse(birthyear);
    final month = int.tryParse(birthday.substring(0, 2));
    final day = int.tryParse(birthday.substring(2, 4));
    if (year == null || month == null || day == null) {
      return null;
    }

    final now = DateTime.now();
    var age = now.year - year;
    final hasBirthdayPassed = now.month > month || (now.month == month && now.day >= day);
    if (!hasBirthdayPassed) {
      age -= 1;
    }
    return age < 0 ? null : age;
  }
}
