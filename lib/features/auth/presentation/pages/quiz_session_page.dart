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
import 'package:wizi_learn/features/auth/presentation/pages/quiz_adventure_page.dart';

import 'dashboard_page.dart';

class QuizSessionPage extends StatefulWidget {
  final Quiz quiz;
  final List<Question> questions;
  final bool isRestart;
  final bool quizAdventureEnabled;
  final List<String> playedQuizIds;

  const QuizSessionPage({
    super.key,
    required this.quiz,
    required this.questions,
    this.isRestart = false,
    this.quizAdventureEnabled = false,
    required this.playedQuizIds,
  });

  @override
  State<QuizSessionPage> createState() => _QuizSessionPageState();
}

class _QuizSessionPageState extends State<QuizSessionPage> {
  late final QuizSessionManager _sessionManager;
  final PageController _pageController = PageController();

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
    // _startSwipeTutorials();
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
    super.dispose();
  }

  void _handlePageChanged(int index) {
    _sessionManager.goToQuestion(index);
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
                playedQuizIds: widget.playedQuizIds,
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
        showBanner: false,
        // Désactivez le banner si nécessaire
        showBottomNavigationBar:
            false,
        showHomeAndQuizIcons: true,
        onHomePressed: () {
          // Navigation vers l'accueil
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (context) => DashboardPage(
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
        onQuizListPressed: () {
          // Navigation vers la liste des quiz
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (context) => DashboardPage(
                initialIndex: 2,
                arguments: {
                  'selectedTabIndex': 2,
                  'fromNotification': true,
                  'useCustomScaffold': true,
                },
              ),
            ),
                (route) => false,
          );
        },// Cache la barre de navigation pendant le quiz
      ),
    );
  }
}
