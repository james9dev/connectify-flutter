import 'dart:async';
import 'dart:convert';

import 'package:connectify/core/network/api_client.dart';
import 'package:connectify/core/dto/result_dto.dart';
import 'package:connectify/shared/models/member.dart';
import 'package:connectify/shared/models/profile_tag_catalog.dart';
import 'package:http/http.dart' as http;

class MemberClient {
  final ApiClient _apiClient;

  MemberClient(this._apiClient);

  Future<List<Member>> getIntroMembers() async {
    final response = await _apiClient.get('/match/intro');

    final jsonResponse = jsonDecode(response.body) as Map<String, dynamic>;

    final resultDto = ResultDto<ListDto<Member>>.fromJson(jsonResponse, (data) => ListDto<Member>.fromJson(data as Map<String, dynamic>, (json) => Member.fromJson(json as Map<String, dynamic>)));

    if (resultDto.success()) {
      final members = resultDto.data?.values ?? [];
      return members;
    }

    return [];
  }

  Future<Member?> getMember(String memberId) async {
    final response = await _apiClient.get('/profile/$memberId');

    final jsonResponse = jsonDecode(response.body) as Map<String, dynamic>;

    final resultDto = ResultDto<Member>.fromJson(jsonResponse, (json) => Member.fromJson(json as Map<String, dynamic>));

    if (resultDto.success()) {
      final member = resultDto.data;

      return member;
    }

    return null;
  }

  Future<Member?> getUser() async {
    final response = await _apiClient.get('/profile/me');

    final jsonResponse = jsonDecode(response.body) as Map<String, dynamic>;

    final resultDto = ResultDto<Member>.fromJson(jsonResponse, (json) => Member.fromJson(json as Map<String, dynamic>));

    if (resultDto.success()) {
      final member = resultDto.data;

      return member;
    }

    return null;
  }

  Future<ProfilePhotoUploadUrlDto> createProfilePhotoUploadUrl({required int order, required String contentType, required int contentLength, required String fileName}) async {
    final response = await _apiClient.post('/profile/photos/upload-url', body: {'order': order, 'contentType': contentType, 'contentLength': contentLength, 'fileName': fileName});

    final resultDto = _parseResultDto<ProfilePhotoUploadUrlDto>(response, (json) => ProfilePhotoUploadUrlDto.fromJson(json as Map<String, dynamic>));

    if (response.statusCode >= 200 && response.statusCode < 300 && resultDto.success() && resultDto.data != null) {
      return resultDto.data!;
    }

    throw MemberClientException(resultDto.message);
  }

