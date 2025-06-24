import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:wizi_learn/features/auth/data/models/stats_model.dart';

class QuizStatsWidget extends StatelessWidget {
  final QuizStats stats;

  const QuizStatsWidget({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Card(
        margin: const EdgeInsets.all(12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader('📊 Mes Statistiques'),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatTile(Icons.check_circle, 'Quiz\ncomplétés', stats.totalQuizzes.toString(), Colors.blue),
                  _buildStatTile(Icons.star, 'Score\nmoyen', '${stats.averageScore.toStringAsFixed(2)}%', Colors.orange),
                  _buildStatTile(Icons.emoji_events, 'Points\ntotaux', stats.totalPoints.toString(), Colors.green),
                ],
              ),
              const SizedBox(height: 24),
              _buildSectionHeader('📚 Statistiques par Catégorie'),
              const SizedBox(height: 8),
              ...stats.categoryStats.map((category) => _buildCategoryStat(category)),
              const SizedBox(height: 24),
              _buildSectionHeader('🎯 Progression par Niveau'),
              const SizedBox(height: 8),
              _buildLevelProgress(stats.levelProgress),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildStatTile(IconData icon, String label, String value, Color color) {
    return Column(
      children: [
        CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          radius: 24,
          child: Icon(icon, color: color, size: 28),
        ),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 4),
        Text(label, textAlign: TextAlign.center, style: const TextStyle(color: Colors.black54)),
      ],
    );
  }

  Widget _buildCategoryStat(CategoryStat category) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            category.category,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: stats.totalQuizzes == 0 ? 0 : category.quizCount / stats.totalQuizzes,
            backgroundColor: Colors.grey[200],
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
            minHeight: 6,
          ),
          const SizedBox(height: 4),
          Text('${category.quizCount} quiz - Moyenne: ${category.averageScore.toStringAsFixed(2)}'),
        ],
      ),
    );
  }

  Widget _buildLevelProgress(LevelProgress progress) {
    return Column(
      children: [
        _buildLevelItem('Débutant', progress.debutant),
        _buildLevelItem('Intermédiaire', progress.intermediaire),
        _buildLevelItem('Avancé', progress.avance),
      ],
    );
  }

  Widget _buildLevelItem(String label, LevelData data) {
    final total = stats.totalQuizzes;
    final progressValue = total == 0 ? 0.0 : data.completed / total;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: progressValue,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(_getLevelColor(label)),
            minHeight: 6,
          ),
          const SizedBox(height: 4),
          Text('${data.completed} quiz - Moyenne: ${data.averageScore?.toStringAsFixed(2) ?? 'N/A'}'),
        ],
      ),
    );
  }

  Color _getLevelColor(String level) {
    switch (level) {
      case 'Débutant':
        return Colors.green;
      case 'Intermédiaire':
        return Colors.orange;
      case 'Avancé':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }
}
