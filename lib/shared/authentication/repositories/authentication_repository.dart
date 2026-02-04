import 'dart:async';

import 'package:connectify/core/network/token_storage.dart';

enum AuthStatus {
  unknown,
  success, // 로그인 성공
  invalidCredentials, // 아이디/비번 오류
  tokenExpired, // 토큰 만료
  unauthorized, // 권한 없음 (401)
  forbidden, // 접근 금지 (403)
  networkError, // 네트워크 문제
  serverError, // 서버 내부 오류
}

class AuthenticationRepository {
  final _controller = StreamController<AuthStatus>();

  final TokenStorage tokenStorage;

  AuthenticationRepository({required this.tokenStorage});

  Stream<AuthStatus> get status async* {
    String? token = await tokenStorage.getToken();

    if (token != null) {
      yield AuthStatus.success;
    } else {
      yield AuthStatus.unauthorized;
    }

    yield* _controller.stream;
  }

  Future<void> logIn({required String? accessToken}) async {
    if (accessToken == null) {
      _controller.add(AuthStatus.unauthorized);
      return;
    }

    /// ✅ 저장
    await tokenStorage.saveToken(accessToken);

    _controller.add(AuthStatus.success);
  }

  void logOut() async {
    /// ✅ 삭제
    await tokenStorage.clear();

    /// ✅ 전체 삭제
    //await storage.deleteAll();

    _controller.add(AuthStatus.unauthorized);
  }

  void dispose() => _controller.close();
}
