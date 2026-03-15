import 'package:connectify/features/sign/presentation/bloc/login_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:formz/formz.dart';

const Color _accentYellow = Color(0xFFFFC629);

class LoginForm extends StatelessWidget {
  const LoginForm({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<LoginBloc, LoginState>(
      listener: (context, state) {
        if (state.status.isFailure) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(const SnackBar(content: Text('인증에 실패했습니다. 다시 시도해주세요.')));
        }
      },
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 24),
            const Text(
              'Connectify에 오신 걸 환영해요',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.black87),
            ),
            const SizedBox(height: 8),
            const Text(
              '카카오 로그인으로 빠르게 시작해보세요.',
              style: TextStyle(fontSize: 15, color: Colors.black54, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFFC629).withValues(alpha: 0.5)),
              ),
              child: const Column(children: [_UsernameInput(), SizedBox(height: 12), _PasswordInput(), SizedBox(height: 16), _LoginButton()]),
            ),
            const SizedBox(height: 18),
            const _KakaoButton(),
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
    final isLoading = context.select((LoginBloc bloc) => bloc.state.status.isInProgress);

    return FilledButton(
      style: FilledButton.styleFrom(
        backgroundColor: _accentYellow,
        foregroundColor: Colors.black,
        padding: const EdgeInsets.symmetric(vertical: 15),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
      ),
      onPressed: isLoading
          ? null
          : () {
              context.read<LoginBloc>().add(KakaoSignClicked());
            },
      child: isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black)) : const Text('카카오톡으로 시작하기'),
    );
  }
}

class _UsernameInput extends StatelessWidget {
  const _UsernameInput();

  @override
  Widget build(BuildContext context) {
    final displayError = context.select((LoginBloc bloc) => bloc.state.username.displayError);

    return TextField(
      key: const Key('loginForm_usernameInput_textField'),
      onChanged: (username) {
        context.read<LoginBloc>().add(LoginUsernameChanged(username));
      },
      decoration: InputDecoration(labelText: 'username', filled: true, fillColor: Colors.white, border: const OutlineInputBorder(), errorText: displayError != null ? 'invalid username' : null),
    );
  }
}

class _PasswordInput extends StatelessWidget {
  const _PasswordInput();

  @override
  Widget build(BuildContext context) {
    final displayError = context.select((LoginBloc bloc) => bloc.state.password.displayError);

    return TextField(
      key: const Key('loginForm_passwordInput_textField'),
      onChanged: (password) {
        context.read<LoginBloc>().add(LoginPasswordChanged(password));
      },
      obscureText: true,
      decoration: InputDecoration(labelText: 'password', filled: true, fillColor: Colors.white, border: const OutlineInputBorder(), errorText: displayError != null ? 'invalid password' : null),
    );
  }
}

class _LoginButton extends StatelessWidget {
  const _LoginButton();

  @override
  Widget build(BuildContext context) {
    final isInProgressOrSuccess = context.select((LoginBloc bloc) => bloc.state.status.isInProgressOrSuccess);

    if (isInProgressOrSuccess) {
      return const CircularProgressIndicator();
    }

    final isValid = context.select((LoginBloc bloc) => bloc.state.isValid);

    return OutlinedButton(
      key: const Key('loginForm_continue_raisedButton'),
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.black87,
        side: const BorderSide(color: Color(0xFFE0E0DB)),
        padding: const EdgeInsets.symmetric(vertical: 12),
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
      onPressed: () {
        if (isValid) {
          context.read<LoginBloc>().add(const LoginSubmitted());
        }
      },
      child: const Text('Login'),
    );
  }
}
