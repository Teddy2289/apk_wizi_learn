import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class HowToPlay extends StatelessWidget {
  const HowToPlay({super.key});

  @override
  Widget build(BuildContext context) {
    final steps = [
      {
        'icon': LucideIcons.gamepad2,
        'color': Colors.orange.shade500,
        'title': 'Choisissez un quiz',
        'description': 'Sélectionnez un quiz à découvrir.',
      },
      {
        'icon': LucideIcons.helpCircle,
        'color': Colors.blue.shade500,
        'title': 'Répondez aux questions',
        'description':
            'Testez vos connaissances en répondant à une série de questions.',
      },
      {
        'icon': LucideIcons.trophy,
        'color': Colors.yellow.shade500,
        'title': 'Gagnez des points',
        'description':
            'Accumulez des points à chaque bonne réponse et montez dans le classement.',
      },
    ];

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 32.0),
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(12.0)),
      child: Column(
        children: [
          // Text(
          //   'Comment jouer ?',
          //   style: Theme.of(context).textTheme.headlineSmall?.copyWith(
          //         fontWeight: FontWeight.bold,
          //       ),
          //   textAlign: TextAlign.center,
          // ),
          const SizedBox(height: 24.0),
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth > 600) {
                // Desktop layout
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children:
                      steps.map((step) {
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8.0,
                            ),
                            child: _HowToPlayStep(
                              icon: step['icon'] as IconData,
                              color: step['color'] as Color,
                              title: step['title'] as String,
                              description: step['description'] as String,
                            ),
                          ),
                        );
                      }).toList(),
                );
              } else {
                // Mobile layout
                return Column(
                  children:
                      steps.map((step) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: _HowToPlayStep(
                            icon: step['icon'] as IconData,
                            color: step['color'] as Color,
                            title: step['title'] as String,
                            description: step['description'] as String,
                          ),
                        );
                      }).toList(),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}

class _HowToPlayStep extends StatelessWidget {
  const _HowToPlayStep({
    required this.icon,
    required this.color,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[800] : Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.grey[700] : Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 32.0, color: color),
          ),
          const SizedBox(height: 16.0),
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8.0),
          Text(
            description,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: isDarkMode ? Colors.grey[300] : Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
