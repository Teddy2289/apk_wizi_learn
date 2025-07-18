import 'package:flutter/material.dart';
import 'package:wizi_learn/features/auth/data/models/question_model.dart';
import 'package:wizi_learn/features/auth/data/models/quiz_model.dart';
import 'package:wizi_learn/features/auth/presentation/components/quiz_navigation_controls.dart';
import 'package:wizi_learn/features/auth/presentation/components/quiz_progress_bar.dart';
import 'package:wizi_learn/features/auth/presentation/components/quiz_timer_display.dart';
import 'package:wizi_learn/features/auth/presentation/widgets/quiz_session/quiz_session_manager.dart';
import 'package:wizi_learn/features/auth/presentation/pages/question_type_page.dart';

class QuizSessionPage extends StatefulWidget {
  final Quiz quiz;
  final List<Question> questions;
  final bool isRestart;

  const QuizSessionPage({
    Key? key,
    required this.quiz,
    required this.questions,
    this.isRestart = false,
  }) : super(key: key);

  @override
  State<QuizSessionPage> createState() => _QuizSessionPageState();
}

class _QuizSessionPageState extends State<QuizSessionPage> {
  late final QuizSessionManager _sessionManager;
  final PageController _pageController = PageController();
  double _dragOffset = 0;

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
    );
    _sessionManager.startSession();

    _sessionManager.currentQuestionIndex.addListener(_syncPageController);
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

  void _handleHorizontalDragUpdate(DragUpdateDetails details) {
    setState(() => _dragOffset = details.primaryDelta ?? 0);
  }

  void _handleHorizontalDragEnd(DragEndDetails details) {
    if (_dragOffset.abs() > 20) {
      final newIndex =
          _sessionManager.currentQuestionIndex.value +
          (_dragOffset < 0 ? 1 : -1);
      _sessionManager.goToQuestion(
        newIndex.clamp(0, widget.questions.length - 1),
      );
    }
    setState(() => _dragOffset = 0);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.quiz.titre,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.3,
          ),
        ),
        centerTitle: false,
        elevation: 0,
        backgroundColor: isDarkMode ? theme.cardColor : Colors.white,
        foregroundColor: isDarkMode ? Colors.white : Colors.black87,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ValueListenableBuilder<int>(
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
          ),
        ],
      ),
      body: Column(
        children: [
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
                QuizTimerDisplay(sessionManager: _sessionManager),
              ],
            ),
          ),

          // Question area
          Expanded(
            child: PageView.builder(
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
    );
  }
}
