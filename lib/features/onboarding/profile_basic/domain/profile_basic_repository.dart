import 'package:connectify/features/onboarding/profile_basic/domain/entities/profile_basic_info_command.dart';
import 'package:connectify/shared/models/profile_tag_catalog.dart';

abstract class ProfileBasicRepository {
  Future<ProfileTagCatalog> getProfileTagCatalog();

  Future<List<String>> getProfileRegions();

  Future<void> submitProfileBasicInfo(ProfileBasicInfoCommand command);
}
