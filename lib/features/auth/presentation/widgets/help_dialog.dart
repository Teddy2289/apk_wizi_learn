import 'package:flutter/material.dart';

Future<void> showStandardHelpDialog(
  BuildContext context, {
  String title = 'Comment utiliser cette page ?',
  required List<String> steps,
}) async {
  return showDialog(
    context: context,
    builder:
        (context) => AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.help_outline),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (int i = 0; i < steps.length; i++) ...[
                _HelpStep(text: steps[i]),
                if (i != steps.length - 1) const SizedBox(height: 8),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Compris !'),
            ),
          ],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
  );
}

class _HelpStep extends StatelessWidget {
  final String text;
  const _HelpStep({required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.play_arrow, size: 16),
        const SizedBox(width: 6),
        Expanded(child: Text(text)),
      ],
    );
  }
}
