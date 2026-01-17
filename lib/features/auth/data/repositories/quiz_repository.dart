import 'package:flutter/cupertino.dart';
import 'package:wizi_learn/core/constants/app_constants.dart';
import 'package:wizi_learn/core/network/api_client.dart';
import 'package:wizi_learn/features/auth/data/models/question_model.dart';
import 'package:wizi_learn/features/auth/data/models/quiz_model.dart';
import 'dart:convert';

class QuizRepository {
  final ApiClient apiClient;

  QuizRepository({required this.apiClient});

  Future<List<Quiz>> getQuizzesForStagiaire({int? stagiaireId}) async {
    try {
      final response = await apiClient.get('/stagiaire/quizzes');
      // debugPrint('Response from /stagiaire/quizzes: ${jsonEncode(response.data)}');
      if (response.data == null || response.data['data'] == null) {
        return [];
      }

      final List<dynamic> rawQuizzes =
          response.data['data'] is List ? response.data['data'] : [];

      final List<Quiz> quizzes = [];
      for (var rawQuiz in rawQuizzes) {
        try {
          if (rawQuiz is Map<String, dynamic>) {
            final quiz = Quiz.fromJson(rawQuiz);
            // On ne garde que les quiz avec status == "actif"
            if (quiz.status.toLowerCase() == 'actif') {
              quizzes.add(quiz);
            }
          }
        } catch (e, stack) {
          debugPrint('Error parsing quiz: $e\n$stack');
        }
      }

      return quizzes;
    } catch (e) {
      // debugPrint('Error in getQuizzesForStagiaire: $e\n$stack');
      return [];
    }
  }


  Future<List<Question>> getQuizQuestions(int quizId) async {
    try {
      final response = await apiClient.get('/quiz/$quizId/questions');

      if (response.data == null || response.data['data'] == null) return [];

      // Convertir toutes les questions
      final allQuestions = (response.data['data'] as List).map((q) {
        // Ajouter les réponses si elles ne sont pas présentes
        if (q['reponses'] == null) {
          q['reponses'] = [];
        }
        return Question.fromJson(q);
      }).toList();

      // Mélanger la liste des questions
      allQuestions.shuffle();

      // Prendre seulement 5 questions (ou moins si il y en a moins de 5)
      final randomQuestions = allQuestions.take(5).toList();

      return randomQuestions;
    } catch (e) {
      // debugPrint('Error loading questions: $e\n$stack');
      return [];
    }
  }
  Future<Map<String, dynamic>> submitQuizResults({
    required int quizId,
    required Map<String, dynamic> answers,
    required int timeSpent,
  }) async {
    try {
      // Valider le payload avant envoi
      if (answers.isEmpty) {
        throw Exception('Aucune réponse à soumettre');
      }

      // Créer le payload avec le format exact attendu par le serveur
      final payload = {
        'answers': answers,
        'timeSpent': timeSpent,
      };

      // debugPrint('Sending payload to server: $payload');

      final response = await apiClient.post(
        '/quiz/$quizId/result',
        data: payload,
      );

      if (response.data == null) {
        throw Exception('Réponse vide du serveur');
      }

      return response.data;
    } catch (e) {
      // debugPrint('Error submitting quiz results: $e\n$stack');
      throw Exception('Échec de la soumission: ${e.toString()}');
    }
  }
}
