import 'package:flutter/material.dart';

class MissionCard extends StatelessWidget {
  final String title;
  final String description;
  final int progress;
  final int goal;
  final String reward;
  const MissionCard({Key? key, required this.title, required this.description, required this.progress, required this.goal, required this.reward}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final percent = (progress / goal).clamp(0.0, 1.0);
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(description, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: percent,
              minHeight: 8,
              backgroundColor: Colors.grey[200],
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('$progress / $goal', style: Theme.of(context).textTheme.bodySmall),
                Row(
                  children: [
                    const Icon(Icons.emoji_events, color: Colors.amber, size: 18),
                    const SizedBox(width: 4),
                    Text(reward, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
} 