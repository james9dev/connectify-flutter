import 'package:connectify/shared/models/member.dart';

abstract class LikedRepository {
  Future<List<Member>> getMembersWhoLikedMe();
  Future<List<Member>> getMembersWhoLikedMyPictures();
}
