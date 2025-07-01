import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:wizi_learn/core/network/api_client.dart';
import 'package:wizi_learn/features/auth/data/repositories/quiz_repository.dart';

class QuizSubmissionHandler {
  final String quizId;
  late final QuizRepository _repository;

  QuizSubmissionHandler({required this.quizId}) {
    final apiClient = ApiClient(
      dio: Dio(),
      storage: const FlutterSecureStorage(),
    );
    _repository = QuizRepository(apiClient: apiClient);
  }

  Future<Map<String, dynamic>> submitQuiz({
    required Map<String, dynamic> userAnswers,
    required int timeSpent,
  }) async {
    try {
      debugPrint('Submitting quiz with answers: $userAnswers');
      if (userAnswers.containsKey('1594')) {
        debugPrint('Flashcard answer for 1594: ${userAnswers['1594']}');
      }

      final response = await _repository.submitQuizResults(
        quizId: int.parse(quizId),
        answers: userAnswers,
        timeSpent: timeSpent,
      );

      final transformedResponse = _transformResponse(response);
      debugPrint('Transformed response: $transformedResponse');

      return transformedResponse;
    } catch (e) {
      debugPrint('Error submitting quiz: $e');
      throw Exception('Failed to submit quiz: $e');
    }
  }

  Map<String, dynamic> _transformResponse(Map<String, dynamic> response) {
    if (response.containsKey('questions') && response['questions'] is List) {
      final questions = List<Map<String, dynamic>>.from(response['questions']);

      final transformedQuestions =
          questions.map((question) {
            // Ne pas transformer les questions sans réponse
            if (question['selectedAnswers'] == null) {
              return question;
            }

            // Cas spécial pour les questions audio
            if (question['type'] == 'question audio') {
              // Si c'est déjà dans le bon format Map
              if (question['selectedAnswers'] is Map) {
                return question;
              }

              // Si c'est une String, la convertir en Map
              if (question['selectedAnswers'] is String) {
                return {
                  ...question,
                  'selectedAnswers': {
                    'text': question['selectedAnswers'],
                    'id': _findAnswerId(
                      question['answers'],
                      question['selectedAnswers'],
                    ),
                  },
                };
              }

              // Si c'est une liste, prendre le premier élément
              if (question['selectedAnswers'] is List &&
                  question['selectedAnswers'].isNotEmpty) {
                final first = question['selectedAnswers'].first;
                return {
                  ...question,
                  'selectedAnswers': {
                    'text': first is Map ? first['text'] : first.toString(),
                    'id':
                        first is Map
                            ? first['id']?.toString()
                            : _findAnswerId(question['answers'], first),
                  },
                };
              }
            }

            if (question['type'] == 'carte flash') {
              // Get all correct answers (handling both isCorrect and is_correct formats)
              final correctAnswers = (question['answers'] as List)
                  .where((a) =>
              a['isCorrect'] == true ||
                  a['is_correct'] == true ||
                  a['isCorrect'] == 1) // Also handle numeric 1/0 values
                  .map((a) => a['text'].toString().trim())
                  .toList();

              // Format user's answer
              dynamic userAnswer = question['selectedAnswers'];
              if (userAnswer is Map) {
                userAnswer = userAnswer['text'] ?? userAnswer['id'] ?? '';
              }

              // Clean and compare answers
              final cleanUserAnswer = userAnswer.toString().trim();
              final isActuallyCorrect = correctAnswers.any(
                      (correct) => correct.trim() == cleanUserAnswer
              );

              return {
                ...question,
                'selectedAnswers': cleanUserAnswer,
                'correctAnswers': correctAnswers,
                'isCorrect': isActuallyCorrect,
              };
            }
            return question;
          }).toList();

      return {...response, 'questions': transformedQuestions};
    }
    return response;
  }

  static String? _findAnswerId(List<dynamic> answers, dynamic answerValue) {
    try {
      if (answers == null) return null;

      final answerText =
          answerValue is Map ? answerValue['text'] : answerValue.toString();

      final matching = answers.firstWhere(
        (a) => a['text'] == answerText,
        orElse: () => null,
      );

      return matching?['id']?.toString();
    } catch (e) {
      debugPrint("Error finding answer ID: $e");
      return null;
    }
  }
}
