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
import 'package:wizi_learn/features/auth/presentation/widgets/custom_scaffold.dart';
import 'package:wizi_learn/features/auth/presentation/pages/achievement_page.dart';
import 'package:wizi_learn/features/auth/presentation/widgets/help_dialog.dart';

class QuizPage extends StatefulWidget {
  final int? selectedTabIndex;
  final bool useCustomScaffold;
  final bool scrollToPlayed;
  final bool quizAdventureEnabled;
  final bool forceList;

  const QuizPage({
    super.key,
    this.selectedTabIndex = 2,
    this.useCustomScaffold = false,
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
  bool _fromNotification = false;
  List<String> _playedQuizIds = [];
  String? _scrollToQuizId;
  bool _didRedirectToAdventure = false;
  // Optimisation: cache des listes filtrées pour éviter les FutureBuilder imbriqués
  List<quiz_model.Quiz> _baseQuizzes = [];
  List<quiz_model.Quiz> _visiblePlayed = [];
  List<quiz_model.Quiz> _visibleUnplayed = [];
  List<QuizHistory> _quizHistoryList = [];
  bool _showAllPlayed = false;

  // Filtres
  String? _selectedLevel;
  String? _selectedFormation;
  List<String> _availableLevels = [];
  List<String> _availableFormations = [];

  @override
  void initState() {
    super.initState();
    debugPrint(
      'QuizPage params - useCustomScaffold: ${widget.useCustomScaffold}',
    );
    debugPrint('QuizPage params - scrollToPlayed: ${widget.scrollToPlayed}');
    _initializeRepositories();
    _loadInitialData();
    _scrollController.addListener(_scrollListener);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map<String, dynamic>) {
        setState(() {
          _fromNotification = args['fromNotification'] ?? false;
          _scrollToQuizId = args['scrollToQuizId'];
        });
      }

      final bool forceListArg =
          (args is Map<String, dynamic>) ? (args['forceList'] ?? false) : false;

      // Charger la préférence utilisateur
      final userPrefersAdventure = await _loadQuizViewPreference();

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

  Future<void> _scrollToQuiz(String quizId) async {
    debugPrint('Srolling to quiz with ID: $quizId');
    if (_scrollController.hasClients && _futureQuizzes != null) {
      try {
        final quizzes = await _futureQuizzes!;
        final quizIndex = quizzes.indexWhere((q) => q.id.toString() == quizId);

        if (quizIndex != -1) {
          // Calcul plus précis de la position
          final RenderBox renderBox = context.findRenderObject() as RenderBox;
          final double itemHeight =
              renderBox.size.height / 5; // Estimation de la hauteur d'un item
          final double position = quizIndex * itemHeight;

          await Future.delayed(
            const Duration(milliseconds: 500),
          ); // Délai supplémentaire

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
        true; // Par défaut: aventure
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
    final isDarkMode = theme.brightness == Brightness.dark;
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    final bool useCustomScaffold =
        args?['useCustomScaffold'] ?? _fromNotification;
    final bool scrollToPlayed = args?['scrollToPlayed'] ?? false;
    final int selectedTabIndex;

    if (args is int) {
      selectedTabIndex = args as int;
    } else if (args is Map<String, dynamic>) {
      selectedTabIndex = args['selectedTabIndex'] ?? 2;
    } else {
      selectedTabIndex = 2;
    }

    // Contenu principal (header + liste optimisée)
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

    // Gestion scroll ciblé
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollToQuizId != null) {
        _scrollToQuiz(_scrollToQuizId!);
      } else if (scrollToPlayed) {
        _scrollToPlayedQuizzes();
      }
    });

    if (useCustomScaffold) {
      return CustomScaffold(
        body: content,
        currentIndex: selectedTabIndex,
        onTabSelected: (index) {
          if (index != selectedTabIndex) {
            Navigator.pushReplacementNamed(
              context,
              RouteConstants.dashboard,
              arguments: index,
            );
          }
        },
        showBanner: true,
        quizAdventureEnabled: widget.quizAdventureEnabled,
      );
    } else {
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
          backgroundColor:
              isDarkMode ? theme.appBarTheme.backgroundColor : Colors.white,
          elevation: 0,
          automaticallyImplyLeading: false,
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
              onPressed: _showHowToPlayDialog,
              tooltip: 'Voir le tutoriel',
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
                  // const Text('Aventure'),
                  const SizedBox(width: 6),
                  Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Switch(
                      value: false,
                      activeColor: Colors.white,
                      activeTrackColor: Colors.black,
                      inactiveThumbColor: Colors.black,
                      inactiveTrackColor: Colors.white,
                      onChanged: (v) async {
                        if (!v) return;
                        // Sauvegarder la préférence utilisateur pour la vue aventure
                        await _saveQuizViewPreference(true);

                        Navigator.pushReplacement(
                          context,
                          PageRouteBuilder(
                            pageBuilder:
                                (_, __, ___) => const QuizAdventurePage(
                                  quizAdventureEnabled: true,
                                ),
                            transitionsBuilder:
                                (_, animation, __, child) => FadeTransition(
                                  opacity: animation,
                                  child: child,
                                ),
                            transitionDuration: const Duration(
                              milliseconds: 250,
                            ),
                          ),
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
  }

  Future<void> _loadInitialData() async {
    setState(() => _isInitialLoad = true);
    try {
      final user = await _authRepository.getMe();
      _connectedStagiaireId = user.stagiaire?.id;

      if (_connectedStagiaireId == null) {
        setState(() => _isInitialLoad = false);
        return;
      }

      await Future.wait([
        _loadUserPoints(),
        _loadQuizHistory(),
        _loadQuizzes(),
      ]);
    } catch (e) {
      debugPrint('Erreur chargement initial: $e');
    } finally {
      setState(() => _isInitialLoad = false);
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
      debugPrint('Chargement historique des quiz...');
      debugPrint('Stagiaire ID: $_connectedStagiaireId');

      final history = await _statsRepository.getQuizHistory();
      debugPrint('QuizHistory (raw):');
      for (var h in history) {
        debugPrint(
          'id: ${h.id}, quizId: ${h.quiz.id}, completedAt: ${h.completedAt}, score: ${h.score}, totalQuestions: ${h.totalQuestions}, correctAnswers: ${h.correctAnswers}',
        );
      }
      setState(() {
        _futureQuizHistory = Future.value(history);
        _playedQuizIds = history.map((h) => h.quiz.id.toString()).toList();
        _quizHistoryList = history;
      });
      // Si déjà des quiz en base, tenter de sélectionner la formation du dernier quiz joué
      if (_baseQuizzes.isNotEmpty) {
        _selectFormationFromLastPlayedIfAny();
      }
    } catch (e) {
      debugPrint('Erreur chargement historique: $e');
    }
  }

  Future<void> _loadQuizzes() async {
    try {
      final quizzes = await _quizRepository.getQuizzesForStagiaire(
        stagiaireId: _connectedStagiaireId!,
      );
      final filteredQuizzes = _filterQuizzesByPoints(quizzes, _userPoints);

      // Extraire les niveaux et formations disponibles
      _extractAvailableFilters(filteredQuizzes);
      // Tenter de sélectionner la formation basée sur la dernière participation
      _selectFormationFromLastPlayedIfAny();
      // Sélectionner par défaut la première formation disponible si aucune sélection
      if (_selectedFormation == null && _availableFormations.isNotEmpty) {
        _selectedFormation = _availableFormations.first;
      }

      setState(() {
        _futureQuizzes = Future.value(filteredQuizzes);
        _baseQuizzes = filteredQuizzes;
      });
      _applyFilters();
      _selectFormationFromLastPlayedIfAny();
    } catch (e) {
      debugPrint('Erreur chargement quiz: $e');
      setState(() => _futureQuizzes = Future.value([]));
    }
  }

  void _extractAvailableFilters(List<quiz_model.Quiz> quizzes) {
    final levels = <String>{};
    final formations = <String>{};

    for (final quiz in quizzes) {
      if (quiz.niveau.isNotEmpty) {
        levels.add(quiz.niveau);
      }
      if (quiz.formation.titre.isNotEmpty) {
        formations.add(quiz.formation.titre);
      }
    }

    _availableLevels = levels.toList()..sort();
    _availableFormations = formations.toList()..sort();
  }

  // _separateQuizzes supprimé: remplacé par _applyFilters()

  void _applyFilters() {
    List<quiz_model.Quiz> list = [..._baseQuizzes];
    if (_selectedLevel != null) {
      list = list.where((q) => q.niveau == _selectedLevel).toList();
    }
    if (_selectedFormation != null) {
      list =
          list.where((q) => q.formation.titre == _selectedFormation).toList();
    }
    final played =
        list.where((q) => _playedQuizIds.contains(q.id.toString())).toList();
    final unplayed =
        list.where((q) => !_playedQuizIds.contains(q.id.toString())).toList();

    if (_quizHistoryList.isNotEmpty) {
      played.sort((a, b) {
        final ha = _quizHistoryList.firstWhere(
          (h) => h.quiz.id.toString() == a.id.toString(),
          orElse:
              () => QuizHistory(
                id: '',
                quiz: a,
                score: 0,
                completedAt: '',
                timeSpent: 0,
                totalQuestions: 0,
                correctAnswers: 0,
              ),
        );
        final hb = _quizHistoryList.firstWhere(
          (h) => h.quiz.id.toString() == b.id.toString(),
          orElse:
              () => QuizHistory(
                id: '',
                quiz: b,
                score: 0,
                completedAt: '',
                timeSpent: 0,
                totalQuestions: 0,
                correctAnswers: 0,
              ),
        );
        try {
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
      for (var quiz in list) {
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
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
        const SizedBox(height: 8),
        // Row(
        //   children: [
        //     OutlinedButton.icon(
        //       onPressed: () async {
        //         // Scroll to available section (top)
        //         _scrollController.animateTo(
        //           0,
        //           duration: const Duration(milliseconds: 500),
        //           curve: Curves.easeInOut,
        //         );
        //       },
        //       icon: const Icon(Icons.playlist_add_check),
        //       label: const Text('Disponibles'),
        //     ),
        //     const SizedBox(width: 8),
        //     OutlinedButton.icon(
        //       onPressed: _scrollToPlayedQuizzes,
        //       icon: const Icon(Icons.history),
        //       label: const Text('Déjà joués'),
        //     ),
        //   ],
        // ),
        const SizedBox(height: 10),
        if (_availableFormations.isNotEmpty)
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
                      color: theme.colorScheme.primary.withOpacity(0.5),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _selectedFormation ?? 'Choisir une formation',
                        style: TextStyle(
                          color: theme.colorScheme.onSurface.withOpacity(0.8),
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
              if (_selectedFormation != null) ...[
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Réinitialiser',
                  onPressed: () {
                    setState(() => _selectedFormation = null);
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
        // if (_selectedLevel != null || _selectedFormation != null) ...[
        //   const SizedBox(height: 8),
        //   Container(
        //     padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        //     decoration: BoxDecoration(
        //       color: theme.colorScheme.primary.withOpacity(0.1),
        //       borderRadius: BorderRadius.circular(20),
        //       border: Border.all(
        //         color: theme.colorScheme.primary.withOpacity(0.3),
        //       ),
        //     ),
        //     child: Row(
        //       mainAxisSize: MainAxisSize.min,
        //       children: [
        //         Icon(
        //           Icons.filter_list,
        //           size: 16,
        //           color: theme.colorScheme.primary,
        //         ),
        //         const SizedBox(width: 6),
        //         Text(
        //           _buildFilterText(),
        //           style: theme.textTheme.bodySmall?.copyWith(
        //             color: theme.colorScheme.primary,
        //             fontWeight: FontWeight.w500,
        //           ),
        //         ),
        //         const SizedBox(width: 8),
        //         GestureDetector(
        //           onTap: () {
        //             setState(() {
        //               _selectedLevel = null;
        //               _selectedFormation = null;
        //             });
        //             _applyFilters();
        //             _scrollController.animateTo(
        //               0,
        //               duration: const Duration(milliseconds: 400),
        //               curve: Curves.easeInOut,
        //             );
        //           },
        //           child: Icon(
        //             Icons.close,
        //             size: 16,
        //             color: theme.colorScheme.primary,
        //           ),
        //         ),
        //       ],
        //     ),
        //   ),
        // ],
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildQuizListContent(ThemeData theme) {
    if (_isInitialLoad) {
      return SliverFillRemaining(child: _buildLoadingScreen(theme));
    }
    final unplayed = _visibleUnplayed;
    final played = _visiblePlayed;
    final displayedPlayed = _showAllPlayed ? played : played.take(5).toList();
    return SliverList(
      delegate: SliverChildListDelegate([
        if (unplayed.isNotEmpty) ...[
          _buildSectionTitle('Quiz disponibles', theme),
          ...unplayed
              .map(
                (quiz) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildQuizCard(
                    quiz,
                    _expandedQuizzes[quiz.id] ?? false,
                    theme,
                  ),
                ),
              )
              .toList(),
          const SizedBox(height: 16),
        ],
        if (played.isNotEmpty) ...[
          _buildSectionTitle('Historique de vos quiz déjà jouer', theme),
          ...displayedPlayed
              .map(
                (quiz) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildPlayedQuizCard(quiz, theme),
                ),
              )
              .toList(),
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

        // Correction NaN : si totalQuestions == 0, afficher 0%
        final scorePercentage =
            (history.totalQuestions == 0)
                ? 0
                : (history.correctAnswers / history.totalQuestions * 100)
                    .round();

        // Gestion du format de date invalide + debug valeur brute
        String formattedDate;
        String debugDate = history.completedAt;
        try {
          formattedDate =
              'Terminé le ' +
              DateFormat(
                'dd/MM/yyyy',
              ).format(DateTime.parse(history.completedAt));
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
                color: Colors.black.withOpacity(0.1),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              // Header
              InkWell(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                onTap:
                    () =>
                        setState(() => _expandedQuizzes[quiz.id] = !isExpanded),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      // Score circle
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 48,
                            height: 48,
                            child: CircularProgressIndicator(
                              value: scorePercentage / 100,
                              backgroundColor: categoryColor.withOpacity(0.1),
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
                      // Title and date
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
                                color: theme.colorScheme.onSurface.withOpacity(
                                  0.6,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              formattedDate,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface.withOpacity(
                                  0.6,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Chevron
                      Icon(
                        isExpanded ? Icons.expand_less : Icons.expand_more,
                        color: categoryColor,
                      ),
                    ],
                  ),
                ),
              ),

              // Expanded content
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
                      Divider(color: theme.dividerColor.withOpacity(0.2)),
                      const SizedBox(height: 12),
                      // Stats
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
                      // Retry button
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
                            'REJOUER CE QUIZ',
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
            color: theme.colorScheme.onSurface.withOpacity(0.6),
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

      // Mettre à jour l'état pour indiquer que le quiz a été joué
      setState(() {
        _playedQuizIds.add(quiz.id.toString());
      });

      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (_) => QuizSessionPage(
                quiz: quiz,
                questions: questions,
                quizAdventureEnabled: widget.quizAdventureEnabled,
              ),
        ),
      );

      // Rafraîchir les données si le quiz a été complété
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
            color: Colors.black.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          InkWell(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            onTap:
                () => setState(() => _expandedQuizzes[quiz.id] = !isExpanded),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Icon with gradient
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [categoryColor.withOpacity(0.8), categoryColor],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.quiz, color: Colors.white),
                  ),
                  const SizedBox(width: 16),
                  // Title and subtitle - now takes full available width
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
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Chevron only in header now
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: categoryColor,
                  ),
                ],
              ),
            ),
          ),

          // Expandable content
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
                  Divider(color: theme.dividerColor.withOpacity(0.2)),
                  const SizedBox(height: 12),
                  // Quiz details - Points badge moved here
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
                                color: theme.colorScheme.onSurface.withOpacity(
                                  0.6,
                                ),
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
                  // Start button
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
                        'COMMENCER LE QUIZ',
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
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
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
            color: theme.colorScheme.primary.withOpacity(0.5),
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

  // _buildErrorState supprimé (flux simplifié)

  // _buildQuizShimmer supprimé (flux simplifié)

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
                      // Filtre par niveau
                      Text(
                        'Niveau',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _selectedLevel,
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

                      // Filtre par formation
                      Text(
                        'Formation',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _selectedFormation,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        hint: const Text('Toutes les formations'),
                        items: [
                          const DropdownMenuItem<String>(
                            value: null,
                            child: Text('Toutes les formations'),
                          ),
                          ..._availableFormations.map(
                            (formation) => DropdownMenuItem<String>(
                              value: formation,
                              child: Text(formation),
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          setDialogState(() {
                            _selectedFormation = value;
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
                          _selectedFormation = null;
                        });
                      },
                      child: const Text('Réinitialiser'),
                      style: TextButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.error,
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Annuler'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        setState(
                          () {},
                        ); // Rafraîchir l'affichage avec les filtres
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
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        final items = [..._availableFormations];
        return ListView.separated(
          shrinkWrap: true,
          padding: const EdgeInsets.all(8),
          itemBuilder: (_, i) {
            final title = items[i];
            final selected = (_selectedFormation == title);
            return ListTile(
              leading: Icon(
                Icons.school,
                color: selected ? Theme.of(context).colorScheme.primary : null,
              ),
              title: Text(title),
              trailing:
                  selected
                      ? Icon(
                        Icons.check,
                        color: Theme.of(context).colorScheme.primary,
                      )
                      : null,
              onTap: () {
                setState(() {
                  _selectedFormation = title;
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
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemCount: items.length,
        );
      },
    );
  }

  void _showHowToPlayDialog() {
    showStandardHelpDialog(
      context,
      title: 'Comment jouer ?',
      steps: const [
        '1. Choisissez un quiz dans la liste',
        '2. Répondez aux questions qui s\'affichent',
        '3. Validez vos réponses',
        '4. Découvrez votre score à la fin !',
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
        color: theme.colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.6),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star_rounded, size: 18, color: theme.colorScheme.primary),
          const SizedBox(width: 6),
          Text(
            '$_userPoints points',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  List<quiz_model.Quiz> _filterQuizzesByPoints(
    List<quiz_model.Quiz> allQuizzes,
    int userPoints,
  ) {
    if (allQuizzes.isEmpty) return [];

    String normalizeLevel(String? level) {
      if (level == null) return 'débutant';
      final lvl = level.toLowerCase().trim();
      if (lvl.contains('inter') || lvl.contains('moyen'))
        return 'intermédiaire';
      if (lvl.contains('avancé') || lvl.contains('expert')) return 'avancé';
      return 'débutant';
    }

    final debutant =
        allQuizzes
            .where((q) => normalizeLevel(q.niveau) == 'débutant')
            .toList();
    final intermediaire =
        allQuizzes
            .where((q) => normalizeLevel(q.niveau) == 'intermédiaire')
            .toList();
    final avance =
        allQuizzes.where((q) => normalizeLevel(q.niveau) == 'avancé').toList();

    if (userPoints < 10) return debutant.take(2).toList();
    if (userPoints < 20) return debutant.take(4).toList();
    if (userPoints < 40) return [...debutant, ...intermediaire.take(2)];
    if (userPoints < 60) return [...debutant, ...intermediaire];
    if (userPoints < 80)
      return [...debutant, ...intermediaire, ...avance.take(2)];
    if (userPoints < 100)
      return [...debutant, ...intermediaire, ...avance.take(4)];
    return [...debutant, ...intermediaire, ...avance];
  }

  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  void _selectFormationFromLastPlayedIfAny() {
    if (_selectedFormation != null)
      return; // ne pas override le choix utilisateur
    if (_quizHistoryList.isEmpty || _availableFormations.isEmpty) return;
    DateTime _parseDate(String s) =>
        DateTime.tryParse(s) ?? DateTime.fromMillisecondsSinceEpoch(0);
    final sorted = List<QuizHistory>.from(_quizHistoryList)..sort(
      (a, b) => _parseDate(b.completedAt).compareTo(_parseDate(a.completedAt)),
    );
    final last = sorted.first;
    final lastFormationTitle = last.quiz.formation.titre;
    if (lastFormationTitle.isNotEmpty &&
        _availableFormations.contains(lastFormationTitle)) {
      setState(() {
        _selectedFormation = lastFormationTitle;
      });
      _applyFilters();
    }
  }
}
