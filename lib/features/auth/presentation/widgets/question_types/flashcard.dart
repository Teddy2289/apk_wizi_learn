import 'package:flutter/material.dart';
import 'package:wizi_learn/features/auth/data/models/question_model.dart';

class FlashcardQuestion extends StatefulWidget {
  final Question question;
  final Function(List<String>) onAnswer;
  final bool showFeedback;

  const FlashcardQuestion({
    super.key,
    required this.question,
    required this.onAnswer,
    this.showFeedback = false,
  });

  @override
  State<FlashcardQuestion> createState() => _FlashcardQuestionState();
}

class _FlashcardQuestionState extends State<FlashcardQuestion> {
  bool _isFlipped = false;
  bool? _isCorrect;
  String _userAnswer = '';
  int _points = 0;
  int _streak = 0;
  late List<Answer> _shuffledAnswers;

  @override
  void initState() {
    super.initState();
    _shuffleAnswers();
  }

  void _shuffleAnswers() {
    setState(() {
      _shuffledAnswers = List<Answer>.from(widget.question.answers)
        ..shuffle();
    });
  }

  void _handleFlip() {
    if (!widget.showFeedback) {
      setState(() {
        _isFlipped = !_isFlipped;
      });
    }
  }

  // In _FlashcardQuestionState
  void _handleAnswer(Answer answer) {
    setState(() {
      _userAnswer = answer.text;
      _isCorrect = answer.correct;

      if (_isCorrect == true) {
        _points += 10;
        _streak += 1;
      } else {
        _streak = 0;
      }

      // Send answer as a map with question ID as key and answer text as value
      widget.onAnswer({widget.question.id.toString(): answer.text} as List<String>);
    });
  }

  void _resetCard() {
    setState(() {
      _isFlipped = false;
      _isCorrect = null;
      _userAnswer = '';
      _shuffleAnswers();
    });
  }

  Answer? get _correctAnswer {
    return widget.question.answers.firstWhere(
          (r) => r.correct,
      orElse: () => Answer(id: "-1", text: '', correct: false),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                widget.question.text,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w500),
              ),
            ),
            Row(
              children: [
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 20),
                    const SizedBox(width: 4),
                    Text('$_points',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                if (_streak > 0) ...[
                  const SizedBox(width: 16),
                  Text(
                    '${_streak}x streak!',
                    style: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ]
              ],
            ),
          ],
        ),
        const SizedBox(height: 24),
        GestureDetector(
          onTap: _handleFlip,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            transitionBuilder: (child, animation) {
              final rotateAnim = Tween(begin: 0.0, end: 1.0).animate(animation);
              return Rotation3d(rotationY: rotateAnim, child: child);
            },
            child: _isFlipped ? _buildBackCard() : _buildFrontCard(),
          ),
        ),
        if (!widget.showFeedback) ...[
          const SizedBox(height: 24),
          Text(
            'Quelle est votre réponse ?',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w500,
              color: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.color
                  ?.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 8),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            children: _shuffledAnswers
                .map((answer) => ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side:
                  BorderSide(color: Theme.of(context).dividerColor),
                ),
              ),
              onPressed: () => _handleAnswer(answer),
              child: Text(answer.text),
            ))
                .toList(),
          ),
        ],
        if (widget.showFeedback && _isCorrect != null) ...[
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _isCorrect! ? Icons.check_circle : Icons.cancel,
                color: _isCorrect! ? Colors.green : Colors.red,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                _isCorrect! ? 'Bonne réponse ! +10 points' : 'Essayez encore !',
                style: TextStyle(
                  color: _isCorrect! ? Colors.green : Colors.red,
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 16),
        Center(
          child: TextButton(
            onPressed: _resetCard,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.refresh, size: 16),
                SizedBox(width: 8),
                Text('Recommencer'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFrontCard() {
    return Card(
      key: const ValueKey('front'),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SizedBox(
        height: 200,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  widget.question.text,
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                if (!widget.showFeedback) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Cliquez pour retourner la carte',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.color
                          ?.withOpacity(0.6),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBackCard() {
    return Card(
      key: const ValueKey('back'),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SizedBox(
        height: 200,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _correctAnswer?.flashcardBack ?? '',
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                if (!widget.showFeedback) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Cliquez pour retourner la carte',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.color
                          ?.withOpacity(0.6),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class Rotation3d extends AnimatedWidget {
  const Rotation3d({super.key, required this.rotationY, required this.child})
      : super(listenable: rotationY);

  final Animation<double> rotationY;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final angle = rotationY.value * 3.1415926535897932;
    return Transform(
      transform: Matrix4.identity()
        ..setEntry(3, 2, 0.001)
        ..rotateY(angle),
      alignment: Alignment.center,
      child: child,
    );
  }
}
