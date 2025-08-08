import 'package:flutter/material.dart';
import 'package:wizi_learn/features/auth/data/models/stats_model.dart';

class QuizStatsWidget extends StatelessWidget {
  final QuizStats stats;

  const QuizStatsWidget({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;
    final isMediumScreen = screenWidth >= 600 && screenWidth < 900;
    final isLargeScreen = screenWidth >= 900;

    // Sécurisation des valeurs
    final totalQuizzes =
        (stats.totalQuizzes is int && stats.totalQuizzes > 0)
            ? stats.totalQuizzes
            : 0;
    final totalPoints =
        (stats.totalPoints is int && stats.totalPoints >= 0)
            ? stats.totalPoints
            : 0;
    final averageScore =
        (stats.averageScore is double && stats.averageScore >= 0)
            ? stats.averageScore
            : 0.0;

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
                padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Vos Performances',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize:
                            isSmallScreen
                                ? 18
                                : isMediumScreen
                                ? 20
                                : 22,
                      ),
                    ),
                    SizedBox(height: isSmallScreen ? 12 : 16),
                    // Affichage adaptatif selon la taille d'écran
                    if (isSmallScreen) ...[
                      // Version mobile : cartes empilées verticalement
                      Column(
                        children: [
                          _buildCompactStatCard(
                            context,
                            Icons.assignment_turned_in,
                            'Quiz complétés',
                            totalQuizzes > 0 ? totalQuizzes.toString() : '0',
                            Colors.blueAccent,
                            isSmallScreen: true,
                          ),
                          const SizedBox(height: 12),
                          _buildCompactStatCard(
                            context,
                            Icons.star_rate_rounded,
                            'Score moyen',
                            totalQuizzes > 0
                                ? '${averageScore.toStringAsFixed(1)}%'
                                : '-',
                            Colors.amber,
                            isSmallScreen: true,
                          ),
                          const SizedBox(height: 12),
                          _buildCompactStatCard(
                            context,
                            Icons.bolt_rounded,
                            'Points totaux',
                            totalPoints > 0 ? totalPoints.toString() : '0',
                            Colors.greenAccent,
                            isSmallScreen: true,
                          ),
                        ],
                      ),
                    ] else if (isMediumScreen) ...[
                      // Version tablette : cartes en ligne avec scroll horizontal
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildCompactStatCard(
                              context,
                              Icons.assignment_turned_in,
                              'Quiz complétés',
                              totalQuizzes > 0 ? totalQuizzes.toString() : '0',
                              Colors.blueAccent,
                              isSmallScreen: false,
                            ),
                            const SizedBox(width: 16),
                            _buildCompactStatCard(
                              context,
                              Icons.star_rate_rounded,
                              'Score moyen',
                              totalQuizzes > 0
                                  ? '${averageScore.toStringAsFixed(1)}%'
                                  : '-',
                              Colors.amber,
                              isSmallScreen: false,
                            ),
                            const SizedBox(width: 16),
                            _buildCompactStatCard(
                              context,
                              Icons.bolt_rounded,
                              'Points totaux',
                              totalPoints > 0 ? totalPoints.toString() : '0',
                              Colors.greenAccent,
                              isSmallScreen: false,
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      // Version desktop : cartes en ligne fixes
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Expanded(
                            child: _buildCompactStatCard(
                              context,
                              Icons.assignment_turned_in,
                              'Quiz complétés',
                              totalQuizzes > 0 ? totalQuizzes.toString() : '0',
                              Colors.blueAccent,
                              isSmallScreen: false,
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: _buildCompactStatCard(
                              context,
                              Icons.star_rate_rounded,
                              'Score moyen',
                              totalQuizzes > 0
                                  ? '${averageScore.toStringAsFixed(1)}%'
                                  : '-',
                              Colors.amber,
                              isSmallScreen: false,
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: _buildCompactStatCard(
                              context,
                              Icons.bolt_rounded,
                              'Points totaux',
                              totalPoints > 0 ? totalPoints.toString() : '0',
                              Colors.greenAccent,
                              isSmallScreen: false,
                            ),
                          ),
                        ],
                      ),
                    ],
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
                        fontSize: isSmallScreen ? 18 : 20,
                      ),
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
    final total =
        (stats.totalQuizzes is int && stats.totalQuizzes > 0)
            ? stats.totalQuizzes
            : 0;
    final quizCount =
        (category.quizCount is int && category.quizCount >= 0)
            ? category.quizCount
            : 0;
    final avg =
        (category.averageScore is double && category.averageScore >= 0)
            ? category.averageScore
            : 0.0;
    final percentage =
        total > 0 ? (quizCount / total * 100).toStringAsFixed(1) : '0.0';
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
            value: total > 0 ? quizCount / total : 0.0,
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
                '$quizCount quiz',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
              Text(
                'Moyenne: ${avg.toStringAsFixed(1)}',
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
    Color color, {
    bool isSmallScreen = false,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 900;

    // Calcul des dimensions adaptatives
    final cardWidth =
        isMobile
            ? double.infinity
            : isTablet
            ? 140.0
            : 160.0;
    final cardPadding = isMobile ? 16.0 : 20.0;
    final iconSize = isMobile ? 28.0 : 32.0;
    final titleFontSize = isMobile ? 14.0 : 16.0;
    final valueFontSize = isMobile ? 18.0 : 20.0;

    return Container(
      width: cardWidth,
      padding: EdgeInsets.all(cardPadding),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(isMobile ? 12 : 16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: iconSize),
          ),
          SizedBox(height: isMobile ? 12 : 16),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: valueFontSize,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontSize: titleFontSize,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
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
    final total =
        (stats.totalQuizzes is int && stats.totalQuizzes > 0)
            ? stats.totalQuizzes
            : 0;
    final completed =
        (data.completed is int && data.completed >= 0) ? data.completed : 0;
    final avg =
        (data.averageScore is double &&
                data.averageScore != null &&
                data.averageScore! >= 0)
            ? data.averageScore!
            : 0.0;
    final percentage = total == 0 ? 0.0 : (completed / total * 100);
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
          value: total == 0 ? 0.0 : completed / total,
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
              '$completed quiz complétés',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            Text(
              'Moyenne: ${avg.toStringAsFixed(1)}',
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
