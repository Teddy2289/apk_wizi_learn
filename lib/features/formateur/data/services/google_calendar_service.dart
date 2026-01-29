import 'package:flutter/foundation.dart';
import 'package:wizi_learn/core/network/api_client.dart';
import 'package:dio/dio.dart';

class GoogleCalendarService {
  final ApiClient apiClient;

  GoogleCalendarService({required this.apiClient});

  /// Sync Google Calendar data by calling the centralized backend endpoint
  Future<void> syncWithBackend() async {
    try {
      // Direct call to the new centralized sync endpoint
      // Only Admins should be authorized to call this on the backend
      await apiClient.post('/agendas/sync');
      debugPrint('✅ Backend sync triggered successfully');
    } catch (e) {
      debugPrint('❌ Backend sync error: $e');
      rethrow;
    }
  }

  // Google sign-in methods removed as sync is now centralized in backend
  bool get isSignedIn => false;
  Future<void> signOut() async {}
}
