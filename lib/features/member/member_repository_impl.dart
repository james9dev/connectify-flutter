import 'package:connectify/features/member/member_client.dart';
import 'package:connectify/features/tab_controller/tab_4_profile/domain/profile_repository.dart';
import 'package:connectify/shared/models/member.dart';
import 'package:connectify/features/tab_controller/tab_1_explore/domain/member_repository.dart';

class MemberRepositoryImpl implements MemberRepository, ProfileRepository {
  final MemberClient _memberClient;

  MemberRepositoryImpl(this._memberClient);

  @override
  Future<List<Member>> fetchMembers() async {
    return await _memberClient.getIntroMembers();
  }

  @override
  Future<Member?> getMember(String memberId) async {
    return await _memberClient.getMember(memberId);
  }

  @override
  Future<Member?> getProfile() async {
    return await _memberClient.getUser();
  }
}
