import 'package:json_annotation/json_annotation.dart';
part 'member.g.dart';

enum GenderType { MALE, FEMALE }

@JsonSerializable()
class Member {
  final int id;
  final String email;
  final String? phoneNumber;
  final String name;

  final bool newbie;
  final Profile profile;

  Member({required this.id, required this.email, required this.phoneNumber, required this.name, required this.newbie, required this.profile});

  factory Member.fromJson(Map<String, dynamic> json) => _$MemberFromJson(json);
}

@JsonSerializable()
class Profile {
  final int id;

  final String? nickName;
  final GenderType? gender;
  final int? height;
  final String? birthyear;
  final String? birthday;

  String? job;
  String? company;
  String? educationInstitution;
  String? educationGraduation;

  double? latitude;
  double? longitude;
  String? location;

  String? bio;
  final List<ProfilePicture> pictures;

  Profile({required this.id, required this.nickName, required this.gender, required this.height, required this.birthyear, required this.birthday, required this.pictures});

  factory Profile.fromJson(Map<String, dynamic> json) => _$ProfileFromJson(json);

  int age() {
    if (birthyear == null) {
      return 0;
    }

    final year = int.parse(birthyear!);

    final month = int.parse(birthday!.substring(0, 2));
    final day = int.parse(birthday!.substring(2, 4));

    final today = DateTime.now();
    final birthdayDateTime = DateTime(year, month, day);

    int age = today.year - birthdayDateTime.year;

    // 생일이 안 지난 경우 -1
    if (today.month < birthdayDateTime.month || (today.month == birthdayDateTime.month && today.day < birthdayDateTime.day)) {
      age--;
    }

    return age;
  }
}

@JsonSerializable()
class ProfilePicture {
  final int id;
  @JsonKey(fromJson: _decodeUrl)
  final String imageUrl;
  final int order;

  ProfilePicture({required this.id, required this.imageUrl, required this.order});

  factory ProfilePicture.fromJson(Map<String, dynamic> json) => _$ProfilePictureFromJson(json);

  static String _decodeUrl(String encoded) {
    return Uri.decodeFull(encoded);
  }
}
