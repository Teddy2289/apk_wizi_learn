import 'dart:math';
import 'package:wizi_learn/core/network/api_client.dart';
import 'package:confetti/confetti.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:wizi_learn/features/auth/data/models/achievement_model.dart';
import 'package:wizi_learn/features/auth/data/models/question_model.dart';
import 'package:wizi_learn/features/auth/data/repositories/achievement_repository.dart';
import 'package:wizi_learn/features/auth/presentation/pages/achievement_page.dart';
import 'package:wizi_learn/features/auth/presentation/pages/dashboard_page.dart';
import 'package:wizi_learn/features/auth/presentation/components/quiz_question_card.dart';
import 'package:wizi_learn/features/auth/presentation/components/quiz_score_header.dart';
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

    _fetchNewAchievements();
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
