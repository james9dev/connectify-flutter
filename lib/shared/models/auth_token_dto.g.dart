// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_token_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AuthTokenDto _$AuthTokenDtoFromJson(Map<String, dynamic> json) => AuthTokenDto(
  authType: $enumDecode(_$AuthTypeEnumMap, json['authType']),
  accessToken: json['accessToken'] as String,
  refreshToken: json['refreshToken'] as String,
);

Map<String, dynamic> _$AuthTokenDtoToJson(AuthTokenDto instance) =>
    <String, dynamic>{
      'authType': _$AuthTypeEnumMap[instance.authType]!,
      'accessToken': instance.accessToken,
      'refreshToken': instance.refreshToken,
    };

const _$AuthTypeEnumMap = {
  AuthType.SignIn: 'SignIn',
  AuthType.SignUp: 'SignUp',
  AuthType.Refresh: 'Refresh',
};
