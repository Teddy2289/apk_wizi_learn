import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
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

class QuizPage extends StatefulWidget {
  const QuizPage({super.key});

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

  @override
  void initState() {
    super.initState();
    _initializeRepositories();
    _loadInitialData();
    _scrollController.addListener(_scrollListener);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map<String, dynamic> && args['fromNotification'] == true) {
        setState(() => _fromNotification = true);
      }
    });
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
      final history = await _statsRepository.getQuizHistory();
      setState(() {
        _futureQuizHistory = Future.value(history);
        _playedQuizIds = history.map((h) => h.quiz.id).toList();
      });
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

      setState(() {
        _futureQuizzes = Future.value(filteredQuizzes);
        _expandedQuizzes.clear();
        for (var quiz in filteredQuizzes) {
          _expandedQuizzes.putIfAbsent(quiz.id, () => false);
        }
      });
    } catch (e) {
      debugPrint('Erreur chargement quiz: $e');
      setState(() => _futureQuizzes = Future.value([]));
    }
  }

  Map<String, List<quiz_model.Quiz>> _separateQuizzes(
    List<quiz_model.Quiz> allQuizzes,
  ) {
    final played =
        allQuizzes
            .where((q) => _playedQuizIds.contains(q.id.toString()))
            .toList();
    final unplayed =
        allQuizzes
            .where((q) => !_playedQuizIds.contains(q.id.toString()))
            .toList();
    return {'played': played, 'unplayed': unplayed};
  }

  void _scrollListener() {
    if (_scrollController.offset >= 400 && !_showBackToTopButton) {
      setState(() => _showBackToTopButton = true);
    } else if (_scrollController.offset < 400 && _showBackToTopButton) {
      setState(() => _showBackToTopButton = false);
    }
  }

  void _replayQuiz(quiz_model.Quiz quiz) async {
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

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => QuizSessionPage(quiz: quiz, questions: questions),
        ),
      ).then((_) => _loadInitialData()); // Rafraîchir les données après retour
    } catch (e) {
      _showErrorSnackbar('Erreur de chargement des questions');
    }
  }

  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    final bool useCustomScaffold = args?['useCustomScaffold'] ?? _fromNotification;
    final bool scrollToPlayed = args?['scrollToPlayed'] ?? false;
    final int selectedTabIndex = args?['selectedTabIndex'] ?? 2; // Valeur par défaut

    // Ajout du toggle pour le mode interactif
    bool _isAdventureMode = false;

    return useCustomScaffold
        ? CustomScaffold(
      body: _isInitialLoad
          ? _buildLoadingScreen(theme)
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 8, left: 16, right: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text('Mode interactif', style: theme.textTheme.bodyMedium),
                      Switch(
                        value: _isAdventureMode,
                        onChanged: (val) {
                          if (val) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const QuizAdventurePage(),
                              ),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
                Expanded(child: _buildMainContent(theme, scrollToPlayed: scrollToPlayed)),
              ],
            ),
      currentIndex: selectedTabIndex,
      onTabSelected: (index) {
        // Gestion de la navigation entre onglets
        if (index != selectedTabIndex) {
          Navigator.pushReplacementNamed(
            context,
            RouteConstants.dashboard,
            arguments: index,
          );
        }
      },
      showBanner: true,
    )
        : Scaffold(
      appBar: AppBar(
        title: const Text('Mes Quiz'),
        centerTitle: true,
        backgroundColor: isDarkMode ? theme.appBarTheme.backgroundColor : Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          Row(
            children: [
              Text('Mode interactif', style: theme.textTheme.bodyMedium),
              Switch(
                value: _isAdventureMode,
                onChanged: (val) {
                  if (val) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const QuizAdventurePage(),
                      ),
                    );
                  }
                },
              ),
            ],
          ),
        ],
      ),
      body: _isInitialLoad
          ? _buildLoadingScreen(theme)
          : _buildMainContent(theme, scrollToPlayed: scrollToPlayed),
      floatingActionButton: _showBackToTopButton
          ? FloatingActionButton(
        onPressed: _scrollToTop,
        mini: true,
        backgroundColor: theme.colorScheme.primary,
        child: Icon(Icons.arrow_upward, color: theme.colorScheme.onPrimary),
      )
          : null,
    );
  }

  Widget _buildMainContent(ThemeData theme, {bool scrollToPlayed = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollToPlayed) {
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
    });
    return RefreshIndicator(
      onRefresh: _loadInitialData,
      child: CustomScrollView(
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
  }

  Future<double> _calculatePlayedQuizzesPosition() async {
    if (_futureQuizzes == null) return 0;

    try {
      final quizzes = await _futureQuizzes!;
      final unplayedCount = _separateQuizzes(quizzes)['unplayed']?.length ?? 0;
      // Estimation: 200px par élément (header + 1 item)
      final headerHeight = 100.0; // Hauteur approximative du header
      const itemHeight = 120.0; // Hauteur approximative d'un item de quiz
      return headerHeight + (unplayedCount * itemHeight);
    } catch (e) {
      debugPrint('Erreur calcul position: $e');
      return 0;
    }
  }

  Widget _buildHeader(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Vos quiz',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Testez vos connaissances avec ces quiz',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildQuizListContent(ThemeData theme) {
    if (_futureQuizzes == null) {
      return SliverFillRemaining(child: _buildEmptyState(theme));
    }

    return FutureBuilder<List<quiz_model.Quiz>>(
      future: _futureQuizzes,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !_isInitialLoad) {
          return SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => _buildQuizShimmer(theme),
              childCount: 3,
            ),
          );
        }

        if (snapshot.hasError) {
          return SliverFillRemaining(child: _buildErrorState(theme));
        }

        if (snapshot.hasData) {
          final separated = _separateQuizzes(snapshot.data!);
          final unplayed = separated['unplayed']!;
          final played = separated['played']!;

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
                ...played
                    .map(
                      (quiz) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildPlayedQuizCard(quiz, theme),
                      ),
                    )
                    .toList(),
              ],

              if (unplayed.isEmpty && played.isEmpty) _buildEmptyState(theme),
            ]),
          );
        }

        return SliverFillRemaining(child: _buildLoadingScreen(theme));
      },
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
          (h) => h.quiz.id == quiz.id.toString(),
          orElse:
              () => QuizHistory(
                id: '',
                quiz: Quiz(id: '', title: '', category: '', level: ''),
                score: 0,
                completedAt: '',
                timeSpent: 0,
                totalQuestions: 0,
                correctAnswers: 0,
              ),
        );

        final scorePercentage =
            (history.correctAnswers / history.totalQuestions * 100).round();

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
                            const SizedBox(height: 4),
                            Text(
                              'Terminé le ${DateFormat('dd/MM/yyyy').format(DateTime.parse(history.completedAt))}',
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
                            '${quiz.nbPointsTotal}',
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


      Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CustomScaffold(
              body: QuizSessionPage(
                quiz: quiz,
                questions: questions,
              ),
              currentIndex: 2,
              onTabSelected: (index) => Navigator.pushReplacementNamed(
                  context,
                  RouteConstants.dashboard,
                  arguments: index
              ),
              showBanner: true,
            ),
          ),
      );// Rafraîchir les données après retour
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
                              '${quiz.nbPointsTotal} points',
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

  Widget _buildErrorState(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
          const SizedBox(height: 16),
          Text(
            'Erreur de chargement',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Nous n\'avons pas pu charger vos quiz. Veuillez réessayer.',
            style: theme.textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadInitialData,
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }

  Widget _buildQuizShimmer(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        height: 16,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: 120,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
