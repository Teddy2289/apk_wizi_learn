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
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  // GlobalKeys pour le tutoriel interactif
  final GlobalKey _keyTabBar = GlobalKey();
  final GlobalKey _keyTitle = GlobalKey();
  final GlobalKey _keyPodium = GlobalKey();
  final GlobalKey _keyMyRank = GlobalKey();
  final GlobalKey _keyShare = GlobalKey();
  TutorialCoachMark? _tutorialCoachMark;

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
    _checkAndShowTutorial();
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

    String? errorSource;
    try {
      try {
        _historyFuture = _repository.getQuizHistory();
        await _historyFuture;
      } catch (e) {
        errorSource = 'getQuizHistory: ' + e.toString();
        rethrow;
      }
      try {
        _rankingFuture = _repository.getGlobalRanking();
        await _rankingFuture;
      } catch (e) {
        errorSource = 'getGlobalRanking: ' + e.toString();
        rethrow;
      }
      try {
        _statsFuture = _repository.getQuizStats();
        await _statsFuture;
      } catch (e) {
        errorSource = 'getQuizStats: ' + e.toString();
        rethrow;
      }
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = errorSource ?? e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _checkAndShowTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getBool('ranking_tutorial_seen') ?? false;
    if (!seen) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _showTutorial());
      await prefs.setBool('ranking_tutorial_seen', true);
    }
  }

  void _showTutorial() {
    _tutorialCoachMark = TutorialCoachMark(
      targets: _buildTargets(),
      colorShadow: Colors.black,
      textSkip: 'Passer',
      paddingFocus: 8,
      opacityShadow: 0.8,
      onFinish: () {},
      onSkip: () {
        return true;
      },
    )..show(context: context);
  }

  List<TargetFocus> _buildTargets() {
    return [
      TargetFocus(
        identify: 'tabbar',
        keyTarget: _keyTabBar,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            child: const Text(
              'Navigue entre Statistiques, Classement et Historique.',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
          ),
        ],
      ),
      TargetFocus(
        identify: 'title',
        keyTarget: _keyTitle,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            child: const Text(
              'Voici le classement global de tous les joueurs.',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
          ),
        ],
      ),
      TargetFocus(
        identify: 'podium',
        keyTarget: _keyPodium,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            child: const Text(
              'Le podium : les 3 meilleurs joueurs du moment !',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
          ),
        ],
      ),
      TargetFocus(
        identify: 'myrank',
        keyTarget: _keyMyRank,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            child: const Text(
              'Voici ta position dans le classement.',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
          ),
        ],
      ),
      TargetFocus(
        identify: 'share',
        keyTarget: _keyShare,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            child: const Text(
              'Partage ton score et défie tes amis !',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
          ),
        ],
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Classement et Statistiques',
          key: _keyTitle,
          style: const TextStyle(
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
          key: _keyTabBar,
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
            key: _keyShare,
            icon: const Icon(Icons.share),
            tooltip: 'Partager mon classement',
            onPressed: () async {
              // Récupère le rang et les points de l'utilisateur
              final rankings = await _rankingFuture;
              final stats = await _statsFuture;
              if (rankings != null && stats != null) {
                final myRanking = rankings.firstWhere(
                  (r) =>
                      r.stagiaire.id ==
                      stats.levelProgress.debutant.completed.toString(),
                  orElse: () => rankings.first,
                );
                final rang = myRanking.rang;
                final points = myRanking.totalPoints;
                final msg =
                    "Je suis classé $rang${rang == 1 ? 'er' : 'e'} avec $points points sur Wizi Learn ! 🏆\nRejoins-moi pour progresser !";
                await Share.share(msg);
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.help_outline),
            tooltip: 'Voir le tutoriel',
            onPressed: _showTutorial,
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
