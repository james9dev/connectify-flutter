import 'package:connectify/shared/models/auth_token_dto.dart';

abstract class SignRepository {
  Future<AuthTokenDto> loginKakao(String kakaoToken);

  Future<AuthTokenDto> registerKakao(String kakaoToken);
}

class SignRepositoryException implements Exception {
  final String message;
  final int? statusCode;

  const SignRepositoryException(this.message, {this.statusCode});

  bool get isNotRegisteredUser => statusCode == 404;

  bool get isAlreadyRegisteredUser => statusCode == 409;

  @override
  String toString() => message;
}
