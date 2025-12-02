import 'package:flutter/cupertino.dart';
import 'package:wizi_learn/core/network/api_client.dart';
import 'package:wizi_learn/core/constants/app_constants.dart';
import 'package:wizi_learn/features/auth/data/models/achievement_model.dart';

class AchievementRepository {
  final ApiClient apiClient;

  AchievementRepository({required this.apiClient});

  Future<List<Achievement>> getUserAchievements() async {
    try {
      final response = await apiClient.get(AppConstants.userAchievements);
      // debugPrint('Réponse userAchievements : ${response.data}');

      if (response.data == null || response.data['achievements'] == null) {
        // debugPrint('⚠ Aucune donnée achievements trouvée');
        return [];
      }

      final List<dynamic> raw = response.data['achievements'];
      return raw.map((e) => Achievement.fromJson(e)).toList();
    } catch (e) {
      debugPrint(
        "❌ Erreur lors de la récupération des achievements utilisateur : $e",
      );
      return [];
    }
  }

  Future<List<Achievement>> getAllAchievements() async {
    try {
      final response = await apiClient.get(AppConstants.allAchievements);
      // debugPrint('Réponse allAchievements : ${response.data}');

      if (response.data == null || response.data['achievements'] == null) {
        // debugPrint('⚠ Aucune donnée achievements trouvée');
        return [];
      }

      final List<dynamic> raw = response.data['achievements'];
      return raw.map((e) => Achievement.fromJson(e)).toList();
    } catch (e) {
      debugPrint(
        "❌ Erreur lors de la récupération de tous les achievements : $e",
      );
      return [];
    }
  }

  // Trigger server-side achievement checks and return newly unlocked ones
  Future<List<Achievement>> checkAchievements({
    String? code,
    int? quizId,
  }) async {
    try {
      final payload = <String, dynamic>{};
      if (code != null) payload['code'] = code;
      if (quizId != null) payload['quiz_id'] = quizId;
      final response = await apiClient.post(
        '/stagiaire/achievements/check',
        data: payload,
      );
      final data = response.data;
      List<dynamic> raw = [];
      if (data is Map<String, dynamic>) {
        // Support both snake_case (backend) and camelCase (some endpoints)
        raw =
            (data['new_achievements'] as List?) ??
            (data['newAchievements'] as List?) ??
            [];
      }
      return raw
          .map((e) => Achievement.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('❌ Erreur checkAchievements: $e');
      return [];
    }
  }
}
