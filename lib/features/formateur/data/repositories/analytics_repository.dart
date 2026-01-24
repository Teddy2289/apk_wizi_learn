import 'package:wizi_learn/core/network/api_client.dart';
import 'package:wizi_learn/features/formateur/data/models/analytics_model.dart';
import 'package:flutter/foundation.dart';

class AnalyticsRepository {
  final ApiClient apiClient;

  AnalyticsRepository({required this.apiClient});

  /// Get quiz success rate stats
  Future<List<QuizSuccessStats>> getQuizSuccessRate({int period = 30, String? formationId}) async {
    try {
      final response = await apiClient.get(
        '/formateur/analytics/quiz-success-rate',
        queryParameters: {
          'period': period,
          if (formationId != null) 'formation_id': formationId,
        },
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
  Future<List<ActivityByDay>> getActivityByDay({int period = 30, String? formationId}) async {
    try {
      final response = await apiClient.get(
        '/formateur/analytics/activity-heatmap',
        queryParameters: {
          'period': period,
          if (formationId != null) 'formation_id': formationId,
        },
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
  Future<List<DropoutStats>> getDropoutStats({String? formationId}) async {
    try {
      final response = await apiClient.get(
        '/formateur/analytics/dropout-rate',
        queryParameters: formationId != null ? {'formation_id': formationId} : null,
      );

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
  Future<DashboardSummary> getDashboardSummary({int period = 30, String? formationId}) async {
    try {
      // Changed to match React's dashboard endpoint
      final response = await apiClient.get(
        '/formateur/dashboard/stats',
        queryParameters: {
          'period': period,
          if (formationId != null) 'formation_id': formationId,
        },
      );

      // Note: Model parsing might need adjustment depending on backend response format
      return DashboardSummary.fromJson(response.data);
    } catch (e) {
      debugPrint('❌ Erreur dashboard summary: $e');
      rethrow;
    }
  }

  /// Get formations performance (New for React parity)
  Future<List<dynamic>> getFormationsPerformance() async {
    try {
      final response = await apiClient.get('/formateur/analytics/formations/performance');
      return response.data as List<dynamic>;
    } catch (e) {
      debugPrint('❌ Erreur formations performance: $e');
      return [];
    }
  }

  /// Get students comparison (New for React parity)
  Future<Map<String, dynamic>> getStudentsComparison({String? formationId}) async {
    try {
      final response = await apiClient.get(
        '/formateur/analytics/performance',
        queryParameters: formationId != null ? {'formation_id': formationId} : null,
      );
      return response.data as Map<String, dynamic>;
    } catch (e) {
      debugPrint('❌ Erreur comparaison stagiaires: $e');
      return {'performance': [], 'rankings': {'most_quizzes': [], 'most_active': []}};
    }
  }

  /// Get inactive stagiaires
  Future<List<InactiveStagiaire>> getInactiveStagiaires({int days = 7, String scope = 'mine'}) async {
    try {
      final response = await apiClient.get(
        '/formateur/stagiaires/inactive',
        queryParameters: {'days': days, 'scope': scope},
      );
      final data = response.data;
      final list = (data is Map ? data['inactive_stagiaires'] : data) as List?;
      return list?.map((e) => InactiveStagiaire.fromJson(e)).toList() ?? [];
    } catch (e) {
      debugPrint('❌ Erreur inactifs: $e');
      return [];
    }
  }

  /// Get online stagiaires
  Future<List<OnlineStagiaire>> getOnlineStagiaires() async {
    try {
      final response = await apiClient.get('/formateur/stagiaires/online');
      final data = response.data;
      final list = (data is Map ? data['stagiaires'] : data) as List?;
      return list?.map((e) => OnlineStagiaire.fromJson(e)).toList() ?? [];
    } catch (e) {
      debugPrint('❌ Erreur en ligne: $e');
      return [];
    }
  }

  /// Get formations with videos for analytics
  Future<List<FormationVideos>> getFormationsVideos() async {
    try {
      final response = await apiClient.get('/formateur/formations-videos');
      final list = (response.data['data'] ?? response.data) as List?;
      return list?.map((e) => FormationVideos.fromJson(e)).toList() ?? [];
    } catch (e) {
      debugPrint('❌ Erreur formations-videos: $e');
      return [];
    }
  }

  /// Get video statistics
  Future<VideoStats?> getVideoStats(int videoId) async {
    try {
      final response = await apiClient.get('/formateur/video/$videoId/stats');
      final data = response.data['data'] ?? response.data;
      return VideoStats.fromJson(data);
    } catch (e) {
      debugPrint('❌ Erreur stats vidéo: $e');
      return null;
    }
  }

  /// Get training requests tracking
  Future<List<DemandeSuivi>> getDemandesSuivi() async {
    try {
      final response = await apiClient.get('/formateur/suivi/demandes');
      final data = response.data['data'] ?? response.data;
      final list = data as List?;
      return list?.map((e) => DemandeSuivi.fromJson(e)).toList() ?? [];
    } catch (e) {
      debugPrint('❌ Erreur suivi demandes: $e');
      return [];
    }
  }

  /// Get sponsorship tracking
  Future<List<ParrainageSuivi>> getParrainageSuivi() async {
    try {
      final response = await apiClient.get('/formateur/suivi/parrainage');
      final data = response.data['data'] ?? response.data;
      final list = data as List?;
      return list?.map((e) => ParrainageSuivi.fromJson(e)).toList() ?? [];
    } catch (e) {
      debugPrint('❌ Erreur suivi parrainage: $e');
      return [];
    }
  }
}

