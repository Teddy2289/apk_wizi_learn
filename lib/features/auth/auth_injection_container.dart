import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wizi_learn/features/auth/data/repositories/auth_repository_contract.dart';
import '../../core/network/api_client.dart';
import 'data/datasources/auth_remote_data_source.dart';
import 'data/repositories/auth_repository.dart';
import 'presentation/bloc/auth_bloc.dart';
import 'services/quiz_resume_service.dart';

final sl = GetIt.instance;

Future<void> initAuthDependencies() async {
  // External
  sl.registerSingleton<Dio>(Dio());
  sl.registerSingleton<FlutterSecureStorage>(const FlutterSecureStorage());
  sl.registerSingletonAsync<SharedPreferences>(
        () => SharedPreferences.getInstance(),
  );

  // Attendre que SharedPreferences soit prêt
  await sl.isReady<SharedPreferences>();


  // Core
  sl.registerLazySingleton<ApiClient>(
        () => ApiClient(dio: sl(), storage: sl()),
  );

  // Data sources
  sl.registerLazySingleton<AuthRemoteDataSource>(
        () => AuthRemoteDataSourceImpl(apiClient: sl(), storage: sl()),
  );

  // Repositories - Enregistrez à la fois l'interface et l'implémentation
  sl.registerLazySingleton<AuthRepository>(
        () => AuthRepository(remoteDataSource: sl(), storage: sl()),
  );

  // Enregistrez l'interface en pointant vers l'implémentation
  sl.registerLazySingleton<AuthRepositoryContract>(
        () => sl<AuthRepository>(),
  );

  // Services
  sl.registerLazySingleton<QuizResumeService>(
        () => QuizResumeService(sl()),
  );

  // Bloc
  sl.registerFactory(
        () => AuthBloc(authRepository: sl<AuthRepositoryContract>()),
  );
}