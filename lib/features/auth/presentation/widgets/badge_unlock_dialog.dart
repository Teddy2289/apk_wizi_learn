import 'package:flutter/material.dart';
import 'package:wizi_learn/features/auth/data/models/achievement_model.dart';
import 'package:wizi_learn/features/auth/presentation/widgets/achievement_badge_widget.dart';

/// Dialog pour afficher la notification de badge débloqué
/// Design cohérent avec l'image de référence
class BadgeUnlockDialog extends StatelessWidget {
  final Achievement badge;
  final List<Achievement>? otherBadges;
  final VoidCallback? onViewAll;

  const BadgeUnlockDialog({
    super.key,
    required this.badge,
    this.otherBadges,
    this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.amber.shade50, Colors.orange.shade50],
          ),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Badge rond orange en haut
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.amber,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.amber.withOpacity(0.5),
                    blurRadius: 15,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.emoji_events,
                color: Colors.white,
                size: 40,
              ),
            ),
            const SizedBox(height: 20),

            // Titre
            Text(
              'Nouveau badge débloqué !',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.orange.shade900,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),

            // Message
            Text(
              'Félicitations pour votre accomplissement !',
              style: TextStyle(
                color: Colors.orange.shade700,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            // Card du badge débloqué avec fond beige
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7ED), // Beige/amber-50
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  AchievementBadgeWidget(
                    achievement: badge,
                    unlocked: true,
                  ),
                  const SizedBox(height: 12),
                  // Badge "Nouveau"
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.yellow.shade400,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Nouveau',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  ...[
                  const SizedBox(height: 12),
                  Text(
                    badge.description,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.orange.shade800,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
                ],
              ),
            ),

            // Section "Découvrez d'autres badges"
            if (otherBadges != null && otherBadges!.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text(
                'Découvrez d\'autres badges',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.orange.shade900,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: otherBadges!
                    .take(2)
                    .map(
                      (b) => Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: AchievementBadgeWidget(
                            achievement: b,
                            unlocked: false,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],

            const SizedBox(height: 20),

            // Boutons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: BorderSide(color: Colors.orange.shade300),
                    ),
                    child: Text(
                      'Continuer',
                      style: TextStyle(
                        color: Colors.orange.shade900,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      onViewAll?.call();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.emoji_events, size: 18),
                        SizedBox(width: 6),
                        Text(
                          'Voir',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
