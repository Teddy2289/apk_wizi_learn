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

  // MODIFICATION: 30 secondes pour regarder les résultats
  int _viewResultsSeconds = 30;
  // MODIFICATION: 5 secondes pour le prochain quiz
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

    // Charger les quizzes disponibles et sélectionner le prochain
    _loadNextQuiz();

    // MODIFICATION: Démarrer le décompte pour regarder les résultats (30s)
    _startViewResultsTimer();

    // If backend returned new achievements in quizResult, show them immediately
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
    // Attempt to report this completion to the Challenge API (non-blocking)
    (() async {
      try {
        final dio = Dio();
        final storage = const FlutterSecureStorage();
        final apiClient = ApiClient(dio: dio, storage: storage);
        final challengeRepo = ChallengeRepository(apiClient: apiClient);

        final config = await challengeRepo.fetchConfig();
        if (config != null && config.id != 0) {
          // Attempt to flush any queued submissions first
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

      // Récupérer l'utilisateur connecté
      final user = await authRepository.getMe();
      final stagiaireId = user.stagiaire?.id;

      if (stagiaireId == null) return;

      // Charger tous les quizzes
      final allQuizzes = await quizRepository.getQuizzesForStagiaire(
        stagiaireId: stagiaireId,
      );

      // Charger l'historique pour obtenir les IDs joués
      final statsRepository = StatsRepository(apiClient: apiClient);
      final history = await statsRepository.getQuizHistory();
      final playedQuizIds = history.map((h) => h.quiz.id.toString()).toSet();

      // Filtrer pour obtenir seulement les quizzes non joués
      final unplayedQuizzes =
          allQuizzes
              .where((quiz) => !playedQuizIds.contains(quiz.id.toString()))
              .toList();

      if (unplayedQuizzes.isNotEmpty) {
        setState(() {
          _availableQuizzes = unplayedQuizzes;
          _nextQuiz = unplayedQuizzes.first;
        });

        // Précharger les questions du prochain quiz
        _preloadNextQuizQuestions();
      }
    } catch (e) {
      debugPrint('Erreur chargement prochain quiz: $e');
    }
  }

  Future<void> _preloadNextQuizQuestions() async {
    if (_nextQuiz == null) return;

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

  // MODIFICATION: Timer de 30 secondes pour regarder les résultats
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

  // MODIFICATION: Timer de 5 secondes pour le prochain quiz
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

  // MODIFICATION SUPPRIMÉE: _startNextQuizTimer n'est plus utilisé

  List<String> _getPlayedQuizIds() {
    // Récupérer l'ID du quiz actuel depuis quizResult
    final currentQuizId = widget.quizResult?['quizId']?.toString();

    // Si on a la liste des quizzes disponibles, on peut construire la liste des IDs joués
    if (_availableQuizzes != null && currentQuizId != null) {
      final allQuizIds =
          _availableQuizzes!.map((q) => q.id.toString()).toList();
      final playedIds = allQuizIds.where((id) => id != currentQuizId).toList();
      return playedIds;
    }

    // Fallback: retourner une liste vide ou avec l'ID actuel
    return currentQuizId != null ? [currentQuizId] : [];
  }

  void _navigateToNextQuiz() {
    // Annuler les timers pour éviter les actions multiples
    _nextQuizTimer?.cancel();
    _countdownTimer?.cancel();

    // Si on a chargé le prochain quiz et ses questions, naviguer directement
    if (_nextQuiz != null &&
        _nextQuizQuestions != null &&
        _nextQuizQuestions!.isNotEmpty) {
      final playedQuizIds = _getPlayedQuizIds();
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
    } else {
      // Fallback: retourner à la liste des quiz
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
  }

  // MODIFICATION: Nouvelle méthode pour afficher les deux décomptes
  Widget _buildCountdownInfo() {
    if (_showViewResultsCountdown) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.1),
          border: Border(
            bottom: BorderSide(color: Colors.blue.withOpacity(0.2)),
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.visibility, color: Colors.blue, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Text(
                  //   'Temps pour consulter vos résultats',
                  //   style: TextStyle(
                  //     fontWeight: FontWeight.w600,
                  //     color: Colors.blue.shade800,
                  //     fontSize: 14,
                  //   ),
                  // ),
                  Text(
                    'Prochain quiz dans ${_viewResultsSeconds}s',
                    style: TextStyle(color: Colors.blue.shade600, fontSize: 13),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                '${_viewResultsSeconds}s',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (_showNextQuizCountdown) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.1),
          border: Border(
            bottom: BorderSide(color: Colors.green.withOpacity(0.2)),
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.quiz, color: Colors.green, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Prochain quiz: ${_nextQuiz?.titre ?? "Chargement..."}',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.green.shade800,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    'Démarrage dans ${_nextQuizSeconds}s',
                    style: TextStyle(
                      color: Colors.green.shade600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                '${_nextQuizSeconds}s',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: _navigateToNextQuiz,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
              child: Text(
                'Commencer',
                style: TextStyle(
                  color: Colors.green.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  // MODIFICATION: Supprimer l'ancienne méthode _buildNextQuizInfo

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
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.emoji_events, color: Colors.amber, size: 48),
                const SizedBox(height: 16),
                Text(
                  'Nouveau badge débloqué !',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 16),
                ...badges.map(
                  (badge) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: AchievementBadgeWidget(
                      achievement: badge,
                      unlocked: true,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  icon: const Icon(Icons.emoji_events),
                  label: const Text('Voir mes badges'),
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const AchievementPage(),
                      ),
                    );
                  },
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
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.star, color: Colors.amber, size: 60),
              const SizedBox(height: 20),
              Text(
                'Félicitations !',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Vous avez répondu correctement à toutes les questions !',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Continuer'),
              ),
            ],
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
    final answeredQuestions =
        widget.questions.where((q) => q.selectedAnswers != null).toList();

    final calculatedScore =
        widget.questions.where((q) => q.isCorrect == true).length * 2;
    final calculatedCorrectAnswers =
        widget.questions.where((q) => q.isCorrect == true).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Récapitulatif du Quiz"),
        centerTitle: true,
        actions: [
          // MODIFICATION: Afficher le décompte actuel dans l'AppBar
          if (_showViewResultsCountdown || _showNextQuizCountdown)
            Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color:
                    _showViewResultsCountdown
                        ? Colors.blue.withOpacity(0.1)
                        : Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _showViewResultsCountdown ? Colors.blue : Colors.green,
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _showViewResultsCountdown ? Icons.visibility : Icons.quiz,
                    size: 16,
                    color:
                        _showViewResultsCountdown ? Colors.blue : Colors.green,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _showViewResultsCountdown
                        ? '${_viewResultsSeconds}s'
                        : '${_nextQuizSeconds}s',
                    style: TextStyle(
                      fontSize: 14,
                      color:
                          _showViewResultsCountdown
                              ? Colors.blue
                              : Colors.green,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          // Indicateur pour les résultats locaux
          if (widget.quizResult?['isLocal'] == true)
            Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange, width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.warning, size: 16, color: Colors.orange),
                  const SizedBox(width: 4),
                  Text(
                    'Local',
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
            icon: const Icon(Icons.list),
            tooltip: 'Retour à la liste des quiz',
            onPressed:
                () => Navigator.of(context).popUntil((route) => route.isFirst),
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // MODIFICATION: Utiliser le nouveau widget de décompte
              _buildCountdownInfo(),

              QuizScoreHeader(
                score: calculatedScore,
                correctAnswers: calculatedCorrectAnswers,
                totalQuestions: answeredQuestions.length,
                timeSpent: widget.timeSpent,
              ),

              // Message d'information pour les résultats locaux
              if (widget.quizResult?['isLocal'] == true)
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.orange, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Ces résultats sont calculés localement car la soumission au serveur a échoué. '
                          'Ils ne sont pas sauvegardés.',
                          style: TextStyle(
                            color: Colors.orange.shade800,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: widget.questions.length,
                  itemBuilder: (context, index) {
                    final question = widget.questions[index];
                    final isCorrect = question.isCorrect ?? false;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: QuizQuestionCard(
                        question: question,
                        isCorrect: isCorrect,
                        index: index,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
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
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // NOUVEAU: Bouton Accueil
          FloatingActionButton(
            heroTag: 'home_button',
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder:
                      (context) => DashboardPage(
                        initialIndex: 0, // Index pour la page d'accueil
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
            child: const Icon(Icons.home),
          ),
          const SizedBox(width: 16),
          // Bouton Retour aux quiz (existant)
          FloatingActionButton(
            heroTag: 'restart_quiz',
            onPressed: () {
              debugPrint(
                'Quiz ID to scroll to: ${widget.quizResult?['quizId']}',
              );
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
            tooltip: 'Retour aux quiz',
            child: const Icon(Icons.refresh),
          ),
          const SizedBox(width: 16),
          // Bouton Rejouer ce quiz (existant)
          if (widget.onRestartQuiz != null)
            FloatingActionButton(
              heroTag: 'replay_quiz',
              onPressed: widget.onRestartQuiz,
              tooltip: 'Rejouer ce quiz',
              child: const Icon(Icons.replay),
            ),
        ],
      ),
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
