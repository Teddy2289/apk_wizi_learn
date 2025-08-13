import 'dart:async';
import 'package:flutter/material.dart';
import 'package:wizi_learn/features/auth/data/models/question_model.dart';
import 'package:wizi_learn/features/auth/data/models/quiz_model.dart';
import 'package:wizi_learn/features/auth/presentation/components/quiz_navigation_controls.dart';
import 'package:wizi_learn/features/auth/presentation/components/quiz_progress_bar.dart';
import 'package:wizi_learn/features/auth/presentation/components/quiz_timer_display.dart';
import 'package:wizi_learn/features/auth/presentation/widgets/quiz_session/quiz_session_manager.dart';
import 'package:wizi_learn/features/auth/presentation/pages/question_type_page.dart';
import 'package:wizi_learn/features/auth/presentation/widgets/custom_scaffold.dart';
import 'package:wizi_learn/core/constants/route_constants.dart';
import 'package:wizi_learn/features/auth/presentation/pages/quiz_summary_page.dart';
import 'package:wizi_learn/features/auth/presentation/pages/quiz_adventure_page.dart';

class QuizSessionPage extends StatefulWidget {
  final Quiz quiz;
  final List<Question> questions;
  final bool isRestart;
  final bool quizAdventureEnabled;

  const QuizSessionPage({
    Key? key,
    required this.quiz,
    required this.questions,
    this.isRestart = false,
    this.quizAdventureEnabled = false,
  }) : super(key: key);

  @override
  State<QuizSessionPage> createState() => _QuizSessionPageState();
}

class _QuizSessionPageState extends State<QuizSessionPage> {
  late final QuizSessionManager _sessionManager;
  final PageController _pageController = PageController();
  double _dragOffset = 0;

  // Variables pour les tutoriels de glissement
  bool _showSwipeHint = true;
  bool _showSwipeTutorial = false;
  int _tutorialStep = 0;
  Timer? _tutorialTimer;

