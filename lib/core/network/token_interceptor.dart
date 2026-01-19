import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';

/// Interceptor to handle JWT token refresh automatically
class TokenInterceptor extends Interceptor {
  final Dio dio;
  final SharedPreferences prefs;
  
  bool _isRefreshing = false;
  final List<Completer<void>> _refreshQueue = [];

  TokenInterceptor(this.dio, this.prefs);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = prefs.getString('access_token');
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // Check if token expired
    if (err.response?.statusCode == 401 &&
        err.response?.data is Map &&
        err.response?.data['error'] == 'token_expired') {
      
      // If already refreshing, queue this request
      if (_isRefreshing) {
        final completer = Completer<void>();
        _refreshQueue.add(completer);
        
        try {
          await completer.future;
          final response = await dio.fetch(err.requestOptions);
          handler.resolve(response);
          return;
        } catch (e) {
          handler.reject(err);
          return;
        }
      }

      _isRefreshing = true;

      try {
        final refreshToken = prefs.getString('refresh_token');
        if (refreshToken == null) {
          throw Exception('No refresh token available');
        }

        debugPrint('🔄 Token expired, refreshing...');

        // Call refresh endpoint
        final response = await dio.post(
          '/refresh',
          data: {'refresh_token': refreshToken},
        );

        final newToken = response.data['access_token'];

        // Save new token
        await prefs.setString('access_token', newToken);
        
        debugPrint('✅ New token received and saved');

        // Retry original request with new token
        err.requestOptions.headers['Authorization'] = 'Bearer $newToken';
        final retryResponse = await dio.fetch(err.requestOptions);

        // Process all queued requests
        _processQueue();

        handler.resolve(retryResponse);
      } catch (refreshError) {
        debugPrint('❌ Refresh failed: $refreshError');
        
        // Refresh failed, logout user
        await _logout();
        _processQueueWithError(refreshError);
        handler.reject(err);
      } finally {
        _isRefreshing = false;
      }
    } else {
      // Not a token expiration error
      handler.next(err);
    }
  }

  /// Process all queued requests (called after successful refresh)
  void _processQueue() {
    for (final completer in _refreshQueue) {
      completer.complete();
    }
    _refreshQueue.clear();
  }

  /// Process queue with error (called after failed refresh)
  void _processQueueWithError(dynamic error) {
    for (final completer in _refreshQueue) {
      completer.completeError(error);
    }
    _refreshQueue.clear();
  }

  /// Logout user and clear tokens
  Future<void> _logout() async {
    await prefs.remove('access_token');
    await prefs.remove('refresh_token');
    await prefs.remove('user');
    
    // TODO: Navigate to login screen
    // navigatorKey.currentState?.pushReplacementNamed('/login');
  }
}
