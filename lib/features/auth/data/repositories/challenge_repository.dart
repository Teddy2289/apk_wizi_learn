import 'package:flutter/material.dart';
import 'package:wizi_learn/core/network/api_client.dart';
import 'package:wizi_learn/core/constants/app_constants.dart';

class ChallengeConfig {
  final int id;
  final String mode; // 'fastest' or 'most_points'
  final int formationId;
  final DateTime? start;
  final DateTime? end;

  ChallengeConfig({
    required this.id,
    required this.mode,
    required this.formationId,
    this.start,
    this.end,
  });

  factory ChallengeConfig.fromJson(Map<String, dynamic> json) =>
      ChallengeConfig(
        id: json['id'] as int,
        mode: json['mode'] as String,
        formationId: json['formation_id'] as int,
        start:
            json['start_at'] != null
                ? DateTime.tryParse(json['start_at'])
                : null,
        end: json['end_at'] != null ? DateTime.tryParse(json['end_at']) : null,
      );
}

class ChallengeEntry {
  final String userId;
  final String name;
  final int points;
  final int quizzesCompleted;
  final Duration duration; // used for 'fastest'

  ChallengeEntry({
    required this.userId,
    required this.name,
    required this.points,
    required this.quizzesCompleted,
    required this.duration,
  });

  factory ChallengeEntry.fromJson(Map<String, dynamic> json) => ChallengeEntry(
    userId: (json['user_id'] ?? '').toString(),
    name: (json['name'] ?? '').toString(),
    points: (json['points'] ?? 0) as int,
    quizzesCompleted: (json['quizzes_completed'] ?? 0) as int,
    duration: Duration(seconds: (json['duration_seconds'] ?? 0) as int),
  );
}

class ChallengeRepository {
  final ApiClient apiClient;

  ChallengeRepository({required this.apiClient});

  Future<ChallengeConfig?> fetchConfig() async {
    try {
      final res = await apiClient.get(AppConstants.challengeConfig);
      if (res.data == null) return null;
      return ChallengeConfig.fromJson(Map<String, dynamic>.from(res.data));
    } catch (e) {
      debugPrint('Challenge config fetch failed: $e');
      return null;
    }
  }

  Future<List<ChallengeEntry>> fetchLeaderboard({int? formationId}) async {
    try {
      final url =
          formationId != null
              ? '${AppConstants.challengeLeaderboard}?formation=$formationId'
              : AppConstants.challengeLeaderboard;
      final res = await apiClient.get(url);
      final list = res.data as List?;
      if (list == null) return [];
      return list
          .map((e) => ChallengeEntry.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (e) {
      debugPrint('Challenge leaderboard fetch failed: $e');
      return [];
    }
  }
}
