import 'package:connectify/features/onboarding/profile_basic/domain/entities/profile_basic_info_command.dart';
import 'package:connectify/features/onboarding/profile_photo/domain/entities/profile_photo_draft.dart';

abstract class ProfilePhotoRepository {
  Future<void> completeOnboarding({
    required String kakaoAccessToken,
    required ProfileBasicInfoCommand basicInfoCommand,
    required List<ProfilePhotoDraft> draftPhotos,
    required void Function(int uploadedCount, int totalCount) onUploadProgress,
  });
}

class ProfilePhotoOnboardingException implements Exception {
  final String message;
  final int uploadedCount;
  final int totalCount;

  const ProfilePhotoOnboardingException({required this.message, required this.uploadedCount, required this.totalCount});

  @override
  String toString() => message;
}
