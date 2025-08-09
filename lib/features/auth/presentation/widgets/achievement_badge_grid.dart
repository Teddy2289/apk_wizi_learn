import 'package:flutter/material.dart';
import 'package:wizi_learn/features/auth/data/models/achievement_model.dart';
import 'achievement_badge_widget.dart';

class AchievementBadgeGrid extends StatelessWidget {
  final List<Achievement> achievements;
  final Key? keyFirstBadge;
  const AchievementBadgeGrid({
    Key? key,
    required this.achievements,
    this.keyFirstBadge,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.8,
      ),
      itemCount: achievements.length,
      itemBuilder: (context, index) {
        final achievement = achievements[index];
        final unlocked = achievement.unlockedAt != null;
        return AchievementBadgeWidget(
          achievement: achievement,
          unlocked: unlocked,
          colored: true,
          key: index == 0 ? keyFirstBadge : null,
        );
      },
    );
  }
}
