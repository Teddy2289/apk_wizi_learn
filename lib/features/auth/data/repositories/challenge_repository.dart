import 'package:flutter/material.dart';
import 'package:wizi_learn/core/network/api_client.dart';
import 'package:wizi_learn/core/constants/app_constants.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';

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
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  static const _queueKey = 'challenge_submission_queue';

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

  Future<bool> submitEntry({
    required int challengeId,
    required int points,
    required int quizzesCompleted,
    required int durationSeconds,
  }) async {
    try {
      final payload = {
        'challenge_id': challengeId,
        'points': points,
        'quizzes_completed': quizzesCompleted,
        'duration_seconds': durationSeconds,
      };
      final res = await apiClient.post(
        AppConstants.challengeEntries,
        data: payload,
      );
      return res.statusCode != null &&
          res.statusCode! >= 200 &&
          res.statusCode! < 300;
    } catch (e) {
      debugPrint('Failed to submit challenge entry: $e');
      return false;
    }
  }

  /// Submit entry with local queueing: if network fails the payload is stored and
  /// retried on next call to flushQueue() or on app start.
  Future<bool> submitEntryWithQueue({
    required int challengeId,
    required int points,
    required int quizzesCompleted,
    required int durationSeconds,
  }) async {
    final payload = {
      'challenge_id': challengeId,
      'points': points,
      'quizzes_completed': quizzesCompleted,
      'duration_seconds': durationSeconds,
      'ts': DateTime.now().toIso8601String(),
    };

    final ok = await submitEntry(
      challengeId: challengeId,
      points: points,
      quizzesCompleted: quizzesCompleted,
      durationSeconds: durationSeconds,
    );

    if (ok) return true;

    // Save to local queue
    try {
      final raw = await _storage.read(key: _queueKey);
      final list =
          raw == null
              ? []
              : List<Map<String, dynamic>>.from(jsonDecode(raw) as List);
      list.add(payload);
      await _storage.write(key: _queueKey, value: jsonEncode(list));
    } catch (e) {
      debugPrint('Failed to persist challenge payload: $e');
    }

    return false;
  }

  /// Attempt to flush the stored queue. Stops on first failure to avoid busy loops.
  Future<void> flushQueue() async {
    try {
      final raw = await _storage.read(key: _queueKey);
      if (raw == null) return;
      final list = List<Map<String, dynamic>>.from(jsonDecode(raw) as List);
      final remaining = <Map<String, dynamic>>[];
      for (final item in list) {
        try {
          final ok = await submitEntry(
            challengeId: item['challenge_id'] as int,
            points: item['points'] as int,
            quizzesCompleted: item['quizzes_completed'] as int,
            durationSeconds: item['duration_seconds'] as int,
          );
          if (!ok) {
            remaining.add(item);
            break; // stop on first failure
          }
        } catch (e) {
          remaining.add(item);
          break;
        }
      }

      if (remaining.isEmpty) {
        await _storage.delete(key: _queueKey);
      } else {
        await _storage.write(key: _queueKey, value: jsonEncode(remaining));
      }
    } catch (e) {
      debugPrint('Failed to flush challenge queue: $e');
    }
  }
}
