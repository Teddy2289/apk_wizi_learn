import 'package:wizi_learn/core/network/api_client.dart';
import 'package:wizi_learn/features/formateur/data/models/analytics_model.dart';
import 'package:flutter/foundation.dart';

class AnalyticsRepository {
  final ApiClient apiClient;

  AnalyticsRepository({required this.apiClient});

  /// Get quiz success rate stats
  Future<List<QuizSuccessStats>> getQuizSuccessRate({int period = 30}) async {
    try {
      final response = await apiClient.get(
        '/formateur/analytics/quiz-success-rate',
        queryParameters: {'period': period},
      );

      final stats = (response.data['quiz_stats'] as List?)
              ?.map((s) => QuizSuccessStats.fromJson(s))
              .toList() ??
          [];

      return stats;
    } catch (e) {
      debugPrint('❌ Erreur stats taux de réussite: $e');
      rethrow;
    }
  }

  /// Get completion time trends
  Future<List<CompletionTrend>> getCompletionTimeTrends({int period = 30}) async {
    try {
      final response = await apiClient.get(
        '/formateur/analytics/completion-time',
        queryParameters: {'period': period},
      );

      final trends = (response.data['completion_trends'] as List?)
              ?.map((t) => CompletionTrend.fromJson(t))
              .toList() ??
          [];

      return trends;
    } catch (e) {
      debugPrint('❌ Erreur trends temps: $e');
      rethrow;
    }
  }

  /// Get activity heatmap by day
  Future<List<ActivityByDay>> getActivityByDay({int period = 30}) async {
    try {
      final response = await apiClient.get(
        '/formateur/analytics/activity-heatmap',
        queryParameters: {'period': period},
      );

      final activities = (response.data['activity_by_day'] as List?)
              ?.map((a) => ActivityByDay.fromJson(a))
              .toList() ??
          [];

      return activities;
    } catch (e) {
      debugPrint('❌ Erreur heatmap: $e');
      rethrow;
    }
  }

  /// Get dropout rates
  Future<List<DropoutStats>> getDropoutStats() async {
    try {
      final response = await apiClient.get('/formateur/analytics/dropout-rate');

      final stats = (response.data['quiz_dropout'] as List?)
              ?.map((d) => DropoutStats.fromJson(d))
              .toList() ??
          [];

      return stats;
    } catch (e) {
      debugPrint('❌ Erreur dropout stats: $e');
      rethrow;
    }
  }

  /// Get dashboard summary
  Future<DashboardSummary> getDashboardSummary({int period = 30}) async {
    try {
      final response = await apiClient.get(
        '/formateur/analytics/dashboard',
        queryParameters: {'period': period},
      );

      return DashboardSummary.fromJson(response.data['summary'] ?? {});
    } catch (e) {
      debugPrint('❌ Erreur dashboard summary: $e');
      rethrow;
    }
  }
}
