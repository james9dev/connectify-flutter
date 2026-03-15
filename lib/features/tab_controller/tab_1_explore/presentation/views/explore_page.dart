import 'package:cached_network_image/cached_network_image.dart';
import 'package:connectify/core/di/di.dart';
import 'package:connectify/shared/models/member.dart';
import 'package:connectify/features/tab_controller/tab_1_explore/domain/member_repository.dart';
import 'package:connectify/features/tab_controller/tab_1_explore/presentation/bloc/explore_bloc.dart';
import 'package:dots_indicator/dots_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
      body: SafeArea(
        child: BlocBuilder<ExploreBloc, ExploreState>(
          builder: (context, state) {
            if (state.status == ExploreStatus.loading) {
              return const Center(child: CircularProgressIndicator());
            } else if (state.status == ExploreStatus.failure) {
              return const Center(child: Text("회원 정보를 불러오지 못했습니다."));
            } else if (state.status == ExploreStatus.success) {
              return Column(
                children: [
                  const SizedBox(height: 16),
                  _ProfileList(members: state.members, selected: state.selectedMember),
                  const SizedBox(height: 16),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: state.selectedMember == null ? const SizedBox.shrink() : _MemberDetail(member: state.selectedMember!),
                    ),
                  ),
                ],
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}

class _ProfileList extends StatefulWidget {
  final List<Member> members;
  final Member? selected;
  const _ProfileList({required this.members, this.selected});

  @override
  State<_ProfileList> createState() => _ProfileListState();
}

class _ProfileListState extends State<_ProfileList> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 120,
      child: Scrollbar(
        controller: _scrollController,
        thumbVisibility: true, // 항상 표시하고 싶으면 true
        child: ListView.separated(
          controller: _scrollController,
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: widget.members.length,
          separatorBuilder: (_, __) => const SizedBox(width: 20),
          itemBuilder: (context, index) {
            final member = widget.members[index];
            final isSelected = widget.selected?.id == member.id;
            final avatarUrl = member.profile.pictures.isNotEmpty ? member.profile.pictures.first.imageUrl : null;
            return GestureDetector(
              onTap: () {
                context.read<ExploreBloc>().add(MemberSelected(isSelected ? null : member));
              },
              child: Column(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: EdgeInsets.all(isSelected ? 0 : 0),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: isSelected ? Border.all(color: member.profile.gender == GenderType.FEMALE ? Colors.pinkAccent : Colors.blueAccent, width: 2) : null,
                    ),
                    child: CircleAvatar(
                      radius: 40,
                      backgroundImage: avatarUrl != null ? CachedNetworkImageProvider(avatarUrl) : null,
                      child: avatarUrl == null ? const Icon(Icons.person_outline) : null,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(member.name),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _MemberDetail extends StatefulWidget {
  final Member member;

  const _MemberDetail({required this.member});

  @override
  State<_MemberDetail> createState() => _MemberState();
}

class _MemberState extends State<_MemberDetail> {
  Member get member => widget.member;

  final controller = PageController();
  int current = 0;

  @override
  Widget build(BuildContext context) {
    final pictureCount = member.profile.pictures.length;
    final hasPictures = pictureCount > 0;
    final indicatorPosition = pictureCount > 0 ? current.clamp(0, pictureCount - 1).toDouble() : 0.0;

    return Container(
      key: ValueKey(member.id),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: const BoxDecoration(
        color: Color(0xFFF7F7F7),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, -4))],
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // -------------------------------
            // 👤 이름 / 나이 / 지역
            // -------------------------------
            Text(member.name, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),

            const SizedBox(height: 8),

            Text('${member.profile.age()}세 • ${member.profile.location}', style: const TextStyle(fontSize: 18, color: Colors.grey)),

            const SizedBox(height: 24),

            // -------------------------------
            // 🖼 프로필 이미지 슬라이더
            // -------------------------------
            SizedBox(
              height: 320,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  children: [
                    if (hasPictures)
                      PageView.builder(
                        itemCount: pictureCount,
                        onPageChanged: (index) => setState(() {
                          current = index;
                        }),
                        itemBuilder: (context, index) {
                          return CachedNetworkImage(
                            imageUrl: member.profile.pictures[index].imageUrl,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            placeholder: (context, _) => const Center(child: CircularProgressIndicator()),
                            errorWidget: (context, _, _) => const ColoredBox(
                              color: Color(0xFFEAEAEA),
                              child: Center(child: Icon(Icons.broken_image_outlined)),
                            ),
                          );
                        },
                      )
                    else
                      const ColoredBox(
                        color: Color(0xFFEAEAEA),
                        child: Center(child: Icon(Icons.image_not_supported_outlined)),
                      ),
                    if (hasPictures)
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: DotsIndicator(
                            dotsCount: pictureCount,
                            position: indicatorPosition,
                            decorator: const DotsDecorator(
                              color: Colors.grey, // inactive
                              activeColor: Colors.pink, // active
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // -------------------------------
            // 📝 Bio
            // -------------------------------
            Text(member.profile.bio ?? "안녕하세요!\n새로운 사람을 만나고 싶어요. 😊", style: const TextStyle(fontSize: 16, height: 1.5), textAlign: TextAlign.center),

            const SizedBox(height: 32),

            // -------------------------------
            // ❤️ 좋아요 / 메시지 버튼
            // -------------------------------
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.favorite_border),
                  label: const Text('좋아요'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.pinkAccent, foregroundColor: Colors.white),
                ),
                ElevatedButton.icon(onPressed: () {}, icon: const Icon(Icons.chat_bubble_outline), label: const Text('메시지')),
              ],
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
