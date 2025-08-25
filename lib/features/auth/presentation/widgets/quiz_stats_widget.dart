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

    // Sécurisation des valeurs
    final totalQuizzes = stats.totalQuizzes > 0 ? stats.totalQuizzes : 0;
    final totalPoints = stats.totalPoints >= 0 ? stats.totalPoints : 0;
    final averageScore = stats.averageScore >= 0 ? stats.averageScore : 0.0;

    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
        child: Column(
          children: [
            // Bloc performance global - design sobre
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              color: Theme.of(context).colorScheme.surface,
              child: Padding(
                padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Vos performances',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.w700,
                        fontSize:
                            isSmallScreen
                                ? 18
                                : isMediumScreen
                                ? 20
                                : 22,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Stat cards adaptatives et interactives
                    if (isSmallScreen) ...[
                      Column(
                        children: [
                          _buildCompactStatCard(
                            context,
                            Icons.assignment_turned_in,
                            'Quiz complétés',
                            totalQuizzes > 0 ? totalQuizzes.toString() : '0',
                            Theme.of(context).colorScheme.primary,
                            isSmallScreen: true,
                            onTap:
                                () => _showInfoSheet(
                                  context,
                                  'Quiz complétés',
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _buildSheetRow('Total', '$totalQuizzes'),
                                      _buildSheetRow(
                                        'Score moyen',
                                        '${averageScore.toStringAsFixed(1)}%',
                                      ),
                                      _buildSheetRow(
                                        'Points totaux',
                                        totalPoints.toString(),
                                      ),
                                    ],
                                  ),
                                ),
                          ),
                          const SizedBox(height: 12),
                          _buildCompactStatCard(
                            context,
                            Icons.star_rate_rounded,
                            'Score moyen',
                            totalQuizzes > 0
                                ? '${averageScore.toStringAsFixed(1)}%'
                                : '-',
                            Colors.amber.shade700,
                            isSmallScreen: true,
                            onTap:
                                () => _showInfoSheet(
                                  context,
                                  'Score moyen',
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _buildSheetRow(
                                        'Score moyen',
                                        totalQuizzes > 0
                                            ? '${averageScore.toStringAsFixed(1)}%'
                                            : '-',
                                      ),
                                      _buildSheetRow(
                                        'Quiz complétés',
                                        '$totalQuizzes',
                                      ),
                                    ],
                                  ),
                                ),
                          ),
                          const SizedBox(height: 12),
                          _buildCompactStatCard(
                            context,
                            Icons.bolt_rounded,
                            'Points totaux',
                            totalPoints > 0 ? totalPoints.toString() : '0',
                            Colors.green.shade700,
                            isSmallScreen: true,
                            onTap:
                                () => _showInfoSheet(
                                  context,
                                  'Points totaux',
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _buildSheetRow(
                                        'Points totaux',
                                        totalPoints.toString(),
                                      ),
                                      _buildSheetRow(
                                        'Quiz complétés',
                                        '$totalQuizzes',
                                      ),
                                    ],
                                  ),
                                ),
                          ),
                        ],
                      ),
                    ] else if (isMediumScreen) ...[
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
                              Theme.of(context).colorScheme.primary,
                              isSmallScreen: false,
                              onTap:
                                  () => _showInfoSheet(
                                    context,
                                    'Quiz complétés',
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        _buildSheetRow(
                                          'Total',
                                          '$totalQuizzes',
                                        ),
                                        _buildSheetRow(
                                          'Score moyen',
                                          '${averageScore.toStringAsFixed(1)}%',
                                        ),
                                        _buildSheetRow(
                                          'Points totaux',
                                          totalPoints.toString(),
                                        ),
                                      ],
                                    ),
                                  ),
                            ),
                            const SizedBox(width: 16),
                            _buildCompactStatCard(
                              context,
                              Icons.star_rate_rounded,
                              'Score moyen',
                              totalQuizzes > 0
                                  ? '${averageScore.toStringAsFixed(1)}%'
                                  : '-',
                              Colors.amber.shade700,
                              isSmallScreen: false,
                              onTap:
                                  () => _showInfoSheet(
                                    context,
                                    'Score moyen',
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        _buildSheetRow(
                                          'Score moyen',
                                          totalQuizzes > 0
                                              ? '${averageScore.toStringAsFixed(1)}%'
                                              : '-',
                                        ),
                                        _buildSheetRow(
                                          'Quiz complétés',
                                          '$totalQuizzes',
                                        ),
                                      ],
                                    ),
                                  ),
                            ),
                            const SizedBox(width: 16),
                            _buildCompactStatCard(
                              context,
                              Icons.bolt_rounded,
                              'Points totaux',
                              totalPoints > 0 ? totalPoints.toString() : '0',
                              Colors.green.shade700,
                              isSmallScreen: false,
                              onTap:
                                  () => _showInfoSheet(
                                    context,
                                    'Points totaux',
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        _buildSheetRow(
                                          'Points totaux',
                                          totalPoints.toString(),
                                        ),
                                        _buildSheetRow(
                                          'Quiz complétés',
                                          '$totalQuizzes',
                                        ),
                                      ],
                                    ),
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Expanded(
                            child: _buildCompactStatCard(
                              context,
                              Icons.assignment_turned_in,
                              'Quiz complétés',
                              totalQuizzes > 0 ? totalQuizzes.toString() : '0',
                              Theme.of(context).colorScheme.primary,
                              isSmallScreen: false,
                              onTap:
                                  () => _showInfoSheet(
                                    context,
                                    'Quiz complétés',
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        _buildSheetRow(
                                          'Total',
                                          '$totalQuizzes',
                                        ),
                                        _buildSheetRow(
                                          'Score moyen',
                                          '${averageScore.toStringAsFixed(1)}%',
                                        ),
                                        _buildSheetRow(
                                          'Points totaux',
                                          totalPoints.toString(),
                                        ),
                                      ],
                                    ),
                                  ),
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
                              Colors.amber.shade700,
                              isSmallScreen: false,
                              onTap:
                                  () => _showInfoSheet(
                                    context,
                                    'Score moyen',
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        _buildSheetRow(
                                          'Score moyen',
                                          totalQuizzes > 0
                                              ? '${averageScore.toStringAsFixed(1)}%'
                                              : '-',
                                        ),
                                        _buildSheetRow(
                                          'Quiz complétés',
                                          '$totalQuizzes',
                                        ),
                                      ],
                                    ),
                                  ),
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: _buildCompactStatCard(
                              context,
                              Icons.bolt_rounded,
                              'Points totaux',
                              totalPoints > 0 ? totalPoints.toString() : '0',
                              Colors.green.shade700,
                              isSmallScreen: false,
                              onTap:
                                  () => _showInfoSheet(
                                    context,
                                    'Points totaux',
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        _buildSheetRow(
                                          'Points totaux',
                                          totalPoints.toString(),
                                        ),
                                        _buildSheetRow(
                                          'Quiz complétés',
                                          '$totalQuizzes',
                                        ),
                                      ],
                                    ),
                                  ),
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

            // Level progress sobres et interactives
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              color: Theme.of(context).colorScheme.surface,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Progression par niveau',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.w700,
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

  // Version compacte interactive des cartes de statistiques
  Widget _buildCompactStatCard(
    BuildContext context,
    IconData icon,
    String title,
    String value,
    Color color, {
    bool isSmallScreen = false,
    VoidCallback? onTap,
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
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(cardPadding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(isMobile ? 12 : 16),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.08),
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
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.7),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (onTap != null) ...[
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.touch_app, size: 16),
                    SizedBox(width: 6),
                    Text('En savoir plus', style: TextStyle(fontSize: 12)),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLevelProgress(BuildContext context, LevelProgress progress) {
    return Column(
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap:
              () => _showInfoSheet(
                context,
                'Débutant',
                _buildLevelDetail(context, 'Débutant', progress.debutant),
              ),
          child: _buildLevelProgressItem(
            context,
            'Débutant',
            progress.debutant,
            Colors.greenAccent,
          ),
        ),
        const SizedBox(height: 16),
        InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap:
              () => _showInfoSheet(
                context,
                'Intermédiaire',
                _buildLevelDetail(
                  context,
                  'Intermédiaire',
                  progress.intermediaire,
                ),
              ),
          child: _buildLevelProgressItem(
            context,
            'Intermédiaire',
            progress.intermediaire,
            Colors.orangeAccent,
          ),
        ),
        const SizedBox(height: 16),
        InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap:
              () => _showInfoSheet(
                context,
                'Avancé',
                _buildLevelDetail(context, 'Avancé', progress.avance),
              ),
          child: _buildLevelProgressItem(
            context,
            'Avancé',
            progress.avance,
            Colors.redAccent,
          ),
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
    final total = stats.totalQuizzes > 0 ? stats.totalQuizzes : 0;
    final completed = data.completed >= 0 ? data.completed : 0;
    final avg =
        (data.averageScore != null && data.averageScore! >= 0)
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
            Row(
              children: [
                Text(
                  '${percentage.toStringAsFixed(1)}%',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: color),
                ),
                const SizedBox(width: 6),
                const Icon(Icons.touch_app, size: 16),
              ],
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

  // Helpers pour feuilles d’information
  void _showInfoSheet(BuildContext context, String title, Widget content) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder:
          (_) => SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.insights,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          title,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  content,
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildSheetRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value),
        ],
      ),
    );
  }

  Widget _buildLevelDetail(BuildContext context, String level, LevelData data) {
    final completed = data.completed >= 0 ? data.completed : 0;
    final avg =
        (data.averageScore != null && data.averageScore! >= 0)
            ? data.averageScore!
            : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSheetRow('Niveau', level),
        _buildSheetRow('Quiz complétés', '$completed'),
        _buildSheetRow('Score moyen', '${avg.toStringAsFixed(1)}%'),
      ],
    );
  }
}
