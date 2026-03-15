import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:connectify/features/tab_controller/tab_4_profile/domain/profile_repository.dart';
import 'package:connectify/shared/authentication/repositories/authentication_repository.dart';
import 'package:connectify/shared/models/member.dart';
import 'package:equatable/equatable.dart';

part 'authentication_event.dart';
part 'authentication_state.dart';

class AuthenticationBloc extends Bloc<AuthenticationEvent, AuthenticationState> {
  AuthenticationBloc({required AuthenticationRepository authenticationRepository, required ProfileRepository userRepository})
    : _authenticationRepository = authenticationRepository,
      _userRepository = userRepository,
      super(const AuthenticationState.unknown()) {
    on<AuthenticationSubscriptionRequested>(_onSubscriptionRequested);
    on<AuthenticationLogoutPressed>(_onLogoutPressed);
  }

  final AuthenticationRepository _authenticationRepository;
  final ProfileRepository _userRepository;

  Future<void> _onSubscriptionRequested(AuthenticationSubscriptionRequested event, Emitter<AuthenticationState> emit) {
    return emit.onEach(
      _authenticationRepository.status,
      onData: (status) async {
        switch (status) {
          case AuthStatus.unauthorized:
            return emit(const AuthenticationState.unauthenticated());
          case AuthStatus.profileSetupRequired:
            final pendingKakaoAccessToken = _authenticationRepository.pendingKakaoAccessToken;
            final token = await _authenticationRepository.tokenStorage.getToken();
            if (token == null && (pendingKakaoAccessToken == null || pendingKakaoAccessToken.isEmpty)) {
              return emit(const AuthenticationState.unauthenticated());
            }

            final user = token == null ? null : await _tryGetUser();
            return emit(AuthenticationState.authenticated(token, user, requiresProfileSetup: true, pendingKakaoAccessToken: pendingKakaoAccessToken));
          case AuthStatus.success:
            final token = await _authenticationRepository.tokenStorage.getToken();
            if (token == null) {
              return emit(const AuthenticationState.unauthenticated());
            }

            final user = await _tryGetUser();
            return emit(AuthenticationState.authenticated(token, user, requiresProfileSetup: false));
          default:
            return emit(const AuthenticationState.unknown());
        }
      },
      onError: addError,
    );
  }

  Future<void> _onLogoutPressed(AuthenticationLogoutPressed event, Emitter<AuthenticationState> emit) async {
    await _authenticationRepository.logOut();
  }

  Future<Member?> _tryGetUser() async {
    try {
      final user = await _userRepository.getProfile();
      return user;
    } catch (_) {
      return null;
    }
  }
}
