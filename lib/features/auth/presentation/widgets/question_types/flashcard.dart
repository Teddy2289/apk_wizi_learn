import 'package:flutter/material.dart';
import 'package:wizi_learn/features/auth/data/models/question_model.dart';

class FlashcardQuestion extends StatefulWidget {
  final Question question;
  final Function(Map<String, dynamic>) onAnswer;
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
      _shuffledAnswers = List<Answer>.from(widget.question.answers)..shuffle();
    });
  }

  void _handleFlip() {
    if (!widget.showFeedback) {
      setState(() {
        _isFlipped = !_isFlipped;
      });
    }
  }

  void _handleAnswer(Answer answer) {
    final isCorrect = answer.correct;
    setState(() {
      _isCorrect = isCorrect;
      _userAnswer = answer.text;
      if (isCorrect) {
        _points += 10;
        _streak++;
      } else {
        _streak = 0;
      }
    });

    widget.onAnswer({
      widget.question.id.toString(): answer.text
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
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with points and streak
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: theme.dividerColor.withOpacity(0.1),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Flashcard',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.star,
                            color: Colors.amber,
                            size: 18,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$_points',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_streak > 0) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Text(
                              '$_streak',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.green,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.bolt,
                              color: Colors.green,
                              size: 18,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Flashcard
          GestureDetector(
            onTap: _handleFlip,
            child: Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                transitionBuilder: (child, animation) {
                  final rotateAnim = Tween(begin: 0.0, end: 1.0).animate(animation);
                  return Rotation3d(rotationY: rotateAnim, child: child);
                },
                child: _isFlipped ? _buildBackCard(theme) : _buildFrontCard(theme),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Answer options
          if (!widget.showFeedback) ...[
            Text(
              'Sélectionnez la bonne réponse :',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.onSurface.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                final crossAxisCount = constraints.maxWidth > 600 ? 3 : 2;
                return GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: crossAxisCount,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 3,
                  children: _shuffledAnswers.map((answer) {
                    return ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDarkMode
                            ? theme.cardColor
                            : Colors.white,
                        foregroundColor: theme.colorScheme.onSurface,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: theme.dividerColor,
                            width: 1,
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 16,
                        ),
                      ),
                      onPressed: () => _handleAnswer(answer),
                      child: Text(
                        answer.text,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],

          // Feedback
          if (widget.showFeedback && _isCorrect != null) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _isCorrect!
                    ? Colors.green.withOpacity(0.1)
                    : Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    _isCorrect! ? Icons.check_circle : Icons.error,
                    color: _isCorrect! ? Colors.green : Colors.red,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _isCorrect!
                          ? 'Bonne réponse ! +10 points'
                          : 'Mauvaise réponse. Essayez encore !',
                      style: TextStyle(
                        color: _isCorrect! ? Colors.green : Colors.red,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Reset button
          const SizedBox(height: 24),
          Center(
            child: TextButton.icon(
              onPressed: _resetCard,
              icon: Icon(
                Icons.refresh,
                size: 18,
                color: theme.colorScheme.primary,
              ),
              label: Text(
                'Recommencer',
                style: TextStyle(
                  color: theme.colorScheme.primary,
                ),
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFrontCard(ThemeData theme) {
    return Card(
      key: const ValueKey('front'),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.dividerColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      color: theme.cardColor,
      child: Container(
        constraints: const BoxConstraints(minHeight: 200, maxWidth: 500),
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                widget.question.text,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                ),
              ),
              if (!widget.showFeedback) ...[
                const SizedBox(height: 16),
                Text(
                  'Appuyez pour retourner la carte',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBackCard(ThemeData theme) {
    return Card(
      key: const ValueKey('back'),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.dividerColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      color: theme.cardColor,
      child: Container(
        constraints: const BoxConstraints(minHeight: 200, maxWidth: 500),
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _correctAnswer?.flashcardBack ?? '',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                ),
              ),
              if (!widget.showFeedback) ...[
                const SizedBox(height: 16),
                Text(
                  'Appuyez pour retourner la carte',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class Rotation3d extends AnimatedWidget {
  const Rotation3d({
    super.key,
    required this.rotationY,
    required this.child,
  }) : super(listenable: rotationY);

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