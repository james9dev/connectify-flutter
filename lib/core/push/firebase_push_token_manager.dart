import 'dart:async';
import 'dart:io';

import 'package:connectify/core/network/api_client.dart';
import 'package:connectify/core/push/push_token_manager.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp();
    }
  } catch (_) {
    // 앱 런타임에서 초기화 실패 시 백그라운드 핸들러는 조용히 종료한다.
  }
}

class FirebasePushTokenManager implements PushTokenManager {
  FirebasePushTokenManager({required ApiClient apiClient, FirebaseMessaging? messaging}) : _apiClient = apiClient, _messaging = messaging;

  final ApiClient _apiClient;
  FirebaseMessaging? _messaging;

  final StreamController<PushMessageEvent> _messageController = StreamController<PushMessageEvent>.broadcast();

  bool _initialized = false;
  bool _isAuthenticated = false;
  String? _lastKnownToken;

  @override
  Stream<PushMessageEvent> get messages => _messageController.stream;

  @override
  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }

      final messaging = _messaging ?? FirebaseMessaging.instance;
      _messaging = messaging;

      await messaging.requestPermission(alert: true, announcement: false, badge: true, carPlay: false, criticalAlert: false, provisional: false, sound: true);

      await messaging.setForegroundNotificationPresentationOptions(alert: true, badge: true, sound: true);

      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      FirebaseMessaging.onMessage.listen((message) => _emitMessage(message, openedApp: false));
      FirebaseMessaging.onMessageOpenedApp.listen((message) => _emitMessage(message, openedApp: true));

      final initialMessage = await messaging.getInitialMessage();
      if (initialMessage != null) {
        _emitMessage(initialMessage, openedApp: true);
      }

      messaging.onTokenRefresh.listen((nextToken) {
        final normalized = nextToken.trim();
        if (normalized.isEmpty) {
          return;
        }

        _lastKnownToken = normalized;

        if (_isAuthenticated) {
          unawaited(_registerPushToken(normalized));
        }
      });

      _initialized = true;
    } catch (_) {
      _initialized = false;
    }
  }

  @override
  Future<void> onAuthenticated() async {
    _isAuthenticated = true;
    await initialize();

    if (!_initialized) {
      return;
    }

    final token = await _resolveCurrentToken();
    if (token == null) {
      return;
    }

    await _registerPushToken(token);
  }

  @override
  Future<void> onUnauthenticated() async {
    _isAuthenticated = false;
    await initialize();

    if (!_initialized) {
      return;
    }

    final token = await _resolveCurrentToken();
    if (token == null) {
      return;
    }

    await _unregisterPushToken(token);
  }

  Future<String?> _resolveCurrentToken() async {
    final cachedToken = _lastKnownToken?.trim();
    if (cachedToken != null && cachedToken.isNotEmpty) {
      return cachedToken;
    }

    final messaging = _messaging;
    if (messaging == null) {
      return null;
    }

    final token = (await messaging.getToken())?.trim();
    if (token == null || token.isEmpty) {
      return null;
    }

    _lastKnownToken = token;
    return token;
  }

  Future<void> _registerPushToken(String token) async {
    try {
      await _apiClient.post('/profile/me/push-token', body: <String, dynamic>{'deviceToken': token, 'platform': _platformValue()});
    } catch (_) {
      // 로그인/토큰 갱신 흐름을 막지 않기 위해 실패를 전파하지 않는다.
    }
  }

  Future<void> _unregisterPushToken(String token) async {
    try {
      await _apiClient.delete('/profile/me/push-token', body: <String, dynamic>{'deviceToken': token});
    } catch (_) {
      // 로그아웃 흐름을 막지 않기 위해 실패를 전파하지 않는다.
    }
  }

  void _emitMessage(RemoteMessage message, {required bool openedApp}) {
    final notification = message.notification;

    _messageController.add(PushMessageEvent(title: notification?.title, body: notification?.body, data: message.data.map((key, value) => MapEntry(key, value)), openedApp: openedApp));
  }

  String _platformValue() {
    if (kIsWeb) {
      return 'WEB';
    }

    if (Platform.isIOS) {
      return 'IOS';
    }

    if (Platform.isAndroid) {
      return 'ANDROID';
    }

    return 'WEB';
  }
}
