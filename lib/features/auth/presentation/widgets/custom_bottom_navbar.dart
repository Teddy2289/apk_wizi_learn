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
    final theme = Theme.of(context);
    final mediaQuery = MediaQuery.of(context);
    final safeAreaBottom = mediaQuery.padding.bottom;
    final isCompact = mediaQuery.size.width < 600;

    // Responsive values
    final double fabSize = isCompact ? 60.0 : 72.0;
    final double iconSize = isCompact ? 22.0 : 26.0;
    final double labelFontSize = isCompact ? 10.0 : 12.0;
    final double navBarHeight = isCompact ? 70.0 : 80.0;
    final double fabIconSize = isCompact ? 28.0 : 36.0;

    return SizedBox(
      height: navBarHeight + safeAreaBottom,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          _buildBackground(theme, navBarHeight),
          Positioned(
            top: -fabSize * 0.4,
            child: _buildFab(fabSize, fabIconSize),
          ),
          _buildNavItems(
            theme,
            navBarHeight,
            fabSize,
            iconSize,
            labelFontSize,
            safeAreaBottom,
          ),
        ],
      ),
    );
  }

  Widget _buildNavItems(
    ThemeData theme,
    double navBarHeight,
    double fabSize,
    double iconSize,
    double labelFontSize,
    double safeAreaBottom,
  ) {
    final navItems = [
      _buildNavItem(
        icon: LucideIcons.home,
        label: "Accueil",
        index: 0,
        iconSize: iconSize,
        labelFontSize: labelFontSize,
      ),
      _buildNavItem(
        icon: LucideIcons.bookOpen,
        label: "Formation",
        index: 1,
        iconSize: iconSize,
        labelFontSize: labelFontSize,
      ),
      SizedBox(width: fabSize * 1.2),
      _buildNavItem(
        icon: LucideIcons.trophy,
        label: "Classement",
        index: 3,
        iconSize: iconSize,
        labelFontSize: labelFontSize,
      ),
      // _buildNavItem(
      //   icon: LucideIcons.mail,
      //   label: "Contact",
      //   index: 5,
      //   iconSize: iconSize,
      //   labelFontSize: labelFontSize,
      // ),
      _buildNavItem(
        icon: LucideIcons.video,
        label: "Tutoriel",
        index: 4,
        iconSize: iconSize,
        labelFontSize: labelFontSize,
      ),
    ];

    return Padding(
      padding: EdgeInsets.only(left: 16, right: 16, bottom: safeAreaBottom),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: navItems,
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
    required double iconSize,
    required double labelFontSize,
  }) {
    final isActive = index == currentIndex;

    return Expanded(
      child: InkWell(
        onTap: () {
          if (index != currentIndex) {
            onTap(index); // Appelle le callback de sélection
          }
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: iconSize,
                color: isActive ? selectedColor : unselectedColor,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: labelFontSize,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  color: isActive ? selectedColor : unselectedColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBackground(ThemeData theme, double navBarHeight) {
    return ClipPath(
      clipper: BottomNavBarClipper(),
      child: Container(
        height: navBarHeight,
        decoration: BoxDecoration(
          color: theme.cardColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 15,
              offset: const Offset(0, -2),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFab(double size, double iconSize) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [selectedColor.withOpacity(0.8), selectedColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: selectedColor.withOpacity(0.4),
            blurRadius: 20,
            spreadRadius: 2,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onTap(2),
          customBorder: const CircleBorder(),
          child: Icon(LucideIcons.brain, size: iconSize, color: Colors.white),
        ),
      ),
    );
  }
}
