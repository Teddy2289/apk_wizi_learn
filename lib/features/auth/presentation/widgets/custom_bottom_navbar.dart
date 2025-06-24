import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:wizi_learn/features/auth/presentation/constants/bar_clipper.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final Color backgroundColor;
  final Color selectedColor;
  final Color unselectedColor;

  const CustomBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.backgroundColor,
    required this.selectedColor,
    required this.unselectedColor,
  });

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final isVerySmallScreen = mediaQuery.size.width < 340;
    final isSmallScreen = mediaQuery.size.width < 400;
    final safeAreaBottom = mediaQuery.padding.bottom;

    final navBarHeight = isVerySmallScreen
        ? 60.0 + safeAreaBottom
        : isSmallScreen
        ? 70.0 + safeAreaBottom
        : 80.0 + safeAreaBottom;

    final iconSize = isVerySmallScreen ? 18.0 : isSmallScreen ? 20.0 : 24.0;
    final labelFontSize = isVerySmallScreen ? 7.0 : isSmallScreen ? 9.0 : 12.0;
    final fabSize = isVerySmallScreen ? 50.0 : isSmallScreen ? 60.0 : 70.0;
    final fabIconSize = isVerySmallScreen ? 18.0 : isSmallScreen ? 24.0 : 32.0;
    final itemPadding = isVerySmallScreen ? 4.0 : isSmallScreen ? 6.0 : 8.0;

    return SizedBox(
      height: navBarHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Fond avec encoche au centre
          ClipPath(
            clipper: BottomNavBarClipper(),
            child: Container(
              height: navBarHeight,
              decoration: BoxDecoration(
                color: backgroundColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 20,
                    spreadRadius: 0,
                    offset: Offset(0, -5),
                  ),
                ],
              ),
            ),
          ),

          // Bouton central flottant
            Positioned(
            left: mediaQuery.size.width / 2 - fabSize / 2,
            top: -fabSize * 0.15, // Redescendu un peu
            child: GestureDetector(
              onTap: () => onTap(2),
              child: Container(
              height: fabSize,
              width: fabSize,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                colors: [Color(0xFFFFA800), Color(0xFFFFD700)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                BoxShadow(
                  color: selectedColor.withOpacity(0.3),
                  blurRadius: 15,
                  spreadRadius: 2,
                  offset: Offset(0, 5),
                ),
                ],
                border: Border.all(
                color: Colors.white,
                width: 3,
                ),
              ),
              child: Icon(
                LucideIcons.brain,
                size: isVerySmallScreen ? 22.0 : isSmallScreen ? 26.0 : 33.0,
                color: Colors.white,
              ),
              ),
            ),
            ),

          // Contenu de la barre (icônes)
          Padding(
            padding: EdgeInsets.only(
              left: 12,
              right: 12,
              top: 8,
              bottom: 8 + safeAreaBottom,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildNavItem(
                  context,
                  icon: LucideIcons.home,
                  label: "Accueil",
                  index: 0,
                  isVerySmallScreen: isVerySmallScreen,
                  isSmallScreen: isSmallScreen,
                  iconSize: iconSize,
                  fontSize: labelFontSize,
                  padding: itemPadding,
                ),
                _buildNavItem(
                  context,
                  icon: LucideIcons.bookOpen,
                  label: "Formation",
                  index: 1,
                  isVerySmallScreen: isVerySmallScreen,
                  isSmallScreen: isSmallScreen,
                  iconSize: iconSize,
                  fontSize: labelFontSize,
                  padding: itemPadding,
                ),
                SizedBox(width: fabSize * 0.7), // Espace central
                _buildNavItem(
                  context,
                  icon: LucideIcons.trophy,
                  label: "Classement",
                  index: 3,
                  isVerySmallScreen: isVerySmallScreen,
                  isSmallScreen: isSmallScreen,
                  iconSize: iconSize,
                  fontSize: labelFontSize,
                  padding: itemPadding,
                ),
                _buildNavItem(
                  context,
                  icon: LucideIcons.video,
                  label: "Tutoriel",
                  index: 4,
                  isVerySmallScreen: isVerySmallScreen,
                  isSmallScreen: isSmallScreen,
                  iconSize: iconSize,
                  fontSize: labelFontSize,
                  padding: itemPadding,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
      BuildContext context, {
        required IconData icon,
        required String label,
        required int index,
        required bool isVerySmallScreen,
        required bool isSmallScreen,
        required double iconSize,
        required double fontSize,
        required double padding,
      }) {
    final isActive = index == currentIndex;
    final theme = Theme.of(context);

    return Flexible(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => onTap(index),
          child: Container(
            padding: EdgeInsets.all(padding),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: iconSize,
                  color: isActive ? selectedColor : unselectedColor,
                ),
                SizedBox(height: isVerySmallScreen ? 2 : 4),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontSize: fontSize,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                    color: isActive ? selectedColor : unselectedColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
