import 'package:flutter/foundation.dart';
import 'package:wizi_learn/core/network/api_client.dart';
import 'package:wizi_learn/features/formateur/data/models/quiz_model.dart';
import 'package:dio/dio.dart';

class QuizRepository {
  final ApiClient apiClient;

  QuizRepository({required this.apiClient});

  /// Get quiz details with questions
  Future<Quiz> getQuizById(int id) async {
    try {
      final response = await apiClient.get('/formateur/quizzes/$id');
      // Laravel endpoint returns { quiz: {...}, questions: [...] }
      // Some endpoints wrap in "data". Support both shapes.
      final root = (response.data is Map && response.data['data'] is Map)
          ? response.data['data'] as Map<String, dynamic>
          : response.data as Map<String, dynamic>;

      if (root['quiz'] is Map) {
        final quizJson = Map<String, dynamic>.from(root['quiz'] as Map);
        if (root['questions'] is List) {
          quizJson['questions'] = root['questions'];
        }
        return Quiz.fromJson(quizJson);
      }

      // Fallback: API already returns quiz with embedded questions
      return Quiz.fromJson(root);
    } catch (e) {
      debugPrint('❌ Erreur chargement quiz $id: $e');
      rethrow;
    }
  }

  /// Add a question to a quiz
  Future<bool> addQuestion(int quizId, Map<String, dynamic> questionData) async {
    try {
      await apiClient.post(
        '/formateur/quizzes/$quizId/questions',
        data: questionData,
      );
      return true;
    } catch (e) {
      debugPrint('❌ Erreur ajout question: $e');
      return false;
    }
  }

  /// Update a question
  Future<bool> updateQuestion(int quizId, int questionId, Map<String, dynamic> questionData) async {
    try {
      await apiClient.put(
        '/formateur/quizzes/$quizId/questions/$questionId',
        data: questionData,
      );
      return true;
    } catch (e) {
      debugPrint('❌ Erreur modif question: $e');
      return false;
    }
  }

  /// Delete a question
  Future<bool> deleteQuestion(int quizId, int questionId) async {
    try {
      await apiClient.delete(
        '/formateur/quizzes/$quizId/questions/$questionId',
      );
      return true;
    } catch (e) {
      debugPrint('❌ Erreur suppression question: $e');
      return false;
    }
  }

  /// Publish the quiz
  Future<bool> publishQuiz(int quizId) async {
    try {
      await apiClient.post('/formateur/quizzes/$quizId/publish');
      return true;
    } catch (e) {
      return false;
    }
  }
}
