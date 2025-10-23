import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

const Color kYellowLight = Color(0xFFFFF9C4);
const Color kYellow = Color(0xFFFFEB3B);
const Color kOrange = Color(0xFFFF9800);
const Color kOrangeDark = Color(0xFFF57C00);
const Color kBrown = Color(0xFF8D6E63);

class HowToPlay extends StatelessWidget {
  const HowToPlay({super.key});

  @override
  Widget build(BuildContext context) {
    final steps = [
      {
        'icon': LucideIcons.gamepad2,
        'color': kOrange,
        'title': 'Choisissez un quiz',
        'description': 'Sélectionnez un quiz à découvrir.',
      },
      {
        'icon': LucideIcons.helpCircle,
        'color': kYellow,
        'title': 'Répondez aux questions',
        'description':
            'Testez vos connaissances en répondant à une série de questions.',
      },
      {
        'icon': LucideIcons.trophy,
        'color': kOrangeDark,
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
                  children: steps.map((step) {
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
                  children: steps.map((step) {
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
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: kYellowLight.withOpacity(0.7),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: kYellow.withOpacity(0.3), width: 0.5),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 32.0, color: color),
          ),
          const SizedBox(height: 16.0),
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600, color: kBrown),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8.0),
          Text(
            description,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: kBrown.withOpacity(0.7),
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}