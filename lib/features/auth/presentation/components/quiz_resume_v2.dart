import 'package:flutter/material.dart';
import 'package:wizi_learn/features/auth/data/models/question_model.dart';

/// Widget principal de résumé de quiz - Logique équivalente à React QuizSummary.tsx
/// Version 2.0: Optimisée et sans warnings de dépréciation
///
/// Affiche:
/// - Statistiques principales (score, réponses, temps, date)
/// - Détail de chaque réponse (correct vs utilisateur)
/// - Boutons d'action (Nouveau Quiz, Recommencer, Quiz Suivant)
class QuizResume extends StatelessWidget {
  final List<Question> questions;
  final int score;
  final int correctAnswers;
  final int totalQuestions;
  final int timeSpent;
  final String? quizTitle;
  final String? completedAt;
  final Map<String, dynamic>? quizResult;
  final VoidCallback? onNewQuiz;
  final VoidCallback? onRestart;
  final VoidCallback? onNextQuiz;
  final bool showNextQuiz;

  const QuizResume({
    super.key,
    required this.questions,
    required this.score,
    required this.correctAnswers,
    required this.totalQuestions,
    required this.timeSpent,
    this.quizTitle,
    this.completedAt,
    this.quizResult,
    this.onNewQuiz,
    this.onRestart,
    this.onNextQuiz,
    this.showNextQuiz = false,
  });

