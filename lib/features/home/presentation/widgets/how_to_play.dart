import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

// Nouvelle palette de couleurs harmonieuse
const Color kPrimaryBlue = Color(0xFF3D9BE9);
const Color kPrimaryBlueLight = Color(0xFFE8F4FE);
const Color kPrimaryBlueDark = Color(0xFF2A7BC8);

const Color kSuccessGreen = Color(0xFFABDA96);
const Color kSuccessGreenLight = Color(0xFFF0F9ED);
const Color kSuccessGreenDark = Color(0xFF7BBF5E);

const Color kAccentPurple = Color(0xFF9392BE);
const Color kAccentPurpleLight = Color(0xFFF5F4FF);
const Color kAccentPurpleDark = Color(0xFF6A6896);

const Color kWarningOrange = Color(0xFFFFC533);
const Color kWarningOrangeLight = Color(0xFFFFF8E8);
const Color kWarningOrangeDark = Color(0xFFE6A400);

const Color kNeutralWhite = Colors.white;
const Color kNeutralGrey = Color(0xFFF8F9FA);
const Color kNeutralGreyDark = Color(0xFF6C757D);
const Color kNeutralBlack = Color(0xFF212529);

class HowToPlay extends StatelessWidget {
  const HowToPlay({super.key});

  @override
  Widget build(BuildContext context) {
    final steps = [
      {
        'number': '1',
        'icon': LucideIcons.gamepad2,
        'color': kPrimaryBlue,
        'title': 'Choisissez un quiz',
        'description':
            'Sélectionnez un quiz adapté à votre niveau et formation.',
      },
      {
        'number': '2',
        'icon': LucideIcons.helpCircle,
        'color': kSuccessGreen,
        'title': 'Répondez aux questions',
        'description':
            'Testez vos connaissances en répondant à une série de questions chronométrées.',
      },
      {
        'number': '3',
        'icon': LucideIcons.trophy,
        'color': kWarningOrange,
        'title': 'Gagnez des points',
        'description':
            'Accumulez des points à chaque bonne réponse et montez dans le classement général.',
      },
    ];

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16.0),
          SizedBox(
            height: 220, // Hauteur fixe pour le défilement horizontal
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              itemCount: steps.length,
              separatorBuilder: (context, index) => const SizedBox(width: 12.0),
              itemBuilder: (context, index) {
                final step = steps[index];
                return _HowToPlayStep(
                  number: step['number'] as String,
                  icon: step['icon'] as IconData,
                  color: step['color'] as Color,
                  title: step['title'] as String,
                  description: step['description'] as String,
                  isLast: index == steps.length - 1,
                );
              },
            ),
          ),
          const SizedBox(height: 8.0),
          // Indicateurs de défilement
          // Padding(
          //   padding: const EdgeInsets.symmetric(horizontal: 16.0),
          //   child: Row(
          //     mainAxisAlignment: MainAxisAlignment.center,
          //     children: List.generate(steps.length, (index) {
          //       return Container(
          //         width: 8.0,
          //         height: 8.0,
          //         margin: const EdgeInsets.symmetric(horizontal: 4.0),
          //         decoration: BoxDecoration(
          //           shape: BoxShape.circle,
          //           color:
          //               index == 0
          //                   ? kPrimaryBlue
          //                   : kNeutralGreyDark.withOpacity(0.3),
          //         ),
          //       );
          //     }),
          //   ),
          // ),
        ],
      ),
    );
  }
}

class _HowToPlayStep extends StatelessWidget {
  const _HowToPlayStep({
    required this.number,
    required this.icon,
    required this.color,
    required this.title,
    required this.description,
    required this.isLast,
  });

  final String number;
  final IconData icon;
  final Color color;
  final String title;
  final String description;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280, // Largeur fixe pour chaque étape
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: kNeutralWhite,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: kPrimaryBlue.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête avec numéro et icône
          Row(
            children: [
              // Badge numéroté
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                child: Center(
                  child: Text(
                    number,
                    style: const TextStyle(
                      color: kNeutralWhite,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Icône
              Container(
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: _getLightColor(color),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 20.0, color: color),
              ),
              const Spacer(),
              // Flèche de progression (sauf pour la dernière étape)
              if (!isLast)
                Icon(
                  LucideIcons.arrowRight,
                  color: kNeutralGreyDark.withOpacity(0.5),
                  size: 20,
                ),
            ],
          ),
          const SizedBox(height: 16.0),
          // Titre
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: kPrimaryBlueDark,
            ),
          ),
          const SizedBox(height: 8.0),
          // Description
          Text(
            description,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: kNeutralGreyDark,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16.0),
          // Barre de progression colorée
          Container(
            height: 4,
            decoration: BoxDecoration(
              color: kNeutralGrey,
              borderRadius: BorderRadius.circular(2),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: _getProgressFactor(int.parse(number)),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color, _darkenColor(color, 0.2)],
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getLightColor(Color baseColor) {
    if (baseColor == kPrimaryBlue) return kPrimaryBlueLight;
    if (baseColor == kSuccessGreen) return kSuccessGreenLight;
    if (baseColor == kWarningOrange) return kWarningOrangeLight;
    return kAccentPurpleLight;
  }

  double _getProgressFactor(int stepNumber) {
    switch (stepNumber) {
      case 1:
        return 0.25;
      case 2:
        return 0.5;
      case 3:
        return 0.75;
      case 4:
        return 1.0;
      default:
        return 0.25;
    }
  }

  Color _darkenColor(Color color, [double amount = 0.1]) {
    assert(amount >= 0 && amount <= 1);

    final hsl = HSLColor.fromColor(color);
    final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));

    return hslDark.toColor();
  }
}
