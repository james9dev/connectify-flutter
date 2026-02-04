import 'package:connectify/shared/models/member.dart';

abstract class MemberRepository {
  Future<List<Member>> fetchMembers();
  Future<Member?> getMember(String memberId);
  //Future<Member?> getProfile();
}
