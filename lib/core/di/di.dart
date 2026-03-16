import 'package:connectify/features/member/data/member_client.dart';
import 'package:connectify/features/member/data/member_repository_impl.dart';
import 'package:connectify/features/onboarding/profile_basic/domain/profile_basic_repository.dart';
import 'package:connectify/features/sign/data/sign_client.dart';
import 'package:connectify/features/sign/data/sign_repository_impl.dart';
import 'package:connectify/features/sign/domain/sign_repository.dart';
import 'package:connectify/features/tab_controller/tab_1_explore/domain/member_repository.dart';
import 'package:connectify/features/tab_controller/tab_2_liked/data/liked_repository_impl.dart';
import 'package:connectify/features/tab_controller/tab_2_liked/domain/liked_repository.dart';
import 'package:connectify/features/tab_controller/tab_4_profile/domain/profile_repository.dart';
import 'package:get_it/get_it.dart';

import '../network/api_client.dart';
import '../network/token_storage.dart';

final getIt = GetIt.instance;

void setupDI() {
  if (getIt.isRegistered<TokenStorage>()) {
    return;
  }

  // Core
  getIt.registerLazySingleton<TokenStorage>(() => TokenStorage());
  getIt.registerLazySingleton<ApiClient>(() => ApiClient(tokenStorage: getIt<TokenStorage>()));

  // Member
  getIt.registerLazySingleton<MemberClient>(() => MemberClient(getIt<ApiClient>()));
  getIt.registerLazySingleton<LikedRepository>(() => LikedRepositoryImpl(getIt<ApiClient>()));
  getIt.registerLazySingleton<MemberRepositoryImpl>(() => MemberRepositoryImpl(getIt<MemberClient>()));
  getIt.registerLazySingleton<MemberRepository>(() => getIt<MemberRepositoryImpl>());
  getIt.registerLazySingleton<ProfileRepository>(() => getIt<MemberRepositoryImpl>());
  getIt.registerLazySingleton<ProfileBasicRepository>(() => getIt<MemberRepositoryImpl>());

  // Sign
  getIt.registerLazySingleton<SignClient>(() => SignClient(getIt<ApiClient>()));
  getIt.registerLazySingleton<SignRepository>(() => SignRepositoryImpl(signClient: getIt<SignClient>()));
}
