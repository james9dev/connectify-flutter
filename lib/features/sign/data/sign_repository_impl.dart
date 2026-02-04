import 'package:connectify/features/sign/data/sign_client.dart';
import 'package:connectify/features/sign/domain/sign_repository.dart';

class SignRepositoryImpl extends SignRepository {
  final SignClient _signClient;

  SignRepositoryImpl({required SignClient signClient}) : _signClient = signClient;

  @override
  Future<String?> sign(String kakoToken) async {
    final authToken = await _signClient.signWithKakao(kakoToken);

    return authToken?.accessToken;
  }
}
