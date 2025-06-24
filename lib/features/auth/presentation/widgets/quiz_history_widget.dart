import 'package:flutter/material.dart';
import 'package:wizi_learn/features/auth/data/models/stats_model.dart';

class QuizHistoryWidget extends StatelessWidget {
  final List<QuizHistory> history;

  const QuizHistoryWidget({super.key, required this.history});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.history, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Historique des Quiz',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (history.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: Text(
                    'Aucun quiz complété pour le moment',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              )
            else
              Column(
                children: history.map((item) => _buildHistoryItem(item)).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryItem(QuizHistory item) {
    final scorePercentage = (item.correctAnswers / item.totalQuestions) * 100;
    final completedDate = item.completedAt.split('T')[0];
    final completedTime = item.completedAt.split('T')[1].substring(0, 5);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    item.quiz.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                _buildScoreBadge(scorePercentage),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildInfoChip(
                  icon: Icons.category,
                  text: item.quiz.category,
                  color: Colors.blue.shade100,
                ),
                const SizedBox(width: 8),
                _buildInfoChip(
                  icon: Icons.star,
                  text: item.quiz.level,
                  color: Colors.amber.shade100,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Score: ${item.correctAnswers}/${item.totalQuestions}',
                  style: TextStyle(
                    color: Colors.grey.shade700,
                  ),
                ),
                Text(
                    'Durée: ${item.timeSpent ~/ 60}m ${item.timeSpent % 60}s',
                  style: TextStyle(
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.access_time, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  '$completedDate à $completedTime',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreBadge(double percentage) {
    final color = _getScoreColor(percentage / 100);
    final textColor = color.computeLuminance() > 0.5 ? Colors.black : Colors.white;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '${percentage.toStringAsFixed(0)}%',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Chip(
      backgroundColor: color,
      avatar: Icon(icon, size: 16),
      label: Text(
        text,
        style: const TextStyle(fontSize: 12),
      ),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
    );
  }

  Color _getScoreColor(double ratio) {
    if (ratio >= 0.8) return Colors.green.shade400;
    if (ratio >= 0.5) return Colors.orange.shade400;
    return Colors.red.shade400;
  }
}