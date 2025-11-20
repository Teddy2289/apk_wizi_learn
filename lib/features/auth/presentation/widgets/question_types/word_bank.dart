import 'package:flutter/material.dart';
import 'package:wizi_learn/features/auth/data/models/question_model.dart';

class WordBankQuestion extends StatefulWidget {
  final Question question;
  final Function(List<String>) onAnswer;
  final bool showFeedback;

  const WordBankQuestion({
    super.key,
    required this.question,
    required this.onAnswer,
    this.showFeedback = false,
  });

  @override
  State<WordBankQuestion> createState() => _WordBankState();
}

class _WordBankState extends State<WordBankQuestion> {
  late List<String> _selectedWords;

  @override
  void initState() {
    super.initState();
    // Initialiser avec les réponses sélectionnées existantes
    _selectedWords =
        widget.question.selectedAnswers != null
            ? List<String>.from(widget.question.selectedAnswers as Iterable)
            : [];
  }

  void _handleWordSelect(String wordId) {
    if (widget.showFeedback) return;

    setState(() {
      if (_selectedWords.contains(wordId)) {
        _selectedWords.remove(wordId);
      } else {
        _selectedWords.add(wordId);
      }
    });

    // Envoyer les textes des mots sélectionnés
    final selectedTexts =
        _selectedWords.map((id) {
          return widget.question.answers.firstWhere((a) => a.id == id).text;
        }).toList();

    widget.onAnswer(selectedTexts);
  }

  bool? _isWordCorrect(String wordId) {
    if (!widget.showFeedback) return null;

    final answer = widget.question.answers.firstWhere(
      (a) => a.id == wordId,
      orElse: () => Answer(correct: false, id: '', text: ''),
    );

    return answer.correct ?? answer.correct;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // CORRECTION: Afficher la question réelle
            // CORRECTION: Afficher la question réelle
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.question.text ?? '',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),

            // Instructions
            Text(
              'Sélectionnez les réponses correctes:',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
                color: Theme.of(
                  context,
                ).textTheme.bodySmall?.color?.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 8),

            // Mots à sélectionner
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children:
                  (widget.question.answers ?? []).map((word) {
                    final isSelected = _selectedWords.contains(word.id);
                    final correctStatus = _isWordCorrect(word.id);

                    Color? backgroundColor;
                    Color? textColor;
                    Color? borderColor;
                    Icon? icon;

                    if (widget.showFeedback) {
                      if (correctStatus == true) {
                        backgroundColor = Colors.green[50];
                        textColor = Colors.green[800];
                        borderColor = Colors.green[300];
                      } else if (correctStatus == false && isSelected) {
                        backgroundColor = Colors.red[50];
                        textColor = Colors.red[800];
                        borderColor = Colors.red[300];
                      }
                    } else if (isSelected) {
                      backgroundColor = Theme.of(context).colorScheme.primary;
                      textColor = Theme.of(context).colorScheme.onPrimary;
                    }

                    if (widget.showFeedback && isSelected) {
                      icon = Icon(
                        correctStatus == true ? Icons.check : Icons.close,
                        size: 16,
                        color:
                            correctStatus == true ? Colors.green : Colors.red,
                      );
                    }

                    return OutlinedButton(
                      onPressed: () => _handleWordSelect(word.id),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: backgroundColor,
                        foregroundColor: textColor,
                        side: BorderSide(
                          color:
                              borderColor ??
                              Theme.of(context).colorScheme.outline,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(word.text),
                          if (icon != null) ...[const SizedBox(width: 4), icon],
                        ],
                      ),
                    );
                  }).toList(),
            ),

            // Section de feedback (seulement en mode correction)
            if (widget.showFeedback) ...[
              const SizedBox(height: 16),
              Divider(height: 1, color: Theme.of(context).dividerColor),
              const SizedBox(height: 16),
              Text(
                'Réponses correctes:',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.8),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children:
                    (widget.question.answers ?? [])
                        .where((answer) => (answer.correct ?? false))
                        .map((answer) {
                          final wasSelected = _selectedWords.contains(
                            answer.id,
                          );

                          return Chip(
                            label: Text(answer.text),
                            backgroundColor:
                                wasSelected
                                    ? Colors.green[50]
                                    : Colors.grey[100],
                            labelStyle: TextStyle(
                              color:
                                  wasSelected
                                      ? Colors.green[800]
                                      : Colors.grey[800],
                              fontWeight:
                                  wasSelected
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                            ),
                            side: BorderSide.none,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          );
                        })
                        .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
