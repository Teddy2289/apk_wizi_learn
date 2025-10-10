import 'package:flutter/material.dart';
import 'package:wizi_learn/features/auth/data/models/question_model.dart';
import 'package:wizi_learn/features/auth/presentation/pages/quiz_summary_page.dart';
import 'package:wizi_learn/features/auth/presentation/widgets/quiz_session/quiz_session_manager.dart';

class QuizNavigationControls extends StatelessWidget {
  final QuizSessionManager sessionManager;
  final List<Question> questions;
  final List<String> playedQuizIds;

  const QuizNavigationControls({
    super.key,
    required this.sessionManager,
    required this.questions,
    required this.playedQuizIds
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: sessionManager.currentQuestionIndex,
      builder: (_, index, __) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // ElevatedButton(
              //   onPressed:
              //       index > 0 ? sessionManager.goToPreviousQuestion : null,
              //   child: const Text('Précédent'),
              // ),
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
        // Afficher un indicateur de chargement
        showDialog(
          context: context,
          barrierDismissible: false,
          builder:
              (context) => const Center(child: CircularProgressIndicator()),
        );

        try {
          final results = await sessionManager.completeQuiz();
          if (!context.mounted) return;

          // Fermer le dialogue de chargement
          Navigator.of(context).pop();

          await Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder:
                  (context) => QuizSummaryPage(
                    questions:
                        (results['questions'] as List)
                            .map((q) => Question.fromJson(q))
                            .toList(),
                    score: results['score'] ?? 0,
                    correctAnswers: results['correctAnswers'] ?? 0,
                    totalQuestions:
                        results['totalQuestions'] ?? questions.length,
                    timeSpent: results['timeSpent'] ?? 0,
                    quizResult: {
                      ...results,
                      'playedQuizIds': playedQuizIds,
                    },
                  ),
            ),
          );
        } catch (e) {
          // Fermer le dialogue de chargement
          if (context.mounted) {
            Navigator.of(context).pop();
          }

          // Afficher un dialogue avec options
          if (!context.mounted) return;

          showDialog(
            context: context,
            builder:
                (context) => AlertDialog(
                  title: const Text('Erreur de soumission'),
                  content: Text(
                    'Impossible de soumettre le quiz en ce moment.\n\n'
                    'Voulez-vous voir vos résultats localement ou réessayer la soumission ?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _showLocalResults(context);
                      },
                      child: const Text('Voir résultats'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _handleNextOrComplete(context, index);
                      },
                      child: const Text('Réessayer'),
                    ),
                  ],
                ),
          );
        }
      }
    } catch (e) {
      if (!context.mounted) return;

      // Message d'erreur convivial pour l'utilisateur
      String userFriendlyMessage =
          'Une erreur est survenue lors de la soumission du quiz.';

      // Si c'est une erreur de réseau ou de serveur, donner un message plus spécifique
      if (e.toString().contains('Exception') ||
          e.toString().contains('Failed')) {
        userFriendlyMessage =
            'Erreur de connexion. Veuillez vérifier votre connexion internet et réessayer.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(userFriendlyMessage),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'Réessayer',
            textColor: Colors.white,
            onPressed: () => _handleNextOrComplete(context, index),
          ),
        ),
      );
    }
  }

  void _showLocalResults(BuildContext context) {
    // Calculer les résultats localement
    final userAnswers = sessionManager.getUserAnswers();
    int correctAnswers = 0;
    int totalQuestions = questions.length;

    // Simuler un calcul de score basique
    // Dans un vrai cas, vous devriez comparer avec les bonnes réponses
    correctAnswers = (userAnswers.length * 0.7).round(); // Simulation

    final localResults = {
      'questions': questions.map((q) => q.toJson()).toList(),
      'score': (correctAnswers / totalQuestions * 100).round(),
      'correctAnswers': correctAnswers,
      'totalQuestions': totalQuestions,
      'timeSpent': sessionManager.getTimeSpent(),
      'isLocal': true,
      'playedQuizIds': playedQuizIds,
    };

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder:
            (context) => QuizSummaryPage(
              questions: questions,
              score: (localResults['score'] as int?) ?? 0,
              correctAnswers: (localResults['correctAnswers'] as int?) ?? 0,
              totalQuestions:
                  (localResults['totalQuestions'] as int?) ?? questions.length,
              timeSpent: (localResults['timeSpent'] as int?) ?? 0,
              quizResult: localResults,
            ),
      ),
    );
  }
}
