import 'dart:async';
import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:connectify/core/di/di.dart';
import 'package:connectify/features/tab_controller/tab_2_liked/domain/liked_repository.dart';
import 'package:connectify/features/tab_controller/tab_2_liked/presentation/bloc/liked_bloc.dart';
import 'package:connectify/shared/models/member.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

const Color _accentYellow = Color(0xFFFFC629);
const Color _pageBackground = Color(0xFFFFF8E7);
const Color _surface = Color(0xFFFFFEF9);
const Color _ink = Color(0xFF14130F);
const Color _muted = Color(0xFF6B675D);
const Color _line = Color(0xFFE4DCC0);

class LikedPage extends StatelessWidget {
  const LikedPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(create: (_) => LikedBloc(getIt<LikedRepository>())..add(const LikedStarted()), child: const _LikedView());
  }
}

class _LikedView extends StatefulWidget {
  const _LikedView();

  @override
  State<_LikedView> createState() => _LikedViewState();
}

class _LikedViewState extends State<_LikedView> {
  late final ScrollController _likedMeScrollController;
  late final ScrollController _likedMyPicturesScrollController;

  @override
  void initState() {
    super.initState();
    _likedMeScrollController = ScrollController();
    _likedMyPicturesScrollController = ScrollController();
  }

  @override
  void dispose() {
    _likedMeScrollController.dispose();
    _likedMyPicturesScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedSegment = context.select((LikedBloc bloc) => bloc.state.selectedSegment);

    return Scaffold(
      backgroundColor: _pageBackground,
      appBar: AppBar(
        backgroundColor: _pageBackground,
        elevation: 0,
        centerTitle: false,
        titleSpacing: 14,
        title: Row(
          children: [
            const Text(
              'Likes',
              style: TextStyle(fontWeight: FontWeight.w900, color: _ink),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _LikedSegmentTabs(selectedSegment: selectedSegment, onSegmentSelected: (segment) => context.read<LikedBloc>().add(LikedSegmentChanged(segment))),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: '새로고침',
            onPressed: () => context.read<LikedBloc>().add(LikedRefreshRequested(segment: selectedSegment)),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: BlocBuilder<LikedBloc, LikedState>(
          builder: (context, state) {
            final segment = state.selectedSegment;
            final status = segment == LikedSegment.likedMe ? state.likedMeStatus : state.likedMyPicturesStatus;
            final members = segment == LikedSegment.likedMe ? state.likedMeMembers : state.likedMyPicturesMembers;
            final errorMessage = segment == LikedSegment.likedMe ? state.likedMeErrorMessage : state.likedMyPicturesErrorMessage;

            if (status == LikedFetchStatus.loading && members.isEmpty) {
              return const _LikedLoadingView();
            }

            if (status == LikedFetchStatus.failure && members.isEmpty) {
              return _LikedErrorView(
                message: errorMessage ?? '목록을 불러오지 못했어요.',
                onRetry: () => context.read<LikedBloc>().add(LikedRefreshRequested(segment: segment)),
              );
            }

            if (members.isEmpty) {
              return _LikedEmptyView(message: segment == LikedSegment.likedMe ? '아직 받은 좋아요가 없어요. Explore에서 먼저 반응해보세요.' : '아직 내 사진을 좋아요한 회원이 없어요.');
            }

            return RefreshIndicator(
              onRefresh: () => _refreshSegment(context, segment),
              child: ListView.separated(
                key: PageStorageKey<String>('liked-list-${segment.name}'),
                controller: _scrollControllerFor(segment),
                physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                padding: const EdgeInsets.fromLTRB(14, 4, 14, 24),
                itemCount: members.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final member = members[index];
                  const isRevealed = false;

                  return _LikedMemberCard(member: member, segment: segment, isRevealed: isRevealed, onRevealRequested: _showProfileUpgradeSheet);
                },
              ),
            );
          },
        ),
      ),
    );
  }

  ScrollController _scrollControllerFor(LikedSegment segment) {
    switch (segment) {
      case LikedSegment.likedMe:
        return _likedMeScrollController;
      case LikedSegment.likedMyPictures:
        return _likedMyPicturesScrollController;
    }
  }

  Future<void> _refreshSegment(BuildContext context, LikedSegment segment) async {
    final bloc = context.read<LikedBloc>();
    final completer = Completer<void>();
    late final StreamSubscription<LikedState> subscription;
    subscription = bloc.stream.listen((state) {
      final status = segment == LikedSegment.likedMe ? state.likedMeStatus : state.likedMyPicturesStatus;
      if (status != LikedFetchStatus.loading) {
        if (!completer.isCompleted) {
          completer.complete();
        }
        subscription.cancel();
      }
    });

    bloc.add(LikedRefreshRequested(segment: segment));
    await completer.future.timeout(const Duration(seconds: 6), onTimeout: () async => subscription.cancel());
  }

  Future<void> _showProfileUpgradeSheet() async {
    final parentContext = context;

    await showModalBottomSheet<void>(
      context: parentContext,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      builder: (sheetContext) {
        return SafeArea(
          top: false,
          child: Container(
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
            decoration: const BoxDecoration(
              color: _surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(color: const Color(0xFFD8D1BC), borderRadius: BorderRadius.circular(999)),
                  ),
                ),
                const SizedBox(height: 12),
                Image.asset('assets/images/tmp_img_001.png', fit: BoxFit.cover),
                const SizedBox(height: 24),
                const Text(
                  '당신을 좋아하는 사람이 기다리고 있어요.',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: _ink),
                ),
                const SizedBox(height: 8),
                const Text(
                  '멤버십을 시작하면 블러 프로필을 확인하고, 누가 관심을 보냈는지 더 빠르게 파악할 수 있어요.',
                  style: TextStyle(fontSize: 13, color: _muted, fontWeight: FontWeight.w600, height: 1.35),
                ),
                const SizedBox(height: 16),
                const _UpgradePlanRow(title: 'Connectify Plus', price: '월 9,900원', description: '블러 프로필 월 30회 확인 · 좋아요 인사이트 제공'),
                const SizedBox(height: 8),
                const _UpgradePlanRow(title: 'Connectify Premium', price: '월 19,900원', description: '블러 프로필 무제한 확인 · 우선 노출 혜택'),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.of(sheetContext).pop();
                      ScaffoldMessenger.of(parentContext)
                        ..hideCurrentSnackBar()
                        ..showSnackBar(const SnackBar(content: Text('Upgrade 결제 화면은 준비 중입니다.')));
                    },
                    style: FilledButton.styleFrom(backgroundColor: _accentYellow, foregroundColor: _ink, padding: const EdgeInsets.symmetric(vertical: 13)),
                    icon: const Icon(Icons.rocket_launch_rounded, size: 18),
                    label: const Text('Upgrade', style: TextStyle(fontWeight: FontWeight.w800)),
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(onPressed: () => Navigator.of(sheetContext).pop(), child: const Text('나중에')),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _UpgradePlanRow extends StatelessWidget {
  const _UpgradePlanRow({required this.title, required this.price, required this.description});

  final String title;
  final String price;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 11, 12, 11),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7DE),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE9DEBC)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: _ink),
                ),
              ),
              Text(
                price,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _ink),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: const TextStyle(fontSize: 12, color: _muted, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _LikedSegmentTabs extends StatelessWidget {
  const _LikedSegmentTabs({required this.selectedSegment, required this.onSegmentSelected});

  final LikedSegment selectedSegment;
  final ValueChanged<LikedSegment> onSegmentSelected;

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
            child: _SegmentButton(label: '나를 좋아요', isSelected: selectedSegment == LikedSegment.likedMe, onTap: () => onSegmentSelected(LikedSegment.likedMe)),
          ),
          Expanded(
            child: _SegmentButton(label: '내 사진을 좋아요', isSelected: selectedSegment == LikedSegment.likedMyPictures, onTap: () => onSegmentSelected(LikedSegment.likedMyPictures)),
          ),
        ],
      ),
    );
  }
}

