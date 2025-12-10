import 'package:flutter/material.dart';

class ProfileStats extends StatelessWidget {
  final Map<String, dynamic>? profile;
  final Map<String, dynamic>? stats;
  final bool loading;

  const ProfileStats({
    Key? key,
    this.profile,
    this.stats,
    this.loading = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return _buildLoadingState();
    }

    if (stats == null) {
      return _buildEmptyState();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Titre
          Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.emoji_events, size: 32, color: Colors.amber[700]),
                const SizedBox(width: 8),
                Text(
                  'Mes statistiques',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF8B4513), // brown-shade
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Grille de statistiques
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 0.85,
            children: [
              _buildStatCard(
                context,
                label: 'Score total',
                icon: const Icon(Icons.trending_up, size: 32, color: Colors.orange),
                value: '${stats!['totalScore'] ?? 0}',
                backgroundColor: Colors.orange[50]!,
                animate: true,
              ),
              _buildStatCard(
                context,
                label: 'Quiz complétés',
                icon: const Icon(Icons.check_circle, size: 32, color: Colors.green),
                value: '${stats!['totalQuizzes'] ?? 0}',
                backgroundColor: Colors.green[50]!,
                animate: true,
              ),
              _buildStatCard(
                context,
                label: 'Score moyen',
                icon: const Icon(Icons.bar_chart, size: 32, color: Colors.blue),
                value: stats!['averageScore'] != null
                    ? '${(stats!['averageScore'] as num).round()}%'
                    : '0%',
                backgroundColor: Colors.blue[50]!,
                animate: true,
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Message de motivation
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.orange.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Text(
                'Continue comme ça, chaque quiz te rapproche du sommet ! 🚀',
                style: TextStyle(
                  color: Color(0xFFEA580C), // orange-700
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required String label,
    required Icon icon,
    required String value,
    required Color backgroundColor,
    bool animate = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icône
          SizedBox(
            width: 40,
            height: 40,
            child: icon,
          ),
          const SizedBox(height: 8),
          // Label
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: Colors.black54,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.5,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          // Valeur
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          const Text(
            'Chargement des statistiques...',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 16),
          ...List.generate(
            3,
            (index) => Container(
              height: 64,
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Text(
            'Statistiques de l\'utilisateur',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Aucune statistique disponible',
            style: TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
