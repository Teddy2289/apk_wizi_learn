import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:wizi_learn/core/constants/route_constants.dart';
import 'package:wizi_learn/features/auth/data/models/question_model.dart';
import 'package:wizi_learn/features/auth/presentation/components/quiz_question_card.dart';
import 'package:wizi_learn/features/auth/presentation/components/quiz_score_header.dart';
import 'dart:math';

import 'package:wizi_learn/features/auth/presentation/pages/quiz_page.dart';

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
  bool _showSuccessDialog = false;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );

    final allCorrect = widget.questions.every((q) => q.isCorrect == true);
    if (allCorrect) {
      _showConfetti = true;
      _showSuccessDialog = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _confettiController.play();
        _showCongratulationDialog();
      });
    }
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
                  setState(() {
                    _showSuccessDialog = false;
                  });
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
    final allCorrect = calculatedCorrectAnswers == widget.totalQuestions;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Récapitulatif du Quiz"),
        centerTitle: true,
        actions: [
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
                totalQuestions:
                    answeredQuestions.length, // Utiliser le nouveau total
                timeSpent: widget.timeSpent,
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
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (_) => WillPopScope(
                    onWillPop: () async => false, // Désactive le retour physique
                    child: QuizPage(), // QuizPage utilisera son CustomScaffold normal
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
