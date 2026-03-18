import 'package:bloc/bloc.dart';
import 'package:connectify/shared/authentication/repositories/authentication_repository.dart';
import 'package:connectify/features/sign/domain/entities/password.dart';
import 'package:connectify/features/sign/domain/entities/username.dart';
import 'package:connectify/features/sign/domain/sign_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/services.dart';
import 'package:formz/formz.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';

part 'login_event.dart';
part 'login_state.dart';

class LoginBloc extends Bloc<LoginEvent, LoginState> {
  LoginBloc({required AuthenticationRepository authenticationRepository, required SignRepository signRepository})
    : _authenticationRepository = authenticationRepository,
      _signRepository = signRepository,
      super(const LoginState()) {
    on<LoginUsernameChanged>(_onUsernameChanged);
    on<LoginPasswordChanged>(_onPasswordChanged);
    on<LoginSubmitted>(_onSubmitted);
    on<KakaoSignClicked>(_onKakaoSignClicked);
    on<TestAccountLoginRequested>(_onTestAccountLoginRequested);
  }

  final AuthenticationRepository _authenticationRepository;
  final SignRepository _signRepository;

  void _onUsernameChanged(LoginUsernameChanged event, Emitter<LoginState> emit) {
    final username = Username.dirty(event.username);
    emit(state.copyWith(username: username, isValid: Formz.validate([state.password, username])));
  }

  void _onPasswordChanged(LoginPasswordChanged event, Emitter<LoginState> emit) {
    final password = Password.dirty(event.password);
    emit(state.copyWith(password: password, isValid: Formz.validate([password, state.username])));
  }

  Future<void> _onSubmitted(LoginSubmitted event, Emitter<LoginState> emit) async {
    if (state.isValid) {
      emit(state.copyWith(status: FormzSubmissionStatus.inProgress));
      try {
        //await _authenticationRepository.logIn(username: state.username.value, password: state.password.value);
        emit(state.copyWith(status: FormzSubmissionStatus.success));
      } catch (_) {
        emit(state.copyWith(status: FormzSubmissionStatus.failure));
      }
    }
  }

  Future<void> _onKakaoSignClicked(KakaoSignClicked event, Emitter<LoginState> emit) async {
    final kakaoToken = await kakaoLogin();

    if (kakaoToken == null) {
      emit(state.copyWith(status: FormzSubmissionStatus.failure));
      return;
    }

    await _loginWithKakaoAccessToken(kakaoToken, emit);
  }

  Future<void> _onTestAccountLoginRequested(TestAccountLoginRequested event, Emitter<LoginState> emit) async {
    emit(state.copyWith(status: FormzSubmissionStatus.inProgress));

    try {
      final authToken = await _signRepository.tmpLoginKakao(event.providerId);
      await _authenticationRepository.logIn(accessToken: authToken.accessToken, requireProfileSetup: false);
      emit(state.copyWith(status: FormzSubmissionStatus.success));
    } on SignRepositoryException {
      emit(state.copyWith(status: FormzSubmissionStatus.failure));
    } catch (_) {
      emit(state.copyWith(status: FormzSubmissionStatus.failure));
    }
  }

  Future<void> _loginWithKakaoAccessToken(String kakaoToken, Emitter<LoginState> emit) async {
    emit(state.copyWith(status: FormzSubmissionStatus.inProgress));

    try {
      final authToken = await _signRepository.loginKakao(kakaoToken);
      await _authenticationRepository.logIn(accessToken: authToken.accessToken, requireProfileSetup: false);
      emit(state.copyWith(status: FormzSubmissionStatus.success));
    } on SignRepositoryException catch (error) {
      if (error.isNotRegisteredUser) {
        await _authenticationRepository.beginKakaoSignUp(kakaoAccessToken: kakaoToken);
        emit(state.copyWith(status: FormzSubmissionStatus.success));
        return;
      }

      emit(state.copyWith(status: FormzSubmissionStatus.failure));
    } catch (_) {
      emit(state.copyWith(status: FormzSubmissionStatus.failure));
    }
  }

  Future<String?> kakaoLogin() async {
    if (await isKakaoTalkInstalled()) {
      try {
        OAuthToken authToken = await UserApi.instance.loginWithKakaoTalk();
        return authToken.accessToken;
      } catch (error) {
        // 사용자가 카카오톡 설치 후 디바이스 권한 요청 화면에서 로그인을 취소한 경우,
        // 의도적인 로그인 취소로 보고 카카오계정으로 로그인 시도 없이 로그인 취소로 처리 (예: 뒤로 가기)
        if (error is PlatformException && error.code == 'CANCELED') {
          return null;
        }
        // 카카오톡에 연결된 카카오계정이 없는 경우, 카카오계정으로 로그인
        try {
          OAuthToken authToken = await UserApi.instance.loginWithKakaoAccount();
          return authToken.accessToken;
        } catch (_) {}
      }
    } else {
      try {
        OAuthToken authToken = await UserApi.instance.loginWithKakaoAccount();
        return authToken.accessToken;
      } catch (_) {}
    }

    return null;
  }
}
