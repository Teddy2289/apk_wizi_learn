import 'dart:async';
import 'dart:math';
import 'package:wizi_learn/core/network/api_client.dart';
import 'package:confetti/confetti.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:wizi_learn/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:wizi_learn/features/auth/data/models/achievement_model.dart';
import 'package:wizi_learn/features/auth/data/models/question_model.dart';
import 'package:wizi_learn/features/auth/data/models/quiz_model.dart';
import 'package:wizi_learn/features/auth/data/models/stats_model.dart';
import 'package:wizi_learn/features/auth/data/repositories/achievement_repository.dart';
import 'package:wizi_learn/features/auth/data/repositories/auth_repository.dart';
import 'package:wizi_learn/features/auth/data/repositories/quiz_repository.dart';
import 'package:wizi_learn/features/auth/data/repositories/stats_repository.dart';
import 'package:wizi_learn/features/auth/data/repositories/challenge_repository.dart';
import 'package:wizi_learn/features/auth/presentation/pages/achievement_page.dart';
import 'package:wizi_learn/features/auth/presentation/pages/dashboard_page.dart';
import 'package:wizi_learn/features/auth/presentation/components/quiz_question_card.dart';
import 'package:wizi_learn/features/auth/presentation/components/quiz_score_header.dart';
import 'package:wizi_learn/features/auth/presentation/pages/quiz_session_page.dart';
import 'package:wizi_learn/features/auth/presentation/widgets/achievement_badge_widget.dart';

class QuizSummaryPage extends StatefulWidget {
  final List<Question> questions;
  final int score;
  final int correctAnswers;
  final int totalQuestions;
  final int timeSpent;
  final Map<String, dynamic>? quizResult;
  final VoidCallback? onRestartQuiz;

  const QuizSummaryPage({
    super.key,
    required this.questions,
    required this.score,
    required this.correctAnswers,
    required this.totalQuestions,
    required this.timeSpent,
    this.quizResult,
    this.onRestartQuiz,
  });

  @override
  State<QuizSummaryPage> createState() => _QuizSummaryPageState();
}

class _QuizSummaryPageState extends State<QuizSummaryPage> {
  late ConfettiController _confettiController;
  bool _showConfetti = false;
  Timer? _nextQuizTimer;
  Timer? _countdownTimer;

  int _viewResultsSeconds = 60;
  int _nextQuizSeconds = 5;

  bool _showViewResultsCountdown = true;
  bool _showNextQuizCountdown = false;

