import 'package:flutter/material.dart';
import 'package:wizi_learn/features/auth/data/models/question_model.dart';

class TrueFalseQuestion extends StatefulWidget {
  final Question question;
  final Function(List<Map<String, String>>) onAnswer;
  final bool showFeedback;

  const TrueFalseQuestion({
    super.key,
    required this.question,
    required this.onAnswer,
    required this.showFeedback,
  });

  @override
  State<TrueFalseQuestion> createState() => _TrueFalseQuestionState();
}

class _TrueFalseQuestionState extends State<TrueFalseQuestion> {
  late List<String> _selectedAnswers;

  @override
  void initState() {
    super.initState();
    _selectedAnswers = [];

    if (widget.question.selectedAnswers != null) {
      if (widget.question.selectedAnswers is List) {
        _selectedAnswers = List<String>.from(
          widget.question.selectedAnswers as Iterable,
        );
      } else if (widget.question.selectedAnswers is String) {
        _selectedAnswers = [widget.question.selectedAnswers as String];
      }
    }
  }

  void _handleAnswerSelect(String answerId) {
    if (widget.showFeedback) return;

    setState(() {
      _selectedAnswers = [answerId];
    });

    // Trouver la réponse complète
    final selectedAnswer = widget.question.answers.firstWhere(
      (a) => a.id.toString() == answerId,
      orElse: () => Answer(id: '', text: '', correct: false),
    );

    if (selectedAnswer.id.isNotEmpty) {
      // Envoyer le TEXTE de la réponse
      widget.onAnswer([
        {'text': selectedAnswer.text},
      ]);
    }
  }

  bool _isCorrectAnswer(String answerId) {
    return widget.question.answers
            .firstWhere((a) => a.id.toString() == answerId)
            .correct ??
        false;
  }

  bool _isSelectedAnswerCorrect(String answerId) {
    return _selectedAnswers.contains(answerId) && _isCorrectAnswer(answerId);
  }

  bool _shouldShowCorrectIndicator(String answerId) {
    return widget.showFeedback &&
        (_selectedAnswers.contains(answerId) || _isCorrectAnswer(answerId));
  }
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Texte de la question
          Text(
            widget.question.text,
            style: textTheme.bodyLarge?.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),

          // Liste des réponses (True/False)
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: widget.question.answers.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final answer = widget.question.answers[index];
              final answerId = answer.id.toString();
              final isSelected = _selectedAnswers.contains(answerId);
              final showCorrectIndicator = _shouldShowCorrectIndicator(answerId);
              final isCorrect = _isCorrectAnswer(answerId);

              Color backgroundColor;
              if (isSelected) {
                backgroundColor = theme.colorScheme.primary.withOpacity(0.1);
                if (widget.showFeedback) {
                  backgroundColor = _isSelectedAnswerCorrect(answerId)
                      ? Colors.green[50]!
                      : Colors.red[50]!;
                }
              } else {
                backgroundColor = Colors.grey[100]!;
                if (widget.showFeedback && isCorrect) {
                  backgroundColor = Colors.green[50]!;
                }
              }

              return Material(
                borderRadius: BorderRadius.circular(12),
                color: backgroundColor,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: widget.showFeedback
                      ? null
                      : () => _handleAnswerSelect(answerId),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 16,
                    ),
                    child: Row(
                      children: [
                        // Pastille sélection
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected
                                  ? theme.colorScheme.primary
                                  : Colors.grey[400]!,
                              width: 2,
                            ),
                          ),
                          child: isSelected
                              ? Center(
                            child: Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          )
                              : null,
                        ),
                        const SizedBox(width: 16),

                        // Texte réponse
                        Expanded(
                          child: Text(
                            answer.text,
                            style: textTheme.bodyMedium?.copyWith(
                              fontSize: 14,
                              color: isSelected
                                  ? widget.showFeedback
                                  ? _isSelectedAnswerCorrect(answerId)
                                  ? Colors.green[800]
                                  : Colors.red[800]
                                  : Colors.grey[800]
                                  : widget.showFeedback && isCorrect
                                  ? Colors.green[800]
                                  : Colors.grey[800],
                            ),
                          ),
                        ),

                        // Check ou Close en feedback
                        if (showCorrectIndicator)
                          Icon(
                            isCorrect ? Icons.check : Icons.close,
                            color: isCorrect ? Colors.green : Colors.red,
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),

          if (widget.showFeedback) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: _selectedAnswers.isNotEmpty &&
                    _selectedAnswers.every(_isCorrectAnswer)
                    ? Colors.green[50]
                    : Colors.red[50],
              ),
              child: Text(
                _selectedAnswers.isNotEmpty &&
                    _selectedAnswers.every(_isCorrectAnswer)
                    ? "Bonne réponse !"
                    : "Réponse incorrecte. La bonne réponse était: ${widget.question.answers.where((a) => a.correct == true).map((a) => a.text).join(", ")}",
                style: TextStyle(
                  color: _selectedAnswers.isNotEmpty &&
                      _selectedAnswers.every(_isCorrectAnswer)
                      ? Colors.green[800]
                      : Colors.red[800],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
