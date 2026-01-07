import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:wizi_learn/features/auth/presentation/constants/bar_clipper.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final Color backgroundColor;
  final Color selectedColor;
  final Color unselectedColor;
  final bool isLandscape;

  const CustomBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.backgroundColor,
    required this.selectedColor,
    required this.unselectedColor,
    this.isLandscape = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mediaQuery = MediaQuery.of(context);
    final safeAreaBottom = mediaQuery.padding.bottom;

    // Détection tablette basée sur la taille d'écran
    final bool isTablet = mediaQuery.size.shortestSide >= 600;
    final bool isCompact = mediaQuery.size.width < 600;

    // Valeurs responsive adaptées pour tablette
    final double fabSize = _getFabSize(isTablet, isLandscape, isCompact);
    final double iconSize = _getIconSize(isTablet, isLandscape, isCompact);
    final double labelFontSize = _getLabelFontSize(isTablet, isLandscape, isCompact);
    final double navBarHeight = _getNavBarHeight(isTablet, isLandscape, isCompact, safeAreaBottom);
    final double fabIconSize = _getFabIconSize(isTablet, isLandscape, isCompact);

    return SizedBox(
      height: navBarHeight,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          // Fond avec effet de verre
          _buildGlassBackground(theme, navBarHeight, isLandscape, isTablet),

          // Effet de lumière derrière le FAB
          if (!isLandscape) _buildFabGlow(fabSize, isTablet),

          // Bouton central FAB
          Positioned(
            top: _getFabPosition(isTablet, isLandscape, fabSize),
            child: _buildQuizFab(fabSize, fabIconSize, isLandscape, isTablet),
          ),

          // Items de navigation
          _buildNavItems(
            theme,
            navBarHeight,
            fabSize,
            iconSize,
            labelFontSize,
            safeAreaBottom,
            isLandscape,
            isTablet,
          ),
        ],
      ),
    );
  }

  // Méthodes pour calculer les dimensions responsive
  double _getFabSize(bool isTablet, bool isLandscape, bool isCompact) {
    if (isTablet) {
      return isLandscape ? 60.0 : 70.0; // Taille réduite sur tablette
    }
    return isLandscape ? (isCompact ? 56.0 : 64.0) : (isCompact ? 68.0 : 80.0);
  }

  double _getIconSize(bool isTablet, bool isLandscape, bool isCompact) {
    if (isTablet) {
      return isLandscape ? 22.0 : 24.0; // Icônes légèrement plus grandes sur tablette
    }
    return isLandscape ? (isCompact ? 18.0 : 20.0) : (isCompact ? 22.0 : 26.0);
  }

  double _getLabelFontSize(bool isTablet, bool isLandscape, bool isCompact) {
    if (isTablet) {
      return isLandscape ? 10.0 : 11.0; // Texte plus lisible sur tablette
    }
    return isLandscape ? (isCompact ? 8.0 : 9.0) : (isCompact ? 10.0 : 12.0);
  }

  double _getNavBarHeight(bool isTablet, bool isLandscape, bool isCompact, double safeAreaBottom) {
    if (isTablet) {
      return (isLandscape ? 65.0 : 75.0) + safeAreaBottom; // Barre plus compacte
    }
    return (isLandscape ? (isCompact ? 60.0 : 70.0) : (isCompact ? 75.0 : 85.0)) + safeAreaBottom;
  }

  double _getFabIconSize(bool isTablet, bool isLandscape, bool isCompact) {
    if (isTablet) {
      return isLandscape ? 26.0 : 28.0; // Icône FAB adaptée tablette
    }
    return isLandscape ? (isCompact ? 24.0 : 28.0) : (isCompact ? 30.0 : 38.0);
  }

  double _getFabPosition(bool isTablet, bool isLandscape, double fabSize) {
    if (isTablet) {
      return isLandscape ? -fabSize * 0.2 : -fabSize * 0.3; // Position plus compacte
    }
    return isLandscape ? -fabSize * 0.25 : -fabSize * 0.35;
  }

  Widget _buildNavItems(
      ThemeData theme,
      double navBarHeight,
      double fabSize,
      double iconSize,
      double labelFontSize,
      double safeAreaBottom,
      bool isLandscape,
      bool isTablet,
      ) {
    final double fabSpace = _getFabSpace(isTablet, isLandscape, fabSize);

    final navItems = [
      _buildNavItem(
        icon: LucideIcons.home,
        label: "Accueil",
        index: 0,
        iconSize: iconSize,
        labelFontSize: labelFontSize,
        isLandscape: isLandscape,
        isTablet: isTablet,
      ),
      _buildNavItem(
        icon: LucideIcons.bookOpen,
        label: "Formation",
        index: 1,
        iconSize: iconSize,
        labelFontSize: labelFontSize,
        isLandscape: isLandscape,
        isTablet: isTablet,
      ),
      SizedBox(width: fabSpace),
      _buildNavItem(
        icon: LucideIcons.trophy,
        label: "Classement",
        index: 3,
        iconSize: iconSize,
        labelFontSize: labelFontSize,
        isLandscape: isLandscape,
        isTablet: isTablet,
      ),
      _buildNavItem(
        icon: LucideIcons.video,
        label: _getTutorialLabel(isTablet, isLandscape),
        index: 4,
        iconSize: iconSize,
        labelFontSize: labelFontSize,
        isLandscape: isLandscape,
        isTablet: isTablet,
      ),
    ];

    return Padding(
      padding: _getNavPadding(isTablet, isLandscape, safeAreaBottom),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: navItems,
      ),
    );
  }

  double _getFabSpace(bool isTablet, bool isLandscape, double fabSize) {
    if (isTablet) {
      return isLandscape ? fabSize * 0.7 : fabSize * 1.1; // Espace optimisé tablette
    }
    return isLandscape ? fabSize * 0.8 : fabSize * 1.3;
  }

  String _getTutorialLabel(bool isTablet, bool isLandscape) {
    if (isTablet) {
      return isLandscape ? "Tuto" : "Tutoriel";
    }
    return isLandscape ? "Tuto" : "Tutoriel";
  }

  EdgeInsets _getNavPadding(bool isTablet, bool isLandscape, double safeAreaBottom) {
    if (isTablet) {
      return EdgeInsets.only(
        left: isLandscape ? 16 : 24,
        right: isLandscape ? 16 : 24,
        bottom: safeAreaBottom + (isLandscape ? 4 : 6),
      );
    }
    return EdgeInsets.only(
      left: isLandscape ? 12 : 20,
      right: isLandscape ? 12 : 20,
      bottom: safeAreaBottom + (isLandscape ? 2 : 4),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
    required double iconSize,
    required double labelFontSize,
    required bool isLandscape,
    required bool isTablet,
  }) {
    final isActive = index == currentIndex;

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (index != currentIndex) {
              onTap(index);
            }
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            margin: _getNavItemMargin(isTablet, isLandscape),
            padding: _getNavItemPadding(isTablet, isLandscape),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: isActive ? selectedColor.withOpacity(0.1) : Colors.transparent,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icone
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: _getIconPadding(isTablet, isLandscape),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isActive ? selectedColor.withOpacity(0.15) : Colors.transparent,
                  ),
                  child: Icon(
                    icon,
                    size: iconSize,
                    color: isActive ? selectedColor : unselectedColor.withOpacity(0.7),
                  ),
                ),
                SizedBox(height: _getLabelSpacing(isTablet, isLandscape)),
                // Label
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 300),
                  style: TextStyle(
                    fontSize: labelFontSize,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                    color: isActive ? selectedColor : unselectedColor.withOpacity(0.8),
                    letterSpacing: isActive ? 0.5 : 0.0,
                  ),
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  EdgeInsets _getNavItemMargin(bool isTablet, bool isLandscape) {
    if (isTablet) {
      return EdgeInsets.symmetric(horizontal: isLandscape ? 4 : 6);
    }
    return EdgeInsets.symmetric(horizontal: isLandscape ? 2 : 4);
  }

  EdgeInsets _getNavItemPadding(bool isTablet, bool isLandscape) {
    if (isTablet) {
      return EdgeInsets.symmetric(
        vertical: isLandscape ? 8 : 10,
        horizontal: isLandscape ? 4 : 6,
      );
    }
    return EdgeInsets.symmetric(
      vertical: isLandscape ? 6 : 8,
      horizontal: isLandscape ? 2 : 4,
    );
  }

  EdgeInsets _getIconPadding(bool isTablet, bool isLandscape) {
    if (isTablet) {
      return EdgeInsets.all(isLandscape ? 6 : 8);
    }
    return EdgeInsets.all(isLandscape ? 4 : 6);
  }

  double _getLabelSpacing(bool isTablet, bool isLandscape) {
    if (isTablet) {
      return isLandscape ? 3 : 5;
    }
    return isLandscape ? 2 : 4;
  }

  Widget _buildGlassBackground(
      ThemeData theme,
      double navBarHeight,
      bool isLandscape,
      bool isTablet,
      ) {
    return ClipPath(
      clipper: BottomNavBarClipper(),
      child: Container(
        height: navBarHeight,
        decoration: BoxDecoration(
          color: theme.cardColor.withOpacity(
            isTablet ? 0.98 : (isLandscape ? 0.98 : 0.95),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isTablet ? 0.08 : (isLandscape ? 0.1 : 0.15)),
              blurRadius: isTablet ? 12 : (isLandscape ? 15 : 20),
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: (isTablet || isLandscape)
            ? Container()
            : BackdropFilter(
          filter: ColorFilter.mode(
            Colors.white.withOpacity(0.1),
            BlendMode.srcOver,
          ),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  theme.cardColor.withOpacity(0.8),
                  theme.cardColor.withOpacity(0.95),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFabGlow(double fabSize, bool isTablet) {
    return Positioned(
      top: -fabSize * (isTablet ? 0.15 : 0.2),
      child: Container(
        width: fabSize * (isTablet ? 1.3 : 1.4),
        height: fabSize * (isTablet ? 1.3 : 1.4),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              selectedColor.withOpacity(isTablet ? 0.2 : 0.3),
              selectedColor.withOpacity(isTablet ? 0.08 : 0.1),
              Colors.transparent,
            ],
            stops: const [0.1, 0.5, 1.0],
          ),
        ),
      ),
    );
  }

  Widget _buildQuizFab(double size, double iconSize, bool isLandscape, bool isTablet) {
    final isQuizActive = currentIndex == 2;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: isQuizActive
              ? [selectedColor, selectedColor.withOpacity(0.8)]
              : [const Color(0xFF667eea), const Color(0xFF764ba2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: (isQuizActive ? selectedColor : const Color(0xFF667eea))
                .withOpacity(isTablet ? 0.2 : (isLandscape ? 0.3 : 0.5)),
            blurRadius: isTablet ? 12 : (isLandscape ? 15 : 25),
            spreadRadius: isTablet ? 1 : (isLandscape ? 1 : 3),
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(isTablet ? 0.08 : (isLandscape ? 0.1 : 0.15)),
            blurRadius: isTablet ? 4 : (isLandscape ? 6 : 10),
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: Colors.white.withOpacity(isTablet ? 0.15 : (isLandscape ? 0.2 : 0.3)),
          width: isTablet ? 1.5 : (isLandscape ? 1 : 2),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onTap(2),
          customBorder: const CircleBorder(),
          splashColor: Colors.white.withOpacity(0.3),
          highlightColor: Colors.white.withOpacity(0.2),
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (isQuizActive && !isLandscape && !isTablet) _buildPulseAnimation(size),
              _buildQuizIcon(iconSize, isQuizActive, isLandscape, isTablet),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuizIcon(double iconSize, bool isActive, bool isLandscape, bool isTablet) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      transform: Matrix4.identity()..scale(isActive && !isLandscape && !isTablet ? 1.1 : 1.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: _getQuizIconPadding(isTablet, isLandscape),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(isTablet ? 0.12 : (isLandscape ? 0.15 : 0.2)),
            ),
            child: Icon(
              Icons.quiz_rounded,
              size: iconSize * _getQuizIconScale(isTablet, isLandscape),
              color: Colors.white,
            ),
          ),
          if (!isLandscape)
            SizedBox(height: isTablet ? 3 : 2),
          if (!isLandscape)
            Text(
              'Quiz',
              style: TextStyle(
                color: Colors.white,
                fontSize: iconSize * _getQuizTextScale(isTablet, isLandscape),
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
        ],
      ),
    );
  }

  EdgeInsets _getQuizIconPadding(bool isTablet, bool isLandscape) {
    if (isTablet) {
      return EdgeInsets.all(isLandscape ? 4 : 5);
    }
    return EdgeInsets.all(isLandscape ? 3 : 4);
  }

  double _getQuizIconScale(bool isTablet, bool isLandscape) {
    if (isTablet) {
      return isLandscape ? 0.65 : 0.75;
    }
    return isLandscape ? 0.7 : 0.8;
  }

  double _getQuizTextScale(bool isTablet, bool isLandscape) {
    if (isTablet) {
      return isLandscape ? 0.18 : 0.25;
    }
    return isLandscape ? 0.2 : 0.3;
  }

  Widget _buildPulseAnimation(double size) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 2000),
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selectedColor.withOpacity(0.3),
      ),
      child: const SizedBox(),
    );
  }
}