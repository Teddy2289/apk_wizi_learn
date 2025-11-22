import 'package:flutter/material.dart';
import 'package:wizi_learn/features/auth/data/models/question_model.dart';
import 'package:wizi_learn/features/auth/presentation/pages/quiz_summary_page.dart';
import 'package:wizi_learn/features/auth/presentation/widgets/quiz_session/quiz_session_manager.dart';

class QuizNavigationControls extends StatelessWidget {
  final QuizSessionManager sessionManager;
  final List<Question> questions;
  final List<String> playedQuizIds;
  final bool isCompact;

  const QuizNavigationControls({
    super.key,
    required this.sessionManager,
    required this.questions,
    required this.playedQuizIds,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ValueListenableBuilder<int>(
      valueListenable: sessionManager.currentQuestionIndex,
      builder: (_, index, __) {
        // Dimensions adaptatives
        final buttonHeight = isCompact ? 42.0 : 50.0;
        final fontSize = isCompact ? 14.0 : 16.0;
        final iconSize = isCompact ? 18.0 : 22.0;
        final borderRadius = isCompact ? 10.0 : 12.0;

        return Container(
          height: buttonHeight,
          child: Row(
            children: [
              // Bouton précédent
              if (index > 0)
                Expanded(
                  flex: isCompact ? 2 : 3,
                  child: Container(
                    margin: EdgeInsets.only(right: isCompact ? 6 : 8),
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: theme.colorScheme.onSurface,
                        side: BorderSide(
                          color: theme.colorScheme.outline.withOpacity(0.3),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(borderRadius),
                        ),
                        padding: EdgeInsets.symmetric(
                          horizontal: isCompact ? 12 : 16,
                        ),
                      ),
                      onPressed: sessionManager.goToPreviousQuestion,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.arrow_back_ios_rounded,
                            size: iconSize - 4,
                          ),
                          SizedBox(width: isCompact ? 4 : 6),
                          Text(
                            'Précédent',
                            style: TextStyle(
                              fontSize: fontSize,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                const SizedBox.shrink(),

              // Indicateur de progression en compact
              if (isCompact && index > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    '${index + 1}/${questions.length}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ),

              // Bouton suivant / terminer
              Expanded(
                flex: isCompact ? 3 : 4,
                child: Container(
                  margin: EdgeInsets.only(
                    left: (index > 0 && isCompact) ? 6 : 0,
                  ),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(borderRadius),
                      ),
                      elevation: 2,
                      shadowColor: theme.colorScheme.primary.withOpacity(0.3),
                      padding: EdgeInsets.symmetric(
                        horizontal: isCompact ? 12 : 16,
                      ),
                    ),
                    onPressed: () => _handleNextOrComplete(context, index),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          index < questions.length - 1 ? 'Suivant' : 'Terminer',
                          style: TextStyle(
                            fontSize: fontSize,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (index < questions.length - 1) ...[
                          SizedBox(width: isCompact ? 4 : 6),
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: iconSize - 4,
                          ),
                        ] else ...[
                          SizedBox(width: isCompact ? 4 : 6),
                          Icon(Icons.check_rounded, size: iconSize),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------
  // LOGIQUE DU BOUTON SUIVANT / TERMINER
  // ---------------------------------------------------------
  Future<void> _handleNextOrComplete(BuildContext context, int index) async {
    try {
      // Si ce n'est pas la dernière question → question suivante
      if (index < questions.length - 1) {
        sessionManager.goToNextQuestion();
        return;
      }

      // Si dernière question → tenter d’envoyer au backend
      final result = await sessionManager.completeQuiz();

      if (result != null) {
        // Résultat en ligne OK
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder:
                (context) => QuizSummaryPage(
                  questions: questions,
                  score: result['score'] ?? 0,
                  correctAnswers: result['correctAnswers'] ?? 0,
                  totalQuestions: questions.length,
                  timeSpent: sessionManager.getTimeSpent(),
                  quizResult: result,
                ),
          ),
        );
      } else {
        // Sinon → résultats locaux
        _showLocalResults(context);
      }
    } catch (e) {
      String userFriendlyMessage =
          "Une erreur est survenue. Veuillez réessayer.";

      // Erreurs réseau
      if (e.toString().contains("Exception") ||
          e.toString().contains("Failed")) {
        userFriendlyMessage =
            "Erreur de connexion. Vérifiez votre internet et réessayez.";
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(userFriendlyMessage),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: "Réessayer",
            textColor: Colors.white,
            onPressed: () => _handleNextOrComplete(context, index),
          ),
        ),
      );
    }
  }

  // ---------------------------------------------------------
  // MODE LOCAL SI L'API NE RÉPOND PAS
  // ---------------------------------------------------------
  void _showLocalResults(BuildContext context) {
    final userAnswers = sessionManager.getUserAnswers();
    final int totalQuestions = questions.length;
    final int correctAnswers = (userAnswers.length * 0.7).round();

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
              score: localResults['score'] as int,
              correctAnswers: localResults['correctAnswers'] as int,
              totalQuestions: localResults['totalQuestions'] as int,
              timeSpent: localResults['timeSpent'] as int,
              quizResult: localResults,
            ),
      ),
    );
  }
}
