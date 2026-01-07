import 'dart:math';
import 'package:flutter/material.dart';
import 'package:wizi_learn/features/auth/data/models/question_model.dart';

class MatchingQuestion extends StatefulWidget {
  final Question question;
  final Function(dynamic) onAnswer;
  final bool showFeedback;

  const MatchingQuestion({
    super.key,
    required this.question,
    required this.onAnswer,
    required this.showFeedback,
  });

  @override
  State<MatchingQuestion> createState() => _MatchingQuestionState();
}

class _MatchingQuestionState extends State<MatchingQuestion> {
  late Map<String, String> _matches;
  late List<Answer> _leftItems;
  late List<Answer> _availableOptions;

  @override
  void initState() {
    super.initState();
    _initMatchingData();
  }

  void _initMatchingData() {
    _matches = {};

    // Group answers by bankGroup
    final answerGroups = <String, List<Answer>>{};
    for (var answer in widget.question.answers) {
      final group = answer.bankGroup ?? '';
      answerGroups.putIfAbsent(group, () => []).add(answer);
    }

    // Séparer les left/right en fonction de matchPair
    _leftItems = [];
    _availableOptions = [];

    answerGroups.forEach((group, answers) {
      final leftItem = answers.firstWhere(
            (a) => a.matchPair == "left",
        orElse: () => Answer(id: "", text: "", correct: false),
      );

      final rightItem = answers.firstWhere(
            (a) => a.matchPair == "right",
        orElse: () => Answer(id: "", text: "", correct: false),
      );

      if (leftItem.id.isNotEmpty) _leftItems.add(leftItem);
      if (rightItem.id.isNotEmpty) _availableOptions.add(rightItem);
    });

    // Alternative fallback
    if (_leftItems.isEmpty && _availableOptions.isEmpty) {
      _leftItems = widget.question.answers
          .where((a) => a.position != null && a.position! % 2 == 1)
          .toList();
      _availableOptions = widget.question.answers
          .where((a) => a.position != null && a.position! % 2 == 0)
          .toList();
    }

    // Tri
    _leftItems.sort((a, b) => (a.position ?? 0).compareTo(b.position ?? 0));
    _availableOptions.sort((a, b) => (a.position ?? 0).compareTo(b.position ?? 0));

    // ✅ Shuffle right options for randomness
    _availableOptions.shuffle(Random());

    setState(() {});
  }

  void _updateMatch(String leftId, String? rightValue) {
    if (rightValue == null || rightValue == "_empty") {
      setState(() {
        _matches.remove(leftId);
      });
      return;
    }

    setState(() {
      _matches[leftId] = rightValue;
    });

    widget.onAnswer(_matches);
  }

  bool _isCorrectMatch(String leftId) {
    if (!widget.showFeedback) return false;

    final leftItem = _leftItems.firstWhere(
          (item) => item.id == leftId,
      orElse: () => Answer(id: "", text: "", correct: false),
    );

    if (leftItem.id.isEmpty) return false;

    final userMatch = _matches[leftId];
    final correctMatch = _availableOptions.firstWhere(
          (option) => option.bankGroup == leftItem.bankGroup,
      orElse: () => Answer(id: "", text: "", correct: false),
    );

    return userMatch == correctMatch.text;
  }

  String _getCorrectMatch(String leftId) {
    final leftItem = _leftItems.firstWhere((item) => item.id == leftId);
    final correctMatch = _availableOptions.firstWhere(
          (option) => option.matchPair == leftItem.id,
      orElse: () => Answer(id: "-1", text: "Non trouvé", correct: false),
    );
    return correctMatch.text;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 3,
      // shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.all(0),
      color: theme.colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Question header
            Text(
              widget.question.text,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 16),

            // Matching items
            ..._leftItems.map((leftItem) {
              final isCorrect = _isCorrectMatch(leftItem.id);
              final selectedValue = _matches[leftItem.id] ?? "_empty";

              return Container(
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: widget.showFeedback
                      ? isCorrect
                      ? Colors.green[50]
                      : Colors.red[50]
                      : theme.colorScheme.surfaceContainerHighest.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 16,
                  ),
                  child: Row(
                    children: [
                      // Left label
                      Expanded(
                        flex: 2,
                        child: Text(
                          leftItem.text,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const Icon(Icons.arrow_forward, size: 20, color: Colors.grey),
                      const SizedBox(width: 12),

                      // Dropdown
                      Expanded(
                        flex: 3,
                        child: DropdownButtonFormField<String>(
                          initialValue: selectedValue,
                          items: [
                            DropdownMenuItem(
                              value: "_empty",
                              child: Text(
                                "Sélectionnez...",
                                style: TextStyle(color: Colors.grey[500]),
                              ),
                            ),
                            ..._availableOptions.map((option) {
                              return DropdownMenuItem(
                                value: option.text,
                                child: Text(option.text),
                              );
                            }),
                          ],
                          onChanged: widget.showFeedback
                              ? null
                              : (value) => _updateMatch(leftItem.id, value),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                color: theme.dividerColor,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                color: theme.dividerColor,
                              ),
                            ),
                          ),
                          isExpanded: true,
                        ),
                      ),
                      if (widget.showFeedback) ...[
                        const SizedBox(width: 12),
                        Icon(
                          isCorrect ? Icons.check_circle : Icons.cancel,
                          color: isCorrect ? Colors.green : Colors.red,
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }),

            // Feedback
            if (widget.showFeedback) ...[
              const SizedBox(height: 16),
              Text(
                "Corrections :",
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.red[700],
                ),
              ),
              const SizedBox(height: 8),
              ..._leftItems.where((item) => !_isCorrectMatch(item.id)).map(
                    (leftItem) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: "${leftItem.text} ",
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const TextSpan(text: "→ "),
                          TextSpan(
                            text: _getCorrectMatch(leftItem.id),
                            style: TextStyle(
                              color: Colors.red[700],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}
