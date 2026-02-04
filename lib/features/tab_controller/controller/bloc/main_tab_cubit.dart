import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

part 'main_tab_state.dart';

class MainTabCubit extends Cubit<MainTabState> {
  MainTabCubit() : super(const MainTabState());

  void setTab(MainTab tab) => emit(MainTabState(tab: tab));
}
