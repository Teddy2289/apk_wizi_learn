import 'package:flutter/material.dart';
import 'package:wizi_learn/features/auth/data/models/stats_model.dart';

class QuizStatsWidget extends StatelessWidget {
  final QuizStats stats;

  const QuizStatsWidget({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.width < 600;

    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
        child: Column(
          children: [
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              color: Theme.of(context).colorScheme.surfaceVariant,
              child: Padding(
                padding: const EdgeInsets.all(16), // Réduit de 20 à 16
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Vos Performances',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: isSmallScreen ? 18 : 20,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildCompactStatCard(
                            context,
                            Icons.assignment_turned_in,
                            'Quiz complétés',
                            stats.totalQuizzes.toString(),
                            Colors.blueAccent,
                          ),
                          const SizedBox(width: 12),
                          _buildCompactStatCard(
                            context,
                            Icons.star_rate_rounded,
                            'Score moyen',
                            '${stats.averageScore.toStringAsFixed(1)}%',
                            Colors.amber,
                          ),
                          const SizedBox(width: 12),
                          _buildCompactStatCard(
                            context,
                            Icons.bolt_rounded,
                            'Points totaux',
                            stats.totalPoints.toString(),
                            Colors.greenAccent,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),
            // Category stats
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              color: Theme.of(context).colorScheme.surfaceVariant,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Par Catégorie',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: isSmallScreen ? 18 : 20,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...stats.categoryStats.map(
                      (category) => _buildCategoryItem(context, category),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Level progress
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              color: Theme.of(context).colorScheme.surfaceVariant,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Progression par Niveau',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: isSmallScreen ? 18 : 20,                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildLevelProgress(context, stats.levelProgress),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    IconData icon,
    String title,
    String value,
    Color color,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryItem(BuildContext context, CategoryStat category) {
    final percentage = (category.quizCount / stats.totalQuizzes * 100)
        .toStringAsFixed(1);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                category.category,
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              Text(
                '$percentage%',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: category.quizCount / stats.totalQuizzes,
            backgroundColor: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(4),
            minHeight: 8,
            valueColor: AlwaysStoppedAnimation<Color>(
              Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${category.quizCount} quiz',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
              Text(
                'Moyenne: ${category.averageScore.toStringAsFixed(1)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }


// Version compacte des cartes de statistiques
  Widget _buildCompactStatCard(
      BuildContext context,
      IconData icon,
      String title,
      String value,
      Color color,
      ) {
    return Container(
      width: 120, // Largeur fixe pour uniformité
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
            maxLines: 2,
          ),
        ],
      ),
    );
  }

  Widget _buildLevelProgress(BuildContext context, LevelProgress progress) {
    return Column(
      children: [
        _buildLevelProgressItem(
          context,
          'Débutant',
          progress.debutant,
          Colors.greenAccent,
        ),
        const SizedBox(height: 16),
        _buildLevelProgressItem(
          context,
          'Intermédiaire',
          progress.intermediaire,
          Colors.orangeAccent,
        ),
        const SizedBox(height: 16),
        _buildLevelProgressItem(
          context,
          'Avancé',
          progress.avance,
          Colors.redAccent,
        ),
      ],
    );
  }

  Widget _buildLevelProgressItem(
    BuildContext context,
    String level,
    LevelData data,
    Color color,
  ) {
    final total = stats.totalQuizzes;
    final percentage = total == 0 ? 0.0 : (data.completed / total * 100);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  level,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            Text(
              '${percentage.toStringAsFixed(1)}%',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: color),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: total == 0 ? 0.0 : data.completed / total,
          backgroundColor: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(4),
          minHeight: 8,
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${data.completed} quiz complétés',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            Text(
              'Moyenne: ${data.averageScore?.toStringAsFixed(1) ?? '0.0'}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
