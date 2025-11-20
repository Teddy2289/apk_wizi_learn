import 'dart:async';
import 'package:flutter/foundation.dart';

/// Quiz list item with participation status
class QuizWithParticipation {
  final String id;
  final String titre;
  final String? description;
  final int? duree;
  final String niveau;
  final String status;
  final int? nbPointsTotal;
  final Map<String, dynamic>? formation;
  final List<dynamic> questions;
  final QuizParticipation? userParticipation;

  QuizWithParticipation({
    required this.id,
    required this.titre,
    this.description,
    this.duree,
    required this.niveau,
    required this.status,
    this.nbPointsTotal,
    this.formation,
    required this.questions,
    this.userParticipation,
  });

  factory QuizWithParticipation.fromJson(Map<String, dynamic> json) {
    final participationData = json['userParticipation'];
    return QuizWithParticipation(
      id: json['id'].toString(),
      titre: json['titre'] ?? '',
      description: json['description'],
      duree: json['duree'],
      niveau: json['niveau'] ?? 'débutant',
      status: json['status'] ?? 'actif',
      nbPointsTotal: json['nb_points_total'],
      formation: json['formation'],
      questions: json['questions'] ?? [],
      userParticipation:
          participationData != null
              ? QuizParticipation.fromJson(participationData)
              : null,
    );
  }
}

/// User participation status
class QuizParticipation {
  final int id;
  final String status; // 'in_progress', 'completed', etc.
  final int score;
  final int correctAnswers;
  final int timeSpent;
  final DateTime? startedAt;
  final DateTime? completedAt;

  QuizParticipation({
    required this.id,
    required this.status,
    required this.score,
    required this.correctAnswers,
    required this.timeSpent,
    this.startedAt,
    this.completedAt,
  });

  factory QuizParticipation.fromJson(Map<String, dynamic> json) {
    return QuizParticipation(
      id: json['id'] ?? 0,
      status: json['status'] ?? '',
      score: json['score'] ?? 0,
      correctAnswers: json['correct_answers'] ?? 0,
      timeSpent: json['time_spent'] ?? 0,
      startedAt:
          json['started_at'] != null
              ? DateTime.parse(json['started_at'])
              : null,
      completedAt:
          json['completed_at'] != null
              ? DateTime.parse(json['completed_at'])
              : null,
    );
  }
}

/// Badge status enum
enum QuizBadgeStatus { loading, completed, resume, start, error }

/// Manages caching and batch fetching of quiz participation data
class QuizListCacheManager {
  final String apiBase;
  final String token;
  final Duration cacheDuration;

  // Cache structure: quizId -> (data, timestamp)
  final Map<String, _CachedQuiz> _cache = {};

  // Listeners for cache updates
  final Set<VoidCallback> _listeners = {};

  QuizListCacheManager({
    required this.apiBase,
    required this.token,
    this.cacheDuration = const Duration(minutes: 5),
  });

  /// Add a listener to be notified when cache updates
  void addListener(VoidCallback callback) => _listeners.add(callback);

  /// Remove a listener
  void removeListener(VoidCallback callback) => _listeners.remove(callback);

  /// Notify all listeners
  void _notifyListeners() {
    for (var listener in _listeners) {
      listener();
    }
  }

  /// Get status for a quiz (from cache or start fetch)
  QuizBadgeStatus getStatus(String quizId) {
    final cached = _cache[quizId];
    if (cached != null && !cached.isExpired) {
      return cached.status;
    }
    return QuizBadgeStatus.loading;
  }

  /// Get participation data (if cached and valid)
  QuizParticipation? getParticipation(String quizId) {
    final cached = _cache[quizId];
    if (cached != null && !cached.isExpired) {
      return cached.participation;
    }
    return null;
  }

  /// Batch fetch quiz list (one API call)
  /// Returns immediately but updates cache asynchronously
  Future<List<QuizWithParticipation>> fetchQuizzesBatch() async {
    try {
      final uri = Uri.parse('$apiBase/api/stagiaire/quizzes');
      final headers = {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      };

      // Simulate some async work (would be an HTTP call)
      final response = await _simulateHttpGet(uri, headers);

      if (response['status'] == 200) {
        final data = response['body']['data'] as List<dynamic>;
        final quizzes =
            data.map((q) => QuizWithParticipation.fromJson(q)).toList();

        // Cache all results
        for (var quiz in quizzes) {
          _cache[quiz.id] = _CachedQuiz(
            status: _statusFromParticipation(quiz.userParticipation),
            participation: quiz.userParticipation,
            timestamp: DateTime.now(),
          );
        }

        _notifyListeners();
        return quizzes;
      } else {
        throw Exception('Failed to fetch quizzes: ${response['status']}');
      }
    } catch (e) {
      // Mark all pending as error
      rethrow;
    }
  }

  /// Clear all cached data
  void clearCache() {
    _cache.clear();
    _notifyListeners();
  }

  /// Clear cache for a specific quiz
  void clearQuizCache(String quizId) {
    _cache.remove(quizId);
    _notifyListeners();
  }

  /// Determine badge status from participation
  static QuizBadgeStatus _statusFromParticipation(
    QuizParticipation? participation,
  ) {
    if (participation == null) return QuizBadgeStatus.start;
    if (participation.status == 'completed') return QuizBadgeStatus.completed;
    if (participation.status == 'in_progress') return QuizBadgeStatus.resume;
    return QuizBadgeStatus.start;
  }

  /// Simulate HTTP call (replace with real http.get in production)
  Future<Map<String, dynamic>> _simulateHttpGet(
    Uri uri,
    Map<String, String> headers,
  ) async {
    // In production, replace with:
    // final response = await http.get(uri, headers: headers);
    // return {
    //   'status': response.statusCode,
    //   'body': response.statusCode == 200 ? jsonDecode(response.body) : {}
    // };

    // For now, simulate with delay
    await Future.delayed(const Duration(milliseconds: 500));
    throw UnimplementedError('Replace with real HTTP call in production');
  }
}

/// Cached quiz data with expiration
class _CachedQuiz {
  final QuizBadgeStatus status;
  final QuizParticipation? participation;
  final DateTime timestamp;

  _CachedQuiz({
    required this.status,
    required this.participation,
    required this.timestamp,
  });

  bool get isExpired =>
      DateTime.now().difference(timestamp).inMinutes > 5; // 5 min cache
}
