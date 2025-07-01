import 'dart:async';
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
  late Timer _timer;
  int _remainingSeconds = 30;
  bool _hasAnswered = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _userAnswer = '';

    // Initialize with existing answer if available
    if (widget.question.selectedAnswers != null &&
        widget.question.selectedAnswers is Map) {
      final answers = widget.question.selectedAnswers as Map;
      if (answers.containsKey('reponse')) {
        _controller.text = answers['reponse'];
        _userAnswer = answers['reponse'];
        _hasAnswered = _userAnswer.isNotEmpty;
      }
    }

    _startTimer();
  }

  @override
  void dispose() {
    _controller.dispose();
    _timer.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() => _remainingSeconds--);
      } else {
        _timer.cancel();
        widget.onTimeout();
      }
    });
  }

  Widget _buildQuestionText() {
    final questionText = widget.question.text;
    final blankStart = questionText.indexOf('{');
    final blankEnd = questionText.indexOf('}');

    // Extract text parts
    final beforeText = questionText.substring(0, blankStart);
    final afterText = questionText.substring(blankEnd + 1);

    return RichText(
      text: TextSpan(
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontSize: 20,
          color: Colors.black87,
          height: 1.4,
        ),
        children: [
          TextSpan(text: beforeText),
          WidgetSpan(
            child: Container(
              width: 180,
              margin: const EdgeInsets.symmetric(horizontal: 8),
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
                  hintText: 'Entrer votre réponse',
                  hintStyle: TextStyle(color: Colors.grey.shade400),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: _hasAnswered ? Colors.green : Colors.yellowAccent,
                      width: 2,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: _hasAnswered ? Colors.green : Colors.yellow,
                      width: 2,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Colors.yellow,
                      width: 2.5,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                enabled: !widget.showFeedback,
                style: const TextStyle(
                  fontSize: 18,
                  color: Colors.black87,
                ),
              ),
            ),
          ),
          TextSpan(text: afterText),
        ],
      ),
    );
  }



  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 3,
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timer indicator
          const SizedBox(height: 24),

          // Question text with fill-in blank
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: _buildQuestionText(),
          ),

          // Feedback if enabled
          if (widget.showFeedback && _hasAnswered) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.green.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: Colors.green[600],
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Your answer has been saved!',
                      style: TextStyle(
                        color: Colors.green[800],
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}