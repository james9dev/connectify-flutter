import 'dart:convert';

import 'package:connectify/core/dto/result_dto.dart';
import 'package:connectify/core/network/api_client.dart';
import 'package:connectify/features/tab_controller/tab_3_chats/domain/chat_repository.dart';
import 'package:connectify/features/tab_controller/tab_3_chats/domain/entities/date_request.dart';
import 'package:connectify/shared/models/member.dart';
import 'package:http/http.dart' as http;

class ChatRepositoryImpl implements ChatRepository {
  ChatRepositoryImpl(this._apiClient);

  final ApiClient _apiClient;

  @override
  Future<int> requestDate({required int receiverMemberId, String? requestMessage}) async {
    final normalizedMessage = requestMessage?.trim();
    final requestBody = normalizedMessage == null || normalizedMessage.isEmpty ? <String, dynamic>{} : <String, dynamic>{'requestMessage': normalizedMessage};
    final response = await _apiClient.post('/match/date-requests/$receiverMemberId', body: requestBody);

    final resultDto = _parseResultDto<int>(response, _parseIntValue);
    if (_isSuccess(response.statusCode) && resultDto.success() && resultDto.data != null) {
      return resultDto.data!;
    }

    throw ChatRepositoryException(resultDto.message);
  }

  @override
  Future<void> cancelDateRequest({required int dateRequestId}) async {
    final response = await _apiClient.patch('/match/date-requests/$dateRequestId/cancel');
    final resultDto = _parseResultDto<Object?>(response, (json) => json);

    if (_isSuccess(response.statusCode) && resultDto.success()) {
      return;
    }

    throw ChatRepositoryException(resultDto.message);
  }

  @override
  Future<void> acceptDateRequest({required int dateRequestId}) async {
    final response = await _apiClient.patch('/match/date-requests/$dateRequestId/accept');
    final resultDto = _parseResultDto<Object?>(response, (json) => json);

    if (_isSuccess(response.statusCode) && resultDto.success()) {
      return;
    }

    throw ChatRepositoryException(resultDto.message);
  }

  @override
  Future<void> rejectDateRequest({required int dateRequestId}) async {
    final response = await _apiClient.patch('/match/date-requests/$dateRequestId/reject');
    final resultDto = _parseResultDto<Object?>(response, (json) => json);

    if (_isSuccess(response.statusCode) && resultDto.success()) {
      return;
    }

    throw ChatRepositoryException(resultDto.message);
  }

  @override
  Future<List<DateRequest>> getSentDateRequests({DateRequestStatus? status, int page = 0, int size = 20}) async {
    return _fetchDateRequests('/match/date-requests/sent', status: status, page: page, size: size);
  }

  @override
  Future<List<DateRequest>> getReceivedDateRequests({DateRequestStatus? status, int page = 0, int size = 20}) async {
    return _fetchDateRequests('/match/date-requests/received', status: status, page: page, size: size);
  }

  @override
  Future<Member?> getMemberProfile({required int memberId}) async {
    final response = await _apiClient.get('/profile/$memberId');
    final resultDto = _parseResultDto<Member>(response, (json) => Member.fromJson(_normalizeMap(json)));

    if (_isSuccess(response.statusCode) && resultDto.success() && resultDto.data != null) {
      return resultDto.data;
    }

    throw ChatRepositoryException(resultDto.message);
  }

  Future<List<DateRequest>> _fetchDateRequests(String basePath, {required DateRequestStatus? status, required int page, required int size}) async {
    final path = _buildRequestListPath(basePath, status: status, page: page, size: size);
    final response = await _apiClient.get(path);
    final resultDto = _parseResultDto<ListDto<DateRequest>>(response, (json) => ListDto<DateRequest>.fromJson(json as Map<String, dynamic>, (item) => _parseDateRequest(item)));

    if (_isSuccess(response.statusCode) && resultDto.success() && resultDto.data != null) {
      return resultDto.data!.values;
    }

    throw ChatRepositoryException(resultDto.message);
  }

  String _buildRequestListPath(String basePath, {required DateRequestStatus? status, required int page, required int size}) {
    final query = <String, String>{'page': '$page', 'size': '$size'};
    if (status != null) {
      query['status'] = _statusToApiValue(status);
    }

    final queryString = query.entries.map((entry) => '${entry.key}=${Uri.encodeQueryComponent(entry.value)}').join('&');
    return '$basePath?$queryString';
  }

  DateRequest _parseDateRequest(Object? json) {
    final data = _normalizeMap(json);

    return DateRequest(
      id: _parseIntValue(data['id']),
      requesterMemberId: _parseIntValue(data['requesterMemberId']),
      requesterNickName: '${data['requesterNickName'] ?? ''}',
      receiverMemberId: _parseIntValue(data['receiverMemberId']),
      receiverNickName: '${data['receiverNickName'] ?? ''}',
      status: _parseStatus(data['status']),
      requestMessage: data['requestMessage']?.toString(),
      requestedAt: _parseDateTime(data['requestedAt']),
      respondedAt: _parseDateTime(data['respondedAt']),
    );
  }

  DateRequestStatus _parseStatus(Object? value) {
    final raw = '$value'.toUpperCase();
    switch (raw) {
      case 'ACCEPTED':
        return DateRequestStatus.accepted;
      case 'REJECTED':
        return DateRequestStatus.rejected;
      default:
        return DateRequestStatus.requested;
    }
  }

  String _statusToApiValue(DateRequestStatus status) {
    switch (status) {
      case DateRequestStatus.requested:
        return 'REQUESTED';
      case DateRequestStatus.accepted:
        return 'ACCEPTED';
      case DateRequestStatus.rejected:
        return 'REJECTED';
    }
  }

  DateTime? _parseDateTime(Object? value) {
    if (value == null) {
      return null;
    }
    return DateTime.tryParse('$value');
  }

  int _parseIntValue(Object? value) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse('$value') ?? 0;
  }

  ResultDto<T> _parseResultDto<T>(http.Response response, T Function(Object? json) fromJsonT) {
    final payload = _decodeJsonObject(response.body);

    try {
      return ResultDto<T>.fromJson(payload, fromJsonT);
    } catch (_) {
      throw ChatRepositoryException(_extractFallbackMessage(payload, response.statusCode));
    }
  }

  bool _isSuccess(int statusCode) => statusCode >= 200 && statusCode < 300;

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

  Map<String, dynamic> _normalizeMap(Object? source) {
    if (source is Map<String, dynamic>) {
      return source;
    }
    if (source is Map) {
      return source.map((key, value) => MapEntry('$key', value));
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

class ChatRepositoryException implements Exception {
  ChatRepositoryException(this.message);

  final String message;

  @override
  String toString() => message;
}
