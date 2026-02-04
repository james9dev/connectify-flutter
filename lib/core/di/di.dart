import 'package:connectify/features/member/member_client.dart';
import 'package:connectify/features/member/member_repository_impl.dart';
import 'package:connectify/features/tab_controller/tab_1_explore/domain/member_repository.dart';
import 'package:connectify/features/tab_controller/tab_4_profile/domain/profile_repository.dart';
import 'package:get_it/get_it.dart';

import '../network/api_client.dart';
import '../network/token_storage.dart';

final getIt = GetIt.instance;

void setupDI() {
  // Core
  getIt.registerLazySingleton<TokenStorage>(() => TokenStorage());
  getIt.registerLazySingleton<ApiClient>(() => ApiClient(tokenStorage: getIt<TokenStorage>()));

  // Member
  getIt.registerLazySingleton<MemberClient>(() => MemberClient(getIt<ApiClient>()));
  getIt.registerLazySingleton<MemberRepository>(() => MemberRepositoryImpl(getIt<MemberClient>()));
  getIt.registerLazySingleton<ProfileRepository>(() => MemberRepositoryImpl(getIt<MemberClient>()));
}
