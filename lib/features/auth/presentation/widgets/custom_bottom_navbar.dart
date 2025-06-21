import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

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
    final size = MediaQuery.of(context).size;
    final width = size.width;
    final height = size.height;
    final isLandscape = width > height;
    // Adaptation fluide avec limites min/max
    double clamp(double value, double min, double max) =>
        value < min ? min : (value > max ? max : value);
    final iconSize = clamp(width * 0.06, 20, 32); // 20-32px
    final labelFontSize = clamp(width * 0.035, 11, 18); // 11-18px
    final navBarHeight =
        isLandscape
            ? clamp(width * 0.13, 48, 70)
            : clamp(width * 0.20, 60, 90); // plus bas en paysage
    final fabSize = clamp(width * 0.16, 44, 80);
    final fabIconSize = clamp(width * 0.08, 22, 40);
    final horizontalPadding = clamp(width * 0.05, 8, 32);
    final navItemPaddingH = clamp(width * 0.03, 6, 18);
    final navItemPaddingV = clamp(width * 0.015, 4, 12);
    final spaceForFab = clamp(width * 0.14, 36, 80);
    final iconTextSpacing = iconSize < 22 ? 2.0 : 4.0;
    final activeElevation = 8.0;

    return Container(
      height: navBarHeight,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(25),
          topRight: Radius.circular(25),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            spreadRadius: 2,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                LucideIcons.home,
                "Accueil",
                0,
                iconSize,
                labelFontSize,
                navItemPaddingH,
                navItemPaddingV,
                iconTextSpacing,
                activeElevation,
              ),
              _buildNavItem(
                LucideIcons.bookOpen,
                "Formation",
                1,
                iconSize,
                labelFontSize,
                navItemPaddingH,
                navItemPaddingV,
                iconTextSpacing,
                activeElevation,
              ),
              SizedBox(width: spaceForFab),
              _buildNavItem(
                LucideIcons.trophy,
                "Classement",
                3,
                iconSize,
                labelFontSize,
                navItemPaddingH,
                navItemPaddingV,
                iconTextSpacing,
                activeElevation,
              ),
              _buildNavItem(
                LucideIcons.video,
                "Tutoriel",
                4,
                iconSize,
                labelFontSize,
                navItemPaddingH,
                navItemPaddingV,
                iconTextSpacing,
                activeElevation,
              ),
            ],
          ),
          Positioned(
            bottom: navBarHeight * 0.19,
            child: GestureDetector(
              onTap: () => onTap(2),
              child: Container(
                height: fabSize,
                width: fabSize,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFA800), Color(0xFFFFD700)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: selectedColor.withOpacity(0.4),
                      blurRadius: 15,
                      spreadRadius: 2,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Icon(
                  LucideIcons.helpCircle,
                  size: fabIconSize,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    IconData icon,
    String label,
    int index,
    double iconSize,
    double labelFontSize,
    double paddingH,
    double paddingV,
    double iconTextSpacing,
    double activeElevation,
  ) {
    final isActive = index == currentIndex;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onTap(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: EdgeInsets.symmetric(horizontal: paddingH, vertical: paddingV),
        decoration: BoxDecoration(
          color:
              isActive ? selectedColor.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          boxShadow:
              isActive
                  ? [
                    BoxShadow(
                      color: selectedColor.withOpacity(0.25),
                      blurRadius: activeElevation,
                      offset: const Offset(0, 2),
                    ),
                  ]
                  : [],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedScale(
              scale: isActive ? 1.18 : 1.0,
              duration: const Duration(milliseconds: 250),
              child: Icon(
                icon,
                color: isActive ? selectedColor : unselectedColor,
                size: iconSize,
              ),
            ),
            SizedBox(height: iconTextSpacing),
            Text(
              label,
              style: TextStyle(
                color: isActive ? selectedColor : unselectedColor,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                fontSize: labelFontSize,
                letterSpacing: 0.1,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
