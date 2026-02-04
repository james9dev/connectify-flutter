import 'package:json_annotation/json_annotation.dart';

part 'auth_token_dto.g.dart';

@JsonSerializable()
class AuthTokenDto {
  final AuthType authType;
  final String accessToken;
  final String refreshToken;

  AuthTokenDto({required this.authType, required this.accessToken, required this.refreshToken});

  factory AuthTokenDto.fromJson(Map<String, dynamic> json) => _$AuthTokenDtoFromJson(json);
}

enum AuthType { SignIn, SignUp, Refresh }
