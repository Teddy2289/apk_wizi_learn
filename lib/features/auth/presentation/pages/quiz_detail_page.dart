import 'package:flutter/material.dart';
import 'package:wizi_learn/features/auth/data/models/question_model.dart';
import 'package:intl/intl.dart';

class QuizDetailPage extends StatelessWidget {
  final String quizTitle;
  final int score;
  final int totalQuestions;
  final int correctAnswers;
  final int timeSpent;
  final DateTime completedAt;
  final List<Question> questions;

  const QuizDetailPage({
    super.key,
    required this.quizTitle,
    required this.score,
    required this.totalQuestions,
    required this.correctAnswers,
    required this.timeSpent,
    required this.completedAt,
    required this.questions,
  });

  @override
  Widget build(BuildContext context) {
    final percent =
        totalQuestions > 0 ? (correctAnswers / totalQuestions) : 0.0;
    final stars =
        percent >= 1.0
            ? 3
            : percent >= 0.7
            ? 2
            : percent >= 0.4
            ? 1
            : 0;
    final theme = Theme.of(context);

    // Filtrer seulement les questions qui ont été jouées (qui ont une réponse sélectionnée)
    final playedQuestions =
        questions.where((q) => q.selectedAnswers != null).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Détail du Quiz'), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Résumé visuel
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    quizTitle,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      ...List.generate(
                        3,
                        (i) => Icon(
                          Icons.star,
                          color: i < stars ? Colors.amber : Colors.grey[300],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        '$score pts',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.timer,
                        size: 18,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 4),
                      Text('${timeSpent}s'),
                      const SizedBox(width: 16),
                      Icon(
                        Icons.calendar_today,
                        size: 18,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        DateFormat('dd/MM/yyyy à HH:mm').format(completedAt),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Statistiques détaillées
                  Row(
                    children: [
                      _buildStatItem(
                        context,
                        Icons.check_circle,
                        'Bonnes réponses',
                        '$correctAnswers/$totalQuestions',
                        Colors.green,
                      ),
                      const SizedBox(width: 16),
                      _buildStatItem(
                        context,
                        Icons.percent,
                        'Taux de réussite',
                        '${(percent * 100).round()}%',
                        theme.colorScheme.primary,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Questions jouées (${playedQuestions.length})',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          if (playedQuestions.isNotEmpty)
            ...playedQuestions.map((q) => _buildQuestionFeedback(q, theme))
          else
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Aucune question jouée disponible',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 24),
          _buildAdviceSection(theme, percent),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(
              value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: color.withOpacity(0.8)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionFeedback(Question q, ThemeData theme) {
    final isCorrect = q.isCorrect ?? false;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isCorrect ? Icons.check_circle : Icons.cancel,
                  color: isCorrect ? Colors.green : Colors.red,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    q.text,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color:
                    isCorrect
                        ? Colors.green.withOpacity(0.1)
                        : Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color:
                      isCorrect
                          ? Colors.green.withOpacity(0.3)
                          : Colors.red.withOpacity(0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Votre réponse :',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    q.selectedAnswers?.join(', ') ?? 'Aucune réponse',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: isCorrect ? Colors.green : Colors.red,
                    ),
                  ),
                  if (!isCorrect && q.correctAnswers != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Bonne réponse :',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      q.correctAnswers?.join(', ') ?? '',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdviceSection(ThemeData theme, double percent) {
    String advice;
    Color adviceColor;

    if (percent >= 0.8) {
      advice =
          'Excellent travail ! Tu maîtrises bien ce sujet. Continue comme ça !';
      adviceColor = Colors.green;
    } else if (percent >= 0.6) {
      advice = 'Bon travail ! Quelques révisions et tu seras au top.';
      adviceColor = Colors.orange;
    } else if (percent >= 0.4) {
      advice =
          'Pas mal ! Continue à t\'entraîner pour améliorer tes résultats.';
      adviceColor = Colors.orange;
    } else {
      advice =
          'N\'abandonne pas ! Revois le cours et réessaie, tu vas y arriver !';
      adviceColor = Colors.red;
    }

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: adviceColor.withOpacity(0.08),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lightbulb, color: adviceColor),
                const SizedBox(width: 8),
                Text(
                  'Conseil personnalisé',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: adviceColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              advice,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: adviceColor.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
