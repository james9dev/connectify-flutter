import 'package:connectify/app.dart';
import 'package:connectify/core/di/di.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:kakao_flutter_sdk_auth/kakao_flutter_sdk_auth.dart';

Future<void> main() async {
  await dotenv.load(fileName: ".env");

  /* 카카오톡 초기화 */
  // 웹 환경에서 카카오 로그인을 정상적으로 완료하려면 runApp() 호출 전 아래 메서드 호출 필요
  WidgetsFlutterBinding.ensureInitialized();
  // // runApp() 호출 전 Flutter SDK 초기화
  KakaoSdk.init(nativeAppKey: dotenv.env['KAKAO_APP_KEY_TEST']);

  setupDI();

  runApp(const App());
}
