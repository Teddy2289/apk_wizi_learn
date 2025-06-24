import 'package:flutter/material.dart';
import 'package:wizi_learn/core/constants/app_constants.dart';
import 'package:wizi_learn/features/auth/data/models/stats_model.dart';

class GlobalRankingWidget extends StatelessWidget {
  final List<GlobalRanking> rankings;

  const GlobalRankingWidget({super.key, required this.rankings});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16.0),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.leaderboard, color: Colors.blue, size: 24),
                const SizedBox(width: 8),
                Text(
                  'Classement Global',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (rankings.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Center(
                  child: Text(
                    'Aucun classement disponible',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              )
            else
              Column(
                children: [
                  _buildHeader(),
                  const SizedBox(height: 8),
                  ...rankings.map((ranking) => _buildRankingItem(ranking)),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 8.0),
      child: Row(
        children: [
          SizedBox(width: 40, child: Text('Rang', style: _headerTextStyle)),
          SizedBox(width: 16),
          Expanded(flex: 2, child: Text('Participant', style: _headerTextStyle)),
          Expanded(child: Text('Quiz', style: _headerTextStyle)),
          Expanded(child: Text('Points', style: _headerTextStyle)),
        ],
      ),
    );
  }

  Widget _buildRankingItem(GlobalRanking ranking) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            // Rang
            SizedBox(
              width: 40,
              child: Center(
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: _getRankColor(ranking.rang),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${ranking.rang}',
                      style: TextStyle(
                        color: _getRankTextColor(ranking.rang),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Photo + Nom
            Expanded(
              flex: 2,
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundImage: NetworkImage(
                      '${AppConstants.baseUrlImg}/${ranking.stagiaire.image}',
                    ),
                    radius: 20,
                    onBackgroundImageError: (_, __) => const Icon(Icons.person),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    ranking.stagiaire.prenom,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // Nombre de quiz
            Expanded(
              child: Center(
                child: Text(
                  '${ranking.quizCount}',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
            ),
            // Points
            Expanded(
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${ranking.totalPoints} ',
                    style: TextStyle(
                      color: Colors.blue.shade800,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return Colors.amber.shade300;
      case 2:
        return Colors.grey.shade300;
      case 3:
        return Colors.orange.shade300;
      default:
        return Colors.grey.shade200;
    }
  }

  Color _getRankTextColor(int rank) {
    switch (rank) {
      case 1:
        return Colors.amber.shade900;
      case 2:
        return Colors.grey.shade800;
      case 3:
        return Colors.orange.shade900;
      default:
        return Colors.grey.shade700;
    }
  }
}

const _headerTextStyle = TextStyle(
  fontWeight: FontWeight.w600,
  color: Colors.grey,
  fontSize: 12,
);