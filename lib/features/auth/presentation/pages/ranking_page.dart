import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/ranking/ranking_bloc.dart';
import '../../domain/entities/ranking.dart';
import '../../data/repositories/ranking_repository.dart';
import 'package:dio/dio.dart';

class RankingPage extends StatelessWidget {
  const RankingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => RankingBloc(
        repository: RankingRepository(dio: Dio()),
      )..add(GetGlobalRanking()),
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Classement',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          backgroundColor: Colors.white,
          elevation: 1,
          centerTitle: true,
        ),
        body: BlocBuilder<RankingBloc, RankingState>(
          builder: (context, state) {
            if (state is RankingInitial) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is RankingLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is RankingError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(state.message),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        context.read<RankingBloc>().add(GetGlobalRanking());
                      },
                      child: const Text('Réessayer'),
                    ),
                  ],
                ),
              );
            }

            if (state is RankingLoaded) {
              return _buildRankingList(context, state);
            }

            return const Center(child: Text('État inconnu'));
          },
        ),
      ),
    );
  }

  Widget _buildRankingList(BuildContext context, RankingLoaded state) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: state.rankings.length,
      itemBuilder: (context, index) {
        final ranking = state.rankings[index];
        final isMyRanking = state.myRanking?.stagiaire.id == ranking.stagiaire.id;

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: _getRankingColor(ranking.rang).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _getRankingColor(ranking.rang).withOpacity(0.3),
                ),
              ),
              child: Center(
                child: Text(
                  '${ranking.rang}',
                  style: TextStyle(
                    color: _getRankingColor(ranking.rang),
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
            title: Row(
              children: [
                Text(
                  ranking.stagiaire.prenom,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (isMyRanking) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Vous',
                      style: TextStyle(
                        color: Colors.blue,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.star,
                      size: 16,
                      color: Colors.amber,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Niveau ${ranking.level}',
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.emoji_events,
                      size: 16,
                      color: Colors.orange,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${ranking.totalPoints} points',
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${ranking.averageScore.toStringAsFixed(1)}%',
                    style: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${ranking.quizCount} quiz',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Color _getRankingColor(int rank) {
    switch (rank) {
      case 1:
        return const Color(0xFFFFD700); // Or
      case 2:
        return const Color(0xFFC0C0C0); // Argent
      case 3:
        return const Color(0xFFCD7F32); // Bronze
      default:
        return Colors.blue;
    }
  }
}
