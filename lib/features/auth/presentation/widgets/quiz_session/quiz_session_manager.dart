import 'dart:async';
import 'package:flutter/material.dart';
import 'package:wizi_learn/features/auth/data/models/question_model.dart';
import 'package:wizi_learn/features/auth/data/models/quiz_session.dart';
import 'package:wizi_learn/features/auth/data/services/quiz_session_storage_service.dart';
import 'package:wizi_learn/features/auth/presentation/widgets/quiz_session/quiz_submission_handler.dart';

class QuizSessionManager {
  final List<Question> questions;
  final String quizId;
  final String? quizTitle;
  final QuizSessionStorageService? storageService;

  final ValueNotifier<int> currentQuestionIndex = ValueNotifier(0);
  final ValueNotifier<int> remainingSeconds = ValueNotifier(30);
  final ValueNotifier<bool> quizCompleted = ValueNotifier(false);

  final void Function()? onTimerEnd;

  Timer? _timer;
  DateTime? _questionStartTime;
  int _totalTimeSpent = 0;
  final Map<String, dynamic> _userAnswers = {};
  final QuizSubmissionHandler _submissionHandler;
  bool _isRestoringSession = false;

  QuizSessionManager({
    required this.questions,
    required this.quizId,
    this.quizTitle,
    this.storageService,
    this.onTimerEnd,
  }) : _submissionHandler = QuizSubmissionHandler(quizId: quizId);

  void startSession() {
    _startQuestionTimer();
  }

  // Navigation methods
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
        if (onTimerEnd != null) {
          onTimerEnd!();
        } else {
          goToNextQuestion();
        }
      }
    });
  }

  void _resetQuestionTimer() {
    if (_questionStartTime != null) {
      _totalTimeSpent += DateTime.now().difference(_questionStartTime!).inSeconds;
    }
    _timer?.cancel();
    remainingSeconds.value = 30;
    _startQuestionTimer();
  }

  dynamic _normalizeAnswer(Question question, dynamic answer) {
    switch (question.type) {
      case "question audio":
        if (answer is Map) return answer;
        if (answer is List) return answer.isNotEmpty ? answer.first : null;
        return {'text': answer.toString()};
      case "carte flash":
        if (answer is Map) {
          return answer['text'] ?? answer.values.first?.toString();
        }
        return answer.toString();
      case "choix multiples":
        return answer is List ? answer : [answer];
      case "remplir le champ vide":
        if (answer is Map) return answer;
        return {'reponse': answer.toString()};
      case "rearrangement":
        return answer is List ? answer : [answer];
      default:
        return answer;
    }
  }

  void handleAnswer(dynamic answer) {
    final question = questions[currentQuestionIndex.value];
    final questionId = question.id.toString();
    debugPrint("Raw answer received for $questionId: $answer");
    _userAnswers[questionId] = _normalizeAnswer(question, answer);
    debugPrint("Stored answer for $questionId: ${_userAnswers[questionId]}");
    if (!_isRestoringSession) {
      _saveCurrentSession();
    }
  }

  void goToNextQuestion() {
    final currentQuestionId = questions[currentQuestionIndex.value].id.toString();
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

  void initialize() {
    debugPrint('Questions chargées dans le manager:');
    for (var q in questions) {
      debugPrint('- ID: ${q.id}, Type: ${q.type}, Texte: ${q.text}');
    }
  }

  Future<Map<String, dynamic>> completeQuiz() async {
    debugPrint('Réponses à soumettre:');
    _userAnswers.forEach((id, answer) {
      debugPrint('- Question ID: $id, Réponse: $answer');
    });
    final invalidIds = _userAnswers.keys
        .where((id) => !questions.any((q) => q.id.toString() == id))
        .toList();
    if (invalidIds.isNotEmpty) {
      debugPrint('ERREUR: IDs de questions invalides: $invalidIds');
      throw Exception('Certaines questions ne font pas partie du quiz');
    }
    quizCompleted.value = true;
    _timer?.cancel();
    _recordTimeSpent();
    try {
      if (_userAnswers.isEmpty) {
        throw Exception('Aucune réponse à soumettre');
      }
      final response = await _submissionHandler.submitQuiz(
        userAnswers: _userAnswers,
        timeSpent: _totalTimeSpent,
      );
      await _clearCurrentSession();
      if (response.containsKey('questions') && response['questions'] is List) {
        final answeredQuestions = (response['questions'] as List)
            .where((q) => q['selectedAnswers'] != null)
            .toList();
        return {
          ...response,
          'questions': answeredQuestions,
          'totalQuestions': answeredQuestions.length,
          'quizId': quizId,
        };
      }
      return response;
    } catch (e, stack) {
      debugPrint('Error completing quiz: $e\n$stack');
      throw Exception('Erreur lors de la soumission: ${e.toString()}');
    }
  }

  void _recordTimeSpent() {
    if (_questionStartTime != null) {
      _totalTimeSpent += DateTime.now().difference(_questionStartTime!).inSeconds;
    }
  }

  // Session data accessors
  Map<String, dynamic> getUserAnswers() => Map<String, dynamic>.from(_userAnswers);
  int getTimeSpent() => _totalTimeSpent;

  // Save current session state
  Future<void> _saveCurrentSession() async {
    if (storageService == null) return;
    try {
      final session = QuizSession(
        quizId: quizId,
        quizTitle: quizTitle ?? '',
        questionIds: questions.map((q) => q.id.toString()).toList(),
        answers: Map<String, dynamic>.from(_userAnswers),
        currentIndex: currentQuestionIndex.value,
        timeSpent: _totalTimeSpent,
        lastUpdated: DateTime.now(),
      );
      await storageService!.saveSession(session);
    } catch (e) {
      debugPrint('❌ Failed to save session: $e');
    }
  }

  // Clear current session from storage
  Future<void> _clearCurrentSession() async {
    if (storageService == null) return;
    try {
      await storageService!.deleteSession(quizId);
      debugPrint('🗑️ Session cleared for quiz: $quizId');
    } catch (e) {
      debugPrint('❌ Failed to clear session: $e');
    }
  }

  // Restore session from saved state
  Future<void> restoreSession(QuizSession session) async {
    try {
      _isRestoringSession = true;
      _userAnswers
        ..clear()
        ..addAll(session.answers);
      _totalTimeSpent = session.timeSpent;
      currentQuestionIndex.value = session.currentIndex;
      debugPrint('✅ Session restored: ${session.quizId}');
      debugPrint('   Questions answered: ${_userAnswers.length}');
      debugPrint('   Current index: ${session.currentIndex}');
      debugPrint('   Time spent: ${session.timeSpent}s');
    } catch (e) {
      debugPrint('❌ Failed to restore session: $e');
    } finally {
      _isRestoringSession = false;
    }
  }

  // Manually save session (called on quiz exit)
  Future<void> saveOnExit() async => await _saveCurrentSession();

  void dispose() {
    _timer?.cancel();
    currentQuestionIndex.dispose();
    remainingSeconds.dispose();
    quizCompleted.dispose();
  }
}
