import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wizi_learn/core/constants/route_constants.dart';
import 'package:wizi_learn/core/network/api_client.dart';
import 'package:wizi_learn/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:wizi_learn/features/auth/data/models/quiz_model.dart'
    as quiz_model;
import 'package:wizi_learn/features/auth/data/models/stats_model.dart';
import 'package:wizi_learn/features/auth/data/repositories/auth_repository.dart';
import 'package:wizi_learn/features/auth/data/repositories/quiz_repository.dart';
import 'package:wizi_learn/features/auth/data/repositories/stats_repository.dart';
import 'package:wizi_learn/features/auth/presentation/pages/quiz_session_page.dart';
import 'package:wizi_learn/features/auth/presentation/pages/quiz_adventure_page.dart';
import 'package:wizi_learn/features/auth/presentation/pages/achievement_page.dart';
import 'package:wizi_learn/features/auth/presentation/widgets/help_dialog.dart';
import 'package:wizi_learn/features/auth/services/quiz_resume_service.dart';
import 'package:wizi_learn/features/auth/presentation/components/resume_quiz_dialog.dart';
import 'package:wizi_learn/features/auth/presentation/components/level_unlock_indicator.dart';
import 'package:wizi_learn/features/auth/auth_injection_container.dart';


class QuizPage extends StatefulWidget {
  final bool scrollToPlayed;
  final bool quizAdventureEnabled;
  final bool forceList;

  const QuizPage({
    super.key,
    this.scrollToPlayed = false,
    this.quizAdventureEnabled = false,
    this.forceList = false,
  });

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  late final QuizRepository _quizRepository;
  late final AuthRepository _authRepository;
  late final StatsRepository _statsRepository;

  Future<List<quiz_model.Quiz>>? _futureQuizzes;
  Future<List<QuizHistory>>? _futureQuizHistory;
  final Map<int, bool> _expandedQuizzes = {};
  final ScrollController _scrollController = ScrollController();
  bool _showBackToTopButton = false;
  bool _isInitialLoad = true;
  int? _connectedStagiaireId;
  int _userPoints = 0;
  List<String> _playedQuizIds = [];
  String? _scrollToQuizId;
  bool _didRedirectToAdventure = false;
  // Optimisation: cache des listes filtrées pour éviter les FutureBuilder imbriqués
  List<quiz_model.Quiz> _allQuizzes = []; // All quizzes without point filtering
  List<quiz_model.Quiz> _baseQuizzes = []; // Quizzes filtered by points
  List<quiz_model.Quiz> _visiblePlayed = [];
  List<quiz_model.Quiz> _visibleUnplayed = [];
  List<QuizHistory> _quizHistoryList = [];
  bool _showAllPlayed = false;

