import 'package:flutter/material.dart';
import 'package:wizi_learn/features/auth/data/models/question_model.dart';
import 'package:wizi_learn/features/auth/presentation/pages/quiz_summary_page.dart';
import 'package:wizi_learn/features/auth/presentation/widgets/quiz_session/quiz_session_manager.dart';

class QuizNavigationControls extends StatelessWidget {
  final QuizSessionManager sessionManager;
  final List<Question> questions;

  const QuizNavigationControls({
    super.key,
    required this.sessionManager,
    required this.questions,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: sessionManager.currentQuestionIndex,
      builder: (_, index, __) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ElevatedButton(
                onPressed:
                    index > 0 ? sessionManager.goToPreviousQuestion : null,
                child: const Text('Précédent'),
              ),
              ElevatedButton(
                onPressed: () => _handleNextOrComplete(context, index),
                child: Text(
                  index < questions.length - 1 ? 'Suivant' : 'Terminer',
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Dans quiz_navigation_controls.dart
  void _handleNextOrComplete(BuildContext context, int index) async {
    try {
      if (index < questions.length - 1) {
        sessionManager.goToNextQuestion();
      } else {
        final results = await sessionManager.completeQuiz();
        if (!context.mounted) return;

        await Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => QuizSummaryPage(
              questions: (results['questions'] as List)
                  .map((q) => Question.fromJson(q))
                  .toList(),
              score: results['score'] ?? 0,
              correctAnswers: results['correctAnswers'] ?? 0,
              totalQuestions: results['totalQuestions'] ?? questions.length,
              timeSpent: results['timeSpent'] ?? 0,
              quizResult: results,
            ),
          ),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }
}
