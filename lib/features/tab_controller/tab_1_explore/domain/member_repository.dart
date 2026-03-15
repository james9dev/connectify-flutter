import 'package:connectify/shared/models/member.dart';

abstract class MemberRepository {
  Future<List<Member>> fetchMembers();
  Future<Member?> getMember(String memberId);
  Future<void> likeProfilePhoto({required int pictureId});
  Future<void> unlikeProfilePhoto({required int pictureId});
  Future<void> likeMember({required int memberId});
  Future<void> cancelMemberLike({required int memberId});
  //Future<Member?> getProfile();
}
