import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

class QuizResumeService {
  final SharedPreferences _prefs;

  QuizResumeService(this._prefs);

  static const String _prefix = 'quiz_session_';

  Future<void> saveSession({
    required String quizId,
    required String quizTitle,
    required int currentIndex,
    required Map<String, dynamic> answers,
    required int timeSpent,
    required List<String> questionIds,
  }) async {
    final key = '$_prefix$quizId';
    final data = {
      'quizId': quizId,
      'quizTitle': quizTitle,
      'currentIndex': currentIndex,
      'answers': answers,
      'timeSpent': timeSpent,
      'questionIds': questionIds,
      'lastUpdated': DateTime.now().toIso8601String(),
    };
    debugPrint('💾 QuizResumeService.saveSession: key=$key');
    debugPrint('   Data: ${jsonEncode(data)}');
    await _prefs.setString(key, jsonEncode(data));
    debugPrint('✅ Saved to SharedPreferences');
  }

  Future<Map<String, dynamic>?> getSession(String quizId) async {
    final key = '$_prefix$quizId';
    debugPrint('🔍 QuizResumeService.getSession: key=$key');
    
    // Forcer le reload depuis le disque pour s'assurer qu'on a les dernières données
    await _prefs.reload();
    debugPrint('   🔄 Reloaded from disk');
    
    final data = _prefs.getString(key);
    debugPrint('   Raw data: $data');
    if (data == null) {
      debugPrint('   ❌ No data found');
      return null;
    }
    try {
      final decoded = jsonDecode(data) as Map<String, dynamic>;
      debugPrint('   ✅ Decoded successfully: $decoded');
      return decoded;
    } catch (e) {
      debugPrint('   ❌ Error decoding: $e');
      await _prefs.remove(key);
      return null;
    }
  }

  Future<void> clearSession(String quizId) async {
    final key = '$_prefix$quizId';
    await _prefs.remove(key);
  }
  
  Future<bool> hasSession(String quizId) async {
    final key = '$_prefix$quizId';
    await _prefs.reload();
    return _prefs.containsKey(key);
  }
}
