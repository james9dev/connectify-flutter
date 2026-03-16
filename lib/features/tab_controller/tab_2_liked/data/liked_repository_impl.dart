import 'dart:convert';

import 'package:connectify/core/dto/result_dto.dart';
import 'package:connectify/core/network/api_client.dart';
import 'package:connectify/features/tab_controller/tab_2_liked/domain/liked_repository.dart';
import 'package:connectify/shared/models/member.dart';

class LikedRepositoryImpl implements LikedRepository {
  LikedRepositoryImpl(this._apiClient);

  final ApiClient _apiClient;

  @override
  Future<List<Member>> getMembersWhoLikedMe() async {
    return _fetchMembers('/profile/me/likes/members/received');
  }

  @override
  Future<List<Member>> getMembersWhoLikedMyPictures() async {
    return _fetchMembers('/profile/me/likes/photos/members');
  }

  Future<List<Member>> _fetchMembers(String path) async {
    final response = await _apiClient.get(path);
    final payload = _decodeJsonObject(response.body);

    final resultDto = _parseResultDto<List<Member>>(payload, (json) => _parseMemberList(json), statusCode: response.statusCode);
    if (response.statusCode >= 200 && response.statusCode < 300 && resultDto.success() && resultDto.data != null) {
      return resultDto.data!;
    }

    throw LikedRepositoryException(resultDto.message);
  }

  ResultDto<T> _parseResultDto<T>(Map<String, dynamic> payload, T Function(Object? json) fromJsonT, {required int statusCode}) {
    try {
      return ResultDto<T>.fromJson(payload, fromJsonT);
    } catch (_) {
      throw LikedRepositoryException(_extractFallbackMessage(payload, statusCode));
    }
  }

  List<Member> _parseMemberList(Object? json) {
    if (json is! List) {
      return const <Member>[];
    }

    final members = <Member>[];
    for (final element in json) {
      if (element is Map<String, dynamic>) {
        members.add(Member.fromJson(element));
        continue;
      }

      if (element is Map) {
        members.add(Member.fromJson(element.map((key, value) => MapEntry('$key', value))));
      }
    }

    return members;
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

    return '요청 처리 중 오류가 발생했습니다. (status: $statusCode)';
  }
}

class LikedRepositoryException implements Exception {
  const LikedRepositoryException(this.message);

  final String message;

  @override
  String toString() => message;
}
