import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:wizi_learn/core/network/api_client.dart';
import 'package:wizi_learn/features/auth/data/models/stats_model.dart';
import 'package:wizi_learn/features/auth/data/repositories/stats_repository.dart';
import 'package:wizi_learn/features/auth/presentation/constants/couleur_palette.dart';
import 'package:wizi_learn/features/auth/presentation/widgets/global_rankig_widget.dart';
import 'package:wizi_learn/features/auth/presentation/widgets/quiz_history_widget.dart';
import 'package:wizi_learn/features/auth/presentation/widgets/quiz_stats_widget.dart';
import 'package:share_plus/share_plus.dart';

class RankingPage extends StatefulWidget {
  const RankingPage({super.key});

  @override
  State<RankingPage> createState() => _RankingPageState();
}

class _RankingPageState extends State<RankingPage>
    with SingleTickerProviderStateMixin {
  late final StatsRepository _repository;
  late TabController _tabController;
  Future<List<QuizHistory>>? _historyFuture;
  Future<List<GlobalRanking>>? _rankingFuture;
  Future<QuizStats>? _statsFuture;
  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final apiClient = ApiClient(
      dio: Dio(),
      storage: const FlutterSecureStorage(),
    );
    _repository = StatsRepository(apiClient: apiClient);
    _tabController = TabController(length: 3, vsync: this);
    _loadAllData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAllData() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = null;
    });

    try {
      _historyFuture = _repository.getQuizHistory();
      _rankingFuture = _repository.getGlobalRanking();
      _statsFuture = _repository.getQuizStats();

      await Future.wait([_historyFuture!, _rankingFuture!, _statsFuture!]);
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Classement et Statistiques',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        backgroundColor: AppColors.background,
        automaticallyImplyLeading: false,
        elevation: 1,
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.assessment), text: 'Statistiques'),
            Tab(icon: Icon(Icons.leaderboard), text: 'Classement'),
            Tab(icon: Icon(Icons.history), text: 'Historique'),
          ],
          labelColor: AppColors.accent,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppColors.accent,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: 'Partager mon classement',
            onPressed: () async {
              // Récupère le rang et les points de l'utilisateur
              final rankings = await _rankingFuture;
              final stats = await _statsFuture;
              if (rankings != null && stats != null) {
                final myRanking = rankings.firstWhere(
                  (r) => r.stagiaire.id == stats.levelProgress.debutant.completed.toString(),
                  orElse: () => rankings.first,
                );
                final rang = myRanking.rang;
                final points = myRanking.totalPoints;
                final msg = "Je suis classé $rang${rang == 1 ? 'er' : 'e'} avec $points points sur Wizi Learn ! 🏆\nRejoins-moi pour progresser !";
                await Share.share(msg);
              }
            },
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _hasError
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Erreur: $_errorMessage',
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _loadAllData,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Réessayer'),
                    ),
                  ],
                ),
              )
              : TabBarView(
                controller: _tabController,
                children: [
                  _buildStatsTab(),
                  _buildRankingTab(),
                  _buildHistoryTab(),
                ],
              ),
    );
  }

  Widget _buildStatsTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: FutureBuilder<QuizStats>(
        future: _statsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return const Center(
              child: Text('Erreur de chargement des statistiques'),
            );
          }
          return Card(
            margin: EdgeInsets.zero, // Supprime la marge interne du Card
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: QuizStatsWidget(stats: snapshot.data!),
          );
        },
      ),
    );
  }

  Widget _buildRankingTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: FutureBuilder<List<GlobalRanking>>(
        future: _rankingFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return const Center(
              child: Text('Erreur de chargement du classement'),
            );
          }
          return Card(
            margin: EdgeInsets.zero,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: GlobalRankingWidget(rankings: snapshot.data!),
          );
        },
      ),
    );
  }

  Widget _buildHistoryTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: FutureBuilder<List<QuizHistory>>(
        future: _historyFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return const Center(
              child: Text('Erreur de chargement de l\'historique'),
            );
          }
          return Card(
            margin: EdgeInsets.zero,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: QuizHistoryWidget(history: snapshot.data!),
          );
        },
      ),
    );
  }
}
