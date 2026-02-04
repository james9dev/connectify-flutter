import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:connectify/features/member/member_repository_impl.dart';
import 'package:connectify/shared/authentication/repositories/authentication_repository.dart';
import 'package:connectify/shared/models/member.dart';
import 'package:equatable/equatable.dart';

part 'authentication_event.dart';
part 'authentication_state.dart';

class AuthenticationBloc extends Bloc<AuthenticationEvent, AuthenticationState> {
  AuthenticationBloc({required AuthenticationRepository authenticationRepository, required MemberRepositoryImpl userRepository})
    : _authenticationRepository = authenticationRepository,
      _userRepository = userRepository,
      super(const AuthenticationState.unknown()) {
    on<AuthenticationSubscriptionRequested>(_onSubscriptionRequested);
    on<AuthenticationLogoutPressed>(_onLogoutPressed);
  }

  final AuthenticationRepository _authenticationRepository;
  final MemberRepositoryImpl _userRepository;

  Future<void> _onSubscriptionRequested(AuthenticationSubscriptionRequested event, Emitter<AuthenticationState> emit) {
    return emit.onEach(
      _authenticationRepository.status,
      onData: (status) async {
        switch (status) {
          case AuthStatus.unauthorized:
            return emit(const AuthenticationState.unauthenticated());
          case AuthStatus.success:
            final token = await _authenticationRepository.tokenStorage.getToken();
            final user = await _tryGetUser();
            return emit(token != null ? AuthenticationState.authenticated(token, user) : const AuthenticationState.unauthenticated());
          default:
            return emit(const AuthenticationState.unknown());
        }
      },
      onError: addError,
    );
  }

  void _onLogoutPressed(AuthenticationLogoutPressed event, Emitter<AuthenticationState> emit) {
    _authenticationRepository.logOut();
  }

  Future<Member?> _tryGetUser() async {
    try {
      final user = await _userRepository.getProfile();
      return user;
    } catch (error) {
      print('tryGetUser error: $error');
      return null;
    }
  }
}