  /// Formate le temps dépensé en format MM:SS
  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '$minutes:${secs.toString().padLeft(2, '0')}';
  }

  /// Formate la date en format français
  String _formatDate(String? dateString) {
    if (dateString == null) return 'Aujourd\'hui';
    try {
      final date = DateTime.parse(dateString);
      const months = [
        'janvier',
        'février',
        'mars',
        'avril',
        'mai',
        'juin',
        'juillet',
        'août',
        'septembre',
        'octobre',
        'novembre',
        'décembre',
      ];
      return '${date.day} ${months[date.month - 1]} ${date.year}';
    } catch (e) {
      return 'Aujourd\'hui';
    }
  }

  /// Extrait le texte d'une réponse (Answer object ou string)
  String _extractAnswerText(dynamic answer) {
    if (answer == null) return '';
    if (answer is String) return answer;
    if (answer is Answer) return answer.text;
    if (answer is Map) {
      return (answer['text'] ?? answer['label'] ?? answer.toString()) as String;
    }
    return answer.toString();
  }

  /// Formate la réponse correcte pour l'affichage
  String _getFormattedCorrectAnswer(Question question) {
    if (question.correctAnswers == null) return 'N/A';

    if (question.correctAnswers is List) {
      final list = question.correctAnswers as List;
      if (list.isEmpty) return 'N/A';
      return list
          .map((a) => _extractAnswerText(a))
          .where((text) => text.isNotEmpty)
          .join(', ');
    }

    if (question.correctAnswers is Map) {
      final map = question.correctAnswers as Map;
      return map.values
          .map((v) => _extractAnswerText(v))
          .where((text) => text.isNotEmpty)
          .join(', ');
    }

    return _extractAnswerText(question.correctAnswers);
  }

  /// Formate la réponse utilisateur pour l'affichage
  String _getFormattedUserAnswer(Question question) {
    if (question.selectedAnswers == null) return 'Non répondue';

    if (question.selectedAnswers is List) {
      final list = question.selectedAnswers as List;
      if (list.isEmpty) return 'Non répondue';
      return list
          .map((a) => _extractAnswerText(a))
          .where((text) => text.isNotEmpty)
          .join(', ');
    }

    if (question.selectedAnswers is Map) {
      final map = question.selectedAnswers as Map;
      return map.values
          .map((v) => _extractAnswerText(v))
          .where((text) => text.isNotEmpty)
          .join(', ');
    }

    return _extractAnswerText(question.selectedAnswers);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final playedQuestions =
        questions.where((q) {
          if (q.selectedAnswers == null) return false;
          if (q.selectedAnswers is List) {
            return (q.selectedAnswers as List).isNotEmpty;
          }
          if (q.selectedAnswers is Map) {
            return (q.selectedAnswers as Map).isNotEmpty;
          }
          return true;
        }).toList();

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Statistiques principales
            _buildStatisticsHeader(context, theme, playedQuestions),
            const SizedBox(height: 24),

            // Détail des réponses
            _buildAnswersDetails(context, theme, playedQuestions),
            const SizedBox(height: 24),

            // Actions footer
            _buildFooterActions(context, theme),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticsHeader(
    BuildContext context,
    ThemeData theme,
    List<Question> playedQuestions,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Titre
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                Icons.trending_up,
                size: 16,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Résultats du quiz',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Cartes de résumé
        Row(
          children: [
            Expanded(
              child: _buildScoreCard(
                context,
                theme,
                'Bravo !',
                '${correctAnswers * 2} pts',
                Icons.emoji_events,
                Colors.amber,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                children: [
                  _buildStatChip(
                    context,
                    theme,
                    Icons.check_circle,
                    'Bonnes réponses',
                    '$correctAnswers/${playedQuestions.length}',
                    Colors.green,
                  ),
                  const SizedBox(height: 8),
                  _buildStatChip(
                    context,
                    theme,
                    Icons.schedule,
                    'Temps',
                    _formatTime(timeSpent),
                    Colors.amber,
                  ),
                  const SizedBox(height: 8),
                  _buildStatChip(
                    context,
                    theme,
                    Icons.star,
                    'Score',
                    '$score pts',
                    Colors.indigo,
                  ),
                  const SizedBox(height: 8),
                  _buildStatChip(
                    context,
                    theme,
                    Icons.calendar_today,
                    'Date',
                    _formatDate(completedAt),
                    Colors.purple,
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildScoreCard(
    BuildContext context,
    ThemeData theme,
    String title,
    String score,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 32, color: color),
          const SizedBox(height: 8),
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            score,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(
    BuildContext context,
    ThemeData theme,
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Icon(icon, size: 14, color: color),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: Colors.grey,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  value,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnswersDetails(
    BuildContext context,
    ThemeData theme,
    List<Question> playedQuestions,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Détail des réponses',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          'Revoyez chaque question et vos réponses',
          style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
        ),
        const SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: playedQuestions.length,
          itemBuilder: (context, index) {
            final question = playedQuestions[index];
            final isCorrect = question.isCorrect ?? false;
            return _buildQuestionCard(
              context,
              theme,
              question,
              index + 1,
              isCorrect,
              index,
            );
          },
        ),
      ],
    );
  }

  Widget _buildQuestionCard(
    BuildContext context,
    ThemeData theme,
    Question question,
    int questionNumber,
    bool isCorrect,
    int index,
  ) {
    final bgColor =
        index % 2 == 0 ? Colors.grey.withValues(alpha: 0.05) : Colors.white;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '$questionNumber',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  question.text,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildAnswerBox(
                  context,
                  theme,
                  'Bonne réponse:',
                  _getFormattedCorrectAnswer(question),
                  true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildAnswerBox(
                  context,
                  theme,
                  'Votre réponse:',
                  _getFormattedUserAnswer(question),
                  isCorrect,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAnswerBox(
    BuildContext context,
    ThemeData theme,
    String label,
    String answer,
    bool isCorrect,
  ) {
    final icon = isCorrect ? Icons.check_circle : Icons.close;
    final color = isCorrect ? Colors.green : Colors.red;

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 10, color: color),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.grey,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            answer,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: color,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildFooterActions(BuildContext context, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: const Border(
          top: BorderSide(color: Color.fromARGB(51, 158, 158, 158)),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  context,
                  theme,
                  'Nouveau quiz',
                  Icons.arrow_back,
                  Colors.orange,
                  onNewQuiz,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  context,
                  theme,
                  'Recommencer',
                  Icons.refresh,
                  Colors.blue,
                  onRestart,
                ),
              ),
            ],
          ),
          if (showNextQuiz) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: _buildActionButton(
                context,
                theme,
                'Quiz suivant',
                Icons.play_arrow,
                Colors.green,
                onNextQuiz,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    ThemeData theme,
    String label,
    IconData icon,
    Color color,
    VoidCallback? onPressed,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
