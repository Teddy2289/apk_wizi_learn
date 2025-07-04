import 'package:flutter/material.dart';
import 'package:wizi_learn/features/auth/data/models/question_model.dart';
import 'package:fluttertoast/fluttertoast.dart';

class MultipleChoiceQuestion extends StatefulWidget {
  final Question question;
  final Function(dynamic) onAnswer;
  final VoidCallback? onNext;

  const MultipleChoiceQuestion({
    super.key,
    required this.question,
    required this.onAnswer,
    this.onNext,
  });

  @override
  State<MultipleChoiceQuestion> createState() => _MultipleChoiceQuestionState();
}

class _MultipleChoiceQuestionState extends State<MultipleChoiceQuestion> {
  late List<String> _selectedAnswers;
  bool _answerConfirmed = false;

  @override
  void initState() {
    super.initState();
    _selectedAnswers = [];
    _answerConfirmed = widget.question.selectedAnswers != null;

    if (widget.question.selectedAnswers != null) {
      if (widget.question.selectedAnswers is List) {
        _selectedAnswers = List<String>.from(
          widget.question.selectedAnswers as List,
        );
      } else if (widget.question.selectedAnswers is String) {
        _selectedAnswers = [widget.question.selectedAnswers as String];
      }
    }
  }

  void _handleAnswerSelect(String answerId) {
    setState(() {
      if (_selectedAnswers.contains(answerId)) {
        _selectedAnswers.remove(answerId);
      } else {
        _selectedAnswers.add(answerId);
      }
    });
  }

  void _submitAnswer() {
    if (_selectedAnswers.isEmpty) {
      widget.onAnswer([]);
      setState(() {
        _answerConfirmed = true;
      });
      return;
    }

    final selectedTexts = _selectedAnswers.map((id) {
      return widget.question.answers
          .firstWhere((a) => a.id.toString() == id)
          .text;
    }).toList();

    widget.onAnswer(selectedTexts);
    setState(() {
      _answerConfirmed = true;
    });

    Fluttertoast.showToast(
      msg: "Réponse sauvegardée avec succès !",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.TOP,
      backgroundColor: Colors.green[500],
      textColor: Colors.white,
      fontSize: 16.0,
    );
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
          // Question text
          Text(
            widget.question.text,
            style: textTheme.bodyLarge?.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),

          // Answers list
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: widget.question.answers.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final answer = widget.question.answers[index];
              final isSelected = _selectedAnswers.contains(answer.id.toString());

              return Material(
                borderRadius: BorderRadius.circular(12),
                color: isSelected
                    ? theme.colorScheme.primary.withOpacity(0.1)
                    : Colors.grey[100],
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => _handleAnswerSelect(answer.id.toString()),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 16,
                    ),
                    child: Row(
                      children: [
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
                        Expanded(
                          child: Text(
                            answer.text,
                            style: textTheme.bodyMedium?.copyWith(
                              fontSize: 14,
                              color: Colors.grey[800],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 24),

          // Submit button
          if (_selectedAnswers.isNotEmpty && !_answerConfirmed)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _submitAnswer,
                child: Text(
                  'Confirmer la réponse',
                  style: textTheme.labelLarge?.copyWith(
                    fontSize: 14,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}