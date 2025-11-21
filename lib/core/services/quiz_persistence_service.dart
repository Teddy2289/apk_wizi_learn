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
      
      // Find the most recent session
      Map<String, dynamic>? mostRecentSession;
      DateTime? mostRecentTime;
      
      for (final key in sessionKeys) {
        final jsonStr = prefs.getString(key);
        if (jsonStr != null && jsonStr.isNotEmpty) {
          try {
            final session = json.decode(jsonStr) as Map<String, dynamic>;
            final timestampStr = session['timestamp'] as String?;
            
            if (timestampStr != null) {
              final timestamp = DateTime.parse(timestampStr);
              if (mostRecentTime == null || timestamp.isAfter(mostRecentTime)) {
                mostRecentTime = timestamp;
                mostRecentSession = session;
                // Ensure quizId is present
                mostRecentSession['quizId'] = key.replaceFirst(_keyPrefix, '');
              }
            } else {
               // Fallback if no timestamp, just take it if we have nothing else
               if (mostRecentSession == null) {
                 mostRecentSession = session;
                 mostRecentSession['quizId'] = key.replaceFirst(_keyPrefix, '');
               }
            }
          } catch (e) {
            print('Error parsing session for key $key: $e');
          }
        }
      }
      
      return mostRecentSession;
    } catch (e) {
      print('Error getting last unfinished quiz: $e');
      return null;
    }
  }

  /// Get a specific quiz session by ID
  Future<Map<String, dynamic>?> getSession(String quizId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_keyPrefix$quizId';
      final sessionJson = prefs.getString(key);
      
      if (sessionJson == null || sessionJson.isEmpty) {
        return null;
      }
      
      return json.decode(sessionJson) as Map<String, dynamic>;
    } catch (e) {
      print('Error getting quiz session: $e');
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
  
  /// Check if the resume quiz modal has been hidden for a specific quiz
  Future<bool> isModalHidden(String quizId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'quiz_modal_hidden_$quizId';
      return prefs.getBool(key) ?? false;
    } catch (e) {
      print('Error checking if modal is hidden: $e');
      return false;
    }
  }
  
  /// Set whether the resume quiz modal should be hidden for a specific quiz
  Future<void> setModalHidden(String quizId, bool isHidden) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'quiz_modal_hidden_$quizId';
      await prefs.setBool(key, isHidden);
    } catch (e) {
      print('Error setting modal hidden state: $e');
    }
  }
  
  /// Clear the modal hidden state for a specific quiz
  Future<void> clearModalHiddenState(String quizId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'quiz_modal_hidden_$quizId';
      await prefs.remove(key);
    } catch (e) {
      print('Error clearing modal hidden state: $e');
    }
  }
}
