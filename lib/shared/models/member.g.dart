// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'member.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Member _$MemberFromJson(Map<String, dynamic> json) => Member(
  id: (json['id'] as num).toInt(),
  email: json['email'] as String,
  phoneNumber: json['phoneNumber'] as String?,
  name: json['name'] as String,
  newbie: json['newbie'] as bool,
  profile: Profile.fromJson(json['profile'] as Map<String, dynamic>),
);

Map<String, dynamic> _$MemberToJson(Member instance) => <String, dynamic>{
  'id': instance.id,
  'email': instance.email,
  'phoneNumber': instance.phoneNumber,
  'name': instance.name,
  'newbie': instance.newbie,
  'profile': instance.profile,
};

Profile _$ProfileFromJson(Map<String, dynamic> json) =>
    Profile(
        id: (json['id'] as num).toInt(),
        nickName: json['nickName'] as String?,
        gender: $enumDecodeNullable(_$GenderTypeEnumMap, json['gender']),
        height: (json['height'] as num?)?.toInt(),
        birthyear: json['birthyear'] as String?,
        birthday: json['birthday'] as String?,
        pictures: (json['pictures'] as List<dynamic>)
            .map((e) => ProfilePicture.fromJson(e as Map<String, dynamic>))
            .toList(),
      )
      ..job = json['job'] as String?
      ..company = json['company'] as String?
      ..educationInstitution = json['educationInstitution'] as String?
      ..educationGraduation = json['educationGraduation'] as String?
      ..latitude = (json['latitude'] as num?)?.toDouble()
      ..longitude = (json['longitude'] as num?)?.toDouble()
      ..location = json['location'] as String?
      ..bio = json['bio'] as String?;

Map<String, dynamic> _$ProfileToJson(Profile instance) => <String, dynamic>{
  'id': instance.id,
  'nickName': instance.nickName,
  'gender': _$GenderTypeEnumMap[instance.gender],
  'height': instance.height,
  'birthyear': instance.birthyear,
  'birthday': instance.birthday,
  'job': instance.job,
  'company': instance.company,
  'educationInstitution': instance.educationInstitution,
  'educationGraduation': instance.educationGraduation,
  'latitude': instance.latitude,
  'longitude': instance.longitude,
  'location': instance.location,
  'bio': instance.bio,
  'pictures': instance.pictures,
};

const _$GenderTypeEnumMap = {
  GenderType.MALE: 'MALE',
  GenderType.FEMALE: 'FEMALE',
};

ProfilePicture _$ProfilePictureFromJson(Map<String, dynamic> json) =>
    ProfilePicture(
      id: (json['id'] as num).toInt(),
      imageUrl: ProfilePicture._decodeUrl(json['imageUrl'] as String),
      order: (json['order'] as num).toInt(),
    );

Map<String, dynamic> _$ProfilePictureToJson(ProfilePicture instance) =>
    <String, dynamic>{
      'id': instance.id,
      'imageUrl': instance.imageUrl,
      'order': instance.order,
    };
