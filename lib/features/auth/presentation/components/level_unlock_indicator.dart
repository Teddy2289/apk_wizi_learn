import 'package:flutter/material.dart';

class LevelUnlockIndicator extends StatelessWidget {
  final int userPoints;

  const LevelUnlockIndicator({
    super.key,
    required this.userPoints,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    final levels = [
      {'name': 'Débutant', 'threshold': 0, 'icon': Icons.stars_outlined, 'color': const Color(0xFF10B981)},
      {'name': 'Intermédiaire', 'threshold': 50, 'icon': Icons.bolt, 'color': const Color(0xFFF59E0B)},
      {'name': 'Avancé', 'threshold': 100, 'icon': Icons.star, 'color': const Color(0xFFEF4444)},
    ];

    int getUnlockedCount() {
      if (userPoints >= 100) return 3;
      if (userPoints >= 50) return 2;
      return 1;
    }

    final unlockedCount = getUnlockedCount();
    final nextThreshold = unlockedCount == 1 ? 50 : unlockedCount == 2 ? 100 : null;
    final progressToNext = nextThreshold != null
        ? ((userPoints - (nextThreshold == 50 ? 0 : 50)) / (nextThreshold - (nextThreshold == 50 ? 0 : 50))).clamp(0.0, 1.0)
        : 1.0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.trending_up, color: const Color(0xFFFFB800), size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'NIVEAUX DÉBLOQUÉS',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$unlockedCount / 3',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Level badges
            Row(
              children: levels.map((level) {
                final isUnlocked = userPoints >= (level['threshold'] as int);
                final icon = level['icon'] as IconData;
                final color = level['color'] as Color;
                final name = level['name'] as String;
                final threshold = level['threshold'] as int;
                
                return Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                    decoration: BoxDecoration(
                      color: isUnlocked ? Colors.white : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isUnlocked ? color.withOpacity(0.3) : Colors.grey.shade200,
                      ),
                      boxShadow: isUnlocked ? [
                        BoxShadow(
                          color: color.withOpacity(0.15),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ] : null,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: isUnlocked ? color : Colors.grey.shade300,
                            shape: BoxShape.circle,
                            boxShadow: isUnlocked ? [
                              BoxShadow(
                                color: color.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ] : null,
                          ),
                          child: Icon(
                            icon,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          name,
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isUnlocked ? Colors.grey.shade800 : Colors.grey.shade400,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isUnlocked ? 'Débloqué ✓' : '$threshold pts',
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontSize: 10,
                            color: isUnlocked ? const Color(0xFF10B981) : Colors.grey.shade400,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            
            // Progress bar (only if not all unlocked)
            if (nextThreshold != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.only(top: 12),
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: Colors.grey.shade200)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Prochain niveau',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: Colors.grey.shade500,
                          ),
                        ),
                        Text(
                          '$userPoints / $nextThreshold pts',
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: progressToNext,
                        backgroundColor: Colors.grey.shade100,
                        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFFB800)),
                        minHeight: 6,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
