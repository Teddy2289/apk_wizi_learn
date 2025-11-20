import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for persisting quiz session data locally
class QuizPersistenceService {
  static const String _keyPrefix = 'quiz_session_';
  
  /// Get the last unfinished quiz session
  /// Returns a Map with quiz session data or null if no unfinished quiz exists
  Future<Map<String, dynamic>?> getLastUnfinishedQuiz() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      final sessionKeys = keys.where((k) => k.startsWith(_keyPrefix)).toList();
      
      if (sessionKeys.isEmpty) return null;
      
      // Sort keys to get the most recent session (last modified)
      // For now, just take the last one
      final lastKey = sessionKeys.last;
      final sessionJson = prefs.getString(lastKey);
      
      if (sessionJson == null || sessionJson.isEmpty) {
        return null;
      }
      
      final sessionData = json.decode(sessionJson) as Map<String, dynamic>;
      
      // Add the quizId from the key
      sessionData['quizId'] = lastKey.replaceFirst(_keyPrefix, '');
      
      return sessionData;
    } catch (e) {
      print('Error getting last unfinished quiz: $e');
      return null;
    }
  }
  
  /// Save quiz session data
  Future<void> saveSession(String quizId, Map<String, dynamic> sessionData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_keyPrefix$quizId';
      final jsonStr = json.encode(sessionData);
      await prefs.setString(key, jsonStr);
    } catch (e) {
      print('Error saving quiz session: $e');
    }
  }
  
  /// Clear a specific quiz session
  Future<void> clearSession(String quizId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_keyPrefix$quizId';
      await prefs.remove(key);
    } catch (e) {
      print('Error clearing quiz session: $e');
    }
  }
  
  /// Clear all quiz sessions
  Future<void> clearAllSessions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      final sessionKeys = keys.where((k) => k.startsWith(_keyPrefix)).toList();
      
      for (final key in sessionKeys) {
        await prefs.remove(key);
      }
    } catch (e) {
      print('Error clearing all quiz sessions: $e');
    }
  }
}
