import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:wizi_learn/core/exceptions/api_exception.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/network/api_client.dart';
import '../models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<UserModel> login(String email, String password);
  Future<void> logout();
  Future<UserModel> getUser();
  Future<UserModel> getMe();

  Future<void> sendResetPasswordLink(
    String email,
    String resetUrl,
      {bool isMobile = false}
  );
  Future<void> resetPassword({
    required String email,
    required String token,
    required String password,
    required String passwordConfirmation,
  });
  Future<Map<String, dynamic>> getStagiaireDetails(int stagiaireId);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final ApiClient apiClient;
  final FlutterSecureStorage storage;

  AuthRemoteDataSourceImpl({required this.apiClient, required this.storage});

  @override
  Future<UserModel> login(String email, String password) async {
    try {
      final response = await apiClient.post(
        AppConstants.loginEndpoint,
        data: {'email': email, 'password': password},
      );

      if (response.statusCode == null || response.statusCode! < 200 || response.statusCode! >= 300) {
        throw ApiException(
          message: 'Échec de la connexion',
          statusCode: response.statusCode,
        );
      }

      final responseData = response.data as Map<String, dynamic>;

      // Debug: log raw login response for troubleshooting
      debugPrint('login response: $responseData');

      // Validation du token (supporte plusieurs clés possibles)
      final token = (responseData['token'] ?? responseData['access_token'] ?? (responseData['data'] is Map ? responseData['data']['token'] : null)) as String?;
      debugPrint('extracted token: $token');
      if (token == null || token.isEmpty) {
        throw ApiException(message: 'Veuillez vérifier votre connexion Internet ou vos identifiants (email/mot de passe)');
      }

      await storage.write(key: AppConstants.tokenKey, value: token);

      // Validation des données utilisateur
      if (responseData['user'] == null) {
        throw ApiException(message: 'Données utilisateur manquantes');
      }

      return UserModel.fromJson(responseData);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    } catch (e) {
      throw ApiException(
        message: 'Erreur lors de la connexion: ${e.toString()}',
      );
    }
  }

  @override
  Future<void> logout() async {
    try {
      await apiClient.post(AppConstants.logoutEndpoint);
      await storage.delete(key: AppConstants.tokenKey);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  @override
  Future<UserModel> getUser() async {
    try {
      final response = await apiClient.get(AppConstants.userEndpoint);
      return UserModel.fromJson(response.data);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  @override
  Future<UserModel> getMe() async {
    try {
      final response = await apiClient.get(AppConstants.meEndpoint);
      // debugPrint('Réponse getMe : ${response.data}');

      return UserModel.fromJson(response.data);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  @override
  Future<void> sendResetPasswordLink(String email, String resetUrl,
      {bool isMobile = false}) async {
    try {
      final response = await apiClient.post(
        '/forgot-password',
        data: {'email': email, 'reset_url': resetUrl, 'is_mobile': isMobile},
      );

      if (response.statusCode != 200) {
        throw ApiException(
          message: response.data['error'] ?? 'Failed to send reset link',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
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
      final response = await apiClient.post(
        '/reset-password',
        data: {
          'email': email,
          'token': token,
          'password': password,
          'password_confirmation': passwordConfirmation,
        },
      );

      if (response.statusCode != 200) {
        throw ApiException(
          message: response.data['error'] ?? 'Failed to reset password',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  @override
  Future<Map<String, dynamic>> getStagiaireDetails(int stagiaireId) async {
    try {
      final response = await apiClient.get('/stagiaires/$stagiaireId/details');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}