  List<Quiz>? _availableQuizzes;
  Quiz? _nextQuiz;
  List<Question>? _nextQuizQuestions;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );

    final allCorrect = widget.questions.every((q) => q.isCorrect == true);
    if (allCorrect) {
      _showConfetti = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _confettiController.play();
        _showCongratulationDialog();
      });
    }

    _loadNextQuiz();
    _startViewResultsTimer();

    final serverNew =
        (widget.quizResult?['newAchievements'] as List?) ??
        (widget.quizResult?['new_achievements'] as List?) ??
        [];
    if (serverNew.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showBadgePopup(
          serverNew
              .map((e) => Achievement.fromJson(e as Map<String, dynamic>))
              .toList(),
        );
      });
    } else {
      _fetchNewAchievements();
    }

    (() async {
      try {
        final dio = Dio();
        final storage = const FlutterSecureStorage();
        final apiClient = ApiClient(dio: dio, storage: storage);
        final challengeRepo = ChallengeRepository(apiClient: apiClient);

        final config = await challengeRepo.fetchConfig();
        if (config != null && config.id != 0) {
          await challengeRepo.flushQueue();
          final posted = await challengeRepo.submitEntryWithQueue(
            challengeId: config.id,
            points: widget.score,
            quizzesCompleted: 1,
            durationSeconds: widget.timeSpent,
          );
          debugPrint('Challenge entry posted (or queued): $posted');
        }
      } catch (e) {
        debugPrint('Challenge reporting failed (non-blocking): $e');
      }
    })();
  }

  // [Les autres méthodes _filterQuizzesByPoints, _loadNextQuiz, _preloadNextQuizQuestions, etc. restent identiques]
  List<Quiz> _filterQuizzesByPoints(List<Quiz> allQuizzes, int userPoints) {
    if (allQuizzes.isEmpty) return [];

    String normalizeLevel(String? level) {
      if (level == null) return 'débutant';
      final lvl = level.toLowerCase().trim();
      if (lvl.contains('inter') || lvl.contains('moyen')) {
        return 'intermédiaire';
      }
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

    List<Quiz> result;

    if (userPoints < 10) {
      result = debutant.take(2).toList();
    } else if (userPoints < 20) {
      result = debutant.take(4).toList();
    } else if (userPoints < 40) {
      result = [...debutant, ...intermediaire.take(2)];
    } else if (userPoints < 60) {
      result = [...debutant, ...intermediaire];
    } else if (userPoints < 80) {
      result = [...debutant, ...intermediaire, ...avance.take(2)];
    } else if (userPoints < 100) {
      result = [...debutant, ...intermediaire, ...avance.take(4)];
    } else {
      result = [...debutant, ...intermediaire, ...avance];
    }

    if (result.isEmpty && allQuizzes.isNotEmpty) {
      result = allQuizzes.take(2).toList();
    }

    return result;
  }

  Future<void> _loadNextQuiz() async {
    try {
      final dio = Dio();
      final storage = const FlutterSecureStorage();
      final apiClient = ApiClient(dio: dio, storage: storage);
      final quizRepository = QuizRepository(apiClient: apiClient);
      final authRepository = AuthRepository(
        remoteDataSource: AuthRemoteDataSourceImpl(
          apiClient: apiClient,
          storage: storage,
        ),
        storage: storage,
      );

      final user = await authRepository.getMe();
      final stagiaireId = user.stagiaire?.id;

      if (stagiaireId == null) {
        debugPrint('❌ Aucun stagiaire ID trouvé');
        return;
      }

      final allQuizzes = await quizRepository.getQuizzesForStagiaire(
        stagiaireId: stagiaireId,
      );

      debugPrint('✅ ${allQuizzes.length} quizzes chargés');

      final statsRepository = StatsRepository(apiClient: apiClient);
      final history = await statsRepository.getQuizHistory();
      final playedQuizIds = history.map((h) => h.quiz.id.toString()).toSet();

      debugPrint('📊 ${playedQuizIds.length} quizzes déjà joués');

      final rankings = await statsRepository.getGlobalRanking();
      final userRanking = rankings.firstWhere(
        (r) => r.stagiaire.id == stagiaireId.toString(),
        orElse: () => GlobalRanking.empty(),
      );
      final userPoints = userRanking.totalPoints;

      debugPrint('⭐ Points utilisateur: $userPoints');

      final filteredQuizzes = _filterQuizzesByPoints(allQuizzes, userPoints);
      debugPrint(
        '🎯 ${filteredQuizzes.length} quizzes après filtrage par points',
      );

      final currentQuizId = widget.quizResult?['quizId']?.toString();
      Quiz? currentQuiz;

      if (currentQuizId != null) {
        currentQuiz = allQuizzes.firstWhere(
          (q) => q.id.toString() == currentQuizId,
          orElse:
              () =>
                  filteredQuizzes.isNotEmpty
                      ? filteredQuizzes.first
                      : allQuizzes.first,
        );
        debugPrint(
          '🎯 Quiz actuel: ${currentQuiz.titre} (${currentQuiz.niveau} - ${currentQuiz.formation.titre})',
        );
      }

      List<Quiz> unplayedQuizzes =
          filteredQuizzes
              .where((quiz) => !playedQuizIds.contains(quiz.id.toString()))
              .toList();

      debugPrint(
        '🆕 ${unplayedQuizzes.length} quizzes non joués après filtrage',
      );

      if (unplayedQuizzes.isEmpty) {
        debugPrint('⚠️ Aucun quiz non joué, on prend tous les quizzes filtrés');
        unplayedQuizzes = filteredQuizzes;
      }

      if (currentQuiz != null && unplayedQuizzes.isNotEmpty) {
        final sameLevelAndFormation =
            unplayedQuizzes
                .where(
                  (quiz) =>
                      quiz.niveau == currentQuiz!.niveau &&
                      quiz.formation.titre == currentQuiz!.formation.titre,
                )
                .toList();

        if (sameLevelAndFormation.isNotEmpty) {
          debugPrint(
            '🎯 ${sameLevelAndFormation.length} quizzes de même niveau et formation',
          );
          unplayedQuizzes = sameLevelAndFormation;
        } else {
          final sameLevel =
              unplayedQuizzes
                  .where((quiz) => quiz.niveau == currentQuiz!.niveau)
                  .toList();

          if (sameLevel.isNotEmpty) {
            debugPrint('🎯 ${sameLevel.length} quizzes de même niveau');
            unplayedQuizzes = sameLevel;
          } else {
            final sameFormation =
                unplayedQuizzes
                    .where(
                      (quiz) =>
                          quiz.formation.titre == currentQuiz!.formation.titre,
                    )
                    .toList();

            if (sameFormation.isNotEmpty) {
              debugPrint(
                '🎯 ${sameFormation.length} quizzes de même formation',
              );
              unplayedQuizzes = sameFormation;
            }
          }
        }
      }

      unplayedQuizzes.shuffle();

      debugPrint('🎲 ${unplayedQuizzes.length} quizzes disponibles après tri');

      if (unplayedQuizzes.isNotEmpty) {
        setState(() {
          _availableQuizzes = unplayedQuizzes;
          _nextQuiz = unplayedQuizzes.first;
        });

        debugPrint(
          '➡️ Prochain quiz: ${_nextQuiz!.titre} (${_nextQuiz!.niveau} - ${_nextQuiz!.formation.titre})',
        );

        _preloadNextQuizQuestions();
      } else {
        debugPrint('❌ Aucun quiz disponible après tout le traitement');
        setState(() {
          _nextQuiz = null;
          _availableQuizzes = [];
        });
      }
    } catch (e) {
      debugPrint('❌ Erreur chargement prochain quiz: $e');
      setState(() {
        _nextQuiz = null;
        _availableQuizzes = [];
      });
    }
  }

  Future<void> _preloadNextQuizQuestions() async {
    if (_nextQuiz == null) {
      debugPrint('❌ _nextQuiz est null dans _preloadNextQuizQuestions');
      return;
    }

    try {
      final dio = Dio();
      final storage = const FlutterSecureStorage();
      final apiClient = ApiClient(dio: dio, storage: storage);
      final quizRepository = QuizRepository(apiClient: apiClient);

      final questions = await quizRepository.getQuizQuestions(_nextQuiz!.id);
      setState(() {
        _nextQuizQuestions = questions;
      });
    } catch (e) {
      debugPrint('Erreur préchargement questions: $e');
    }
  }

  void _startViewResultsTimer() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_viewResultsSeconds > 0) {
        setState(() {
          _viewResultsSeconds--;
        });
      } else {
        timer.cancel();
        _startNextQuizCountdown();
      }
    });
  }

  void _startNextQuizCountdown() {
    setState(() {
      _showViewResultsCountdown = false;
      _showNextQuizCountdown = true;
      _nextQuizSeconds = 5;
    });

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_nextQuizSeconds > 0) {
        setState(() {
          _nextQuizSeconds--;
        });
      } else {
        timer.cancel();
        _navigateToNextQuiz();
      }
    });
  }

  List<String> _getPlayedQuizIds() {
    final currentQuizId = widget.quizResult?['quizId']?.toString();

    if (_availableQuizzes != null && currentQuizId != null) {
      final allQuizIds =
          _availableQuizzes!.map((q) => q.id.toString()).toList();
      final playedIds = allQuizIds.where((id) => id != currentQuizId).toList();
      return playedIds;
    }

    return currentQuizId != null ? [currentQuizId] : [];
  }

  void _navigateToNextQuiz() {
    _nextQuizTimer?.cancel();
    _countdownTimer?.cancel();

    debugPrint('🔄 Tentative de navigation vers le prochain quiz...');
    debugPrint('📊 _nextQuiz: ${_nextQuiz?.titre}');
    debugPrint(
      '📊 _nextQuizQuestions: ${_nextQuizQuestions?.length} questions',
    );

    if (_nextQuiz == null) {
      debugPrint('❌ Aucun quiz disponible, retour à la liste');
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder:
              (context) => DashboardPage(
                initialIndex: 2,
                arguments: {
                  'selectedTabIndex': 2,
                  'fromNotification': true,
                  'useCustomScaffold': true,
                  'scrollToPlayed': false,
                },
              ),
        ),
        (route) => false,
      );
      return;
    }

    if (_nextQuizQuestions == null || _nextQuizQuestions!.isEmpty) {
      debugPrint(
        '⚠️ Questions non chargées, tentative de chargement immédiat...',
      );
      _loadQuestionsAndNavigate();
      return;
    }

    final playedQuizIds = _getPlayedQuizIds();
    debugPrint(
      '✅ Navigation vers QuizSessionPage avec ${_nextQuizQuestions!.length} questions',
    );

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder:
            (context) => QuizSessionPage(
              quiz: _nextQuiz!,
              questions: _nextQuizQuestions!,
              quizAdventureEnabled: false,
              playedQuizIds: playedQuizIds,
            ),
      ),
    );
  }

  Future<void> _loadQuestionsAndNavigate() async {
    if (_nextQuiz == null) return;

    try {
      final dio = Dio();
      final storage = const FlutterSecureStorage();
      final apiClient = ApiClient(dio: dio, storage: storage);
      final quizRepository = QuizRepository(apiClient: apiClient);

      final questions = await quizRepository.getQuizQuestions(_nextQuiz!.id);

      if (questions.isNotEmpty) {
        debugPrint('✅ Questions chargées avec succès: ${questions.length}');

        final playedQuizIds = _getPlayedQuizIds();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder:
                (context) => QuizSessionPage(
                  quiz: _nextQuiz!,
                  questions: questions,
                  quizAdventureEnabled: false,
                  playedQuizIds: playedQuizIds,
                ),
          ),
        );
      } else {
        debugPrint('❌ Aucune question chargée, retour à la liste');
        _navigateToQuizList();
      }
    } catch (e) {
      debugPrint('❌ Erreur lors du chargement immédiat: $e');
      _navigateToQuizList();
    }
  }

  void _navigateToQuizList() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder:
            (context) => DashboardPage(
              initialIndex: 2,
              arguments: {
                'selectedTabIndex': 2,
                'fromNotification': true,
                'useCustomScaffold': true,
                'scrollToPlayed': false,
              },
            ),
      ),
      (route) => false,
    );
  }

  // NOUVELLE MÉTHODE : Widget de décompte amélioré
  Widget _buildCountdownInfo() {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    if (_showNextQuizCountdown) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.green.shade50, Colors.green.shade100],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border(
            bottom: BorderSide(color: Colors.green.shade200, width: 1),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.quiz, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Quiz suivant',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Colors.green.shade900,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _nextQuiz?.titre ?? 'Chargement...',
                    style: TextStyle(
                      color: Colors.green.shade700,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'Démarre dans $_nextQuizSeconds secondes',
                    style: TextStyle(
                      color: Colors.green.shade600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    '$_nextQuizSeconds s',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                TextButton(
                  onPressed: _navigateToNextQuiz,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                  ),
                  child: Text(
                    'Commencer',
                    style: TextStyle(
                      color: Colors.green.shade800,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Future<void> _fetchNewAchievements() async {
    final dio = Dio();
    final storage = const FlutterSecureStorage();
    final apiClient = ApiClient(dio: dio, storage: storage);
    final repo = AchievementRepository(apiClient: apiClient);

    try {
      final achievements = await repo.getUserAchievements();

      final today = DateTime.now();
      final newOnes =
          achievements
              .where(
                (a) =>
                    a.unlockedAt != null &&
                    a.unlockedAt!.year == today.year &&
                    a.unlockedAt!.month == today.month &&
                    a.unlockedAt!.day == today.day,
              )
              .toList();

      if (newOnes.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showBadgePopup(newOnes);
        });
      }
    } catch (e) {
      debugPrint("Erreur récupération nouveaux badges: $e");
    }
  }

  void _showBadgePopup(List<Achievement> badges) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.amber.shade50, Colors.orange.shade50],
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.amber,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.amber.withOpacity(0.5),
                        blurRadius: 15,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.emoji_events,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Nouveau badge débloqué !',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade900,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Félicitations pour votre accomplissement !',
                  style: TextStyle(color: Colors.orange.shade700, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                ...badges.map(
                  (badge) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: AchievementBadgeWidget(
                      achievement: badge,
                      unlocked: true,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text('Continuer'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const AchievementPage(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.emoji_events, size: 18),
                            const SizedBox(width: 6),
                            Text('Voir'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showCongratulationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.green.shade50, Colors.lightGreen.shade50],
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withOpacity(0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Icon(Icons.star, color: Colors.white, size: 50),
                ),
                const SizedBox(height: 24),
                Text(
                  'Parfait ! 🎉',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade900,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Vous avez répondu correctement à toutes les questions !',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.green.shade700,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 4,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      'Continuer vers les résultats',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _nextQuizTimer?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final answeredQuestions =
        widget.questions.where((q) => q.selectedAnswers != null).toList();
    final calculatedScore =
        widget.questions.where((q) => q.isCorrect == true).length * 2;
    final calculatedCorrectAnswers =
        widget.questions.where((q) => q.isCorrect == true).length;

    return Scaffold(
      backgroundColor:
          isDarkMode ? theme.scaffoldBackgroundColor : Colors.grey[50],
      appBar: AppBar(
        title: Text(
          "Résultats du Quiz",
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        centerTitle: true,
        backgroundColor:
            isDarkMode ? theme.appBarTheme.backgroundColor : Colors.white,
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.1),
        actions: [
          if (widget.quizResult?['isLocal'] == true)
            Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.orange, width: 1.5),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    size: 16,
                    color: Colors.orange,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Résultats locaux',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          IconButton(
            icon: Icon(Icons.home, color: theme.colorScheme.primary),
            tooltip: 'Retour à l\'accueil',
            onPressed:
                () => Navigator.of(context).popUntil((route) => route.isFirst),
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // Section décompte améliorée
              _buildCountdownInfo(),

              // En-tête des scores
              QuizScoreHeader(
                score: calculatedScore,
                correctAnswers: calculatedCorrectAnswers,
                totalQuestions: answeredQuestions.length,
                timeSpent: widget.timeSpent,
              ),

              // Message d'information pour les résultats locaux
              if (widget.quizResult?['isLocal'] == true)
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        color: Colors.orange,
                        size: 22,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Résultats calculés localement',
                              style: TextStyle(
                                color: Colors.orange.shade800,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Ces résultats ne sont pas sauvegardés sur le serveur.',
                              style: TextStyle(
                                color: Colors.orange.shade600,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

              // En-tête de la liste des questions
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: isDarkMode ? theme.cardColor : Colors.white,
                  border: Border(
                    bottom: BorderSide(
                      color: theme.dividerColor.withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.list_alt_rounded,
                      color: theme.colorScheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Détail des questions',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: isDarkMode ? Colors.white : Colors.black87,
                        fontSize: 16,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${calculatedCorrectAnswers}/${answeredQuestions.length} correctes',
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),

              // Liste des questions
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    gradient:
                        isDarkMode
                            ? LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                theme.scaffoldBackgroundColor,
                                theme.scaffoldBackgroundColor.withOpacity(0.95),
                              ],
                            )
                            : LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Colors.grey[50]!, Colors.grey[100]!],
                            ),
                  ),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: widget.questions.length,
                    itemBuilder: (context, index) {
                      final question = widget.questions[index];
                      final isCorrect = question.isCorrect ?? false;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: QuizQuestionCard(
                          question: question,
                          isCorrect: isCorrect,
                          index: index,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),

          // Confetti
          if (_showConfetti)
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirectionality: BlastDirectionality.explosive,
                shouldLoop: false,
                colors: const [
                  Colors.green,
                  Colors.blue,
                  Colors.pink,
                  Colors.orange,
                  Colors.purple,
                ],
                createParticlePath: drawStar,
              ),
            ),
        ],
      ),

      // Boutons d'action améliorés
      floatingActionButton: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Bouton Accueil
            FloatingActionButton(
              heroTag: 'home_button',
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => DashboardPage(
                          initialIndex: 0,
                          arguments: {
                            'selectedTabIndex': 0,
                            'fromNotification': true,
                            'useCustomScaffold': true,
                          },
                        ),
                  ),
                  (route) => false,
                );
              },
              tooltip: 'Retour à l\'accueil',
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              child: const Icon(Icons.home_rounded),
            ),

            // Bouton Liste des quiz
            FloatingActionButton(
              heroTag: 'quiz_list_button',
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => DashboardPage(
                          initialIndex: 2,
                          arguments: {
                            'selectedTabIndex': 2,
                            'scrollToQuizId':
                                widget.quizResult?['quizId']?.toString(),
                            'fromNotification': true,
                            'useCustomScaffold': true,
                            'scrollToPlayed': true,
                          },
                        ),
                  ),
                  (route) => false,
                );
              },
              tooltip: 'Liste des quiz',
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              child: const Icon(Icons.quiz_rounded),
            ),

            // Bouton Rejouer
            if (widget.onRestartQuiz != null)
              FloatingActionButton(
                heroTag: 'replay_button',
                onPressed: widget.onRestartQuiz,
                tooltip: 'Refaire ce quiz',
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                child: const Icon(Icons.replay_rounded),
              ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Path drawStar(Size size) {
    double degToRad(double deg) => deg * (pi / 180.0);
    const numberOfPoints = 5;
    final halfWidth = size.width / 2;
    final externalRadius = halfWidth;
    final internalRadius = halfWidth / 2.5;
    final degreesPerStep = degToRad(360 / numberOfPoints);
    final halfDegreesPerStep = degreesPerStep / 2;
    final path = Path();
    final fullAngle = degToRad(360);
    path.moveTo(size.width, halfWidth);
    for (double step = 0; step < fullAngle; step += degreesPerStep) {
      path.lineTo(
        halfWidth + externalRadius * cos(step),
        halfWidth + externalRadius * sin(step),
      );
      path.lineTo(
        halfWidth + internalRadius * cos(step + halfDegreesPerStep),
        halfWidth + internalRadius * sin(step + halfDegreesPerStep),
      );
    }
    path.close();
    return path;
  }
}
