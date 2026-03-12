// lib/features/explore/logic/explore_bloc.dart
import 'package:bloc/bloc.dart';
import 'package:connectify/shared/models/member.dart';
import 'package:connectify/features/tab_controller/tab_1_explore/domain/member_repository.dart';
import 'package:equatable/equatable.dart';

part 'explore_event.dart';
part 'explore_state.dart';

class ExploreBloc extends Bloc<ExploreEvent, ExploreState> {
  final MemberRepository repository;

  ExploreBloc(this.repository) : super(const ExploreState()) {
    on<ExploreLoaded>(_onLoaded);
    on<MemberSelected>(_onSelected);
  }

  Future<void> _onLoaded(ExploreLoaded event, Emitter<ExploreState> emit) async {
    emit(state.copyWith(status: ExploreStatus.loading));
    try {
      final members = await repository.fetchMembers();
      emit(state.copyWith(status: ExploreStatus.success, members: members, selectedMember: members.isNotEmpty ? members.first : null));
    } catch (_) {
      emit(state.copyWith(status: ExploreStatus.failure));
    }
  }

  void _onSelected(MemberSelected event, Emitter<ExploreState> emit) {
    emit(state.copyWith(selectedMember: event.member));
  }
}
