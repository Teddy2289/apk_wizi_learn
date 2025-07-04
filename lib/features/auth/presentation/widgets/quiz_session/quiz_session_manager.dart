import 'dart:async';
import 'package:flutter/material.dart';
import 'package:wizi_learn/features/auth/data/models/question_model.dart';
import 'package:wizi_learn/features/auth/presentation/widgets/quiz_session/quiz_submission_handler.dart';

class QuizSessionManager {
  final List<Question> questions;
  final String quizId;
  final ValueNotifier<int> currentQuestionIndex = ValueNotifier(0);
  final ValueNotifier<int> remainingSeconds = ValueNotifier(30);
  final ValueNotifier<bool> quizCompleted = ValueNotifier(false);

  Timer? _timer;
  DateTime? _questionStartTime;
  int _totalTimeSpent = 0;
  Map<String, dynamic> _userAnswers = {};
  final QuizSubmissionHandler _submissionHandler;

  QuizSessionManager({required this.questions, required this.quizId})
    : _submissionHandler = QuizSubmissionHandler(quizId: quizId);

  void startSession() {
    _startQuestionTimer();
  }

  // Méthodes de navigation ajoutées
  void goToQuestion(int index) {
    if (index >= 0 && index < questions.length) {
      _recordTimeSpent();
      currentQuestionIndex.value = index;
      _resetQuestionTimer();
    }
  }

  void _startQuestionTimer() {
    _questionStartTime = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (remainingSeconds.value > 0) {
        remainingSeconds.value--;
      } else {
        _timer?.cancel();
        goToNextQuestion();
      }
    });
  }

  void _resetQuestionTimer() {
    if (_questionStartTime != null) {
      _totalTimeSpent +=
          DateTime.now().difference(_questionStartTime!).inSeconds;
    }
    _timer?.cancel();
    remainingSeconds.value = 30;
    _startQuestionTimer();
  }

  void handleAnswer(dynamic answer) {
    final question = questions[currentQuestionIndex.value];
    final questionId = question.id.toString();

    debugPrint("Raw answer received for $questionId: $answer");

    if (question.type == "question audio") {
      // Cas spécial pour les questions audio
      if (answer is Map) {
        _userAnswers[questionId] = {
          'id': answer['id']?.toString(),
          'text': answer['text']
        };
      } else if (answer is List && answer.isNotEmpty) {
        // Si c'est une liste, prendre le premier élément
        final firstAnswer = answer.first;
        if (firstAnswer is Map) {
          _userAnswers[questionId] = {
            'id': firstAnswer['id']?.toString(),
            'text': firstAnswer['text']
          };
        } else {
          _userAnswers[questionId] = {
            'id': null,
            'text': firstAnswer.toString()
          };
        }
      } else if (answer is String) {
        _userAnswers[questionId] = {
          'id': null,
          'text': answer
        };
      }
    }else if(question.type == "carte flash") {
      if (answer is Map) {
        // Handle both front and back of flashcard if needed
        _userAnswers[questionId] = answer['text'] ?? answer.values.first?.toString() ?? '';
      } else {
        _userAnswers[questionId] = answer.toString();
      }
      debugPrint("Flashcard answer stored: ${_userAnswers[questionId]}");
    }
    else if (question.type == "correspondance" && answer is Map) {
      _userAnswers[questionId] = answer;
    }
    else if (question.type == "vrai/faux" && answer is List) {
      _userAnswers[questionId] = answer;
    }
    else if (question.type == "choix multiples") {
      _userAnswers[questionId] = answer is List ? answer : [];
    }
    else {
      _userAnswers[questionId] = answer;
    }

    debugPrint("Stored answer for $questionId: ${_userAnswers[questionId]}");
  }
  void goToNextQuestion() {
    final currentQuestionId =
        questions[currentQuestionIndex.value].id.toString();
    if (!_userAnswers.containsKey(currentQuestionId)) {
      throw Exception('Veuillez répondre à la question avant de continuer');
    }

    _recordTimeSpent();

    if (currentQuestionIndex.value < questions.length - 1) {
      currentQuestionIndex.value++;
      _resetQuestionTimer();
    }
  }

  void goToPreviousQuestion() {
    _recordTimeSpent();
    if (currentQuestionIndex.value > 0) {
      currentQuestionIndex.value--;
      _resetQuestionTimer();
    }
  }

  Future<Map<String, dynamic>> completeQuiz() async {
    quizCompleted.value = true;
    _timer?.cancel();
    _recordTimeSpent();

    try {
      // Ajoutez return ici pour retourner les résultats
      return await _submissionHandler.submitQuiz(
        userAnswers: _userAnswers,
        timeSpent: _totalTimeSpent,
      );
    } catch (e) {
      throw Exception('Erreur lors de la soumission: ${e.toString()}');
    }
  }

  void _recordTimeSpent() {
    if (_questionStartTime != null) {
      _totalTimeSpent +=
          DateTime.now().difference(_questionStartTime!).inSeconds;
    }
  }

  void dispose() {
    _timer?.cancel();
    currentQuestionIndex.dispose();
    remainingSeconds.dispose();
    quizCompleted.dispose();
  }
}
