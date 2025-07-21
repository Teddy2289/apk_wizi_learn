import 'package:flutter/material.dart';
import 'package:wizi_learn/features/auth/data/models/question_model.dart';

class QuizDetailPage extends StatelessWidget {
  final String quizTitle;
  final int score;
  final int totalQuestions;
  final int correctAnswers;
  final int timeSpent;
  final DateTime completedAt;
  final List<Question> questions;

  const QuizDetailPage({
    Key? key,
    required this.quizTitle,
    required this.score,
    required this.totalQuestions,
    required this.correctAnswers,
    required this.timeSpent,
    required this.completedAt,
    required this.questions,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final percent = totalQuestions > 0 ? (correctAnswers / totalQuestions) : 0.0;
    final stars = percent >= 1.0 ? 3 : percent >= 0.7 ? 2 : percent >= 0.4 ? 1 : 0;
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('Détail du Quiz'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Résumé visuel
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(quizTitle, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      ...List.generate(3, (i) => Icon(Icons.star, color: i < stars ? Colors.amber : Colors.grey[300])),
                      const SizedBox(width: 16),
                      Text('$score pts', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.timer, size: 18, color: theme.colorScheme.primary),
                      const SizedBox(width: 4),
                      Text('${timeSpent}s'),
                      const SizedBox(width: 16),
                      Icon(Icons.calendar_today, size: 18, color: theme.colorScheme.primary),
                      const SizedBox(width: 4),
                      Text('${completedAt.day}/${completedAt.month}/${completedAt.year}'),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text('Questions', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ...questions.map((q) => _buildQuestionFeedback(q, theme)).toList(),
          const SizedBox(height: 24),
          _buildAdviceSection(theme),
        ],
      ),
    );
  }

  Widget _buildQuestionFeedback(Question q, ThemeData theme) {
    final isCorrect = q.isCorrect ?? false;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 1,
      child: ListTile(
        leading: Icon(isCorrect ? Icons.check_circle : Icons.cancel, color: isCorrect ? Colors.green : Colors.red),
        title: Text(q.text, style: theme.textTheme.bodyLarge),
        subtitle: q.selectedAnswers != null
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text('Votre réponse : ${q.selectedAnswers?.join(', ') ?? '-'}'),
                  if (!isCorrect && q.correctAnswers != null)
                    Text('Bonne réponse : ${q.correctAnswers?.join(', ')}', style: const TextStyle(color: Colors.green)),
                ],
              )
            : null,
      ),
    );
  }

  Widget _buildAdviceSection(ThemeData theme) {
    // Exemple de feedback simple, à personnaliser selon les stats
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: theme.colorScheme.primary.withOpacity(0.08),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Conseils personnalisés', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('• Points forts : Bravo pour les questions réussies !'),
            Text('• À retravailler : Revois les questions où tu as eu des erreurs.'),
            // Tu peux ajouter ici des conseils plus avancés selon les stats
          ],
        ),
      ),
    );
  }
} 