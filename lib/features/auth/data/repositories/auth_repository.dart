import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
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
      try {
        // Clear all keys stored in flutter_secure_storage
        await storage.deleteAll();
      } catch (e) {
        // If deleteAll is not available or fails, attempt to delete known keys
        try {
          await storage.delete(key: 'auth_token');
          await storage.delete(key: 'auth_user');
        } catch (_) {}
      }

      // Also clear SharedPreferences (app-level cache/preferences)
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.clear();
      } catch (_) {}
      // Clear image cache managed by flutter_cache_manager (if used)
      try {
        await DefaultCacheManager().emptyCache();
      } catch (e) {
        // ignore cache clearing errors
      }
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

  @override
  Future<void> sendResetPasswordLink(
    String email,
    String resetUrl, {
    bool isMobile = false,
  }) async {
    try {
      await remoteDataSource.sendResetPasswordLink(
        email,
        resetUrl,
        isMobile: isMobile,
      );
    } on ApiException catch (e) {
      throw AuthException(
        e.message.contains('Email non trouvé')
            ? 'Aucun compte associé à cet email'
            : 'Échec de l\'envoi du lien de réinitialisation',
      );
    }
  }

  @override
  Future<void> resetPassword({
    required String email,
    required String token,
    required String password,
    required String passwordConfirmation,
  }) async {
    try {
      await remoteDataSource.resetPassword(
        email: email,
        token: token,
        password: password,
        passwordConfirmation: passwordConfirmation,
      );
    } on ApiException catch (e) {
      final errorMessage = e.message.toLowerCase();

      if (errorMessage.contains('token invalide') ||
          errorMessage.contains('token expiré')) {
        throw AuthException(
          'Le lien de réinitialisation est invalide ou a expiré',
        );
      } else {
        throw AuthException('Échec de la réinitialisation du mot de passe');
      }
    }
  }

  /// Récupère les détails d'un stagiaire
  Future<Map<String, dynamic>> getStagiaireDetails(int stagiaireId) async {
    try {
      final response = await remoteDataSource.getStagiaireDetails(stagiaireId);
      return response;
    } on ApiException catch (e) {
      throw AuthException('Erreur lors de la récupération des détails: ${e.message}');
    }
  }
}
