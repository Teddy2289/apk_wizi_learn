import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:wizi_learn/core/network/api_client.dart';
import 'package:wizi_learn/features/auth/data/models/formation_ranking_model.dart';
import 'package:wizi_learn/features/auth/data/repositories/formation_ranking_repository.dart';

class FormationRankingPage extends StatefulWidget {
  final int formationId;
  final String formationTitle;

  const FormationRankingPage({
    required this.formationId,
    required this.formationTitle,
    Key? key,
  }) : super(key: key);

  @override
  State<FormationRankingPage> createState() => _FormationRankingPageState();
}

class _FormationRankingPageState extends State<FormationRankingPage> {
  late final FormationRankingRepository _repository;
  late Future<FormationRanking> _futureRanking;
  late Future<UserFormationRanking> _futureMyRanking;

  @override
  void initState() {
    super.initState();
    final apiClient = ApiClient(
      dio: Dio(),
      storage: const FlutterSecureStorage(),
    );
    _repository = FormationRankingRepository(apiClient: apiClient);
    _futureRanking = _repository.getFormationRanking(widget.formationId);
    _futureMyRanking = _repository.getMyRanking(widget.formationId);
  }

  Future<void> _onRefresh() async {
    setState(() {
      _futureRanking = _repository.getFormationRanking(widget.formationId);
      _futureMyRanking = _repository.getMyRanking(widget.formationId);
    });
  }

  Color _getRankColor(int rang) {
    switch (rang) {
      case 1:
        return const Color(0xFFFEB823); // Or vif
      case 2:
        return const Color(0xFF9CA3AF); // Argent
      case 3:
        return const Color(0xFFF59E0B); // Bronze
      case 4:
        return const Color(0xFF6B7280); // Gris
      case 5:
        return const Color(0xFF3B82F6); // Bleu
      default:
        return Colors.grey.shade300;
    }
  }

  IconData _getRankIcon(int rang) {
    switch (rang) {
      case 1:
        return Icons.emoji_events;
      case 2:
        return Icons.emoji_events_outlined;
      case 3:
        return Icons.emoji_events_rounded;
      default:
        return Icons.person;
    }
  }

  String _formatName(String prenom, String nom) {
    if (prenom.isEmpty && nom.isEmpty) return '';
    final initial = nom.isNotEmpty ? '${nom[0].toUpperCase()}.' : '';
    return '$prenom${initial.isNotEmpty ? ' $initial' : ''}'.trim();
  }

  @override
  Widget build(BuildContext context) {
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Classement - ${widget.formationTitle}',
          style: TextStyle(
            fontSize: isLandscape ? 16 : 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black87),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: Colors.grey.shade200),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: CustomScrollView(
          slivers: [
            // Mon classement section
            SliverToBoxAdapter(
              child: FutureBuilder<UserFormationRanking>(
                future: _futureMyRanking,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Container(
                      margin: const EdgeInsets.all(16),
                      child: const Center(child: CircularProgressIndicator()),
                    );
                  }

                  final myRanking = snapshot.data;
                  if (myRanking == null || !myRanking.hasParticipation) {
                    return Container(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.shade100),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue.shade700),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              myRanking?.message ?? 'Pas encore de participation',
                              style: TextStyle(color: Colors.blue.shade900),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.blue.shade500, Colors.blue.shade700],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.shade200,
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Votre classement',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${myRanking.rang} / ${myRanking.totalParticipants}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                const Text(
                                  'Points totaux',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  '${myRanking.totalPoints}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                const Text(
                                  'Quiz complétés',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  '${myRanking.quizCompletes} / ${myRanking.totalQuiz}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: (myRanking.pourcentageProgression ?? 0) / 100,
                            backgroundColor: Colors.white.withOpacity(0.3),
                            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                            minHeight: 8,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${myRanking.pourcentageProgression?.toStringAsFixed(1)}% de progression',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Classement général
            FutureBuilder<FormationRanking>(
              future: _futureRanking,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                if (snapshot.hasError) {
                  return SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline, size: 48, color: Colors.red.shade400),
                          const SizedBox(height: 16),
                          Text(
                            'Erreur lors du chargement',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            snapshot.error.toString(),
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final ranking = snapshot.data;
                if (ranking == null || ranking.classement.isEmpty) {
                  return SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.emoji_events, size: 64, color: Colors.grey.shade300),
                          const SizedBox(height: 16),
                          Text(
                            'Aucun classement disponible',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Soyez le premier à participer !',
                            style: TextStyle(color: Colors.grey.shade500),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final entry = ranking.classement[index];
                        final isTopThree = entry.rang <= 3;

                        return Card(
                          elevation: isTopThree ? 4 : 2,
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(
                              color: isTopThree ? _getRankColor(entry.rang) : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: Container(
                            decoration: isTopThree
                                ? BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        _getRankColor(entry.rang).withOpacity(0.1),
                                        _getRankColor(entry.rang).withOpacity(0.05),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                  )
                                : null,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              child: Row(
                                children: [
                                  // Badge de position
                                  Container(
                                    width: 52,
                                    height: 52,
                                    decoration: BoxDecoration(
                                      color: _getRankColor(entry.rang),
                                      shape: BoxShape.circle,
                                      boxShadow: isTopThree
                                          ? [
                                              BoxShadow(
                                                color: _getRankColor(entry.rang).withOpacity(0.4),
                                                blurRadius: 8,
                                                offset: const Offset(0, 2),
                                              ),
                                            ]
                                          : [],
                                    ),
                                    child: Center(
                                      child: isTopThree
                                          ? Icon(
                                              _getRankIcon(entry.rang),
                                              color: Colors.white,
                                              size: 28,
                                            )
                                          : Text(
                                              '${entry.rang}',
                                              style: const TextStyle(
                                                fontSize: 20,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  // Contenu
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _formatName(entry.prenom, entry.nom),
                                          style: TextStyle(
                                            fontWeight: isTopThree ? FontWeight.bold : FontWeight.w600,
                                            fontSize: 17,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.quiz_outlined,
                                              size: 14,
                                              color: Colors.grey.shade600,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              '${entry.quizCompletes} quiz complétés',
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: Colors.grey.shade600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Points
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        '${entry.totalPoints}',
                                        style: const TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFFFEB823), // Or/Gold
                                        ),
                                      ),
                                      Text(
                                        'Pts',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                      childCount: ranking.classement.length,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
