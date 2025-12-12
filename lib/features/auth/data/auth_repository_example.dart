import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:wizi_learn/core/network/dio_client.dart';

/// Example Auth Repository with refresh token support
class AuthRepository {
  final SharedPreferences _prefs;

  AuthRepository(this._prefs);

  /// Login user and save tokens
  Future<void> login(String email, String password) async {
    try {
      final dio = await DioClient.getInstance();
      
      final response = await dio.post('/login', data: {
        'email': email,
        'password': password,
      });

      // Extract tokens and user data
      final accessToken = response.data['access_token'] as String;
      final refreshToken = response.data['refresh_token'] as String;
      final userData = response.data['user'];

      // Save to SharedPreferences
      await _prefs.setString('access_token', accessToken);
      await _prefs.setString('refresh_token', refreshToken);
      await _prefs.setString('user', jsonEncode(userData));

      print('✅ Login successful');
    } catch (e) {
      print('❌ Login failed: $e');
      throw Exception('Login failed: ${e.toString()}');
    }
  }

  /// Logout user and revoke tokens
  Future<void> logout() async {
    try {
      final refreshToken = _prefs.getString('refresh_token');
      
      if (refreshToken != null) {
        final dio = await DioClient.getInstance();
        
        // Send logout request with refresh token
        await dio.post('/logout', data: {
          'refresh_token': refreshToken,
        });
      }

      // Clear all tokens and user data
      await _prefs.remove('access_token');
      await _prefs.remove('refresh_token');
      await _prefs.remove('user');

      // Reset Dio instance
      DioClient.reset();

      print('✅ Logout successful');
    } catch (e) {
      print('⚠️ Logout error (tokens cleared anyway): $e');
      
      // Always clear tokens even if request fails
      await _prefs.remove('access_token');
      await _prefs.remove('refresh_token');
      await _prefs.remove('user');
    }
  }

  /// Check if user is logged in
  bool isLoggedIn() {
    final token = _prefs.getString('access_token');
    return token != null && token.isNotEmpty;
  }

  /// Get current user data
  Map<String, dynamic>? getCurrentUser() {
    final userJson = _prefs.getString('user');
    if (userJson == null) return null;
    
    try {
      return jsonDecode(userJson) as Map<String, dynamic>;
    } catch (e) {
      print('Error parsing user data: $e');
      return null;
    }
  }

  /// Get access token
  String? getAccessToken() {
    return _prefs.getString('access_token');
  }

  /// Get refresh token
  String? getRefreshToken() {
    return _prefs.getString('refresh_token');
  }
}
