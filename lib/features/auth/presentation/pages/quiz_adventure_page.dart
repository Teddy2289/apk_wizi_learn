import 'package:flutter/material.dart';
import 'package:wizi_learn/features/auth/data/repositories/quiz_repository.dart';
import 'package:wizi_learn/features/auth/data/repositories/stats_repository.dart';
import 'package:wizi_learn/features/auth/data/models/quiz_model.dart'
    as quiz_model;
import 'package:wizi_learn/features/auth/data/models/stats_model.dart'
    as stats_model;
import 'package:wizi_learn/features/auth/presentation/pages/quiz_session_page.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio/dio.dart';
import 'package:wizi_learn/core/network/api_client.dart';
import 'package:confetti/confetti.dart';
import 'package:wizi_learn/features/auth/presentation/pages/achievement_page.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wizi_learn/features/auth/presentation/widgets/mission_card.dart';
import 'package:wizi_learn/features/auth/data/models/mission_model.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import 'package:wizi_learn/features/auth/data/repositories/auth_repository.dart';
import 'package:wizi_learn/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:wizi_learn/features/auth/presentation/pages/quiz_page.dart';
import 'package:wizi_learn/core/constants/route_constants.dart';
import 'package:wizi_learn/features/auth/presentation/widgets/help_dialog.dart';
import 'package:wizi_learn/features/auth/services/quiz_resume_service.dart';
import 'package:wizi_learn/features/auth/presentation/components/resume_quiz_dialog.dart';
import 'package:wizi_learn/features/auth/auth_injection_container.dart';

class QuizAdventurePage extends StatefulWidget {
  final bool quizAdventureEnabled;
  const QuizAdventurePage({super.key, this.quizAdventureEnabled = true});

  @override
  State<QuizAdventurePage> createState() => _QuizAdventurePageState();
}

