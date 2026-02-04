import 'package:connectify/features/tab_controller/tab_4_profile/domain/profile_repository.dart';
import 'package:connectify/features/tab_controller/tab_4_profile/presentation/bloc/profile_event.dart';
import 'package:connectify/features/tab_controller/tab_4_profile/presentation/bloc/profile_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final ProfileRepository repository;

  ProfileBloc(this.repository) : super(const ProfileState()) {
    on<ProfileLoaded>(_onLoaded);
  }

  Future<void> _onLoaded(ProfileLoaded event, Emitter<ProfileState> emit) async {
    final profile = await repository.getProfile();
  }
}
