import 'dart:async';
import 'dart:convert';

import 'package:connectify/core/network/api_client.dart';
import 'package:connectify/core/dto/result_dto.dart';
import 'package:connectify/shared/models/member.dart';

class MemberClient {
  final ApiClient _apiClient;

  MemberClient(this._apiClient);

  Future<List<Member>> getIntroMembers() async {
    final response = await _apiClient.get('/match/intro');

    final jsonResponse = jsonDecode(response.body) as Map<String, dynamic>;

    final resultDto = ResultDto<ListDto<Member>>.fromJson(jsonResponse, (data) => ListDto<Member>.fromJson(data as Map<String, dynamic>, (json) => Member.fromJson(json as Map<String, dynamic>)));

    if (resultDto.success()) {
      final members = resultDto.data?.values ?? [];
      print(members.length);

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
}
