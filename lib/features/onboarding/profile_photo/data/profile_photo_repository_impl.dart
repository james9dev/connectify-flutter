import 'package:connectify/features/onboarding/profile_basic/domain/entities/profile_basic_info_command.dart';
import 'package:connectify/features/onboarding/profile_photo/domain/entities/profile_photo_draft.dart';
import 'package:connectify/features/onboarding/profile_photo/domain/profile_photo_repository.dart';
import 'package:connectify/features/sign/domain/sign_repository.dart';
import 'package:connectify/features/tab_controller/tab_4_profile/domain/profile_repository.dart';
import 'package:connectify/shared/authentication/repositories/authentication_repository.dart';
import 'package:connectify/shared/models/auth_token_dto.dart';

class OnboardingProfilePhotoRepositoryImpl implements ProfilePhotoRepository {
  final SignRepository _signRepository;
  final ProfileRepository _profileRepository;
  final AuthenticationRepository _authenticationRepository;

  OnboardingProfilePhotoRepositoryImpl({required SignRepository signRepository, required ProfileRepository profileRepository, required AuthenticationRepository authenticationRepository})
    : _signRepository = signRepository,
      _profileRepository = profileRepository,
      _authenticationRepository = authenticationRepository;

  @override
  Future<void> completeOnboarding({
    required String kakaoAccessToken,
    required ProfileBasicInfoCommand basicInfoCommand,
    required List<ProfilePhotoDraft> draftPhotos,
    required void Function(int uploadedCount, int totalCount) onUploadProgress,
  }) async {
    if (draftPhotos.isEmpty) {
      throw const ProfilePhotoOnboardingException(message: '대표 사진을 포함해 최소 1장의 사진이 필요합니다.', uploadedCount: 0, totalCount: 0);
    }

    final authToken = await _registerOrLoginForOnboarding(kakaoAccessToken);
    await _authenticationRepository.stageAccessToken(authToken.accessToken);

    var uploadedCount = 0;
    final totalCount = draftPhotos.length;

    try {
      await _profileRepository.updateProfileBasicInfo(
        nickName: basicInfoCommand.nickName,
        gender: basicInfoCommand.gender,
        birthyear: basicInfoCommand.birthyear,
        birthday: basicInfoCommand.birthday,
        region: basicInfoCommand.region,
        bio: basicInfoCommand.bio,
        profileTagIds: basicInfoCommand.profileTagIds,
        preferredTagIds: basicInfoCommand.preferredTagIds,
      );

      onUploadProgress(uploadedCount, totalCount);

      for (final draft in draftPhotos) {
        await _profileRepository.uploadProfilePhoto(imageBytes: draft.bytes, fileName: draft.fileName, contentType: draft.contentType);
        uploadedCount += 1;
        onUploadProgress(uploadedCount, totalCount);
      }

      await _authenticationRepository.logIn(accessToken: authToken.accessToken, requireProfileSetup: false);
    } catch (error) {
      await _authenticationRepository.clearStagedAccessToken();

      throw ProfilePhotoOnboardingException(message: _toErrorMessage(error), uploadedCount: uploadedCount, totalCount: totalCount);
    }
  }

  Future<AuthTokenDto> _registerOrLoginForOnboarding(String kakaoAccessToken) async {
    try {
      return await _signRepository.registerKakao(kakaoAccessToken);
    } on SignRepositoryException catch (error) {
      if (error.isAlreadyRegisteredUser) {
        return _signRepository.loginKakao(kakaoAccessToken);
      }
      rethrow;
    }
  }

  String _toErrorMessage(Object error) {
    if (error is ProfilePhotoOnboardingException) {
      return error.message;
    }

    if (error is SignRepositoryException) {
      return error.message;
    }

    final raw = error.toString().trim();
    if (raw.isEmpty) {
      return '회원가입 처리 중 오류가 발생했습니다.';
    }

    if (raw.startsWith('Exception: ')) {
      return raw.replaceFirst('Exception: ', '');
    }

    return raw;
  }
}
