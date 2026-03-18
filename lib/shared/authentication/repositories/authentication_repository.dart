import 'dart:async';

import 'package:connectify/core/push/push_token_manager.dart';
import 'package:connectify/core/network/token_storage.dart';

enum AuthStatus {
  unknown,
  success, // 로그인 성공
  profileSetupRequired, // 회원가입 직후 프로필 기본정보 입력 필요
  invalidCredentials, // 아이디/비번 오류
  tokenExpired, // 토큰 만료
  unauthorized, // 권한 없음 (401)
  forbidden, // 접근 금지 (403)
  networkError, // 네트워크 문제
  serverError, // 서버 내부 오류
}

class AuthenticationRepository {
  final _controller = StreamController<AuthStatus>.broadcast();
  String? _pendingKakaoAccessToken;

  final TokenStorage tokenStorage;
  final PushTokenManager pushTokenManager;

  AuthenticationRepository({required this.tokenStorage, required this.pushTokenManager});

  Stream<AuthStatus> get status async* {
    String? token = await tokenStorage.getToken();

    if (token != null) {
      yield AuthStatus.success;
      unawaited(_syncPushOnAuthenticated());
    } else {
      yield AuthStatus.unauthorized;
      unawaited(_safePushInitialize());
    }

    yield* _controller.stream;
  }

  Future<void> logIn({required String? accessToken, bool requireProfileSetup = false}) async {
    if (accessToken == null) {
      _controller.add(AuthStatus.unauthorized);
      return;
    }

    /// ✅ 저장
    await tokenStorage.saveToken(accessToken);
    _pendingKakaoAccessToken = null;
    unawaited(_syncPushOnAuthenticated());

    _controller.add(requireProfileSetup ? AuthStatus.profileSetupRequired : AuthStatus.success);
  }

  Future<void> beginKakaoSignUp({required String kakaoAccessToken}) async {
    _pendingKakaoAccessToken = kakaoAccessToken;
    _controller.add(AuthStatus.profileSetupRequired);
  }

  Future<void> stageAccessToken(String accessToken) async {
    await tokenStorage.saveToken(accessToken);
    unawaited(_syncPushOnAuthenticated());
  }

  Future<void> clearStagedAccessToken() async {
    unawaited(_syncPushOnUnauthenticated());
    await tokenStorage.clear();
  }

  String? get pendingKakaoAccessToken => _pendingKakaoAccessToken;

  Future<void> logOut() async {
    unawaited(_syncPushOnUnauthenticated());

    /// ✅ 삭제
    await tokenStorage.clear();
    _pendingKakaoAccessToken = null;

    /// ✅ 전체 삭제
    //await storage.deleteAll();

    _controller.add(AuthStatus.unauthorized);
  }

  void dispose() => _controller.close();

  Future<void> _safePushInitialize() async {
    try {
      await pushTokenManager.initialize();
    } catch (_) {
      // 인증 라우팅을 막지 않기 위해 푸시 초기화 실패는 무시한다.
    }
  }

  Future<void> _syncPushOnAuthenticated() async {
    try {
      await pushTokenManager.onAuthenticated();
    } catch (_) {
      // 인증 라우팅을 막지 않기 위해 푸시 동기화 실패는 무시한다.
    }
  }

  Future<void> _syncPushOnUnauthenticated() async {
    try {
      await pushTokenManager.onUnauthenticated();
    } catch (_) {
      // 로그아웃 라우팅을 막지 않기 위해 푸시 동기화 실패는 무시한다.
    }
  }
}
