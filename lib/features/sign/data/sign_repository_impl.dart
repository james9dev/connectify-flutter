import 'package:connectify/features/sign/data/sign_client.dart';
import 'package:connectify/features/sign/domain/sign_repository.dart';
import 'package:connectify/shared/models/auth_token_dto.dart';

class SignRepositoryImpl extends SignRepository {
  final SignClient _signClient;

  SignRepositoryImpl({required SignClient signClient}) : _signClient = signClient;

  @override
  Future<AuthTokenDto> loginKakao(String kakaoToken) async {
    try {
      return await _signClient.loginKakao(kakaoToken);
    } on SignClientException catch (error) {
      throw SignRepositoryException(error.message, statusCode: error.statusCode);
    }
  }

  @override
  Future<AuthTokenDto> tmpLoginKakao(int providerId) async {
    try {
      return await _signClient.tmpLoginKakao(providerId);
    } on SignClientException catch (error) {
      throw SignRepositoryException(error.message, statusCode: error.statusCode);
    }
  }

  @override
  Future<AuthTokenDto> registerKakao(String kakaoToken) async {
    try {
      return await _signClient.registerKakao(kakaoToken);
    } on SignClientException catch (error) {
      throw SignRepositoryException(error.message, statusCode: error.statusCode);
    }
  }
}
