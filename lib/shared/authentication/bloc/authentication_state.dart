part of 'authentication_bloc.dart';

class AuthenticationState extends Equatable {
  const AuthenticationState._({this.status = AuthStatus.unknown, this.user, this.token});

  const AuthenticationState.unknown() : this._();

  const AuthenticationState.authenticated(String? token, Member? user) : this._(status: AuthStatus.success, user: user, token: token);

  const AuthenticationState.unauthenticated() : this._(status: AuthStatus.unauthorized);

  final AuthStatus status;
  final Member? user;
  final String? token;

  @override
  List<Object> get props => [status, ?user, ?token];
}
