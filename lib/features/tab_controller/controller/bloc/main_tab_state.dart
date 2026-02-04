part of 'main_tab_cubit.dart';

enum MainTab { home, search, notifications, profile }

final class MainTabState extends Equatable {
  const MainTabState({this.tab = MainTab.home});

  final MainTab tab;

  @override
  List<Object> get props => [tab];
}
