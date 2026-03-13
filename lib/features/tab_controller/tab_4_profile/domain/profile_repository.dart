import 'package:connectify/shared/models/member.dart';

abstract class ProfileRepository {
  Future<Member?> getProfile();

  Future<Member> uploadProfilePhoto({required List<int> imageBytes, required String fileName, required String contentType});
}
