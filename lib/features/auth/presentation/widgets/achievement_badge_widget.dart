import 'package:flutter/material.dart';
import 'package:wizi_learn/features/auth/data/models/achievement_model.dart';

class AchievementBadgeWidget extends StatelessWidget {
  final Achievement achievement;
  final bool unlocked;
  const AchievementBadgeWidget({
    Key? key,
    required this.achievement,
    required this.unlocked,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: 32,
          backgroundColor: unlocked ? Colors.amber : Colors.grey[300],
          child:
              achievement.icon != null
                  ? Image.network(
                    achievement.icon!,
                    width: 40,
                    height: 40,
                    color: unlocked ? null : Colors.grey,
                  )
                  : Icon(
                    Icons.emoji_events,
                    size: 40,
                    color: unlocked ? Colors.white : Colors.grey,
                  ),
        ),
        const SizedBox(height: 8),
        Text(
          achievement.name,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: unlocked ? theme.colorScheme.onSurface : Colors.grey,
          ),
          textAlign: TextAlign.center,
        ),
        if (unlocked && achievement.unlockedAt != null)
          Text(
            'Débloqué le\n${achievement.unlockedAt!.day}/${achievement.unlockedAt!.month}/${achievement.unlockedAt!.year}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.primary,
            ),
            textAlign: TextAlign.center,
          ),
      ],
    );
  }
}
