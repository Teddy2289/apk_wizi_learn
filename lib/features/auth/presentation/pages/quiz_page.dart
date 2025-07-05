import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
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
  final Map<int, bool> _expandedQuizzes = {};
  final ScrollController _scrollController = ScrollController();
  bool _showBackToTopButton = false;
  bool _isInitialLoad = true;
  int? _connectedStagiaireId;
  int _userPoints = 0;
  bool _fromNotification = false;

  @override
  void initState() {
    super.initState();
    _initializeRepositories();
    _loadConnectedUserAndQuizzes();
    _scrollController.addListener(_scrollListener);

    // Vérifier si on vient d'une notification
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map<String, dynamic> && args['fromNotification'] == true) {
        setState(() {
          _fromNotification = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.offset >= 400 && !_showBackToTopButton) {
      setState(() => _showBackToTopButton = true);
    } else if (_scrollController.offset < 400 && _showBackToTopButton) {
      setState(() => _showBackToTopButton = false);
    }
  }

  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
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

  Future<void> _loadQuizzesForConnectedStagiaire() async {
    setState(() => _isInitialLoad = true);
    try {
      final user = await _authRepository.getMe();
      final connectedStagiaireId = user.stagiaire?.id;

      if (connectedStagiaireId == null) {
        setState(() {
          _futureQuizzes = Future.value([]);
          _isInitialLoad = false;
        });
        return;
      }

      final quizzes = await _quizRepository.getQuizzesForStagiaire(
        stagiaireId: connectedStagiaireId,
      );

      setState(() {
        _futureQuizzes = Future.value(quizzes);
        _isInitialLoad = false;
        for (var quiz in quizzes) {
          _expandedQuizzes.putIfAbsent(quiz.id, () => false);
        }
      });
    } catch (e) {
      debugPrint('Erreur chargement quiz: $e');
      setState(() {
        _futureQuizzes = Future.value([]);
        _isInitialLoad = false;
      });
    }
  }

  Future<void> _loadConnectedUserAndQuizzes() async {
    setState(() => _isInitialLoad = true);
    try {
      final user = await _authRepository.getMe();
      _connectedStagiaireId = user.stagiaire?.id;
      debugPrint("ID du stagiaire connecté: $_connectedStagiaireId");

      if (_connectedStagiaireId == null) {
        setState(() {
          _futureQuizzes = Future.value([]);
          _isInitialLoad = false;
        });
        return;
      }

      final rankings = await _statsRepository.getGlobalRanking();
      debugPrint("Classement global reçu: ${rankings.length} éléments");

      final userRanking = rankings.firstWhere(
        (r) => r.stagiaire.id == _connectedStagiaireId.toString(),
        orElse: () {
          debugPrint("Utilisateur non trouvé dans le classement");
          return GlobalRanking.empty();
        },
      );

      _userPoints = userRanking.totalPoints;
      debugPrint("Points de l'utilisateur: $_userPoints");

      final allQuizzes = await _quizRepository.getQuizzesForStagiaire(
        stagiaireId: _connectedStagiaireId!,
      );

      debugPrint("Quiz reçus: ${allQuizzes.length}");

      final filteredQuizzes = _filterQuizzesByPoints(allQuizzes, _userPoints);

      setState(() {
        _futureQuizzes = Future.value(filteredQuizzes);
        _isInitialLoad = false;
        for (var quiz in filteredQuizzes) {
          _expandedQuizzes.putIfAbsent(quiz.id, () => false);
        }
      });
    } catch (e, stackTrace) {
      debugPrint('Erreur chargement quiz: $e');
      debugPrint('Stack trace: $stackTrace');
      setState(() {
        _futureQuizzes = Future.value([]);
        _isInitialLoad = false;
      });
    }
  }

  List<quiz_model.Quiz> _filterQuizzesByPoints(
    List<quiz_model.Quiz> allQuizzes,
    int userPoints,
  ) {
    if (allQuizzes.isEmpty) {
      debugPrint("Aucun quiz à filtrer");
      return [];
    }

    // Normaliser les niveaux
    String normalizeLevel(String? level) {
      final lvl = level?.toLowerCase().trim() ?? 'débutant';
      if (lvl.contains('inter') || lvl.contains('moyen'))
        return 'intermédiaire';
      if (lvl.contains('avancé') || lvl.contains('expert')) return 'avancé';
      return 'débutant'; // Par défaut
    }

    // Trier par niveau
    allQuizzes.sort(
      (a, b) => normalizeLevel(a.niveau).compareTo(normalizeLevel(b.niveau)),
    );

    debugPrint("Filtrage pour $userPoints points");

    if (userPoints < 20) {
      return allQuizzes
          .where((q) => normalizeLevel(q.niveau) == 'débutant')
          .toList();
    } else if (userPoints < 40) {
      final debutant =
          allQuizzes
              .where((q) => normalizeLevel(q.niveau) == 'débutant')
              .toList();
      final intermediaire =
          allQuizzes
              .where((q) => normalizeLevel(q.niveau) == 'intermédiaire')
              .take(1)
              .toList();
      return [...debutant, ...intermediaire];
    } else if (userPoints < 60) {
      final debutant =
          allQuizzes
              .where((q) => normalizeLevel(q.niveau) == 'débutant')
              .toList();
      final intermediaire =
          allQuizzes
              .where((q) => normalizeLevel(q.niveau) == 'intermédiaire')
              .take(2)
              .toList();
      return [...debutant, ...intermediaire];
    } else if (userPoints < 80) {
      final debutant =
          allQuizzes
              .where((q) => normalizeLevel(q.niveau) == 'débutant')
              .toList();
      final intermediaire =
          allQuizzes
              .where((q) => normalizeLevel(q.niveau) == 'intermédiaire')
              .toList();
      final avance =
          allQuizzes
              .where((q) => normalizeLevel(q.niveau) == 'avancé')
              .take(2)
              .toList();
      return [...debutant, ...intermediaire, ...avance];
    } else {
      return allQuizzes;
    }
  }

  int _getLimitedPoints(String level, int points) {
    if (level == 'débutant') {
      return points > 10 ? 10 : points;
    } else if (level == 'intermédiaire') {
      return points > 20 ? 20 : points;
    } else if (level == 'avancé') {
      return points > 20 ? 20 : points;
    }
    return points;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    // Si on vient d'une notification, utiliser CustomScaffold
    if (_fromNotification) {
      return CustomScaffold(
        body:
            _isInitialLoad
                ? _buildLoadingScreen(theme)
                : _buildMainContent(theme),
        currentIndex: 2, // Index de l'onglet Quiz
        onTabSelected: (index) {
          // Navigation vers les autres onglets
          Navigator.pushReplacementNamed(
            context,
            RouteConstants.dashboard,
            arguments: index,
          );
        },
        showBanner: true,
      );
    }

    // Sinon, utiliser le Scaffold normal
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes Quiz'),
        centerTitle: true,
        backgroundColor:
            isDarkMode ? theme.appBarTheme.backgroundColor : Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        foregroundColor: isDarkMode ? Colors.white : Colors.black87,
      ),
      body:
          _isInitialLoad
              ? _buildLoadingScreen(theme)
              : _buildMainContent(theme),
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

  Widget _buildMainContent(ThemeData theme) {
    return RefreshIndicator(
      onRefresh: _loadQuizzesForConnectedStagiaire,
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

  Widget _buildHeader(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Vos quiz disponibles',
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
          final quizzes = snapshot.data!;
          if (quizzes.isNotEmpty) {
            return SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildQuizCard(
                    quizzes[index],
                    _expandedQuizzes[quizzes[index].id] ?? false,
                    theme,
                  ),
                ),
                childCount: quizzes.length,
              ),
            );
          }
          return SliverFillRemaining(child: _buildEmptyState(theme));
        }

        return SliverFillRemaining(child: _buildLoadingScreen(theme));
      },
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

  Widget _buildInfoRow(IconData icon, String text, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: theme.textTheme.bodyMedium)),
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
            onPressed: _loadQuizzesForConnectedStagiaire,
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

  Widget _buildQuizCard(
    quiz_model.Quiz quiz,
    bool isExpanded,
    ThemeData theme,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          setState(() {
            _expandedQuizzes[quiz.id] = !isExpanded;
          });
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.quiz, color: theme.colorScheme.primary),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          quiz.titre,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          quiz.formation.titre,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: theme.colorScheme.primary,
                  ),
                ],
              ),
              if (isExpanded) ...[
                const SizedBox(height: 16),
                Divider(height: 1, color: theme.dividerColor.withOpacity(0.3)),
                const SizedBox(height: 12),
                _buildInfoRow(
                  Icons.school,
                  'Formation: ${quiz.formation.titre}',
                  theme,
                ),
                _buildInfoRow(
                  Icons.star,
                  'Points: ${_getLimitedPoints(quiz.niveau, quiz.nbPointsTotal)}',
                  theme,
                ),
                _buildInfoRow(
                  Icons.assessment,
                  'Niveau: ${quiz.niveau}',
                  theme,
                ),
                const SizedBox(height: 12),
                Text(
                  'Description',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  quiz.description ?? 'Aucune description disponible',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.8),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                    onPressed: () async {
                      try {
                        final questions = await _quizRepository
                            .getQuizQuestions(quiz.id);

                        if (questions.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text(
                                'Aucune question disponible pour ce quiz',
                              ),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              margin: const EdgeInsets.all(20),
                            ),
                          );
                          return;
                        }

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (_) => QuizSessionPage(
                                  quiz: quiz,
                                  questions: questions,
                                ),
                          ),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text(
                              'Erreur de chargement des questions',
                            ),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            margin: const EdgeInsets.all(20),
                          ),
                        );
                      }
                    },
                    child: const Text('Commencer le quiz'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