  // Filtres
  String? _selectedLevel;
  int? _selectedFormationId; // Utiliser l'ID au lieu du titre pour plus de fiabilité
  List<String> _availableLevels = [];
  List<int> _availableFormationIds = []; // Stocker les IDs des formations
  Map<int, String> _formationIdToTitle = {}; // Map pour afficher titres
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _initializeRepositories();
    _loadInitialData();
    _scrollController.addListener(_scrollListener);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map<String, dynamic>) {
        setState(() {
          _scrollToQuizId = args['scrollToQuizId'];
        });
      }

      final bool forceListArg =
          (args is Map<String, dynamic>) ? (args['forceList'] ?? false) : false;

      // Charger la préférence utilisateur
      final userPrefersAdventure = await _loadQuizViewPreference();

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _checkAutoSelectNextQuiz();
      });

      if (!_didRedirectToAdventure &&
          !widget.quizAdventureEnabled &&
          !widget.forceList &&
          !forceListArg &&
          userPrefersAdventure) {
        _didRedirectToAdventure = true;
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder:
                (_, __, ___) =>
                    const QuizAdventurePage(quizAdventureEnabled: true),
            transitionsBuilder:
                (_, animation, __, child) =>
                    FadeTransition(opacity: animation, child: child),
            transitionDuration: const Duration(milliseconds: 250),
          ),
        );
      }
    });
  }

  void _checkAutoSelectNextQuiz() {
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map<String, dynamic> && args['autoSelectNextQuiz'] == true) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (_visibleUnplayed.isNotEmpty && mounted) {
          _startQuiz(_visibleUnplayed.first);
        }
      });
    }
  }

  Future<void> _scrollToQuiz(String quizId) async {
    if (_scrollController.hasClients && _futureQuizzes != null) {
      try {
        final quizzes = await _futureQuizzes!;
        final quizIndex = quizzes.indexWhere((q) => q.id.toString() == quizId);

        if (quizIndex != -1) {
          final RenderBox renderBox = context.findRenderObject() as RenderBox;
          final double itemHeight =
              renderBox.size.height / 5;
          final double position = quizIndex * itemHeight;

          await Future.delayed(
            const Duration(milliseconds: 500),
          );

          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              position,
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeInOut,
            );
          }
        }
      } catch (e) {
        debugPrint('Erreur lors du scroll vers le quiz: $e');
      }
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _initializeRepositories() {
    final dio = Dio();
    final storage = const FlutterSecureStorage();
    final apiClient = ApiClient(dio: dio, storage: storage);

    _quizRepository = QuizRepository(apiClient: apiClient);
    _authRepository = AuthRepository(
      remoteDataSource: AuthRemoteDataSourceImpl(
        apiClient: apiClient,
        storage: storage,
      ),
      storage: storage,
    );
    _statsRepository = StatsRepository(apiClient: apiClient);
  }

  Future<void> _saveQuizViewPreference(bool isAdventureMode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('quiz_view_preference', isAdventureMode);
  }

  Future<bool> _loadQuizViewPreference() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('quiz_view_preference') ??
        true;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;

    if (args is Map<String, dynamic>) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (args['scrollToQuizId'] != null && mounted) {
          _scrollToQuiz(args['scrollToQuizId']);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    final bool scrollToPlayed =
        args?['scrollToPlayed'] ?? widget.scrollToPlayed;

    Widget content = RefreshIndicator(
      onRefresh: _loadInitialData,
      child: CustomScrollView(
        key: const PageStorageKey('quiz_scroll'),
        controller: _scrollController,
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            sliver: SliverToBoxAdapter(child: _buildHeader(theme)),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: _buildQuizListContent(theme),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
        ],
      ),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollToQuizId != null) {
        _scrollToQuiz(_scrollToQuizId!);
      } else if (scrollToPlayed) {
        _scrollToPlayedQuizzes();
      }
    });

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.home),
          tooltip: 'Accueil',
          onPressed: () {
            Navigator.pushReplacementNamed(
              context,
              RouteConstants.dashboard,
              arguments: 0,
            );
          },
        ),
        title: const Text('Quiz'),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: _buildPointsChip(theme),
          ),
          IconButton(
            icon: const Icon(Icons.emoji_events),
            tooltip: 'Mes Badges',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AchievementPage()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.help_outline),
            tooltip: 'Voir le tutoriel',
            onPressed: _showHowToPlayDialog,
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
            tooltip: 'Filtrer les quiz',
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Row(
              children: [
                const SizedBox(width: 6),
                Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Switch(
                    value: false,
                    activeThumbColor: Colors.white,
                    activeTrackColor: Colors.black,
                    inactiveThumbColor: Colors.black,
                    inactiveTrackColor: Colors.white,
                    onChanged: (v) async {
                      if (!v) return;
                      await _saveQuizViewPreference(true);
                      if (!mounted) return; 
                      await Navigator.pushReplacementNamed(
                        context,
                        RouteConstants.quizAdventure,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: content,
      floatingActionButton:
          _showBackToTopButton
              ? FloatingActionButton(
                onPressed: _scrollToTop,
                mini: true,
                backgroundColor: theme.colorScheme.primary,
                child: Icon(
                  Icons.arrow_upward,
                  color: theme.colorScheme.onPrimary,
                ),
              )
              : null,
    );
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isInitialLoad = true;
      _baseQuizzes = [];
      _visiblePlayed = [];
      _visibleUnplayed = [];
    });

    try {
      final user = await _authRepository.getMe();
      _connectedStagiaireId = user.stagiaire?.id;

      if (_connectedStagiaireId == null) {
        if (mounted) {
          setState(() => _isInitialLoad = false);
        }
        return;
      }

      await Future.wait([
        _loadUserPoints(),
        _loadQuizzes(),
        _loadQuizHistory(),
      ], eagerError: true);

      if (mounted) {
        if (_selectedFormationId == null) {
          _selectFormationFromLastPlayedIfAny();
        } else {
          _applyFilters();
        }
      }
    } catch (e) {
      debugPrint('Erreur chargement initial: $e');
      if (mounted) {
        setState(() {
          _baseQuizzes = [];
          _visiblePlayed = [];
          _visibleUnplayed = [];
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isInitialLoad = false);
      }
    }
  }

  Future<void> _loadUserPoints() async {
    final rankings = await _statsRepository.getGlobalRanking();
    final userRanking = rankings.firstWhere(
      (r) => r.stagiaire.id == _connectedStagiaireId.toString(),
      orElse: () => GlobalRanking.empty(),
    );
    setState(() => _userPoints = userRanking.totalPoints);
  }

  Future<void> _loadQuizHistory() async {
    try {
      final history = await _statsRepository.getQuizHistory();
      final playedIds = history.map((h) => h.quiz.id.toString()).toList();

      if (mounted) {
        setState(() {
          _futureQuizHistory = Future.value(history);
          _playedQuizIds = playedIds;
          _quizHistoryList = history;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _futureQuizHistory = Future.value([]);
          _playedQuizIds = [];
          _quizHistoryList = [];
        });
      }
    }
  }

  Future<void> _loadQuizzes() async {
    try {
      final quizzes = await _quizRepository.getQuizzesForStagiaire(
        stagiaireId: _connectedStagiaireId!,
      );

      final filteredQuizzes = _filterQuizzesByPoints(quizzes, _userPoints);

      await _extractAvailableFilters(quizzes);

      if (mounted) {
        setState(() {
          _allQuizzes = quizzes;
          _baseQuizzes = filteredQuizzes;
          _futureQuizzes = Future.value(filteredQuizzes);
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _baseQuizzes = [];
          _futureQuizzes = Future.value([]);
        });
      }
    }
  }

  Future<void> _extractAvailableFilters(List<quiz_model.Quiz> quizzes) async {
    final formationIds = <int>{};
    final formationIdToTitleMap = <int, String>{};
    final levels = <String>{};
    
    for (final quiz in quizzes) {
      if (quiz.niveau.isNotEmpty) levels.add(quiz.niveau);
      final formationId = quiz.formation.id;
      final title = quiz.formation.titre;
      if (formationId > 0 && title.isNotEmpty) {
        formationIds.add(formationId);
        formationIdToTitleMap[formationId] = title;
      }
    }

    final formationIdsList = formationIds.toList()..sort();
    final levelsList = levels.toList()..sort();

    if (mounted) {
      setState(() {
        _availableFormationIds = formationIdsList;
        _formationIdToTitle = formationIdToTitleMap;
        _availableLevels = levelsList;
      });
    }
  }

  List<quiz_model.Quiz> _filterQuizzesByPoints(List<quiz_model.Quiz> quizzes, int userPoints) {
    if (quizzes.isEmpty) return [];

    String normalizeLevel(String? level) {
      if (level == null || level.isEmpty) return 'débutant';
      final lvl = level.toLowerCase().trim();
      if (lvl.contains('inter') || lvl.contains('moyen')) {
        return 'intermédiaire';
      }
      if (lvl.contains('avanc') || lvl.contains('expert') || lvl.contains('difficile')) {
        return 'avancé';
      }
      return 'débutant';
    }

    final debutant = quizzes.where((q) => normalizeLevel(q.niveau) == 'débutant').toList();
    final intermediaire = quizzes.where((q) => normalizeLevel(q.niveau) == 'intermédiaire').toList();
    final avance = quizzes.where((q) => normalizeLevel(q.niveau) == 'avancé').toList();

    List<quiz_model.Quiz> result;
    
    if (userPoints < 50) {
      result = debutant;
    } else if (userPoints < 100) {
      result = [...debutant, ...intermediaire];
    } else {
      result = [...debutant, ...intermediaire, ...avance];
    }

    debugPrint('🔒 Filtrage quiz: ${quizzes.length} quiz → ${result.length} accessibles ($userPoints pts)');
    
    return result;
  }

  void _applyFilters() {
    if (_baseQuizzes.isEmpty) {
      setState(() {
        _visiblePlayed = [];
        _visibleUnplayed = [];
      });
      return;
    }

    final playedIds = _playedQuizIds;
    
    var played = _allQuizzes.isNotEmpty 
        ? _allQuizzes.where((q) => playedIds.contains(q.id.toString())).toList()
        : <quiz_model.Quiz>[];
    
    var unplayed = _baseQuizzes.where((q) => !playedIds.contains(q.id.toString())).toList();

    if (_selectedFormationId != null) {
      played = played.where((q) => q.formation.id == _selectedFormationId).toList();
      unplayed = unplayed.where((q) => q.formation.id == _selectedFormationId).toList();
    }

    if (_quizHistoryList.isNotEmpty && played.isNotEmpty) {
      played.sort((a, b) {
        try {
          final ha = _quizHistoryList.firstWhere(
            (h) => h.quiz.id.toString() == a.id.toString(),
          );
          final hb = _quizHistoryList.firstWhere(
            (h) => h.quiz.id.toString() == b.id.toString(),
          );
          final da = DateTime.parse(ha.completedAt);
          final db = DateTime.parse(hb.completedAt);
          return db.compareTo(da);
        } catch (_) {
          return 0;
        }
      });
    }

    setState(() {
      _visiblePlayed = played;
      _visibleUnplayed = unplayed;
      _expandedQuizzes.clear();
      for (var quiz in [...played, ...unplayed]) {
        _expandedQuizzes.putIfAbsent(quiz.id, () => false);
      }
      _showAllPlayed = false;
    });
  }

  Future<double> _calculatePlayedQuizzesPosition() async {
    final unplayedCount = _visibleUnplayed.length;
    final headerHeight = 100.0;
    const itemHeight = 120.0;
    return headerHeight + (unplayedCount * itemHeight);
  }

  Widget _buildHeader(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 4),
        Text(
          'Testez vos connaissances avec ces quiz',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 16),
        LevelUnlockIndicator(userPoints: _userPoints),
        const SizedBox(height: 8),

        const SizedBox(height: 10),
        if (_availableFormationIds.isNotEmpty)
          Row(
            children: [
              Icon(Icons.school, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: _showFormationPicker,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      vertical: 10,
                      horizontal: 12,
                    ),
                    side: BorderSide(
                      color: theme.colorScheme.primary.withValues(alpha: 0.5),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _selectedFormationId != null 
                            ? (_formationIdToTitle[_selectedFormationId] ?? 'Formation inconnue')
                            : 'Choisir une formation',
                        style: TextStyle(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                        ),
                      ),
                      Icon(
                        Icons.keyboard_arrow_down,
                        color: theme.colorScheme.primary,
                      ),
                    ],
                  ),
                ),
              ),
              if (_selectedFormationId != null) ...[
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Réinitialiser',
                  onPressed: () {
                    setState(() => _selectedFormationId = null);
                    _applyFilters();
                    _scrollController.animateTo(
                      0,
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeInOut,
                    );
                  },
                  icon: Icon(Icons.close, color: theme.colorScheme.primary),
                ),
              ],
            ],
          ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildQuizListContent(ThemeData theme) {
    if (_isInitialLoad) {
      return SliverFillRemaining(child: _buildLoadingScreen(theme));
    }
    if (_baseQuizzes.isEmpty) {
      return SliverFillRemaining(child: _buildEmptyState(theme));
    }

    final unplayed = _visibleUnplayed;
    final played = _visiblePlayed;

    final displayedPlayed = _showAllPlayed ? played : played.take(5).toList();

    return SliverList(
      delegate: SliverChildListDelegate([
        if (unplayed.isNotEmpty) ...[
          _buildSectionTitle('Quiz disponibles', theme),
          ...unplayed.map(
            (quiz) => Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 800),
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildQuizCard(
                  quiz,
                  _expandedQuizzes[quiz.id] ?? false,
                  theme,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
        if (played.isNotEmpty) ...[
          _buildSectionTitle('Historique de vos quiz déjà terminé', theme),
          ...displayedPlayed.map(
            (quiz) => Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 800),
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildPlayedQuizCard(quiz, theme),
              ),
            ),
          ),
          if (played.length > 5)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed:
                      () => setState(() => _showAllPlayed = !_showAllPlayed),
                  icon: Icon(
                    _showAllPlayed ? Icons.expand_less : Icons.expand_more,
                  ),
                  label: Text(_showAllPlayed ? 'Voir moins' : 'Voir plus'),
                ),
              ),
            ),
        ],
        if (unplayed.isEmpty && played.isEmpty) _buildEmptyState(theme),
      ]),
    );
  }


  Widget _buildSectionTitle(String title, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildPlayedQuizCard(quiz_model.Quiz quiz, ThemeData theme) {
    final categoryColor = _getCategoryColor(quiz.formation.categorie, theme);
    final isExpanded = _expandedQuizzes[quiz.id] ?? false;
    final textColor = theme.colorScheme.onSurface;

    return FutureBuilder<List<QuizHistory>>(
      future: _futureQuizHistory,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();

        final history = snapshot.data!.firstWhere(
          (h) => h.quiz.id.toString() == quiz.id.toString(),
          orElse:
              () => QuizHistory(
                id: '',
                quiz: quiz_model.Quiz(
                  id: 0,
                  titre: '',
                  description: '',
                  duree: '',
                  niveau: '',
                  status: '',
                  nbPointsTotal: 0,
                  formation: quiz.formation,
                  questions: const [],
                ),
                score: 0,
                completedAt: '',
                timeSpent: 0,
                totalQuestions: 0,
                correctAnswers: 0,
              ),
        );

        final scorePercentage =
            (history.totalQuestions == 0)
                ? 0
                : (history.correctAnswers / history.totalQuestions * 100)
                    .round();

        String formattedDate;
        String debugDate = history.completedAt;
        try {
          formattedDate =
              'Terminé le ${DateFormat('dd/MM/yyyy').format(DateTime.parse(history.completedAt))}';
        } catch (e) {
          formattedDate = 'Date inconnue (raw: $debugDate)';
        }

        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              InkWell(
                key: ValueKey('played_quiz_header_${quiz.id}'),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                onTap: () {
                  debugPrint('🔍 Played quiz tapped: ${quiz.id}, current state: $isExpanded');
                  setState(() {
                    final newState = !isExpanded;
                    _expandedQuizzes[quiz.id] = newState;
                    debugPrint('✅ New state: $newState');
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 48,
                            height: 48,
                            child: CircularProgressIndicator(
                              value: scorePercentage / 100,
                              backgroundColor: categoryColor.withValues(alpha: 0.1),
                              color: categoryColor,
                              strokeWidth: 4,
                            ),
                          ),
                          Text(
                            '$scorePercentage%',
                            style: TextStyle(
                              color: categoryColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              quiz.titre,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: textColor,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              quiz.formation.titre,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: categoryColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              quiz.niveau,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              formattedDate,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        isExpanded ? Icons.expand_less : Icons.expand_more,
                        color: categoryColor,
                      ),
                    ],
                  ),
                ),
              ),

              AnimatedCrossFade(
                duration: const Duration(milliseconds: 250),
                crossFadeState:
                    isExpanded
                        ? CrossFadeState.showSecond
                        : CrossFadeState.showFirst,
                firstChild: const SizedBox(),
                secondChild: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Column(
                    children: [
                      Divider(color: theme.dividerColor.withValues(alpha: 0.2)),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatItem(
                            Icons.check_circle,
                            'Réussite',
                            '${history.correctAnswers}/${history.totalQuestions}',
                            categoryColor,
                            theme,
                          ),
                          _buildStatItem(
                            Icons.timer,
                            'Temps',
                            '${history.timeSpent}s',
                            categoryColor,
                            theme,
                          ),
                          _buildStatItem(
                            Icons.star,
                            'Points',
                            '${history.correctAnswers * 2}',
                            categoryColor,
                            theme,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: categoryColor,
                            side: BorderSide(color: categoryColor),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () => _startQuiz(quiz),
                          child: const Text(
                            'Refaire ce quiz',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatItem(
    IconData icon,
    String label,
    String value,
    Color color,
    ThemeData theme,
  ) {
    return Column(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }

  Future<void> _startQuiz(quiz_model.Quiz quiz) async {
    try {
      final questions = await _quizRepository.getQuizQuestions(quiz.id);
      if (questions.isEmpty) {
        _showErrorSnackbar('Aucune question disponible pour ce quiz');
        return;
      }

      final resumeService = sl<QuizResumeService>();
      debugPrint('🔍 Checking for saved session: quizId=${quiz.id}');
      final sessionData = await resumeService.getSession(quiz.id.toString());
      debugPrint('📦 Session data: $sessionData');
      Map<String, dynamic>? initialSessionData;

      if (sessionData != null && mounted) {
        debugPrint('✅ Found saved session! Showing resume dialog...');
        final shouldResume = await showDialog<bool>(
          context: context,
          builder: (context) => ResumeQuizDialog(
            quizTitle: quiz.titre,
            questionCount: questions.length,
            currentIndex: sessionData['currentIndex'] ?? 0,
          ),
        );

        if (shouldResume == null) return;

        if (shouldResume) {
          debugPrint('▶️ User chose to resume');
          initialSessionData = sessionData;
        } else {
          debugPrint('🗑️ User chose to dismiss, clearing session');
          await resumeService.clearSession(quiz.id.toString());
        }
      } else {
        debugPrint('❌ No saved session found or widget not mounted');
      }

      if (mounted) {
        setState(() {
          _playedQuizIds.add(quiz.id.toString());
        });
      }

      if (!mounted) return;

      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (_) => QuizSessionPage(
                quiz: quiz,
                questions: questions,
                quizAdventureEnabled: widget.quizAdventureEnabled,
                playedQuizIds: _playedQuizIds,
                initialSessionData: initialSessionData,
              ),
        ),
      );

      if (result == true) {
        await _loadInitialData();
      }
    } catch (e) {
      _showErrorSnackbar('Erreur de chargement des questions');
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(20),
      ),
    );
  }

  Widget _buildQuizCard(
    quiz_model.Quiz quiz,
    bool isExpanded,
    ThemeData theme,
  ) {
    final categoryColor = _getCategoryColor(quiz.formation.categorie, theme);
    final textColor = theme.colorScheme.onSurface;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            key: ValueKey('quiz_header_${quiz.id}'),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            onTap: () {
              debugPrint('🔍 Quiz tapped: ${quiz.id}, current state: $isExpanded');
              setState(() {
                final newState = !isExpanded;
                _expandedQuizzes[quiz.id] = newState;
                debugPrint('✅ New state: $newState');
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [categoryColor.withValues(alpha: 0.8), categoryColor],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.quiz, color: Colors.white),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          quiz.titre,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: textColor,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          quiz.formation.titre,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: categoryColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          quiz.niveau,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: categoryColor,
                  ),
                ],
              ),
            ),
          ),

          AnimatedCrossFade(
            duration: const Duration(milliseconds: 250),
            crossFadeState:
                isExpanded
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
            firstChild: const SizedBox(),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                children: [
                  Divider(color: theme.dividerColor.withValues(alpha: 0.2)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.star, size: 20, color: categoryColor),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Points à gagner',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              (() {
                                final nbQuestions = quiz.questions.length;
                                final points =
                                    nbQuestions > 5 ? 10 : nbQuestions * 2;
                                return '$points points';
                              })(),
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w500,
                                color: categoryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _buildDetailRow(
                    Icons.school,
                    'Formation',
                    quiz.formation.titre,
                    theme,
                    iconColor: categoryColor,
                  ),
                  _buildDetailRow(
                    Icons.assessment,
                    'Niveau',
                    quiz.niveau,
                    theme,
                    iconColor: categoryColor,
                  ),
                  _buildDetailRow(
                    Icons.description,
                    'Description',
                    _removeHtmlTags(quiz.description ?? 'Aucune description'),
                    theme,
                    iconColor: categoryColor,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: categoryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                        shadowColor: Colors.transparent,
                      ),
                      onPressed: () => _startQuiz(quiz),
                      child: const Text(
                        'Commencer le quiz',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    IconData icon,
    String label,
    String value,
    ThemeData theme, {
    Color? iconColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: iconColor ?? theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _removeHtmlTags(String htmlText) {
    return htmlText.replaceAll(RegExp(r'<[^>]*>'), '').trim();
  }

  Color _getCategoryColor(String? category, ThemeData theme) {
    if (category == null) return theme.colorScheme.primary;

    final cat = category.trim().toLowerCase();
    switch (cat) {
      case 'bureautique':
        return const Color(0xFF3D9BE9);
      case 'langues':
        return const Color(0xFFA55E6E);
      case 'internet':
        return const Color(0xFFFFC533);
      case 'création':
        return const Color(0xFF9392BE);
      case 'IA':
        return const Color(0xFFABDA96);
      default:
        return theme.colorScheme.primary;
    }
  }

  Widget _buildLoadingScreen(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: theme.colorScheme.primary),
          const SizedBox(height: 20),
          Text('Chargement de vos quiz...', style: theme.textTheme.bodyLarge),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.quiz_outlined,
            size: 48,
            color: theme.colorScheme.primary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text('Aucun quiz disponible', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            'Vous n\'avez actuellement aucun quiz disponible.',
            style: theme.textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _scrollToPlayedQuizzes() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (_scrollController.hasClients) {
        final position = await _calculatePlayedQuizzesPosition();
        if (position > 0) {
          _scrollController.animateTo(
            position,
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeInOut,
          );
        }
      }
    });
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setDialogState) => AlertDialog(
                  title: Row(
                    children: [
                      Icon(
                        Icons.filter_list,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 10),
                      const Text('Filtrer les quiz'),
                    ],
                  ),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Niveau',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedLevel,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        hint: const Text('Tous les niveaux'),
                        items: [
                          const DropdownMenuItem<String>(
                            value: null,
                            child: Text('Tous les niveaux'),
                          ),
                          ..._availableLevels.map(
                            (level) => DropdownMenuItem<String>(
                              value: level,
                              child: Text(level),
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          setDialogState(() {
                            _selectedLevel = value;
                          });
                        },
                      ),
                      const SizedBox(height: 16),

                      Text(
                        'Formation',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<int>(
                        value: _selectedFormationId,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        hint: const Text('Toutes les formations'),
                        items: [
                          const DropdownMenuItem<int>(
                            value: null,
                            child: Text('Toutes les formations'),
                          ),
                          ..._availableFormationIds.map(
                            (formationId) => DropdownMenuItem<int>(
                              value: formationId,
                              child: Text(_formationIdToTitle[formationId] ?? 'Formation inconnue'),
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          setDialogState(() {
                            _selectedFormationId = value;
                          });
                        },
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        setDialogState(() {
                          _selectedLevel = null;
                          _selectedFormationId = null;
                        });
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.error,
                      ),
                      child: const Text('Réinitialiser'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Annuler'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        setState(
                          () {},
                        );
                        _applyFilters();
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor:
                            Theme.of(context).colorScheme.onPrimary,
                      ),
                      child: const Text('Appliquer'),
                    ),
                  ],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
          ),
    );
  }

  void _showFormationPicker() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        final formationIds = [..._availableFormationIds];
        final theme = Theme.of(context);
        
        return Align(
          alignment: Alignment.topCenter,
          child: Container(
            width: double.infinity,
            margin: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + kToolbarHeight - 10,
              left: 12,
              right: 12,
            ),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.4,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Icon(Icons.school, color: theme.colorScheme.primary),
                          const SizedBox(width: 12),
                          Text(
                            'Filtrer par formation',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: formationIds.length,
                        separatorBuilder: (_, __) => const Divider(height: 1, indent: 50),
                        itemBuilder: (_, i) {
                          final formationId = formationIds[i];
                          final title = _formationIdToTitle[formationId] ?? 'Formation inconnue';
                          final selected = (_selectedFormationId == formationId);
                          return ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: selected ? theme.colorScheme.primary.withValues(alpha: 0.1) : Colors.transparent,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.school_outlined,
                                size: 20,
                                color: selected ? theme.colorScheme.primary : theme.hintColor,
                              ),
                            ),
                            title: Text(
                              title,
                              style: TextStyle(
                                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                                color: selected ? theme.colorScheme.primary : null,
                              ),
                            ),
                            trailing: selected
                                ? Icon(Icons.check_circle, color: theme.colorScheme.primary)
                                : null,
                            onTap: () {
                              setState(() {
                                _selectedFormationId = formationId;
                              });
                              _applyFilters();
                              _scrollController.animateTo(
                                0,
                                duration: const Duration(milliseconds: 400),
                                curve: Curves.easeInOut,
                              );
                              Navigator.pop(context);
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, -1),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          )),
          child: child,
        );
      },
    );
  }

  void _showHowToPlayDialog() {
    showStandardHelpDialog(
      context,
      title: 'Comment jouer ?',
      steps: const [
        'Choisissez une formation',
        'Touchez un quiz débloqué pour commencer',
        'Répondez aux questions et validez',
        'Consultez votre historique et vos badges',
      ],
    );
  }

  void _scrollListener() {
    if (_scrollController.offset >= 400 && !_showBackToTopButton) {
      setState(() => _showBackToTopButton = true);
    } else if (_scrollController.offset < 400 && _showBackToTopButton) {
      setState(() => _showBackToTopButton = false);
    }
  }

  Widget _buildPointsChip(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.6),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star_rounded, size: 18, color: theme.colorScheme.primary),
          const SizedBox(width: 6),
          Text(
            '$_userPoints pts',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  void _selectFormationFromLastPlayedIfAny() {
    try {
      if (_selectedFormationId != null) return;
      DateTime parseDate(String s) =>
          DateTime.tryParse(s) ?? DateTime.fromMillisecondsSinceEpoch(0);

      if (_quizHistoryList.isEmpty) return;

      final sorted = List<QuizHistory>.from(_quizHistoryList)..sort(
        (a, b) => parseDate(b.completedAt).compareTo(parseDate(a.completedAt)),
      );

      final last = sorted.first;
      final lastFormationId = last.quiz.formation.id;

      if (lastFormationId > 0 &&
          _availableFormationIds.contains(lastFormationId)) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              _selectedFormationId = lastFormationId;
            });
            _applyFilters();
          }
        });
      }
    } catch (e) {
      debugPrint('Erreur dans _selectFormationFromLastPlayedIfAny: $e');
    }
  }

  void _scrollToTop() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }
}
