import 'dart:math';

import 'package:connectify/features/member/data/member_client.dart';
import 'package:connectify/features/onboarding/profile_basic/domain/entities/profile_basic_info_command.dart';
import 'package:connectify/features/onboarding/profile_basic/domain/profile_basic_repository.dart';
import 'package:connectify/features/tab_controller/tab_4_profile/domain/profile_repository.dart';
import 'package:connectify/shared/models/member.dart';
import 'package:connectify/shared/models/profile_tag_catalog.dart';
import 'package:connectify/features/tab_controller/tab_1_explore/domain/member_repository.dart';

class MemberRepositoryImpl implements MemberRepository, ProfileRepository, ProfileBasicRepository {
  final MemberClient _memberClient;

  MemberRepositoryImpl(this._memberClient);

  @override
  Future<List<Member>> fetchMembers() async {
    return await _memberClient.getIntroMembers();
  }

  @override
  Future<Member?> getMember(String memberId) async {
    return await _memberClient.getMember(memberId);
  }

  @override
  Future<void> likeProfilePhoto({required int pictureId}) {
    return _memberClient.likeProfilePhoto(pictureId: pictureId);
  }

  @override
  Future<void> unlikeProfilePhoto({required int pictureId}) {
    return _memberClient.unlikeProfilePhoto(pictureId: pictureId);
  }

  @override
  Future<void> likeMember({required int memberId}) {
    return _memberClient.likeMember(memberId: memberId);
  }

  @override
  Future<void> cancelMemberLike({required int memberId}) {
    return _memberClient.cancelMemberLike(memberId: memberId);
  }

  @override
  Future<Member?> getProfile() async {
    return await _memberClient.getUser();
  }

  @override
  Future<Member> uploadProfilePhoto({required List<int> imageBytes, required String fileName, required String contentType}) async {
    final currentMember = await _memberClient.getUser();
    if (currentMember == null) {
      throw MemberClientException('프로필 정보를 찾지 못했습니다. 잠시 후 다시 시도해주세요.');
    }

    final nextOrder = _resolveNextPictureOrder(currentMember.profile.pictures);
    final signedUpload = await _memberClient.createProfilePhotoUploadUrl(order: nextOrder, contentType: contentType, contentLength: imageBytes.length, fileName: fileName);

    final requiredHeaders = Map<String, String>.from(signedUpload.requiredHeaders);
    final hasContentType = requiredHeaders.keys.any((key) => key.toLowerCase() == 'content-type');
    if (!hasContentType) {
      requiredHeaders['Content-Type'] = contentType;
    }

    await _memberClient.uploadProfilePhotoToSignedUrl(uploadUrl: signedUpload.uploadUrl, imageBytes: imageBytes, requiredHeaders: requiredHeaders);
    await _memberClient.completeProfilePhotoUpload(order: nextOrder, objectKey: signedUpload.objectKey);

    final refreshedMember = await _memberClient.getUser();
    if (refreshedMember != null) {
      return refreshedMember;
    }

    return currentMember;
  }

  @override
  Future<Member> deleteProfilePhoto({required int pictureId}) async {
    final currentMember = await _memberClient.getUser();
    if (currentMember == null) {
      throw MemberClientException('프로필 정보를 찾지 못했습니다. 잠시 후 다시 시도해주세요.');
    }

    await _memberClient.deleteProfilePhoto(pictureId: pictureId);

    final refreshedMember = await _memberClient.getUser();
    if (refreshedMember != null) {
      return refreshedMember;
    }

    return currentMember;
  }

  @override
  Future<ProfileTagCatalog> getProfileTagCatalog() {
    return _memberClient.getProfileTagCatalog();
  }

  @override
  Future<List<String>> getProfileRegions() {
    return _memberClient.getProfileRegions();
  }

  @override
  Future<void> updateProfileBasicInfo({
    required String nickName,
    required GenderType gender,
    required String birthyear,
    required String birthday,
    required String region,
    required String bio,
    required List<int> profileTagIds,
    required List<int> preferredTagIds,
  }) {
    return _memberClient.updateProfileBasicInfo(
      nickName: nickName,
      gender: gender,
      birthyear: birthyear,
      birthday: birthday,
      region: region,
      bio: bio,
      profileTagIds: profileTagIds,
      preferredTagIds: preferredTagIds,
    );
  }

  @override
  Future<void> submitProfileBasicInfo(ProfileBasicInfoCommand command) {
    return updateProfileBasicInfo(
      nickName: command.nickName,
      gender: command.gender,
      birthyear: command.birthyear,
      birthday: command.birthday,
      region: command.region,
      bio: command.bio,
      profileTagIds: command.profileTagIds,
      preferredTagIds: command.preferredTagIds,
    );
  }

  int _resolveNextPictureOrder(List<ProfilePicture> pictures) {
    if (pictures.isEmpty) {
      return 0;
    }

    final maxOrder = pictures.map((picture) => picture.order).reduce(max);
    return maxOrder + 1;
  }
}