  @override
  void initState() {
    super.initState();
    if (widget.isRestart) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Redémarrage du quiz...'),
            duration: Duration(seconds: 2),
          ),
        );
      });
    }
    _sessionManager = QuizSessionManager(
      questions: widget.questions,
      quizId: widget.quiz.id.toString(),
      onTimerEnd: _goToNextQuestionOnTimerEnd,
    );
    _sessionManager.startSession();
    _sessionManager.currentQuestionIndex.addListener(_syncPageController);

    // Démarrer les tutoriels de glissement
    _startSwipeTutorials();
  }

  void _goToNextQuestionOnTimerEnd() {
    final current = _sessionManager.currentQuestionIndex.value;
    if (current < widget.questions.length - 1) {
      _sessionManager.goToQuestion(current + 1);
    }
    // Si besoin, gérer la fin du quiz ici
  }

  void _syncPageController() {
    if (_pageController.hasClients &&
        _pageController.page?.round() !=
            _sessionManager.currentQuestionIndex.value) {
      _pageController.animateToPage(
        _sessionManager.currentQuestionIndex.value,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void dispose() {
    _sessionManager.currentQuestionIndex.removeListener(_syncPageController);
    _sessionManager.dispose();
    _pageController.dispose();
    _tutorialTimer?.cancel();
    super.dispose();
  }

  void _handlePageChanged(int index) {
    _sessionManager.goToQuestion(index);

    // Masquer les tutoriels après la deuxième question
    if (index >= 2 && _showSwipeTutorial) {
      _hideSwipeTutorials();
    }
  }

  void _handleHorizontalDragUpdate(DragUpdateDetails details) {
    setState(() => _dragOffset = details.primaryDelta ?? 0);
  }

  void _handleHorizontalDragEnd(DragEndDetails details) async {
    if (_dragOffset.abs() > 20) {
      final current = _sessionManager.currentQuestionIndex.value;
      final isLast = current >= widget.questions.length - 1;
      final swipedLeftToNext = _dragOffset < 0;

      // Si dernière question et glissement vers la gauche, soumettre le quiz
      if (isLast && swipedLeftToNext) {
        await _submitQuiz();
      } else {
        final newIndex = current + (swipedLeftToNext ? 1 : -1);
        _sessionManager.goToQuestion(
          newIndex.clamp(0, widget.questions.length - 1),
        );
      }

      // Masquer les tutoriels après le premier glissement
      _hideSwipeTutorials();
    }
    setState(() => _dragOffset = 0);
  }

  Future<void> _submitQuiz() async {
    // Afficher un indicateur de chargement
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final results = await _sessionManager.completeQuiz();
      if (!mounted) return;
      Navigator.of(context).pop();

      await Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder:
              (context) => QuizSummaryPage(
                questions:
                    (results['questions'] as List)
                        .map((q) => Question.fromJson(q))
                        .toList(),
                score: results['score'] ?? 0,
                correctAnswers: results['correctAnswers'] ?? 0,
                totalQuestions:
                    results['totalQuestions'] ?? widget.questions.length,
                timeSpent: results['timeSpent'] ?? 0,
                quizResult: results,
              ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Erreur de soumission. Veuillez réessayer.'),
          action: SnackBarAction(
            label: 'Réessayer',
            onPressed: () {
              _submitQuiz();
            },
          ),
        ),
      );
    }
  }

  // Méthodes pour les tutoriels de glissement
  void _startSwipeTutorials() {
    // Afficher les tutoriels seulement pour les premières questions
    // ou si l'utilisateur n'a pas encore interagi
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _showSwipeHint = true;
        _showSwipeTutorial = true;
      });

      // Démarrer l'animation des tutoriels
      _startTutorialAnimation();

      // Masquer automatiquement après 10 secondes
      Timer(const Duration(seconds: 10), () {
        if (mounted) {
          _hideSwipeTutorials();
        }
      });
    });
  }

  void _startTutorialAnimation() {
    _tutorialTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (mounted && _showSwipeTutorial) {
        setState(() {
          _tutorialStep =
              (_tutorialStep + 1) % 3; // 3 étapes : gauche, droite, centre
        });
      } else {
        timer.cancel();
      }
    });
  }

  void _hideSwipeTutorials() {
    setState(() {
      _showSwipeHint = false;
      _showSwipeTutorial = false;
    });
    _tutorialTimer?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;

    return WillPopScope(
      onWillPop: () async {
        // Empêcher de quitter 1pendant le quiz
        return false;
      },
      child: CustomScaffold(
        body: Column(
          children: [
            // Custom AppBar replacement
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                  Text(
                    widget.quiz.titre,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.3,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                  const Spacer(),
                  ValueListenableBuilder<int>(
                    valueListenable: _sessionManager.currentQuestionIndex,
                    builder: (_, index, __) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${index + 1}/${widget.questions.length}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.primary,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            // Progress header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isDarkMode ? theme.cardColor : Colors.grey[50],
                border: Border(
                  bottom: BorderSide(
                    color: theme.dividerColor.withOpacity(0.05),
                    width: 1,
                  ),
                ),
              ),
              child: Column(
                children: [
                  QuizProgressBar(sessionManager: _sessionManager),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ValueListenableBuilder<int>(
                        valueListenable: _sessionManager.currentQuestionIndex,
                        builder: (_, index, __) {
                          return Text(
                            'Question ${index + 1}/${widget.questions.length}',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: theme.colorScheme.onSurface.withOpacity(
                                0.7,
                              ),
                            ),
                          );
                        },
                      ),
                      QuizTimerDisplay(sessionManager: _sessionManager),
                    ],
                  ),
                ],
              ),
            ),

            // Question area
            Expanded(
              child: Stack(
                children: [
                  PageView.builder(
                    controller: _pageController,
                    physics: const BouncingScrollPhysics(),
                    onPageChanged: _handlePageChanged,
                    itemCount: widget.questions.length,
                    itemBuilder: (context, pageIndex) {
                      return QuestionTypePage(
                        key: ValueKey(widget.questions[pageIndex].id),
                        onAnswer: _sessionManager.handleAnswer,
                        question: widget.questions[pageIndex],
                      );
                    },
                  ),

                  // Flèches de tutoriel de glissement
                  if (_showSwipeHint) _buildSwipeHint(),

                  // Indicateurs de tutoriel dynamiques
                  if (_showSwipeTutorial) _buildSwipeTutorial(),

                  // Gesture detector overlay for swipe submit on last question
                  Positioned.fill(
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onHorizontalDragUpdate: _handleHorizontalDragUpdate,
                      onHorizontalDragEnd: _handleHorizontalDragEnd,
                    ),
                  ),
                ],
              ),
            ),

            // Navigation controls
            Container(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              decoration: BoxDecoration(
                color: isDarkMode ? theme.cardColor : Colors.grey[50],
                border: Border(
                  top: BorderSide(
                    color: theme.dividerColor.withOpacity(0.05),
                    width: 1,
                  ),
                ),
              ),
              child: QuizNavigationControls(
                sessionManager: _sessionManager,
                questions: widget.questions,
              ),
            ),
          ],
        ),
        currentIndex: 2,
        onTabSelected: (index) {
          if (index != 2) {
            // If quiz adventure is enabled, redirect to adventure page instead of dashboard
            if (widget.quizAdventureEnabled) {
              Navigator.pushReplacement(
                context,
                PageRouteBuilder(
                  pageBuilder:
                      (_, __, ___) =>
                          QuizAdventurePage(quizAdventureEnabled: true),
                  transitionsBuilder:
                      (_, animation, __, child) =>
                          FadeTransition(opacity: animation, child: child),
                  transitionDuration: const Duration(milliseconds: 250),
                ),
              );
            } else {
              Navigator.pushReplacementNamed(
                context,
                RouteConstants.dashboard,
                arguments: index,
              );
            }
          }
        },
        showBanner: false, // Désactivez le banner si nécessaire
        showBottomNavigationBar:
            false, // Cache la barre de navigation pendant le quiz
      ),
    );
  }

  // Widget pour les flèches de tutoriel de glissement
  Widget _buildSwipeHint() {
    return Positioned.fill(
      child: IgnorePointer(
        child: Container(
          color: Colors.transparent,
          child: Row(
            children: [
              // Flèche gauche
              Expanded(
                child: Container(
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.only(left: 20),
                  child: AnimatedOpacity(
                    opacity: _tutorialStep == 0 ? 0.8 : 0.3,
                    duration: const Duration(milliseconds: 500),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ),

              // Flèche droite
              Expanded(
                child: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  child: AnimatedOpacity(
                    opacity: _tutorialStep == 1 ? 0.8 : 0.3,
                    duration: const Duration(milliseconds: 500),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: const Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget pour les tutoriels dynamiques
  Widget _buildSwipeTutorial() {
    return Positioned(
      bottom: 100,
      left: 0,
      right: 0,
      child: Center(
        child: AnimatedOpacity(
          opacity: _tutorialStep == 2 ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 300),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.8),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.swipe, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Glissez pour naviguer',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
