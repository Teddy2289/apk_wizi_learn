import 'package:flutter/material.dart';
import 'package:wizi_learn/features/auth/data/models/achievement_model.dart';

class AchievementBadgeWidget extends StatelessWidget {
  final Achievement achievement;
  final bool unlocked;
  final bool colored;
  const AchievementBadgeWidget({
    Key? key,
    required this.achievement,
    required this.unlocked,
    this.colored = true,
  }) : super(key: key);

  bool _isUrl(String value) {
    return value.startsWith('http://') || value.startsWith('https://');
  }

  IconData _mapIcon(String name) {
    switch (name.toLowerCase()) {
      case 'trophy':
        return Icons.emoji_events;
      case 'fire':
        return Icons.local_fire_department;
      case 'party':
        return Icons.celebration;
      case 'tv':
        return Icons.live_tv;
      case 'clapper':
        return Icons.movie;
      case 'handshake':
        return Icons.handshake;
      case 'bronze':
      case 'silver':
      case 'gold':
        return Icons.emoji_events;
      default:
        return Icons.emoji_events;
    }
  }

  Color _levelColor(String? level) {
    switch ((level ?? '').toLowerCase()) {
      case 'bronze':
        return const Color(0xFFCD7F32);
      case 'silver':
        return const Color(0xFFC0C0C0);
      case 'gold':
        return const Color(0xFFFFD700);
      default:
        return Colors.amber;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final hasIcon =
        (achievement.icon != null && achievement.icon!.trim().isNotEmpty);
    final baseColor =
        hasIcon &&
                [
                  'bronze',
                  'silver',
                  'gold',
                ].contains(achievement.icon!.toLowerCase())
            ? _levelColor(achievement.icon)
            : _levelColor(achievement.level);

    // Determine circle and icon colors depending on colored flag
    final defaultCircleColor =
        unlocked ? baseColor : (Colors.grey[300] ?? Colors.grey);
    final grayscaleCircleColor =
        unlocked
            ? (Colors.grey[400] ?? Colors.grey)
            : (Colors.grey[300] ?? Colors.grey);
    final circleColor = colored ? defaultCircleColor : grayscaleCircleColor;

    Color iconColor(bool wantWhiteIfColored) {
      if (!colored) return Colors.grey[700] ?? Colors.grey;
      return wantWhiteIfColored
          ? Colors.white
          : (unlocked ? Colors.white : Colors.grey);
    }

    Widget inner;
    if (hasIcon && _isUrl(achievement.icon!)) {
      inner = Image.network(
        achievement.icon!,
        width: 40,
        height: 40,
        color:
            colored
                ? (unlocked ? null : Colors.grey)
                : (Colors.grey[600] ?? Colors.grey),
        errorBuilder:
            (_, __, ___) => Icon(
              _mapIcon(achievement.icon!),
              size: 40,
              color: iconColor(true),
            ),
      );
    } else if (hasIcon) {
      inner = Icon(
        _mapIcon(achievement.icon!),
        size: 40,
        color: iconColor(true),
      );
    } else {
      inner = Icon(Icons.emoji_events, size: 40, color: iconColor(true));
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: circleColor,
            boxShadow:
                (colored && unlocked)
                    ? [
                      BoxShadow(
                        color: baseColor.withOpacity(0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                    : null,
          ),
          child: Center(child: inner),
        ),
        const SizedBox(height: 8),
        Text(
          achievement.name,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: unlocked ? theme.colorScheme.onSurface : Colors.grey,
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        if (unlocked && achievement.unlockedAt != null)
          Text(
            'Débloqué le\n${achievement.unlockedAt!.day}/${achievement.unlockedAt!.month}/${achievement.unlockedAt!.year}',
            style: theme.textTheme.bodySmall?.copyWith(
              color:
                  colored
                      ? theme.colorScheme.primary
                      : (Colors.grey[600] ?? Colors.grey),
            ),
            textAlign: TextAlign.center,
          ),
      ],
    );
  }
}
