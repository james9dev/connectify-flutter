import 'dart:async';
import 'dart:convert';

import 'package:connectify/core/dto/result_dto.dart';
import 'package:connectify/core/network/api_client.dart';
import 'package:connectify/shared/models/auth_token_dto.dart';

class SignClient {
  final ApiClient _apiClient;

  SignClient(this._apiClient);

  Future<AuthTokenDto?> signWithKakao(String kakaoAccessToken) async {
    final response = await _apiClient.post('/member/sign/kakao', body: {'accessToken': kakaoAccessToken});
    print(response.body.toString());

    final jsonResponse = jsonDecode(response.body) as Map<String, dynamic>;

    final resultDto = ResultDto<AuthTokenDto>.fromJson(jsonResponse, (data) => AuthTokenDto.fromJson(data as Map<String, dynamic>));

    if (resultDto.success()) {
      AuthTokenDto? authTokenDto = resultDto.data;
      print(authTokenDto?.accessToken);

      return resultDto.data;
    }

    return null;
  }
}
