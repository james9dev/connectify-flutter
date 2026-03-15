import 'package:connectify/features/sign/domain/sign_repository.dart';
import 'package:connectify/features/sign/presentation/bloc/login_bloc.dart';
import 'package:connectify/features/sign/presentation/view/login_form.dart';
import 'package:connectify/shared/authentication/repositories/authentication_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  static Route<void> route() {
    return MaterialPageRoute<void>(builder: (_) => const LoginPage());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFC629),
        foregroundColor: Colors.black,
        elevation: 0,
        title: const Text('로그인', style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: BlocProvider(
            create: (context) => LoginBloc(authenticationRepository: context.read<AuthenticationRepository>(), signRepository: context.read<SignRepository>()),
            child: const LoginForm(),
          ),
        ),
      ),
    );
  }
}
