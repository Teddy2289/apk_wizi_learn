import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'token_interceptor.dart';

/// Singleton Dio client with token refresh interceptor
class DioClient {
  static Dio? _dio;
  static SharedPreferences? _prefs;

  /// Get or create Dio instance
  static Future<Dio> getInstance() async {
    if (_dio != null) return _dio!;

    // Get SharedPreferences instance
    _prefs ??= await SharedPreferences.getInstance();
    
    // Create Dio with base configuration
    _dio = Dio(
      BaseOptions(
        baseUrl: 'http://127.0.0.1:8000/api', // TODO: Use environment variable
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Add token interceptor
    _dio!.interceptors.add(TokenInterceptor(_dio!, _prefs!));

    // Add logging interceptor (optional, for development)
    _dio!.interceptors.add(
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        error: true,
      ),
    );

    return _dio!;
  }

  /// Reset Dio instance (useful for logout)
  static void reset() {
    _dio = null;
  }
}
