import 'package:connectify/core/di/di.dart';
import 'package:connectify/features/tab_controller/tab_4_profile/domain/profile_repository.dart';
import 'package:connectify/features/tab_controller/tab_4_profile/presentation/bloc/profile_bloc.dart';
import 'package:connectify/features/tab_controller/tab_4_profile/presentation/bloc/profile_event.dart';
import 'package:connectify/features/tab_controller/tab_4_profile/presentation/bloc/profile_state.dart';
import 'package:connectify/shared/authentication/bloc/authentication_bloc.dart';
import 'package:connectify/shared/models/member.dart';
import 'package:dots_indicator/dots_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(create: (_) => ProfileBloc(getIt<ProfileRepository>())..add(ProfileLoaded()), child: const ProfileView());
  }
}

class ProfileView extends StatelessWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.select((AuthenticationBloc bloc) => bloc.state.user);
    return Scaffold(
      body: SafeArea(
        child: BlocBuilder<ProfileBloc, ProfileState>(
          builder: (context, state) {
            return Column(
              children: [
                Row(mainAxisAlignment: MainAxisAlignment.end, children: [_LogoutButton(), SizedBox(width: 24)]),
                _UserId(),
                Expanded(
                  child: SingleChildScrollView(child: user != null ? _ProfileInfoView(member: user) : const SizedBox.shrink()),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _LogoutButton extends StatelessWidget {
  const _LogoutButton();

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      child: const Text('Logout'),
      onPressed: () {
        context.read<AuthenticationBloc>().add(AuthenticationLogoutPressed());
      },
    );
  }
}

class _UserId extends StatelessWidget {
  const _UserId();

  @override
  Widget build(BuildContext context) {
    final user = context.select((AuthenticationBloc bloc) => bloc.state.user);

    final userId = user?.id;
    final name = user?.name;

    return Text('UserID: $userId, UserName: $name');
  }
}

class _ProfileInfoView extends StatefulWidget {
  final Member member;

  const _ProfileInfoView({required this.member});

  @override
  State<_ProfileInfoView> createState() => _ProfileInfoState();
}

class _ProfileInfoState extends State<_ProfileInfoView> {
  Member get member => widget.member;

  int current = 0;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
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
                  PageView.builder(
                    itemCount: member.profile.pictures.length,
                    onPageChanged: (index) => setState(() {
                      current = index;
                    }),
                    itemBuilder: (context, index) {
                      return Image.network(member.profile.pictures[index].imageUrl, fit: BoxFit.cover, width: double.infinity);
                    },
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: DotsIndicator(
                        dotsCount: member.profile.pictures.length,
                        position: current.toDouble(),
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

          Row(
            children: [
              Text('Bio', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: Size.zero,
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2), // 패딩 설정
                  textStyle: TextStyle(fontSize: 15, fontWeight: FontWeight.normal), // 텍스트 크기 설정
                ),
                onPressed: () {
                  //context.read<AuthenticationBloc>().add(AuthenticationLogoutPressed());
                },
                child: const Text('Edit'),
              ),
            ],
          ),
          Text(member.profile.bio ?? "안녕하세요!\n${member.profile.nickName} 입니다. 😊", style: const TextStyle(fontSize: 16, height: 1.5), textAlign: TextAlign.left),

          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
