import 'package:connectify/features/sign/domain/sign_repository.dart';
import 'package:connectify/shared/authentication/bloc/authentication_bloc.dart';
import 'package:connectify/shared/authentication/repositories/authentication_repository.dart';
import 'package:connectify/core/di/di.dart';
import 'package:connectify/core/network/token_storage.dart';
import 'package:connectify/features/tab_controller/controller/view/main_tab_page.dart';
import 'package:connectify/features/splash/splash_page.dart';
import 'package:connectify/features/sign/presentation/view/login_page.dart';
import 'package:connectify/features/tab_controller/tab_4_profile/domain/profile_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    setupDI();

    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider(
          create: (_) => AuthenticationRepository(tokenStorage: getIt<TokenStorage>()),
          dispose: (repository) => repository.dispose(),
        ),
        RepositoryProvider<SignRepository>(create: (_) => getIt<SignRepository>()),
        RepositoryProvider<ProfileRepository>(create: (_) => getIt<ProfileRepository>()),
      ],
      child: BlocProvider(
        lazy: false,
        create: (context) =>
            AuthenticationBloc(authenticationRepository: context.read<AuthenticationRepository>(), userRepository: context.read<ProfileRepository>())..add(AuthenticationSubscriptionRequested()),
        child: const AppView(),
      ),
    );
  }
}

class AppView extends StatefulWidget {
  const AppView({super.key});

  @override
  State<AppView> createState() => _AppViewState();
}

class _AppViewState extends State<AppView> {
  final _navigatorKey = GlobalKey<NavigatorState>();

  NavigatorState get _navigator => _navigatorKey.currentState!;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
      builder: (context, child) {
        return BlocListener<AuthenticationBloc, AuthenticationState>(
          listener: (context, state) {
            switch (state.status) {
              case AuthStatus.success:
                _navigator.pushAndRemoveUntil<void>(MainTabPage.route(), (route) => false);
              case AuthStatus.unauthorized:
                _navigator.pushAndRemoveUntil<void>(LoginPage.route(), (route) => false);
              default:
                break;
            }
          },
          child: child,
        );
      },
      onGenerateRoute: (_) => SplashPage.route(),
    );
  }
}
