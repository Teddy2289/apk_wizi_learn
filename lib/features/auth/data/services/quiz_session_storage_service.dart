import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:wizi_learn/features/auth/data/models/quiz_session.dart';

class QuizSessionStorageService {
  static const String _sessionKeyPrefix = 'quiz_session_';
  static const String _allSessionsKey = 'all_quiz_sessions';

  final SharedPreferences _prefs;

  QuizSessionStorageService(this._prefs);

  /// Save a quiz session to storage
  Future<bool> saveSession(QuizSession session) async {
    try {
      final key = _sessionKeyPrefix + session.quizId;
      final jsonString = jsonEncode(session.toJson());
      final success = await _prefs.setString(key, jsonString);

      if (success) {
        // Track this session in the list of all sessions
        await _addToSessionList(session.quizId);
        debugPrint('✅ Session saved: ${session.quizId}');
      }

      return success;
    } catch (e) {
      debugPrint('❌ Error saving session: $e');
      return false;
    }
  }

  /// Get the most recent unfinished session
  Future<QuizSession?> getUnfinishedSession() async {
    try {
      final sessionIds = await _getAllSessionIds();

      if (sessionIds.isEmpty) {
        return null;
      }

      // Get all sessions and find the most recent one
      QuizSession? mostRecent;
      DateTime? latestTime;

      for (final sessionId in sessionIds) {
        final session = await _getSessionById(sessionId);
        if (session != null && session.isRecent()) {
          if (latestTime == null || session.lastUpdated.isAfter(latestTime)) {
            mostRecent = session;
            latestTime = session.lastUpdated;
          }
        }
      }

      if (mostRecent != null) {
        debugPrint('📋 Found unfinished session: ${mostRecent.quizId}');
      }

      return mostRecent;
    } catch (e) {
      debugPrint('❌ Error getting unfinished session: $e');
      return null;
    }
  }

  /// Get a specific session by quiz ID
  Future<QuizSession?> getSessionById(String quizId) async {
    return _getSessionById(quizId);
  }

  Future<QuizSession?> _getSessionById(String quizId) async {
    try {
      final key = _sessionKeyPrefix + quizId;
      final jsonString = _prefs.getString(key);

      if (jsonString == null) {
        return null;
      }

      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      return QuizSession.fromJson(json);
    } catch (e) {
      debugPrint('❌ Error getting session $quizId: $e');
      return null;
    }
  }

  /// Delete a specific session
  Future<bool> deleteSession(String quizId) async {
    try {
      final key = _sessionKeyPrefix + quizId;
      final success = await _prefs.remove(key);

      if (success) {
        await _removeFromSessionList(quizId);
        debugPrint('🗑️ Session deleted: $quizId');
      }

      return success;
    } catch (e) {
      debugPrint('❌ Error deleting session: $e');
      return false;
    }
  }

  /// Clear all saved sessions
  Future<bool> clearAllSessions() async {
    try {
      final sessionIds = await _getAllSessionIds();

      for (final sessionId in sessionIds) {
        final key = _sessionKeyPrefix + sessionId;
        await _prefs.remove(key);
      }

      await _prefs.remove(_allSessionsKey);
      debugPrint('🗑️ All sessions cleared');
      return true;
    } catch (e) {
      debugPrint('❌ Error clearing all sessions: $e');
      return false;
    }
  }

  /// Get list of all session IDs
  Future<List<String>> _getAllSessionIds() async {
    try {
      final sessionListJson = _prefs.getString(_allSessionsKey);
      if (sessionListJson == null) {
        return [];
      }

      final list = jsonDecode(sessionListJson) as List;
      return List<String>.from(list);
    } catch (e) {
      debugPrint('❌ Error getting session IDs: $e');
      return [];
    }
  }

  /// Add a session ID to the tracking list
  Future<void> _addToSessionList(String quizId) async {
    try {
      final sessionIds = await _getAllSessionIds();

      if (!sessionIds.contains(quizId)) {
        sessionIds.add(quizId);
        await _prefs.setString(_allSessionsKey, jsonEncode(sessionIds));
      }
    } catch (e) {
      debugPrint('❌ Error adding to session list: $e');
    }
  }

  /// Remove a session ID from the tracking list
  Future<void> _removeFromSessionList(String quizId) async {
    try {
      final sessionIds = await _getAllSessionIds();
      sessionIds.remove(quizId);
      await _prefs.setString(_allSessionsKey, jsonEncode(sessionIds));
    } catch (e) {
      debugPrint('❌ Error removing from session list: $e');
    }
  }

  /// Clean up old sessions (older than 7 days)
  Future<void> cleanupOldSessions() async {
    try {
      final sessionIds = await _getAllSessionIds();

      for (final sessionId in sessionIds) {
        final session = await _getSessionById(sessionId);
        if (session != null && !session.isRecent()) {
          await deleteSession(sessionId);
          debugPrint('🧹 Cleaned up old session: $sessionId');
        }
      }
    } catch (e) {
      debugPrint('❌ Error cleaning up old sessions: $e');
    }
  }
}
