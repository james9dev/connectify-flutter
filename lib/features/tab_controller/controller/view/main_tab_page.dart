import 'package:connectify/features/tab_controller/tab_3_chats/presentation/view/chats_page.dart';
import 'package:connectify/features/tab_controller/tab_4_profile/presentation/view/profile_page.dart';
import 'package:connectify/features/tab_controller/tab_2_liked/presentation/view/liked_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../tab_1_explore/presentation/views/explore_page.dart';
import '../bloc/main_tab_cubit.dart';

class MainTabPage extends StatefulWidget {
  const MainTabPage({super.key});

  static Route<void> route() {
    return MaterialPageRoute<void>(builder: (_) => MainTabPage());
  }

  @override
  State<MainTabPage> createState() => _MainTabPageState();
}

class _MainTabPageState extends State<MainTabPage> {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(create: (_) => MainTabCubit(), child: const MainTabView());
  }
}

class MainTabView extends StatelessWidget {
  const MainTabView({super.key});

  static const Color _tabUnselectedColor = Color(0xFF6B675D);

  @override
  Widget build(BuildContext context) {
    final selectedTab = context.select((MainTabCubit cubit) => cubit.state.tab);

    final tabChildren = const [ExplorePage(), LikedPage(), ChatsPage(), ProfilePage()];

    return Scaffold(
      body: IndexedStack(index: selectedTab.index, children: tabChildren),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: selectedTab.index,
        onTap: (index) => context.read<MainTabCubit>().setTab(MainTab.values[index]),
        selectedItemColor: const Color.fromARGB(255, 0, 0, 0),
        unselectedItemColor: _tabUnselectedColor,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        selectedLabelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
        unselectedLabelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.explore_outlined), activeIcon: Icon(Icons.explore_rounded), label: 'Explore'),
          BottomNavigationBarItem(icon: Icon(Icons.favorite_border_rounded), activeIcon: Icon(Icons.favorite_rounded), label: 'Likes'),
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline_rounded), activeIcon: Icon(Icons.chat_bubble_rounded), label: 'Chat'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline_rounded), activeIcon: Icon(Icons.person_rounded), label: 'Profile'),
        ],
      ),
    );
  }
}