class _SegmentButton extends StatelessWidget {
  const _SegmentButton({required this.label, required this.isSelected, required this.onTap});

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

class _LikedMemberCard extends StatelessWidget {
  const _LikedMemberCard({required this.member, required this.segment, required this.isRevealed, required this.onRevealRequested});

  final Member member;
  final LikedSegment segment;
  final bool isRevealed;
  final VoidCallback onRevealRequested;

  @override
  Widget build(BuildContext context) {
    final title = _displayName(member);
    final mainMeta = _mainMeta(member.profile);
    final secondaryMeta = _secondaryMeta(member.profile);
    final profileImageUrl = member.profile.primaryPicture?.imageUrl;

    return InkWell(
      onTap: onRevealRequested,
      borderRadius: BorderRadius.circular(18),
      child: AspectRatio(
        aspectRatio: 0.9,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (profileImageUrl != null && profileImageUrl.isNotEmpty)
                _buildProfileImage(profileImageUrl, isRevealed)
              else
                const ColoredBox(
                  color: Color(0xFFF0EBD9),
                  child: Icon(Icons.person_outline_rounded, size: 46, color: _muted),
                ),
              Positioned(
                left: 14,
                right: 14,
                bottom: 14,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        shadows: [Shadow(color: Color(0x88000000), blurRadius: 6)],
                      ),
                    ),
                    if (mainMeta != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        mainMeta,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFFF3F3F3),
                          fontWeight: FontWeight.w600,
                          shadows: [Shadow(color: Color(0x88000000), blurRadius: 6)],
                        ),
                      ),
                    ],
                    if (secondaryMeta != null) ...[
                      const SizedBox(height: 1),
                      Text(
                        secondaryMeta,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFFE9E9E9),
                          fontWeight: FontWeight.w600,
                          shadows: [Shadow(color: Color(0x88000000), blurRadius: 6)],
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.favorite_rounded, size: 16, color: Color(0xFFFF7D7D)),
                        SizedBox(width: 4),
                        Text(
                          segment == LikedSegment.likedMe ? '회원님에게 관심을 보냈어요.' : '회원님의 사진을 좋아요했어요.',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            shadows: [Shadow(color: Color(0x99000000), blurRadius: 6)],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileImage(String imageUrl, bool isRevealed) {
    final image = CachedNetworkImage(
      imageUrl: imageUrl,
      fit: BoxFit.cover,
      placeholder: (context, _) => const ColoredBox(
        color: Color(0xFFF0EBD9),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2.0)),
      ),
      errorWidget: (context, _, _) => const ColoredBox(
        color: Color(0xFFF0EBD9),
        child: Icon(Icons.broken_image_outlined, color: _muted),
      ),
    );

