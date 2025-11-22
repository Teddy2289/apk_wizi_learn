import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wizi_learn/features/auth/data/models/question_model.dart';
import 'package:wizi_learn/features/auth/data/models/quiz_model.dart';
import 'package:wizi_learn/features/auth/data/services/quiz_session_storage_service.dart';
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
  late QuizSessionManager _sessionManager;
  final PageController _pageController = PageController();
  bool _isInitialized = false;

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
    _initializeSessionManager();
  }

  Future<void> _initializeSessionManager() async {
    final prefs = await SharedPreferences.getInstance();
    final storageService = QuizSessionStorageService(prefs);
    _sessionManager = QuizSessionManager(
      questions: widget.questions,
      quizId: widget.quiz.id.toString(),
      quizTitle: widget.quiz.titre,
      storageService: storageService,
      onTimerEnd: _goToNextQuestionOnTimerEnd,
    );
    _sessionManager.startSession();
    _sessionManager.currentQuestionIndex.addListener(_syncPageController);
    setState(() {
      _isInitialized = true;
    });
  }

  void _goToNextQuestionOnTimerEnd() {
    final current = _sessionManager.currentQuestionIndex.value;
    if (current < widget.questions.length - 1) {
      _sessionManager.goToQuestion(current + 1);
    }
  }

  void _syncPageController() {
    if (_pageController.hasClients &&
        _pageController.page?.round() != _sessionManager.currentQuestionIndex.value) {
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

  void _showQuitConfirmationDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        final theme = Theme.of(context);
        final isDarkMode = theme.brightness == Brightness.dark;
        return Dialog(
          backgroundColor: isDarkMode ? theme.cardColor : Colors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.error.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.warning_rounded,
                    size: 32,
                    color: theme.colorScheme.error,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Quitter le quiz ?',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Votre progression actuelle sera perdue. Êtes-vous sûr de vouloir quitter ?',
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.4,
                    color: isDarkMode ? Colors.white70 : Colors.black54,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          side: BorderSide(
                            color: theme.colorScheme.outline.withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          'Continuer le quiz',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: isDarkMode ? Colors.white70 : Colors.black54,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _quitQuiz,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.error,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Quitter',
                          style: TextStyle(fontWeight: FontWeight.w600),
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

  Future<void> _quitQuiz() async {
    Navigator.of(context).pop();
    if (!_sessionManager.quizCompleted.value) {
      await _sessionManager.saveOnExit();
    }
    _sessionManager.dispose();
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
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    return WillPopScope(
      onWillPop: () async {
        _showQuitConfirmationDialog();
        return false;
      },
      child: CustomScaffold(
        body: Column(
          children: [
            // Header
            Container(
              padding: EdgeInsets.symmetric(
                  horizontal: isLandscape ? 12 : 16,
                  vertical: isLandscape ? 10 : 16),
              decoration: BoxDecoration(
                color: isDarkMode ? theme.cardColor : Colors.white,
                border: Border(bottom: BorderSide(color: theme.dividerColor.withOpacity(0.1), width: 1)),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
              ),
              child: Row(
                children: [
                  // Back button
                  Container(
                    decoration: BoxDecoration(
                      color: isDarkMode ? Colors.grey[800] : Colors.grey[100],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: IconButton(
                      icon: Icon(Icons.arrow_back_ios_rounded, size: isLandscape ? 16 : 18, color: isDarkMode ? Colors.white70 : Colors.black54),
                      onPressed: _showQuitConfirmationDialog,
                      tooltip: 'Quitter le quiz',
                      padding: EdgeInsets.all(isLandscape ? 8 : 12),
                    ),
                  ),
                  SizedBox(width: isLandscape ? 8 : 12),
                  // Quiz info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.quiz.titre,
                          style: TextStyle(fontSize: isLandscape ? 14 : 16, fontWeight: FontWeight.w600, color: isDarkMode ? Colors.white : Colors.black87),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                        SizedBox(height: isLandscape ? 1 : 2),
                        ValueListenableBuilder<int>(
                          valueListenable: _sessionManager.currentQuestionIndex,
                          builder: (_, index, __) => Text(
                            'Question ${index + 1} sur ${widget.questions.length}',
                            style: TextStyle(fontSize: isLandscape ? 11 : 13, color: isDarkMode ? Colors.white60 : Colors.black54),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Progress badge
                  ValueListenableBuilder<int>(
                    valueListenable: _sessionManager.currentQuestionIndex,
                    builder: (_, index, __) => Container(
                      padding: EdgeInsets.symmetric(horizontal: isLandscape ? 8 : 12, vertical: isLandscape ? 4 : 6),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [colorScheme.primary, colorScheme.primary.withOpacity(0.8)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                        borderRadius: BorderRadius.circular(isLandscape ? 8 : 12),
                        boxShadow: [BoxShadow(color: colorScheme.primary.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 2))],
                      ),
                      child: Text(
                        '${index + 1}/${widget.questions.length}',
                        style: TextStyle(fontSize: isLandscape ? 12 : 14, fontWeight: FontWeight.w700, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Progress bar section
            Container(
              padding: EdgeInsets.symmetric(horizontal: isLandscape ? 12 : 16, vertical: isLandscape ? 6 : 12),
              decoration: BoxDecoration(color: isDarkMode ? theme.cardColor.withOpacity(0.5) : Colors.grey[50], border: Border(bottom: BorderSide(color: theme.dividerColor.withOpacity(0.05), width: 1)),
              child: Column(
                children: [
                  QuizProgressBar(sessionManager: _sessionManager),
                  SizedBox(height: isLandscape ? 4 : 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ValueListenableBuilder<int>(
                        valueListenable: _sessionManager.currentQuestionIndex,
                        builder: (_, index, __) {
                          final progress = ((index + 1) / widget.questions.length * 100).round();
                          return Text('$progress% complété', style: TextStyle(fontSize: isLandscape ? 11 : 13, fontWeight: FontWeight.w600, color: colorScheme.primary));
                        },
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: isLandscape ? 6 : 10, vertical: isLandscape ? 2 : 4),
                        decoration: BoxDecoration(color: isDarkMode ? Colors.grey[800] : Colors.grey[200], borderRadius: BorderRadius.circular(isLandscape ? 6 : 8)),
                        child: QuizTimerDisplay(sessionManager: _sessionManager),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Questions area
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  gradient: isDarkMode
                      ? LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [theme.scaffoldBackgroundColor, theme.scaffoldBackgroundColor.withOpacity(0.95)])
                      : LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.grey[50]!, Colors.grey[100]!]),
                ),
                child: PageView.builder(
                  controller: _pageController,
                  physics: const BouncingScrollPhysics(),
                  onPageChanged: _handlePageChanged,
                  itemCount: widget.questions.length,
                  itemBuilder: (context, pageIndex) => Padding(
                    padding: EdgeInsets.only(bottom: isLandscape ? 60 : 80),
                    child: QuestionTypePage(
                      key: ValueKey(widget.questions[pageIndex].id),
                      onAnswer: _sessionManager.handleAnswer,
                      question: widget.questions[pageIndex],
                    ),
                  ),
                ),
              ),
            ),
            // Navigation controls
            _buildStickyNavigationControls(isLandscape, theme),
          ],
        ),
        currentIndex: 2,
        onTabSelected: (index) {
          if (index != 2) {
            if (widget.quizAdventureEnabled) {
              Navigator.pushReplacement(
                context,
                PageRouteBuilder(
                  pageBuilder: (_, __, ___) => QuizAdventurePage(quizAdventureEnabled: true),
                  transitionsBuilder: (_, animation, __, child) => FadeTransition(opacity: animation, child: child),
                  transitionDuration: const Duration(milliseconds: 250),
                ),
              );
            } else {
              Navigator.pushReplacementNamed(context, RouteConstants.dashboard, arguments: index);
            }
          }
        },
        showBanner: false,
        showBottomNavigationBar: false,
        showHomeAndQuizIcons: true,
        onHomePressed: () {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (_) => DashboardPage(initialIndex: 0, arguments: {'selectedTabIndex': 0, 'fromNotification': true, 'useCustomScaffold': true}),
            ),
            (r) => false,
          );
        },
        onQuizListPressed: () {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (_) => DashboardPage(initialIndex: 2, arguments: {'selectedTabIndex': 2, 'fromNotification': true, 'useCustomScaffold': true}),
            ),
            (r) => false,
          );
        },
      ),
    );
  }

  Widget _buildStickyNavigationControls(bool isLandscape, ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: isLandscape ? 12 : 16, vertical: isLandscape ? 8 : 12),
      decoration: BoxDecoration(color: theme.brightness == Brightness.dark ? theme.cardColor : Colors.white, border: Border(top: BorderSide(color: theme.dividerColor.withOpacity(0.1), width: 1)),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 16, offset: const Offset(0, -4))],
      child: QuizNavigationControls(sessionManager: _sessionManager, questions: widget.questions, playedQuizIds: widget.playedQuizIds, isCompact: isLandscape),
    );
  }

  void _handlePageChanged(int index) {
    _sessionManager.goToQuestion(index);
  }
}