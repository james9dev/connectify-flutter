import 'package:connectify/shared/models/profile_tag_catalog.dart';
import 'package:connectify/shared/models/member.dart';

abstract class ProfileRepository {
  Future<Member?> getProfile();

  Future<Member> uploadProfilePhoto({required List<int> imageBytes, required String fileName, required String contentType});

  Future<Member> deleteProfilePhoto({required int pictureId});

  Future<Member> reorderProfilePhoto({required int pictureId, required int targetOrder});

  Future<ProfileTagCatalog> getProfileTagCatalog();

  Future<void> updateProfileBasicInfo({
    required String nickName,
    required GenderType gender,
    required String birthyear,
    required String birthday,
    required String region,
    required String bio,
    required List<int> profileTagIds,
    required List<int> preferredTagIds,
  });
}
