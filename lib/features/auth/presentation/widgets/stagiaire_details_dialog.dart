import 'package:flutter/material.dart';

class StagiaireDetailsDialog extends StatelessWidget {
  final Map<String, dynamic> stagiaireData;

  const StagiaireDetailsDialog({
    super.key,
    required this.stagiaireData,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header avec avatar et nom
              Row(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundImage: stagiaireData['avatar'] != null
                        ? NetworkImage(stagiaireData['avatar'])
                        : null,
                    child: stagiaireData['avatar'] == null
                        ? Text(
                            stagiaireData['firstname']?[0]?.toUpperCase() ?? '?',
                            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                          )
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${stagiaireData['firstname']} ${stagiaireData['name']}',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Position #${stagiaireData['rang']} • ${stagiaireData['totalPoints']} points',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Formations
              if (stagiaireData['formations'] != null &&
                  (stagiaireData['formations'] as List).isNotEmpty) ...[
                const Text(
                  'Formations',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: (stagiaireData['formations'] as List)
                      .map((formation) => Chip(
                            label: Text(formation['titre'] ?? ''),
                            backgroundColor: Colors.blue[50],
                            labelStyle: TextStyle(color: Colors.blue[900]),
                          ))
                      .toList(),
                ),
                const SizedBox(height: 24),
              ],

              // Formateurs
              if (stagiaireData['formateurs'] != null &&
                  (stagiaireData['formateurs'] as List).isNotEmpty) ...[
                const Text(
                  'Formateurs',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: (stagiaireData['formateurs'] as List)
                      .map((formateur) => _buildFormateurChip(
                            formateur['prenom'] ?? '',
                            formateur['nom'] ?? '',
                            formateur['image'],
                          ))
                      .toList(),
                ),
                const SizedBox(height: 24),
              ],

              // Stats Quiz
              const Text(
                'Statistiques Quiz',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              // Cards stats
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      context,
                      'Points',
                      stagiaireData['totalPoints']?.toString() ?? '0',
                      Icons.star,
                      Colors.amber,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      context,
                      'Quiz',
                      '${stagiaireData['quizStats']?['totalCompleted'] ?? 0}/${stagiaireData['quizStats']?['totalQuiz'] ?? 0}',
                      Icons.quiz,
                      Colors.blue,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildStatCard(
                context,
                'Taux de Réussite',
                '${stagiaireData['quizStats']?['pourcentageReussite'] ?? 0}%',
                Icons.trending_up,
                Colors.green,
              ),
              const SizedBox(height: 16),

              // Par niveau
              _buildLevelProgress(
                'Débutant',
                stagiaireData['quizStats']?['byLevel']?['debutant']?['completed'] ?? 0,
                stagiaireData['quizStats']?['byLevel']?['debutant']?['total'] ?? 0,
                Colors.green,
              ),
              const SizedBox(height: 8),
              _buildLevelProgress(
                'Intermédiaire',
                stagiaireData['quizStats']?['byLevel']?['intermediaire']?['completed'] ?? 0,
                stagiaireData['quizStats']?['byLevel']?['intermediaire']?['total'] ?? 0,
                Colors.orange,
              ),
              const SizedBox(height: 8),
              _buildLevelProgress(
                'Expert',
                stagiaireData['quizStats']?['byLevel']?['expert']?['completed'] ?? 0,
                stagiaireData['quizStats']?['byLevel']?['expert']?['total'] ?? 0,
                Colors.red,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormateurChip(String prenom, String nom, String? image) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundImage: image != null ? NetworkImage(image) : null,
            child: image == null ? Text(prenom[0]) : null,
          ),
          const SizedBox(width: 8),
          Text(
            '$prenom $nom',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.1), color.withOpacity(0.2)],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: Colors.grey[700],
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color.withOpacity(0.9),
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLevelProgress(String level, int completed, int total, Color color) {
    final percentage = total > 0 ? (completed / total) : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              level,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '$completed/$total',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: percentage,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 10,
          ),
        ),
      ],
    );
  }
}

// Helper function pour filtrer les quiz par niveau selon les points
List<T> filterQuizByPoints<T extends Map<String, dynamic>>(
  List<T> quizzes,
  int totalPoints,
) {
  List<String> accessibleLevels;
  
  if (totalPoints < 50) {
    accessibleLevels = ['debutant'];
  } else if (totalPoints < 100) {
    accessibleLevels = ['debutant', 'intermediaire'];
  } else {
    accessibleLevels = ['debutant', 'intermediaire', 'expert'];
  }

  return quizzes.where((quiz) {
    final niveau = (quiz['niveau'] as String?)?.toLowerCase() ?? 'debutant';
    return accessibleLevels.contains(niveau);
  }).toList();
}

// Widget pour afficher un badge de niveau
class QuizLevelBadge extends StatelessWidget {
  final int totalPoints;

  const QuizLevelBadge({super.key, required this.totalPoints});

  String get currentLevel {
    if (totalPoints >= 100) return 'Expert';
    if (totalPoints >= 50) return 'Intermédiaire';
    return 'Débutant';
  }

  Color get levelColor {
    if (totalPoints >= 100) return Colors.red;
    if (totalPoints >= 50) return Colors.orange;
    return Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [levelColor.withOpacity(0.1), levelColor.withOpacity(0.2)],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: levelColor.withOpacity(0.3), width: 2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star, color: levelColor, size: 24),
          const SizedBox(width: 8),
          Text(
            '$totalPoints',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: levelColor,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            'points',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
          Container(
            width: 1,
            height: 24,
            margin: const EdgeInsets.symmetric(horizontal: 12),
            color: Colors.grey[400],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Niveau actuel',
                style: TextStyle(fontSize: 10, color: Colors.grey[600]),
              ),
              Text(
                currentLevel,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: levelColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Widget pour afficher un message de niveau bloqué
class LockedLevelNotice extends StatelessWidget {
  final String nextLevel;
  final int pointsNeeded;

  const LockedLevelNotice({
    super.key,
    required this.nextLevel,
    required this.pointsNeeded,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.grey[50]!, Colors.grey[100]!],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[300]!, width: 2),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.lock, color: Colors.grey[600], size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Quiz $nextLevel verrouillés',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Continuez à progresser pour débloquer les quiz de niveau $nextLevel.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(Icons.trending_up, color: Colors.blue[600], size: 18),
                    const SizedBox(width: 6),
                    RichText(
                      text: TextSpan(
                        style: const TextStyle(fontSize: 14),
                        children: [
                          TextSpan(
                            text: 'Plus que ',
                            style: TextStyle(color: Colors.grey[700]),
                          ),
                          TextSpan(
                            text: '$pointsNeeded',
                            style: TextStyle(
                              color: Colors.blue[600],
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          TextSpan(
                            text: ' points',
                            style: TextStyle(color: Colors.blue[600], fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