    if (isRevealed) {
      return image;
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        ImageFiltered(imageFilter: ImageFilter.blur(sigmaX: 150, sigmaY: 150), child: image),
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 0, sigmaY: 0),
          child: Container(color: const Color(0x18000000)),
        ),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color.fromARGB(150, 0, 0, 0), Color.fromARGB(37, 0, 0, 0), Color.fromARGB(150, 0, 0, 0)],
              stops: [0.0, 0.5, 1.0],
            ),
          ),
        ),
      ],
    );
  }
}

class _LikedLoadingView extends StatelessWidget {
  const _LikedLoadingView();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 24),
      itemCount: 5,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, __) {
        return AspectRatio(
          aspectRatio: 4 / 5,
          child: Container(
            decoration: BoxDecoration(
              color: _surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _line),
              boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 8, offset: Offset(0, 4))],
            ),
            child: const Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.4))),
          ),
        );
      },
    );
  }
}

class _LikedEmptyView extends StatelessWidget {
  const _LikedEmptyView({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 26),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 14, color: _muted, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

class _LikedErrorView extends StatelessWidget {
  const _LikedErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: _muted, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            OutlinedButton(onPressed: onRetry, child: const Text('다시 시도')),
          ],
        ),
      ),
    );
  }
}

String _displayName(Member member) {
  final nickName = member.profile.nickName?.trim();
  if (nickName != null && nickName.isNotEmpty) {
    return nickName;
  }
  return '';
}

String? _mainMeta(Profile profile) {
  final parts = <String>[];
  final age = _safeAge(profile);
  if (age != null) {
    parts.add('$age세');
  }
  final gender = _genderLabel(profile.gender);
  if (gender != null) {
    parts.add(gender);
  }

  if (parts.isEmpty) {
    return null;
  }

  return parts.join(' · ');
}

String? _secondaryMeta(Profile profile) {
  final location = profile.location?.trim();
  if (location != null && location.isNotEmpty) {
    return location;
  }

  final job = profile.job?.trim();
  if (job != null && job.isNotEmpty) {
    return job;
  }

  return null;
}

String? _genderLabel(GenderType? gender) {
  if (gender == null) {
    return null;
  }

  switch (gender) {
    case GenderType.MALE:
      return '남성';
    case GenderType.FEMALE:
      return '여성';
  }
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

  final today = DateTime.now();
  int age = today.year - year;
  final hasBirthdayPassed = today.month > month || (today.month == month && today.day >= day);
  if (!hasBirthdayPassed) {
    age -= 1;
  }
  return age < 0 ? null : age;
}
