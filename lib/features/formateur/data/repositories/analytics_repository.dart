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

      final list = _parseList(response.data, key: 'quiz_stats');
      return list.map((s) => QuizSuccessStats.fromJson(s)).toList();
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

      final list = _parseList(response.data, key: 'completion_trends');
      return list.map((t) => CompletionTrend.fromJson(t)).toList();
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

      final list = _parseList(response.data, key: 'activity_by_day');
      return list.map((a) => ActivityByDay.fromJson(a)).toList();
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

      final list = _parseList(response.data, key: 'quiz_dropout');
      return list.map((d) => DropoutStats.fromJson(d)).toList();
    } catch (e) {
      debugPrint('❌ Erreur dropout stats: $e');
      rethrow;
    }
  }

  /// Get dashboard summary
  Future<DashboardSummary> getDashboardSummary({int period = 30, String? formationId}) async {
    try {
      final response = await apiClient.get(
        '/formateur/dashboard/stats',
        queryParameters: {
          'period': period,
          if (formationId != null) 'formation_id': formationId,
        },
      );

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
      return _parseList(response.data);
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
      if (response.data is Map) return response.data;
      return {'performance': [], 'rankings': {'most_quizzes': [], 'most_active': []}};
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
      final list = _parseList(response.data, key: 'inactive_stagiaires');
      return list.map((e) => InactiveStagiaire.fromJson(e)).toList();
    } catch (e) {
      debugPrint('❌ Erreur inactifs: $e');
      return [];
    }
  }

  /// Get online stagiaires
  Future<List<OnlineStagiaire>> getOnlineStagiaires() async {
    try {
      final response = await apiClient.get('/formateur/stagiaires/online');
      final list = _parseList(response.data, key: 'stagiaires');
      return list.map((e) => OnlineStagiaire.fromJson(e)).toList();
    } catch (e) {
      debugPrint('❌ Erreur en ligne: $e');
      return [];
    }
  }

  /// Get formations with videos for analytics
  Future<List<FormationVideos>> getFormationsVideos() async {
    try {
      final response = await apiClient.get('/formateur/formations-videos');
      final list = _parseList(response.data);
      return list.map((e) => FormationVideos.fromJson(e)).toList();
    } catch (e) {
      debugPrint('❌ Erreur formations-videos: $e');
      return [];
    }
  }

  /// Get video statistics
  Future<VideoStats?> getVideoStats(int videoId) async {
    try {
      final response = await apiClient.get('/formateur/video/$videoId/stats');
      final data = response.data is Map ? (response.data['data'] ?? response.data) : response.data;
      if (data is! Map<String, dynamic>) return null;
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
      final list = _parseList(response.data);
      return list.map((e) => DemandeSuivi.fromJson(e)).toList();
    } catch (e) {
      debugPrint('❌ Erreur suivi demandes: $e');
      return [];
    }
  }

  /// Get sponsorship tracking
  Future<List<ParrainageSuivi>> getParrainageSuivi() async {
    try {
      final response = await apiClient.get('/formateur/suivi/parrainage');
      final list = _parseList(response.data);
      return list.map((e) => ParrainageSuivi.fromJson(e)).toList();
    } catch (e) {
      debugPrint('❌ Erreur suivi parrainage: $e');
      return [];
    }
  }

  /// Helper methods
  List<dynamic> _parseList(dynamic data, {String? key}) {
    if (data == null) return [];
    if (data is List) return data;
    if (data is Map) {
      if (key != null && data.containsKey(key) && data[key] is List) {
        return data[key];
      }
      if (data.containsKey('data') && data['data'] is List) {
        return data['data'];
      }
    }
    return [];
  }
}
}