  Future<void> uploadProfilePhotoToSignedUrl({required String uploadUrl, required List<int> imageBytes, required Map<String, String> requiredHeaders}) async {
    final response = await _apiClient.putAbsolute(uploadUrl, bodyBytes: imageBytes, headers: requiredHeaders);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw MemberClientException('이미지 업로드에 실패했습니다. (status: ${response.statusCode})');
    }
  }

  Future<void> completeProfilePhotoUpload({required int order, required String objectKey}) async {
    final response = await _apiClient.post('/profile/photos/complete', body: {'order': order, 'objectKey': objectKey});
    final resultDto = _parseResultDto<Object?>(response, (json) => json);

    if (response.statusCode >= 200 && response.statusCode < 300 && resultDto.success()) {
      return;
    }

    throw MemberClientException(resultDto.message);
  }

  Future<void> deleteProfilePhoto({required int pictureId}) async {
    final response = await _apiClient.delete('/profile/photos/$pictureId');
    final resultDto = _parseResultDto<Object?>(response, (json) => json);

    if (response.statusCode >= 200 && response.statusCode < 300 && resultDto.success()) {
      return;
    }

    throw MemberClientException(resultDto.message);
  }

  Future<void> likeProfilePhoto({required int pictureId}) async {
    final response = await _apiClient.post('/profile/photos/$pictureId/like');
    final resultDto = _parseResultDto<Object?>(response, (json) => json);

    if (response.statusCode >= 200 && response.statusCode < 300 && resultDto.success()) {
      return;
    }

    throw MemberClientException(resultDto.message);
  }

  Future<void> unlikeProfilePhoto({required int pictureId}) async {
    final response = await _apiClient.delete('/profile/photos/$pictureId/like');
    final resultDto = _parseResultDto<Object?>(response, (json) => json);

    if (response.statusCode >= 200 && response.statusCode < 300 && resultDto.success()) {
      return;
    }

    throw MemberClientException(resultDto.message);
  }

  Future<void> likeMember({required int memberId}) async {
    final response = await _apiClient.post('/profile/$memberId/like');
    final resultDto = _parseResultDto<Object?>(response, (json) => json);

    if (response.statusCode >= 200 && response.statusCode < 300 && resultDto.success()) {
      return;
    }

    throw MemberClientException(resultDto.message);
  }

  Future<void> cancelMemberLike({required int memberId}) async {
    final response = await _apiClient.delete('/profile/$memberId/like');
    final resultDto = _parseResultDto<Object?>(response, (json) => json);

    if (response.statusCode >= 200 && response.statusCode < 300 && resultDto.success()) {
      return;
    }

    throw MemberClientException(resultDto.message);
  }

  Future<ProfileTagCatalog> getProfileTagCatalog() async {
    final response = await _apiClient.get('/profile/catalog/tags');
    final resultDto = _parseResultDto<ProfileTagCatalog>(response, (json) => ProfileTagCatalog.fromJson(json as Map<String, dynamic>));

    if (response.statusCode >= 200 && response.statusCode < 300 && resultDto.success() && resultDto.data != null) {
      return resultDto.data!;
    }

    throw MemberClientException(resultDto.message);
  }

  Future<List<String>> getProfileRegions() async {
    final response = await _apiClient.get('/profile/catalog/regions');
    final resultDto = _parseResultDto<ListDto<String>>(response, (json) => ListDto<String>.fromJson(json as Map<String, dynamic>, (value) => '${value ?? ''}'));

    if (response.statusCode >= 200 && response.statusCode < 300 && resultDto.success() && resultDto.data != null) {
      return resultDto.data!.values.map((region) => region.trim()).where((region) => region.isNotEmpty).toList(growable: false);
    }

    throw MemberClientException(resultDto.message);
  }

  Future<void> updateProfileBasicInfo({
    required String nickName,
    required GenderType gender,
    required String birthyear,
    required String birthday,
    required String region,
    required String bio,
    required List<int> profileTagIds,
    required List<int> preferredTagIds,
  }) async {
    final response = await _apiClient.put(
      '/profile/update',
      body: {
        'nickName': nickName,
        'gender': gender.name,
        'birthyear': birthyear,
        'birthday': birthday,
        'region': region,
        'bio': bio,
        'profileTagIds': profileTagIds,
        'preferredTagIds': preferredTagIds,
      },
    );

    final resultDto = _parseResultDto<Object?>(response, (json) => json);

    if (response.statusCode >= 200 && response.statusCode < 300 && resultDto.success()) {
      return;
    }

    throw MemberClientException(resultDto.message);
  }

  ResultDto<T> _parseResultDto<T>(http.Response response, T Function(Object? json) fromJsonT) {
    final payload = _decodeJsonObject(response.body);

    try {
      return ResultDto<T>.fromJson(payload, fromJsonT);
    } catch (_) {
      throw MemberClientException(_extractFallbackMessage(payload, response.statusCode));
    }
  }

  Map<String, dynamic> _decodeJsonObject(String body) {
    if (body.isEmpty) {
      return {};
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
      return {};
    }

    return {};
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

    return '요청 처리 중 오류가 발생했습니다. (status: $statusCode)';
  }
}

class ProfilePhotoUploadUrlDto {
  final String objectKey;
  final String uploadUrl;
  final String? expiresAt;
  final Map<String, String> requiredHeaders;

  ProfilePhotoUploadUrlDto({required this.objectKey, required this.uploadUrl, required this.expiresAt, required this.requiredHeaders});

  factory ProfilePhotoUploadUrlDto.fromJson(Map<String, dynamic> json) {
    final requiredHeaders = <String, String>{};
    final rawHeaders = json['requiredHeaders'];
    if (rawHeaders is Map) {
      rawHeaders.forEach((key, value) {
        requiredHeaders['$key'] = '$value';
      });
    }

    return ProfilePhotoUploadUrlDto(objectKey: '${json['objectKey'] ?? ''}', uploadUrl: '${json['uploadUrl'] ?? ''}', expiresAt: json['expiresAt']?.toString(), requiredHeaders: requiredHeaders);
  }
}

class MemberClientException implements Exception {
  final String message;

  MemberClientException(this.message);

  @override
  String toString() => message;
}
