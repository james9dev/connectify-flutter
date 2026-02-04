import 'package:connectify/shared/models/member.dart';

abstract class ProfileRepository {
  Future<Member?> getProfile();
}
