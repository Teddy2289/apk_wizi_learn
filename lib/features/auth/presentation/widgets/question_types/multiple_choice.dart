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

    // Initialiser avec les réponses existantes si disponibles
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
      // Pour choix multiple uniquement: toggle la sélection
      if (_selectedAnswers.contains(answerId)) {
        _selectedAnswers.remove(answerId);
      } else {
        _selectedAnswers.add(answerId);
      }
    });
  }

  void _submitAnswer() {
    if (_selectedAnswers.isEmpty) {
      // Envoyer une liste vide explicitement si aucune réponse n'est sélectionnée
      widget.onAnswer([]);
      setState(() {
        _answerConfirmed = true;
      });
      return;
    }

    // Récupérer les textes des réponses sélectionnées
    final selectedTexts =
        _selectedAnswers.map((id) {
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
    return Column(
      children: [
        const SizedBox(height: 20),
        ...widget.question.answers.map((answer) {
          final isSelected = _selectedAnswers.contains(answer.id.toString());

          return InkWell(
            onTap: () => _handleAnswerSelect(answer.id.toString()),
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(
                  color:
                      isSelected ? Theme.of(context).primaryColor : Colors.grey,
                ),
                borderRadius: BorderRadius.circular(8),
                color:
                    isSelected
                        ? Theme.of(context).primaryColor.withOpacity(0.1)
                        : null,
              ),
              child: Row(
                children: [
                  Checkbox(
                    value: isSelected,
                    onChanged: (_) => _handleAnswerSelect(answer.id.toString()),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Text(answer.text)),
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: 20),
        if (_selectedAnswers.isNotEmpty)
          if (_selectedAnswers.isNotEmpty && !_answerConfirmed)
            ElevatedButton(
              onPressed: _submitAnswer,
              child: const Text('Confirmer la réponse'),
            ),
      ],
    );
  }
}
