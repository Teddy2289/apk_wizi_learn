import 'package:flutter/material.dart';
import 'package:wizi_learn/features/auth/data/models/mission_model.dart';

class MissionCard extends StatelessWidget {
  final Mission mission;
  const MissionCard({Key? key, required this.mission}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final percent = (mission.progress / mission.goal).clamp(0.0, 1.0);
    final isCompleted = mission.completed;
    final typeColor = mission.type == 'daily'
        ? Colors.blue
        : mission.type == 'weekly'
            ? Colors.purple
            : Colors.orange;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: isCompleted ? 6 : 2,
      shadowColor: isCompleted ? Colors.greenAccent : null,
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      mission.type == 'daily'
                          ? Icons.calendar_today
                          : mission.type == 'weekly'
                              ? Icons.calendar_view_week
                              : Icons.star,
                      color: typeColor,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      mission.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    if (isCompleted)
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: Icon(Icons.check_circle, color: Colors.green, size: 20),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(mission.description, style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: percent,
                  minHeight: 8,
                  backgroundColor: Colors.grey[200],
                  color: isCompleted ? Colors.green : typeColor,
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${mission.progress} / ${mission.goal}', style: Theme.of(context).textTheme.bodySmall),
                    Row(
                      children: [
                        const Icon(Icons.emoji_events, color: Colors.amber, size: 18),
                        const SizedBox(width: 4),
                        Text(mission.reward, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (isCompleted)
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                  ),
                ),
                child: const Text('Complétée', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            ),
        ],
      ),
    );
  }
} 