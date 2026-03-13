import 'dart:math';

import 'package:connectify/features/member/member_client.dart';
import 'package:connectify/features/tab_controller/tab_4_profile/domain/profile_repository.dart';
import 'package:connectify/shared/models/member.dart';
import 'package:connectify/features/tab_controller/tab_1_explore/domain/member_repository.dart';

class MemberRepositoryImpl implements MemberRepository, ProfileRepository {
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

  int _resolveNextPictureOrder(List<ProfilePicture> pictures) {
    if (pictures.isEmpty) {
      return 0;
    }

    final maxOrder = pictures.map((picture) => picture.order).reduce(max);
    return maxOrder + 1;
  }
}
