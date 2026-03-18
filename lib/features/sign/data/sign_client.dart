import 'dart:async';
import 'dart:convert';

import 'package:connectify/core/dto/result_dto.dart';
import 'package:connectify/core/network/api_client.dart';
import 'package:connectify/shared/models/auth_token_dto.dart';
import 'package:http/http.dart' as http;

class SignClient {
  final ApiClient _apiClient;

  SignClient(this._apiClient);

  Future<AuthTokenDto> loginKakao(String kakaoAccessToken) async {
    return _requestKakaoAuth(path: '/member/sign/kakao/login', kakaoAccessToken: kakaoAccessToken);
  }

  Future<AuthTokenDto> registerKakao(String kakaoAccessToken) async {
    return _requestKakaoAuth(path: '/member/sign/kakao/register', kakaoAccessToken: kakaoAccessToken);
  }

  Future<AuthTokenDto> tmpLoginKakao(int providerId) async {
    final response = await _apiClient.post('/member/sign/kakao/login-tmp', body: {'providerId': providerId});
    final resultDto = _parseResultDto<AuthTokenDto>(response, (data) => AuthTokenDto.fromJson(data as Map<String, dynamic>));

    if (response.statusCode >= 200 && response.statusCode < 300 && resultDto.success() && resultDto.data != null) {
      return resultDto.data!;
    }

    throw SignClientException(resultDto.message, statusCode: response.statusCode);
  }

  Future<AuthTokenDto> _requestKakaoAuth({required String path, required String kakaoAccessToken}) async {
    final response = await _apiClient.post(path, body: {'idToken': '', 'accessToken': kakaoAccessToken, 'tokenType': 'Bearer'});
    final resultDto = _parseResultDto<AuthTokenDto>(response, (data) => AuthTokenDto.fromJson(data as Map<String, dynamic>));

    if (response.statusCode >= 200 && response.statusCode < 300 && resultDto.success() && resultDto.data != null) {
      return resultDto.data!;
    }

    throw SignClientException(resultDto.message, statusCode: response.statusCode);
  }

  ResultDto<T> _parseResultDto<T>(http.Response response, T Function(Object? data) fromJsonT) {
    final payload = _decodeJsonObject(response.body);

    try {
      return ResultDto<T>.fromJson(payload, fromJsonT);
    } catch (_) {
      final fallback = _extractFallbackMessage(payload, response.statusCode);
      throw SignClientException(fallback, statusCode: response.statusCode);
    }
  }

  Map<String, dynamic> _decodeJsonObject(String body) {
    if (body.isEmpty) {
      return <String, dynamic>{};
    }

    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      if (decoded is Map) {
        return decoded.map((key, value) => MapEntry('$key', value));
      }
    } catch (_) {
      return <String, dynamic>{};
    }

    return <String, dynamic>{};
  }

  String _extractFallbackMessage(Map<String, dynamic> payload, int statusCode) {
    final message = payload['message'];
    if (message is String && message.trim().isNotEmpty) {
      return message;
    }

    final error = payload['error'];
    if (error is String && error.trim().isNotEmpty) {
      return error;
    }

    return '카카오 인증 처리 중 오류가 발생했습니다. (status: $statusCode)';
  }
}

class SignClientException implements Exception {
  final String message;
  final int? statusCode;

  const SignClientException(this.message, {this.statusCode});

  @override
  String toString() => message;
}
