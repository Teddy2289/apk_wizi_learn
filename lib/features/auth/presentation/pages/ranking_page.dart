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
import 'package:wizi_learn/features/auth/presentation/widgets/help_dialog.dart';
import 'package:wizi_learn/core/constants/route_constants.dart';
import 'package:wizi_learn/core/widgets/safe_area_bottom.dart';

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

  Future<void> _checkAndShowTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getBool('ranking_tutorial_seen') ?? false;
    // if (!seen) {
    //   WidgetsBinding.instance.addPostFrameCallback((_) => _showTutorial());
    //   await prefs.setBool('ranking_tutorial_seen', true);
    // }
  }

  void _showTutorial() {
    final tutorial = TutorialCoachMark(
      targets: _buildTargets(),
      colorShadow: Colors.black,
      textSkip: 'Passer',
      paddingFocus: 8,
      opacityShadow: 0.8,
      onFinish: () {},
      onSkip: () {
        return true;
      },
    );
    tutorial.show(context: context);
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
              'Navigue entre Classement, Statistiques et Historique.',
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
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    return Scaffold(
      appBar: isLandscape ? _buildLandscapeAppBar() : _buildPortraitAppBar(),
      body: SafeAreaBottom(
        child:
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
                    _buildRankingTab(isLandscape),
                    _buildStatsTab(isLandscape),
                    _buildHistoryTab(isLandscape),
                  ],
                ),
      ),
    );
  }

  AppBar _buildPortraitAppBar() {
    return AppBar(
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
          Tab(icon: Icon(Icons.leaderboard), text: 'Classement'),
          Tab(icon: Icon(Icons.assessment), text: 'Statistiques'),
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
          onPressed:
              () => showStandardHelpDialog(
                context,
                title: 'Comment utiliser cette page ?',
                steps: const [
                  'Naviguez entre Classement, Statistiques et Historique via les onglets.',
                  'Consultez le podium et votre position dans la liste.',
                  'Dans Statistiques, explorez vos performances et votre progression.',
                  'Dans Historique, retrouvez vos quiz passés.',
                  'Utilisez le bouton Partager pour défier vos amis.',
                ],
              ),
        ),
      ],
    );
  }

  AppBar _buildLandscapeAppBar() {
    return AppBar(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Titre compact
          Text(
            'Classement',
            key: _keyTitle,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),

          // Tabs horizontales compactes
          Expanded(
            child: Center(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(25),
                ),
                child: TabBar(
                  key: _keyTabBar,
                  controller: _tabController,
                  isScrollable: true,
                  labelPadding: const EdgeInsets.symmetric(horizontal: 12),
                  indicator: BoxDecoration(
                    borderRadius: BorderRadius.circular(25),
                    color: AppColors.accent,
                  ),
                  tabs: const [
                    Tab(
                      icon: Icon(Icons.leaderboard, size: 16),
                      text: 'Classement',
                    ),
                    Tab(icon: Icon(Icons.assessment, size: 16), text: 'Stats'),
                    Tab(
                      icon: Icon(Icons.history, size: 16),
                      text: 'Historique',
                    ),
                  ],
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.grey.shade700,
                  indicatorSize: TabBarIndicatorSize.tab,
                ),
              ),
            ),
          ),

          // Actions compactes
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                key: _keyShare,
                icon: const Icon(Icons.share, size: 18),
                tooltip: 'Partager mon classement',
                onPressed: () async {
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
                icon: const Icon(Icons.help_outline, size: 18),
                tooltip: 'Voir le tutoriel',
                onPressed:
                    () => showStandardHelpDialog(
                      context,
                      title: 'Comment utiliser cette page ?',
                      steps: const [
                        'Naviguez entre Classement, Statistiques et Historique via les onglets.',
                        'Consultez le podium et votre position dans la liste.',
                        'Dans Statistiques, explorez vos performances et votre progression.',
                        'Dans Historique, retrouvez vos quiz passés.',
                        'Utilisez le bouton Partager pour défier vos amis.',
                      ],
                    ),
              ),
            ],
          ),
        ],
      ),
      backgroundColor: AppColors.background,
      automaticallyImplyLeading: false,
      elevation: 1,
    );
  }

  Widget _buildStatsTab(bool isLandscape) {
    return Padding(
      padding: EdgeInsets.all(isLandscape ? 8 : 16),
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
            margin: EdgeInsets.zero,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(isLandscape ? 12 : 16),
            ),
            child: QuizStatsWidget(stats: snapshot.data!),
          );
        },
      ),
    );
  }

  Widget _buildRankingTab(bool isLandscape) {
    return Padding(
      padding: EdgeInsets.all(isLandscape ? 8 : 16),
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
              borderRadius: BorderRadius.circular(isLandscape ? 12 : 16),
            ),
            child: GlobalRankingWidget(rankings: snapshot.data!),
          );
        },
      ),
    );
  }

  Widget _buildHistoryTab(bool isLandscape) {
    return Padding(
      padding: EdgeInsets.all(isLandscape ? 8 : 16),
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
              borderRadius: BorderRadius.circular(isLandscape ? 12 : 16),
            ),
            child: QuizHistoryWidget(history: snapshot.data!),
          );
        },
      ),
    );
  }
}
