import 'package:connectify/shared/models/member.dart';

class ProfileBasicInfoCommand {
  final String nickName;
  final GenderType gender;
  final String birthyear;
  final String birthday;
  final String region;
  final String bio;
  final List<int> profileTagIds;
  final List<int> preferredTagIds;

  const ProfileBasicInfoCommand({
    required this.nickName,
    required this.gender,
    required this.birthyear,
    required this.birthday,
    required this.region,
    required this.bio,
    required this.profileTagIds,
    required this.preferredTagIds,
  });
}
