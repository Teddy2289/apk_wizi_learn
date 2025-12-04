import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:wizi_learn/features/auth/data/models/achievement_model.dart';

class AchievementBadgeWidget extends StatelessWidget {
  final Achievement achievement;
  final bool unlocked;
  final bool colored;
  
  const AchievementBadgeWidget({
    super.key,
    required this.achievement,
    required this.unlocked,
    this.colored = true,
  });

  IconData _getIconForType(String? type) {
    switch (type?.toLowerCase()) {
      case 'connexion_serie':
        return LucideIcons.flame;
      case 'points_total':
        return LucideIcons.trophy;
      case 'palier':
        return LucideIcons.medal;
      case 'quiz':
        return LucideIcons.brain;
      case 'premium':
        return LucideIcons.star;
      case 'challenge':
        return LucideIcons.zap;
      case 'exclusif':
        return LucideIcons.lock;
      default:
        return LucideIcons.checkCircle;
    }
  }

  Map<String, Color> _getLevelColors(String? level) {
    switch (level?.toLowerCase()) {
      case 'bronze':
        return {
          'bg': const Color(0xFFFEF3C7), // amber-100
          'text': const Color(0xFFD97706), // amber-600
        };
      case 'argent':
        return {
          'bg': const Color(0xFFF3F4F6), // gray-100
          'text': const Color(0xFF4B5563), // gray-600
        };
      case 'or':
        return {
          'bg': const Color(0xFFFFF7ED), // orange-50
          'text': const Color(0xFFF97316), // orange-500
        };
      case 'platine':
        return {
          'bg': const Color(0xFFDBEAFE), // blue-100
          'text': const Color(0xFF2563EB), // blue-600
        };
      default:
        return {
          'bg': const Color(0xFFF3E8FF), // purple-100
          'text': const Color(0xFF9333EA), // purple-600
        };
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = _getLevelColors(achievement.level);
    final bgColor = unlocked ? colors['bg']! : const Color(0xFFF3F4F6);
    final iconColor = unlocked ? colors['text']! : const Color(0xFF9CA3AF);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFF3F4F6),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icon with background
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Icon(
              _getIconForType(achievement.type),
              size: 24,
              color: iconColor,
            ),
          ),
          const SizedBox(height: 12),
          
          // Badge name
          Text(
            achievement.name,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: unlocked 
                ? const Color(0xFF1F2937) 
                : const Color(0xFF9CA3AF),
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          
          // Level badge (optional)
          if (achievement.level != null && unlocked) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: colors['bg'],
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                achievement.level!,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: colors['text'],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
