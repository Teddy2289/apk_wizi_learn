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

  const QuizSessionPage({
    super.key,
    required this.quiz,
    required this.questions,
  });

  @override
  State<QuizSessionPage> createState() => _QuizSessionPageState();
}

class _QuizSessionPageState extends State<QuizSessionPage> {
  late final QuizSessionManager _sessionManager;

  @override
  void initState() {
    super.initState();
    _sessionManager = QuizSessionManager(
      questions: widget.questions,
      quizId: widget.quiz.id.toString(),
    );
    _sessionManager.startSession();
  }

  @override
  void dispose() {
    _sessionManager.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.quiz.titre),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Center(
              child: ValueListenableBuilder<int>(
                valueListenable: _sessionManager.currentQuestionIndex,
                builder: (_, index, __) {
                  return Text(
                    '${index + 1}/${widget.questions.length}',
                    style: const TextStyle(fontSize: 16),
                  );
                },
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          QuizProgressBar(sessionManager: _sessionManager),
          QuizTimerDisplay(sessionManager: _sessionManager),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: ValueListenableBuilder<int>(
                valueListenable: _sessionManager.currentQuestionIndex,
                builder: (_, index, __) {
                  return QuestionTypePage(
                    key: ValueKey(widget.questions[index].id),
                    onAnswer: _sessionManager.handleAnswer,
                    question: widget.questions[index],
                  );
                },
              ),
            ),
          ),
          QuizNavigationControls(
            sessionManager: _sessionManager,
            questions: widget.questions,
          ),
        ],
      ),
    );
  }
}
