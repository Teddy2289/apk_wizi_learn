import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:wizi_learn/core/exceptions/api_exception.dart';
import 'package:wizi_learn/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:wizi_learn/features/auth/data/repositories/auth_repository_contract.dart';
import 'package:wizi_learn/features/auth/domain/user_entity.dart';
import 'package:wizi_learn/core/network/api_client.dart';
import '../../../../core/exceptions/auth_exception.dart';
import '../mappers/user_mapper.dart';

class AuthRepository implements AuthRepositoryContract {
  final AuthRemoteDataSource remoteDataSource;
  final FlutterSecureStorage storage;

  AuthRepository({required this.remoteDataSource, required this.storage});

  /// Getter public pour accéder à l'ApiClient utilisé pour les requêtes authentifiées
  ApiClient? get apiClient {
    if (remoteDataSource is AuthRemoteDataSourceImpl) {
      return (remoteDataSource as AuthRemoteDataSourceImpl).apiClient;
    }
    return null;
  }

  @override
  Future<UserEntity> login(String email, String password) async {
    try {
      final userModel = await remoteDataSource.login(email, password);
      return UserMapper.toEntity(userModel);
    } on ApiException catch (e) {
      throw AuthException(e.message);
    }
  }

  @override
  Future<void> logout() async {
    try {
      await remoteDataSource.logout();
    } on ApiException catch (e) {
      if (e.statusCode == 401) {
        // Token might be expired, but we still want to proceed with local logout
        return;
      }
      throw AuthException(e.message);
    } finally {
      // Always clear local storage even if logout fails
      await storage.delete(key: 'auth_token');
      await storage.delete(key: 'auth_user');
    }
  }

  @override
  Future<UserEntity> getUser() async {
    try {
      final userModel = await remoteDataSource.getUser();
      return UserMapper.toEntity(userModel);
    } on ApiException catch (e) {
      throw AuthException(e.message);
    }
  }

  @override
  Future<UserEntity> getMe() async {
    try {
      final userModel = await remoteDataSource.getMe();
      return UserMapper.toEntity(userModel);
    } on ApiException catch (e) {
      throw AuthException(e.message);
    }
  }

  @override
  Future<bool> isLoggedIn() async {
    final token = await storage.read(key: 'auth_token');
    return token != null;
  }
}
