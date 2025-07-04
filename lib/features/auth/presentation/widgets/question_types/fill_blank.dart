import 'package:flutter/material.dart';
import 'package:wizi_learn/features/auth/data/models/question_model.dart';

class FillBlankQuestion extends StatefulWidget {
  final Question question;
  final Function(Map<String, String>) onAnswer;
  final bool showFeedback;
  final VoidCallback onTimeout;

  const FillBlankQuestion({
    super.key,
    required this.question,
    required this.onAnswer,
    required this.showFeedback,
    required this.onTimeout,
  });

  @override
  _FillBlankQuestionState createState() => _FillBlankQuestionState();
}

class _FillBlankQuestionState extends State<FillBlankQuestion> {
  late TextEditingController _controller;
  late String _userAnswer;
  bool _hasAnswered = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _userAnswer = '';

    if (widget.question.selectedAnswers != null &&
        widget.question.selectedAnswers is Map) {
      final answers = widget.question.selectedAnswers as Map;
      if (answers.containsKey('reponse')) {
        _controller.text = answers['reponse'];
        _userAnswer = answers['reponse'];
        _hasAnswered = _userAnswer.isNotEmpty;
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildQuestionText(BuildContext context) {
    final theme = Theme.of(context);
    final questionText = widget.question.text;
    final blankStart = questionText.indexOf('{');
    final blankEnd = questionText.indexOf('}');

    final beforeText = questionText.substring(0, blankStart);
    final afterText = questionText.substring(blankEnd + 1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            style: theme.textTheme.titleLarge?.copyWith(
              fontSize: 18,
              height: 1.5,
            ),
            children: [
              TextSpan(text: beforeText),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          constraints: const BoxConstraints(minWidth: 200, maxWidth: 500),
          child: TextField(
            controller: _controller,
            onChanged: (value) {
              setState(() {
                _userAnswer = value;
                _hasAnswered = value.isNotEmpty;
              });
              widget.onAnswer({'reponse': value});
            },
            decoration: InputDecoration(
              hintText: 'Tapez votre réponse ici...',
              hintStyle: theme.textTheme.bodyMedium?.copyWith(
                color: theme.hintColor,
              ),
              filled: true,
              fillColor: theme.cardColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: _hasAnswered
                      ? theme.colorScheme.primary
                      : theme.dividerColor,
                  width: 1.5,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: theme.colorScheme.primary,
                  width: 2,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
            enabled: !widget.showFeedback,
            style: theme.textTheme.bodyLarge,
            maxLines: null,
          ),
        ),
        const SizedBox(height: 12),
        RichText(
          text: TextSpan(
            style: theme.textTheme.titleLarge?.copyWith(
              fontSize: 18,
              height: 1.5,
            ),
            children: [
              TextSpan(text: afterText),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFeedback(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: _hasAnswered
          ? Container(
        margin: const EdgeInsets.only(top: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              Icons.check_circle,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Réponse enregistrée',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
          ],
        ),
      )
          : const SizedBox.shrink(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            color: theme.scaffoldBackgroundColor,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Question text with blank
                  _buildQuestionText(context),

                  // Feedback
                  if (widget.showFeedback) _buildFeedback(context),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}