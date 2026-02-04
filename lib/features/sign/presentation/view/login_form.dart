import 'package:connectify/features/sign/presentation/bloc/login_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:formz/formz.dart';

class LoginForm extends StatelessWidget {
  const LoginForm({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<LoginBloc, LoginState>(
      listener: (context, state) {
        if (state.status.isFailure) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(const SnackBar(content: Text('Authentication Failure')));
        }
      },
      child: Align(
        alignment: const Alignment(0, -1 / 3),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _UsernameInput(),
            const Padding(padding: EdgeInsets.all(12)),
            _PasswordInput(),
            const Padding(padding: EdgeInsets.all(12)),
            _LoginButton(),
            const Padding(padding: EdgeInsets.all(24)),
            _KakaoButton(),
          ],
        ),
      ),
    );
  }
}

class _KakaoButton extends StatelessWidget {
  const _KakaoButton();

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      child: const Text('KakaoTalk'),
      onPressed: () {
        context.read<LoginBloc>().add(KakaoSignClicked());
        // kakaoLogin();
      },
    );
  }
}

class _UsernameInput extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final displayError = context.select((LoginBloc bloc) => bloc.state.username.displayError);

    return TextField(
      key: const Key('loginForm_usernameInput_textField'),
      onChanged: (username) {
        context.read<LoginBloc>().add(LoginUsernameChanged(username));
      },
      decoration: InputDecoration(labelText: 'username', errorText: displayError != null ? 'invalid username' : null),
    );
  }
}

class _PasswordInput extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final displayError = context.select((LoginBloc bloc) => bloc.state.password.displayError);

    return TextField(
      key: const Key('loginForm_passwordInput_textField'),
      onChanged: (password) {
        context.read<LoginBloc>().add(LoginPasswordChanged(password));
      },
      obscureText: true,
      decoration: InputDecoration(labelText: 'password', errorText: displayError != null ? 'invalid password' : null),
    );
  }
}

class _LoginButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isInProgressOrSuccess = context.select((LoginBloc bloc) => bloc.state.status.isInProgressOrSuccess);

    if (isInProgressOrSuccess) return const CircularProgressIndicator();

    final isValid = context.select((LoginBloc bloc) => bloc.state.isValid);

    return ElevatedButton(
      key: const Key('loginForm_continue_raisedButton'),
      onPressed: () {
        if (isValid) {
          context.read<LoginBloc>().add(const LoginSubmitted());
        } else {
          null;
        }
      },
      child: const Text('Login'),
    );
  }
}
