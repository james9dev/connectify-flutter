part of 'authentication_bloc.dart';

class AuthenticationState extends Equatable {
  const AuthenticationState._({this.status = AuthStatus.unknown, this.user, this.token, this.requiresProfileSetup = false, this.pendingKakaoAccessToken});

  const AuthenticationState.unknown() : this._();

  const AuthenticationState.authenticated(String? token, Member? user, {bool requiresProfileSetup = false, String? pendingKakaoAccessToken})
    : this._(
        status: requiresProfileSetup ? AuthStatus.profileSetupRequired : AuthStatus.success,
        user: user,
        token: token,
        requiresProfileSetup: requiresProfileSetup,
        pendingKakaoAccessToken: pendingKakaoAccessToken,
      );

  const AuthenticationState.unauthenticated() : this._(status: AuthStatus.unauthorized);

  final AuthStatus status;
  final Member? user;
  final String? token;
  final bool requiresProfileSetup;
  final String? pendingKakaoAccessToken;

  @override
  List<Object?> get props => [status, user, token, requiresProfileSetup, pendingKakaoAccessToken];
}
