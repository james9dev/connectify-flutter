import 'package:connectify/features/tab_controller/tab_3_notifications/notifications_page.dart';
import 'package:connectify/features/tab_controller/tab_4_profile/presentation/view/profile_page.dart';
import 'package:connectify/features/tab_controller/tab_2_search/search_page.dart';
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

  @override
  Widget build(BuildContext context) {
    final selectedTab = context.select((MainTabCubit cubit) => cubit.state.tab);

    final tabChildren = [ExplorePage(), NotificationsPage(), SearchPage(), ProfilePage()];

    return Scaffold(
      body: IndexedStack(index: selectedTab.index, children: tabChildren),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        shape: const CircleBorder(),
        key: const Key('homeView_addTodo_floatingActionButton'),
        onPressed: () => {
          //Navigator.of(context).push(EditTodoPage.route()),
        },
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _HomeTabButton(groupValue: selectedTab, value: MainTab.home, icon: const Icon(Icons.list_rounded)),
            _HomeTabButton(groupValue: selectedTab, value: MainTab.search, icon: const Icon(Icons.show_chart_rounded)),
            _HomeTabButton(groupValue: selectedTab, value: MainTab.notifications, icon: const Icon(Icons.notifications)),
            _HomeTabButton(groupValue: selectedTab, value: MainTab.profile, icon: const Icon(Icons.people)),
          ],
        ),
      ),
    );
  }
}

class _HomeTabButton extends StatelessWidget {
  const _HomeTabButton({required this.groupValue, required this.value, required this.icon});

  final MainTab groupValue;
  final MainTab value;
  final Widget icon;

  @override
  Widget build(BuildContext context) {
    return IconButton(onPressed: () => context.read<MainTabCubit>().setTab(value), iconSize: 32, color: groupValue != value ? null : Theme.of(context).colorScheme.secondary, icon: icon);
  }
}
