import 'package:json_annotation/json_annotation.dart';
part 'member.g.dart';

enum GenderType { MALE, FEMALE }

enum MyDateRequestStatus { requested, accepted, rejected, canceled }

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

  Map<String, dynamic> toJson() => _$MemberToJson(this);

  Member copyWith({int? id, String? email, String? phoneNumber, String? name, bool? newbie, Profile? profile}) {
    return Member(
      id: id ?? this.id,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      name: name ?? this.name,
      newbie: newbie ?? this.newbie,
      profile: profile ?? this.profile,
    );
  }
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
  final List<ProfileTagSummary> profileTagIds;
  final List<ProfileTagSummary> preferredTagIds;
  @JsonKey(defaultValue: false)
  final bool memberLikeStatus;
  @JsonKey(fromJson: _dateRequestStatusFromJson, toJson: _dateRequestStatusToJson)
  final MyDateRequestStatus? myDateRequestStatus;

  Profile({
    required this.id,
    required this.nickName,
    required this.gender,
    required this.height,
    required this.birthyear,
    required this.birthday,
    required this.pictures,
    required this.profileTagIds,
    required this.preferredTagIds,
    required this.memberLikeStatus,
    this.myDateRequestStatus,
  });

  factory Profile.fromJson(Map<String, dynamic> json) => _$ProfileFromJson(json);

  Map<String, dynamic> toJson() => _$ProfileToJson(this);

  Profile copyWith({
    int? id,
    String? nickName,
    GenderType? gender,
    int? height,
    String? birthyear,
    String? birthday,
    String? job,
    String? company,
    String? educationInstitution,
    String? educationGraduation,
    double? latitude,
    double? longitude,
    String? location,
    String? bio,
    List<ProfilePicture>? pictures,
    List<ProfileTagSummary>? profileTagIds,
    List<ProfileTagSummary>? preferredTagIds,
    bool? memberLikeStatus,
    MyDateRequestStatus? myDateRequestStatus,
  }) {
    final profile = Profile(
      id: id ?? this.id,
      nickName: nickName ?? this.nickName,
      gender: gender ?? this.gender,
      height: height ?? this.height,
      birthyear: birthyear ?? this.birthyear,
      birthday: birthday ?? this.birthday,
      pictures: pictures ?? this.pictures,
      profileTagIds: profileTagIds ?? this.profileTagIds,
      preferredTagIds: preferredTagIds ?? this.preferredTagIds,
      memberLikeStatus: memberLikeStatus ?? this.memberLikeStatus,
      myDateRequestStatus: myDateRequestStatus ?? this.myDateRequestStatus,
    );

    profile.job = job ?? this.job;
    profile.company = company ?? this.company;
    profile.educationInstitution = educationInstitution ?? this.educationInstitution;
    profile.educationGraduation = educationGraduation ?? this.educationGraduation;
    profile.latitude = latitude ?? this.latitude;
    profile.longitude = longitude ?? this.longitude;
    profile.location = location ?? this.location;
    profile.bio = bio ?? this.bio;

    return profile;
  }

  List<ProfilePicture> get orderedPictures {
    if (pictures.length <= 1) {
      return pictures;
    }

    final sorted = List<ProfilePicture>.from(pictures);
    sorted.sort((left, right) {
      if (left.isPrimary != right.isPrimary) {
        return left.isPrimary ? -1 : 1;
      }
      return left.order.compareTo(right.order);
    });
    return sorted;
  }

  ProfilePicture? get primaryPicture {
    final ordered = orderedPictures;
    return ordered.isEmpty ? null : ordered.first;
  }

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

  static MyDateRequestStatus? _dateRequestStatusFromJson(Object? value) {
    if (value is! String) {
      return null;
    }

    switch (value.toUpperCase()) {
      case 'REQUESTED':
        return MyDateRequestStatus.requested;
      case 'ACCEPTED':
        return MyDateRequestStatus.accepted;
      case 'REJECTED':
        return MyDateRequestStatus.rejected;
      case 'CANCELED':
        return MyDateRequestStatus.canceled;
      default:
        return null;
    }
  }

  static String? _dateRequestStatusToJson(MyDateRequestStatus? value) {
    if (value == null) {
      return null;
    }

    switch (value) {
      case MyDateRequestStatus.requested:
        return 'REQUESTED';
      case MyDateRequestStatus.accepted:
        return 'ACCEPTED';
      case MyDateRequestStatus.rejected:
        return 'REJECTED';
      case MyDateRequestStatus.canceled:
        return 'CANCELED';
    }
  }
}

@JsonSerializable()
class ProfilePicture {
  final int id;
  @JsonKey(fromJson: _decodeUrl)
  final String imageUrl;
  final int order;
  @JsonKey(defaultValue: false)
  final bool isPrimary;
  @JsonKey(defaultValue: false)
  final bool pictureLikeStatus;

  ProfilePicture({required this.id, required this.imageUrl, required this.order, required this.isPrimary, required this.pictureLikeStatus});

  factory ProfilePicture.fromJson(Map<String, dynamic> json) => _$ProfilePictureFromJson(json);

  Map<String, dynamic> toJson() => _$ProfilePictureToJson(this);

  ProfilePicture copyWith({int? id, String? imageUrl, int? order, bool? isPrimary, bool? pictureLikeStatus}) {
    return ProfilePicture(
      id: id ?? this.id,
      imageUrl: imageUrl ?? this.imageUrl,
      order: order ?? this.order,
      isPrimary: isPrimary ?? this.isPrimary,
      pictureLikeStatus: pictureLikeStatus ?? this.pictureLikeStatus,
    );
  }

  static String _decodeUrl(String encoded) {
    return Uri.decodeFull(encoded);
  }
}

@JsonSerializable()
class ProfileTagSummary {
  final int id;
  final String? name;
  final String? category;

  const ProfileTagSummary({required this.id, this.name, this.category});

  factory ProfileTagSummary.fromJson(Map<String, dynamic> json) => _$ProfileTagSummaryFromJson(json);

  Map<String, dynamic> toJson() => _$ProfileTagSummaryToJson(this);
}
