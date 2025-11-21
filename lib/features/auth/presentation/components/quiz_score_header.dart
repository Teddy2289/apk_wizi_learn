import 'package:flutter/material.dart';

class QuizScoreHeader extends StatelessWidget {
  final int score;
  final int correctAnswers;
  final int totalQuestions;
  final int timeSpent;

  const QuizScoreHeader({
    super.key,
    required this.score,
    required this.correctAnswers,
    required this.totalQuestions,
    required this.timeSpent,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text('Score Final', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildScoreItem(context, "$score", "Points"),
                _buildScoreItem(context, "$correctAnswers/5", "Réponses"),
                _buildScoreItem(context, "${timeSpent}s", "Temps"),
              ],
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: correctAnswers / totalQuestions,
              backgroundColor: Colors.grey[200],
              color: _getProgressColor(correctAnswers / totalQuestions),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreItem(BuildContext context, String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }

  Color _getProgressColor(double ratio) {
    if (ratio > 0.75) return Colors.green;
    if (ratio > 0.5) return Colors.lightGreen;
    if (ratio > 0.25) return Colors.orange;
    return Colors.red;
  }
}