class _QuizAdventurePageState extends State<QuizAdventurePage>
    with TickerProviderStateMixin {
  late final ApiClient _apiClient;
  late final QuizRepository _quizRepository;
  late final StatsRepository _statsRepository;
  late final AuthRepository _authRepository;
  int? _connectedStagiaireId;
  List<quiz_model.Quiz> _allQuizzes = [];
  List<quiz_model.Quiz> _quizzes = [];
  List<String> _playedQuizIds = [];
  bool _isLoading = true;
  int _userPoints = 0;
  ConfettiController? _confettiController;
  int _lastCompletedCount = 0;
  List<stats_model.QuizHistory> _quizHistory = [];
  final AudioPlayer _audioPlayer = AudioPlayer();
  // Avatar & boutique supprimés
  int _loginStreak =
      1; // Valeur simulée pour la démo, à remplacer par la vraie valeur API si dispo
  final bool _showMissions = false;
  String? _selectedFormationTitle;
  List<String> _availableFormationTitles = [];
  bool _showAllForFormation = false;
  final ScrollController _scrollController = ScrollController();
  bool _showBackToTopButton = false;

  // GlobalKeys pour le tutoriel interactif
  // Clés liées à la boutique/avatar supprimées
  final GlobalKey _keyBadges = GlobalKey();
  final GlobalKey _keyProgress = GlobalKey();
  final GlobalKey _keyMission = GlobalKey();
  final GlobalKey _keyQuiz = GlobalKey();
  // TutorialCoachMark? _tutorialCoachMark; // Unused field removed
  // bool _tutorialShown = false; // Unused field removed

  @override
  void initState() {
    super.initState();
    _initializeRepositories();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 2),
    );
    // Animations avatar supprimées
    _scrollController.addListener(() {
      final show = _scrollController.offset >= 400;
      if (show != _showBackToTopButton && mounted) {
        setState(() => _showBackToTopButton = show);
      }
    });
    _primeStreakFromLocal();
    _loadLoginStreak();
    // Chargement avatar supprimé
    _loadInitialData();
    // _checkAndShowTutorial();
  }

  void _initializeRepositories() {
    final dio = Dio();
    final storage = const FlutterSecureStorage();
    final apiClient = ApiClient(dio: dio, storage: storage);

    _apiClient = apiClient;
    _quizRepository = QuizRepository(apiClient: apiClient);
    _statsRepository = StatsRepository(apiClient: apiClient);
    _authRepository = AuthRepository(
      remoteDataSource: AuthRemoteDataSourceImpl(
        apiClient: apiClient,
        storage: storage,
      ),
      storage: storage,
    );
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    try {
      final user = await _authRepository.getMe();
      _connectedStagiaireId = user.stagiaire?.id;
      if (_connectedStagiaireId == null) {
        setState(() => _isLoading = false);
        return;
      }
      final quizzes = await _quizRepository.getQuizzesForStagiaire(
        stagiaireId: _connectedStagiaireId,
      );
      print('--- QUIZZES RECUS ---');
      for (var q in quizzes) {
        print(
          'id= [32m${q.id} [0m, titre=${q.titre}, niveau=${q.niveau}, status=${q.status}',
        );
      }
      print('---------------------');
      final history = await _statsRepository.getQuizHistory(
        page: 1,
        limit: 100,
      );
      final rankings = await _statsRepository.getGlobalRanking();
      final userRanking = rankings.firstWhere(
        (r) => r.stagiaire.id == _connectedStagiaireId.toString(),
        orElse: () => stats_model.GlobalRanking.empty(),
      );
      _userPoints = userRanking.totalPoints;
      final filteredQuizzes = _filterQuizzesByPoints(quizzes, _userPoints);
      setState(() {
        _allQuizzes = quizzes;
        _quizzes = filteredQuizzes;
        _playedQuizIds = history.map((h) => h.quiz.id.toString()).toList();
        _quizHistory = history;
        _isLoading = false;
        // Build available formation titles for filter
        _availableFormationTitles =
            _allQuizzes
                .map((q) => q.formation.titre)
                .where((t) => t.isNotEmpty)
                .toSet()
                .toList()
              ..sort();
      });
      // Sélection formation par dernier quiz joué si possible
      if (_selectedFormationTitle == null &&
          _availableFormationTitles.isNotEmpty) {
        DateTime parseDate(String s) =>
            DateTime.tryParse(s) ?? DateTime.fromMillisecondsSinceEpoch(0);
        final sorted = List<stats_model.QuizHistory>.from(history)..sort(
          (a, b) =>
              parseDate(b.completedAt).compareTo(parseDate(a.completedAt)),
        );
        if (sorted.isNotEmpty) {
          final last = sorted.first;
          final lastTitle = last.quiz.formation.titre;
          if (lastTitle.isNotEmpty &&
              _availableFormationTitles.contains(lastTitle)) {
            setState(() {
              _selectedFormationTitle = lastTitle;
              _showAllForFormation = true;
            });
          }
        }
        // Fallback initial si rien déterminé par l’historique
        if (_selectedFormationTitle == null) {
          _selectedFormationTitle = _availableFormationTitles.first;
          _showAllForFormation = true;
        }
      }
      // Animation confettis si progression
      final completed =
          filteredQuizzes
              .where((q) => _playedQuizIds.contains(q.id.toString()))
              .length;
      if (completed > _lastCompletedCount && _lastCompletedCount != 0) {
        _confettiController?.play();
        await _playSound('audio/success.mp3');
      }
      _lastCompletedCount = completed;
      // Gestion de position avatar supprimée
      // Après chargement, défiler vers le prochain quiz non joué
      _scrollToNextUnplayed();
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _confettiController?.dispose();
    _audioPlayer.dispose();
    // Dispose animations avatar supprimées
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _playSound(String asset) async {
    try {
      await _audioPlayer.play(AssetSource(asset));
    } catch (e) {
      // ignore errors silently
      int loginStreak = await _fetchLoginStreakFromBackend().catchError((
        _,
      ) async {
        try {
          final prefs = await SharedPreferences.getInstance();
          return prefs.getInt('login_streak') ?? 0;
        } catch (_) {
          return 0;
        }
      });

      if (mounted) {
        setState(() {
          _loginStreak = loginStreak;
        });
      }
    } catch (e) {
      debugPrint('Erreur en chargeant login streak: $e');
    }
  }

  // Récupère login_streak depuis /stagiaire/profile, sinon lance une erreur
  Future<int> _fetchLoginStreakFromBackend() async {
    try {
      // L'ApiClient injecte déjà l'Authorization via les interceptors
      final response = await _apiClient.get('/stagiaire/profile');

      final data = response.data;
      if (data is Map) {
        // Plusieurs structures possibles: { stagiaire: { login_streak: N } } ou { login_streak: N }
        final stagiaire = data['stagiaire'];
        final dynamic val =
            stagiaire is Map ? stagiaire['login_streak'] : data['login_streak'];
        int parsed;
        if (val is int) {
          parsed = val;
        } else if (val is String) {
          parsed = int.tryParse(val) ?? 0;
        } else {
          parsed = 0;
        }
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setInt('login_streak', parsed);
        } catch (_) {
          // ignore local persistence errors
        }
        return parsed;
      }
      // Si pas trouvé, lever pour déclencher le repli
      throw Exception('login_streak absent');
    } catch (e) {
      // Propager pour utiliser le repli SharedPreferences
      rethrow;
    }
  }

  // Pré-charge la valeur locale pour un affichage instantané au démarrage
  Future<void> _primeStreakFromLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final local = prefs.getInt('login_streak');
      if (local != null) {
        if (mounted) {
          setState(() {
            _loginStreak = local;
          });
        }
      }
    } catch (_) {
      // ignore
    }
  }

  /// Charge la valeur de "login streak" depuis le backend ou le cache local
  Future<void> _loadLoginStreak() async {
    try {
      final loginStreak = await _fetchLoginStreakFromBackend().catchError((
        _,
      ) async {
        try {
          final prefs = await SharedPreferences.getInstance();
          return prefs.getInt('login_streak') ?? 0;
        } catch (_) {
          return 0;
        }
      });

      if (mounted) {
        setState(() {
          _loginStreak = loginStreak;
        });
      }
    } catch (e) {
      debugPrint('Erreur lors du chargement du login streak: $e');
    }
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

  // Sélection d'avatar supprimée

  // Sélection d'avatar supprimée

  Future<void> _checkAndShowTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getBool('adventure_tutorial_seen') ?? false;
    if (!seen) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _showTutorial());
      await prefs.setBool('adventure_tutorial_seen', true);
    }
  }

  void _showTutorial() {
    TutorialCoachMark(
      targets: _buildTargets(),
      colorShadow: Colors.black,
      textSkip: 'Passer',
      paddingFocus: 8,
      opacityShadow: 0.8,
      onFinish: () {},
      onSkip: () {
        return true;
      },
    ).show(context: context);
  }

  List<TargetFocus> _buildTargets() {
    return [
      // Targets boutique/avatar supprimés
      TargetFocus(
        identify: 'badges',
        keyTarget: _keyBadges,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            child: const Text(
              'Ici, retrouve tous tes badges débloqués !',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
          ),
        ],
      ),
      TargetFocus(
        identify: 'progress',
        keyTarget: _keyProgress,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            child: const Text(
              'Suis ta progression dans l’aventure quiz.',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
          ),
        ],
      ),
      TargetFocus(
        identify: 'mission',
        keyTarget: _keyMission,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            child: const Text(
              'Accomplis des missions pour gagner des récompenses !',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
          ),
        ],
      ),
      TargetFocus(
        identify: 'quiz',
        keyTarget: _keyQuiz,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            child: const Text(
              'Clique sur un quiz débloqué pour commencer à participer.',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
          ),
        ],
      ),
      // Target avatarAnim supprimé
    ];
  }

  /// Filtre les quiz en fonction des points totaux de l'utilisateur
  /// pour un déverrouillage progressif par niveau
  List<quiz_model.Quiz> _filterQuizzesByPoints(List<quiz_model.Quiz> quizzes, int userPoints) {
    if (quizzes.isEmpty) return [];

    // Normaliser les niveaux pour gérer les variations de casse/format
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

    // Séparer les quiz par niveau
    final debutant = quizzes.where((q) => normalizeLevel(q.niveau) == 'débutant').toList();
    final intermediaire = quizzes.where((q) => normalizeLevel(q.niveau) == 'intermédiaire').toList();
    final avance = quizzes.where((q) => normalizeLevel(q.niveau) == 'avancé').toList();
    
    // Simplified 3-tier quiz filtering system:
    // < 50 points: beginner only
    // 50-99 points: beginner + intermediate
    // >= 100 points: all levels
    List<quiz_model.Quiz> result;
    
    if (userPoints < 50) {
      // Moins de 50 points : tous les quiz débutants
      result = debutant;
    } else if (userPoints < 100) {
      // 50-99 points : débutants + intermédiaires
      result = [...debutant, ...intermediaire];
    } else {
      // 100+ points : tous les niveaux
      result = [...debutant, ...intermediaire, ...avance];
    }

    debugPrint('🔒 Filtrage quiz adventure: ${quizzes.length} quiz → ${result.length} accessibles (${userPoints} pts)');
    
    return result;
  }

  Future<void> _startQuiz(quiz_model.Quiz quiz) async {
    if (quiz.questions.isEmpty) return;
    
    await _playSound('audio/click.mp3');
    
    try {
      final questions = await _quizRepository.getQuizQuestions(quiz.id);
      if (questions.isEmpty) return;

      // Check for resume
      final resumeService = sl<QuizResumeService>();
      final sessionData = await resumeService.getSession(quiz.id.toString());
      Map<String, dynamic>? initialSessionData;

      if (sessionData != null && mounted) {
        final shouldResume = await showDialog<bool>(
          context: context,
          builder: (context) => ResumeQuizDialog(
            quizTitle: quiz.titre,
            questionCount: questions.length,
            currentIndex: sessionData['currentIndex'] ?? 0,
            onResume: () => Navigator.pop(context, true),
            onDismiss: () => Navigator.pop(context, false),
          ),
        );

        if (shouldResume == null) return; // Cancelled

        if (shouldResume) {
          initialSessionData = sessionData;
        } else {
          await resumeService.clearSession(quiz.id.toString());
        }
      }

      if (!mounted) return;

      await Navigator.push(
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
      _loadInitialData();
    } catch (e) {
      debugPrint('Error starting quiz: $e');
    }
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
            key: _keyBadges,
            icon: const Icon(Icons.emoji_events),
            tooltip: 'Mes Badges',
            onPressed: () {
              _playSound('audio/click.mp3');
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AchievementPage()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.help_outline),
            tooltip: 'Voir le tutoriel',
            onPressed:
                () => showStandardHelpDialog(
                  context,
                  title: 'Comment participer ?',
                  steps: const [
                    'Choisissez une formation',
                    'Touchez un quiz débloqué pour commencer',
                    'Répondez aux questions et validez',
                    'Consultez votre historique et vos badges',
                  ],
                ),
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
                    value: true,
                    activeColor: Colors.white,
                    activeTrackColor: Colors.black,
                    inactiveThumbColor: Colors.black,
                    inactiveTrackColor: Colors.white,
                    onChanged: (v) async {
                      if (v) return;
                      // Navigate directly to quiz list page (not through dashboard)
                      await Navigator.pushReplacementNamed(
                        context,
                        RouteConstants.quiz,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          _isLoading
              ? Center(
                child: CircularProgressIndicator(
                  color: theme.colorScheme.primary,
                ),
              )
              : _quizzes.isEmpty
              ? Center(child: Text('Aucun quiz disponible'))
              : CustomScrollView(
                key: const PageStorageKey('adventure_scroll'),
                controller: _scrollController,
                slivers: [
                  // Formation picker button
                  if (_availableFormationTitles.isNotEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Row(
                          children: [
                            Icon(
                              Icons.school,
                              color: theme.colorScheme.primary,
                            ),
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
                                    color: theme.colorScheme.primary
                                        .withOpacity(0.5),
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      _selectedFormationTitle == null
                                          ? 'Choisir une formation'
                                          : _selectedFormationTitle!,
                                      style: TextStyle(
                                        color: theme.colorScheme.onSurface
                                            .withOpacity(0.8),
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
                          ],
                        ),
                      ),
                    ),
                  // Voir plus when many quizzes
                  SliverToBoxAdapter(
                    child:
                        (_selectedFormationTitle != null &&
                                !_showAllForFormation &&
                                _getDisplayQuizzes().length > 10)
                            ? Padding(
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: TextButton.icon(
                                  onPressed:
                                      () => setState(
                                        () => _showAllForFormation = true,
                                      ),
                                  icon: const Icon(Icons.expand_more),
                                  label: const Text('Voir plus'),
                                ),
                              ),
                            )
                            : const SizedBox.shrink(),
                  ),
                  SliverToBoxAdapter(
                    child:
                        _showMissions
                            ? DailyMissionsSection(
                              keyMission: _keyMission,
                              loginStreak: _loginStreak,
                              quizHistory: _quizHistory,
                            )
                            : const SizedBox.shrink(),
                  ),
                  SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final displayQuizzes = _getDisplayQuizzes();
                      final quiz = displayQuizzes[index];
                      final isPlayed = _playedQuizIds.contains(
                        quiz.id.toString(),
                      );
                      final isUnlocked = _isQuizUnlocked(index);
                      final history =
                          _quizHistory.isNotEmpty
                              ? _quizHistory.firstWhere(
                                (h) => h.quiz.id == quiz.id.toString(),
                                orElse: () => _quizHistory.first,
                              )
                              : stats_model.QuizHistory(
                                id: '',
                                quiz: quiz,
                                score: 0,
                                completedAt: '',
                                timeSpent: 0,
                                totalQuestions: 0,
                                correctAnswers: 0,
                              );
                      int stars = 0;
                      if (history.totalQuestions > 0) {
                        final percent =
                            (history.correctAnswers / history.totalQuestions) *
                            100;
                        if (percent >= 100) {
                          stars = 3;
                        } else if (percent >= 70)
                          stars = 2;
                        else if (percent >= 40)
                          stars = 1;
                      }
                      final isLeft = index % 2 == 0;
                      // Couleur par catégorie de formation
                      Color categoryColor =
                          Theme.of(context).colorScheme.primary;
                      final cat =
                          (quiz.formation.categorie).trim().toLowerCase();
                      switch (cat) {
                        case 'bureautique':
                          categoryColor = const Color(0xFF3D9BE9);
                          break;
                        case 'langues':
                          categoryColor = const Color(0xFFA55E6E);
                          break;
                        case 'internet':
                          categoryColor = const Color(0xFFFFC533);
                          break;
                        case 'IA':
                          categoryColor = const Color(0xFFABDA96);
                          break;
                        case 'création':
                        case 'creation':
                          categoryColor = const Color(0xFF9392BE);
                          break;
                        default:
                          categoryColor = Theme.of(context).colorScheme.primary;
                      }
                      final nodeColor =
                          isPlayed
                              ? Colors.amber
                              : (isUnlocked ? categoryColor : Colors.grey);

                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 8,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (!isLeft)
                              Expanded(
                                child: _buildStepCard(
                                  quiz,
                                  isPlayed,
                                  isUnlocked,
                                  stars,
                                  nodeColor,
                                  onTap: () {
                                    if (!(isUnlocked || isPlayed) ||
                                        quiz.questions.isEmpty) {
                                      return;
                                    }
                                    _startQuiz(quiz);
                                  },
                                ),
                              ),
                            SizedBox(
                              width: 70,
                              child: Column(
                                children: [
                                  Container(
                                    height: 12,
                                    width: 2,
                                    color:
                                        index == 0
                                            ? Colors.transparent
                                            : Colors.grey.shade300,
                                  ),
                                  Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      Container(
                                        width: 24,
                                        height: 24,
                                        decoration: BoxDecoration(
                                          color: nodeColor.withOpacity(
                                            isUnlocked ? 0.12 : 0.08,
                                          ),
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: nodeColor,
                                            width: 2,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  Container(
                                    height: 60,
                                    width: 2,
                                    color:
                                        index == displayQuizzes.length - 1
                                            ? Colors.transparent
                                            : Colors.grey.shade300,
                                  ),
                                ],
                              ),
                            ),
                            if (isLeft)
                              Expanded(
                                child: _buildStepCard(
                                  quiz,
                                  isPlayed,
                                  isUnlocked,
                                  stars,
                                  nodeColor,
                                  onTap: () {
                                    if (!isUnlocked || quiz.questions.isEmpty) {
                                      return;
                                    }
                                    _startQuiz(quiz);
                                  },
                                ),
                              ),
                          ],
                        ),
                      );
                    }, childCount: _effectiveListLength()),
                  ),
                ],
              ),
          // Confetti animation
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController!,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: const [
                Colors.green,
                Colors.blue,
                Colors.pink,
                Colors.orange,
                Colors.purple,
              ],
              emissionFrequency: 0.08,
              numberOfParticles: 20,
              maxBlastForce: 20,
              minBlastForce: 8,
            ),
          ),
        ],
      ),
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

  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  void _scrollToNextUnplayed() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!_scrollController.hasClients) return;
      final displayQuizzes = _getDisplayQuizzes();
      if (displayQuizzes.isEmpty) return;
      final nextIndex = displayQuizzes.indexWhere(
        (q) => !_playedQuizIds.contains(q.id.toString()),
      );
      if (nextIndex <= 0) return; // déjà en tête ou aucun non joué
      const double headerApproxHeight = 220.0;
      const double itemApproxHeight = 130.0;
      final double position =
          headerApproxHeight + (nextIndex * itemApproxHeight);
      _scrollController.animateTo(
        position,
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeInOut,
      );
    });
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
            style: TextStyle(fontWeight: FontWeight.w700, color: Colors.black),
          ),
        ],
      ),
    );
  }

  void _goToQuizList() async {
    if (!widget.quizAdventureEnabled) {
      // Adventure mode is disabled, stay in current page
      return;
    }
    // Sauvegarder la préférence utilisateur pour la vue liste
    await _saveQuizViewPreference(false);

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder:
            (_, __, ___) =>
                QuizPage(quizAdventureEnabled: false, forceList: true),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 250),
      ),
    );
  }

  Widget _buildStepCard(
    quiz_model.Quiz quiz,
    bool isPlayed,
    bool isUnlocked,
    int stars,
    Color accentColor, {
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final String levelRaw = quiz.niveau.trim();
    final String levelLabel =
        levelRaw.isEmpty
            ? 'Niveau inconnu'
            : (levelRaw[0].toUpperCase() + levelRaw.substring(1).toLowerCase());
    return Opacity(
      opacity: isUnlocked ? 1.0 : 0.8,
      child: InkWell(
        onTap: (isUnlocked || isPlayed) ? onTap : null,
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(
                  color:
                      isPlayed
                          ? accentColor.withOpacity(0.4)
                          : theme.dividerColor.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [accentColor.withOpacity(0.9), accentColor],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Icon(
                      isPlayed
                          ? Icons.emoji_events
                          : (isUnlocked ? Icons.star : Icons.lock),
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          quiz.titre,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.school, size: 14, color: accentColor),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                quiz.formation.titre,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface
                                      .withOpacity(0.6),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.trending_up,
                              size: 14,
                              color: accentColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              levelLabel,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface.withOpacity(
                                  0.7,
                                ),
                              ),
                            ),
                            // Mini stats si historique disponible
                            // if (_quizHistory.isNotEmpty)
                            //   ...(() {
                            //     final h = _quizHistory.firstWhere(
                            //       (qH) =>
                            //           qH.quiz.id.toString() ==
                            //           quiz.id.toString(),
                            //       orElse:
                            //           () => stats_model.QuizHistory(
                            //             id: '',
                            //             quiz: quiz,
                            //             score: 0,
                            //             completedAt: '',
                            //             timeSpent: 0,
                            //             totalQuestions: 0,
                            //             correctAnswers: 0,
                            //           ),
                            //     );
                            //     if (h.totalQuestions == 0) return <Widget>[];
                            //     final percent =
                            //         ((h.correctAnswers / h.totalQuestions) *
                            //                 100)
                            //             .round();
                            //     return <Widget>[
                            //         const SizedBox(width: 10),
                            //         Container(
                            //           padding: const EdgeInsets.symmetric(
                            //             horizontal: 6,
                            //             vertical: 2,
                            //           ),
                            //           decoration: BoxDecoration(
                            //             color: Colors.blue.shade50,
                            //             borderRadius: BorderRadius.circular(10),
                            //           ),
                            //           child: Text(
                            //             '$percent% • ${h.correctAnswers}/${h.totalQuestions}',
                            //             style: theme.textTheme.bodySmall
                            //                 ?.copyWith(
                            //                   color: Colors.blue.shade700,
                            //                 ),
                            //           ),
                            //         ),
                            //     ];
                            //   }()),
                          ],
                        ),
                        if (isPlayed)
                          Padding(
                            padding: const EdgeInsets.only(top: 6.0),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Wrap(
                                spacing: 8,
                                runSpacing: 6,
                                children: [
                                  OutlinedButton.icon(
                                    onPressed:
                                        () => _showQuizHistorySheet(quiz),
                                    icon: const Icon(Icons.history, size: 16),
                                    label: const Text('Historique'),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 8,
                                      ),
                                      visualDensity: VisualDensity.compact,
                                      side: BorderSide(
                                        color: accentColor.withOpacity(0.6),
                                      ),
                                      foregroundColor: accentColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.chevron_right,
                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                  ),
                ],
              ),
            ),
            if (!isUnlocked && !isPlayed)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Center(
                    child: Icon(Icons.lock, size: 28, color: Colors.grey),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  bool _isQuizUnlocked(int index) {
    final list = _getDisplayQuizzes();
    if (index == 0) return true;
    final prevQuiz = list[index - 1];
    return _playedQuizIds.contains(prevQuiz.id.toString());
  }

  List<quiz_model.Quiz> _getDisplayQuizzes() {
    if (_selectedFormationTitle == null) return [];
    final full =
        _allQuizzes
            .where((q) => q.formation.titre == _selectedFormationTitle)
            .toList();
    // Trier: quiz déjà joués en haut, puis par ordre de progression
    full.sort((a, b) {
      final aPlayed = _playedQuizIds.contains(a.id.toString());
      final bPlayed = _playedQuizIds.contains(b.id.toString());
      if (aPlayed && !bPlayed) return -1;
      if (!aPlayed && bPlayed) return 1;
      // Si les deux sont joués ou non joués, garder l'ordre original
      return 0;
    });
    if (_showAllForFormation) return full;
    if (full.length > 10) return full.sublist(0, 10);
    return full;
  }

  void _showFormationPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        final items = [..._availableFormationTitles];
        return ListView.separated(
          shrinkWrap: true,
          padding: const EdgeInsets.all(8),
          itemBuilder: (_, i) {
            final title = items[i];
            final selected = (_selectedFormationTitle == title);
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
                  _selectedFormationTitle = title;
                  _showAllForFormation = false;
                });
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

  int _effectiveListLength() {
    if (_selectedFormationTitle == null) return 0;
    final full =
        _allQuizzes
            .where((q) => q.formation.titre == _selectedFormationTitle)
            .toList();
    if (_showAllForFormation) return full.length;
    return full.length > 10 ? 10 : full.length;
  }

  // Progress bar supprimée

  void _showQuizHistorySheet(quiz_model.Quiz quiz) {
    final attempts =
        _quizHistory
            .where((h) => h.quiz.id.toString() == quiz.id.toString())
            .toList()
          ..sort((a, b) {
            // Most recent first by completedAt string parse
            DateTime parseDate(String s) {
              final d = DateTime.tryParse(s);
              return d ?? DateTime.fromMillisecondsSinceEpoch(0);
            }

            return parseDate(b.completedAt).compareTo(parseDate(a.completedAt));
          });
    final latestAttempts = attempts.take(5).toList();

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        final theme = Theme.of(context);
        if (attempts.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Historique - ${quiz.titre}',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                const Text('Aucune tentative trouvée.'),
              ],
            ),
          );
        }
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.history),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Historique - ${quiz.titre}',
                        style: theme.textTheme.titleMedium,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: latestAttempts.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, i) {
                      final h = latestAttempts[i];
                      final date = DateTime.tryParse(h.completedAt);
                      final dateLabel =
                          date != null
                              ? '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}'
                              : h.completedAt;
                      final rate =
                          h.totalQuestions == 0
                              ? 0
                              : ((h.correctAnswers / h.totalQuestions) * 100)
                                  .round();
                      return ListTile(
                        dense: true,
                        leading: CircleAvatar(
                          backgroundColor: theme.colorScheme.primary
                              .withOpacity(0.1),
                          foregroundColor: theme.colorScheme.primary,
                          child: const Icon(Icons.quiz, size: 18),
                        ),
                        title: Text('$rate% • ${h.score} pts'),
                        subtitle: Text(
                          '$dateLabel • ${h.correctAnswers}/${h.totalQuestions} • ${h.timeSpent}s',
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class DailyMissionsSection extends StatelessWidget {
  final GlobalKey? keyMission;
  final int loginStreak;
  final List<stats_model.QuizHistory> quizHistory;

  const DailyMissionsSection({
    super.key,
    this.keyMission,
    required this.loginStreak,
    required this.quizHistory,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              'Missions du jour',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Builder(
            builder: (context) {
              final mission1Completed = loginStreak >= 5;
              final mission2Completed = quizHistory.length >= 2;
              final starsTotal = quizHistory.fold(0, (sum, h) {
                final percent =
                    h.totalQuestions > 0
                        ? (h.correctAnswers / h.totalQuestions) * 100
                        : 0;
                if (percent >= 100) return sum + 3;
                if (percent >= 70) return sum + 2;
                if (percent >= 40) return sum + 1;
                return sum;
              });
              final mission3Completed = starsTotal >= 5;
              final mission4Completed = quizHistory.any(
                (h) => h.quiz.niveau.toLowerCase().contains('avanc'),
              );

              final List<Widget> pending = [];
              if (!mission1Completed) {
                pending.add(
                  Container(
                    key: keyMission,
                    child: MissionCard(
                      mission: Mission(
                        id: 1,
                        title: 'Série de connexion',
                        description:
                            'Connecte-toi plusieurs jours d\'affilée pour gagner un badge.',
                        type: 'daily',
                        goal: 5,
                        reward: 'Badge',
                        progress: loginStreak,
                        completed: mission1Completed,
                        completedAt: null,
                      ),
                    ),
                  ),
                );
              }
              if (!mission2Completed) {
                pending.add(
                  MissionCard(
                    mission: Mission(
                      id: 2,
                      title: 'Réussir 2 quiz',
                      description:
                          'Complète 2 quiz aujourd\'hui pour gagner un badge.',
                      type: 'daily',
                      goal: 2,
                      reward: 'Badge',
                      progress:
                          quizHistory.length >= 2 ? 2 : quizHistory.length,
                      completed: mission2Completed,
                      completedAt: null,
                    ),
                  ),
                );
              }
              if (!mission3Completed) {
                pending.add(
                  MissionCard(
                    mission: Mission(
                      id: 3,
                      title: 'Obtenir 5 étoiles',
                      description: 'Cumule 5 étoiles sur tes quiz.',
                      type: 'daily',
                      goal: 5,
                      reward: 'Badge',
                      progress: starsTotal,
                      completed: mission3Completed,
                      completedAt: null,
                    ),
                  ),
                );
              }
              if (!mission4Completed) {
                pending.add(
                  MissionCard(
                    mission: Mission(
                      id: 4,
                      title: 'participer un quiz difficile',
                      description: 'Termine un quiz de niveau avancé.',
                      type: 'daily',
                      goal: 1,
                      reward: 'Points',
                      progress: mission4Completed ? 1 : 0,
                      completed: mission4Completed,
                      completedAt: null,
                    ),
                  ),
                );
              }

              if (pending.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  child: Row(
                    children: [
                      const Icon(Icons.celebration, color: Colors.green),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Toutes les missions du jour sont complétées !',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                );
              }
              return Column(children: [...pending, const SizedBox(height: 24)]);
            },
          ),
        ],
      ),
    );
  }
}

// Widget animé pour rebond sur l'icône du quiz complété
class _AnimatedQuizStep extends StatefulWidget {
  final IconData icon;
  final Color color;
  final String label;
  final bool isCompleted;
  final bool isUnlocked;
  const _AnimatedQuizStep({
    required this.icon,
    required this.color,
    required this.label,
    required this.isCompleted,
    required this.isUnlocked,
    super.key,
  });

  @override
  State<_AnimatedQuizStep> createState() => _AnimatedQuizStepState();
}

class _AnimatedQuizStepState extends State<_AnimatedQuizStep>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
      lowerBound: 0.9,
      upperBound: 1.15,
    );
    _scaleAnim = CurvedAnimation(parent: _controller, curve: Curves.elasticOut);
    if (widget.isCompleted) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(covariant _AnimatedQuizStep oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isCompleted && !oldWidget.isCompleted) {
      _controller.forward(from: 0.9);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ScaleTransition(
          scale: _scaleAnim,
          child: Icon(widget.icon, size: 48, color: widget.color),
        ),
        const SizedBox(height: 8),
        Text(
          widget.label,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color:
                widget.isUnlocked
                    ? Theme.of(context).colorScheme.onSurface
                    : Colors.grey,
          ),
        ),
      ],
    );
  }
}
