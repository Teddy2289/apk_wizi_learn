import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:wizi_learn/features/auth/presentation/constants/bar_clipper.dart';
import 'package:cached_network_image/cached_network_image.dart';

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
    final double fabSize = isCompact ? 68.0 : 80.0;
    final double iconSize = isCompact ? 22.0 : 26.0;
    final double labelFontSize = isCompact ? 10.0 : 12.0;
    final double navBarHeight = isCompact ? 75.0 : 85.0;
    final double fabIconSize = isCompact ? 30.0 : 38.0;

    return SizedBox(
      height: navBarHeight + safeAreaBottom,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          // Fond avec effet de verre (glassmorphism)
          _buildGlassBackground(theme, navBarHeight),

          // Effet de lumière derrière le FAB
          _buildFabGlow(fabSize),

          // Bouton central FAB
          Positioned(
            top: -fabSize * 0.35,
            child: _buildQuizFab(fabSize, fabIconSize),
          ),

          // Items de navigation
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
      SizedBox(width: fabSize * 1.3), // Espace pour le FAB central
      _buildNavItem(
        icon: LucideIcons.trophy,
        label: "Classement",
        index: 3,
        iconSize: iconSize,
        labelFontSize: labelFontSize,
      ),
      _buildNavItem(
        icon: LucideIcons.video,
        label: "Tutoriel",
        index: 4,
        iconSize: iconSize,
        labelFontSize: labelFontSize,
      ),
    ];

    return Padding(
      padding: EdgeInsets.only(left: 20, right: 20, bottom: safeAreaBottom + 4),
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
            margin: const EdgeInsets.symmetric(horizontal: 4),
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color:
                  isActive
                      ? selectedColor.withOpacity(0.1)
                      : Colors.transparent,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icone avec animation subtile
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color:
                        isActive
                            ? selectedColor.withOpacity(0.15)
                            : Colors.transparent,
                  ),
                  child: Icon(
                    icon,
                    size: iconSize,
                    color:
                        isActive
                            ? selectedColor
                            : unselectedColor.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 4),
                // Label avec animation
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 300),
                  style: TextStyle(
                    fontSize: labelFontSize,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                    color:
                        isActive
                            ? selectedColor
                            : unselectedColor.withOpacity(0.8),
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

  Widget _buildGlassBackground(ThemeData theme, double navBarHeight) {
    return ClipPath(
      clipper: BottomNavBarClipper(),
      child: Container(
        height: navBarHeight,
        decoration: BoxDecoration(
          color: theme.cardColor.withOpacity(0.95),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: BackdropFilter(
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

  Widget _buildFabGlow(double fabSize) {
    return Positioned(
      top: -fabSize * 0.2,
      child: Container(
        width: fabSize * 1.4,
        height: fabSize * 1.4,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              selectedColor.withOpacity(0.3),
              selectedColor.withOpacity(0.1),
              Colors.transparent,
            ],
            stops: const [0.1, 0.5, 1.0],
          ),
        ),
      ),
    );
  }

  Widget _buildQuizFab(double size, double iconSize) {
    final isQuizActive = currentIndex == 2;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors:
              isQuizActive
                  ? [selectedColor, selectedColor.withOpacity(0.8)]
                  : [const Color(0xFF667eea), const Color(0xFF764ba2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color:
                isQuizActive
                    ? selectedColor.withOpacity(0.5)
                    : const Color(0xFF667eea).withOpacity(0.5),
            blurRadius: 25,
            spreadRadius: 3,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
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
              // Effet de pulsation pour le bouton actif
              if (isQuizActive) _buildPulseAnimation(size),

              // Image de l'icône Quiz
              _buildQuizIcon(iconSize, isQuizActive),

              // Badge de notification (optionnel)
              // _buildNotificationBadge(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuizIcon(double iconSize, bool isActive) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      transform: Matrix4.identity()..scale(isActive ? 1.1 : 1.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Option 1: Utiliser une image depuis les assets
          // Image.asset(
          //   'assets/images/quiz_icon.png',
          //   width: iconSize,
          //   height: iconSize,
          //   color: Colors.white,
          // ),

          // Option 2: Utiliser une image réseau (exemple)
          // CachedNetworkImage(
          //   imageUrl: 'https://example.com/quiz-icon.png',
          //   width: iconSize,
          //   height: iconSize,
          //   color: Colors.white,
          //   placeholder: (context, url) => Icon(
          //     Icons.quiz_rounded,
          //     size: iconSize,
          //     color: Colors.white,
          //   ),
          // ),

          // Option 3: Icone personnalisé avec effet (fallback)
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.2),
            ),
            child: Icon(
              Icons.quiz_rounded,
              size: iconSize * 0.8,
              color: Colors.white,
            ),
          ),

          const SizedBox(height: 2),
          Text(
            'Quiz',
            style: TextStyle(
              color: Colors.white,
              fontSize: iconSize * 0.3,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
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

  Widget _buildNotificationBadge() {
    // Exemple de badge de notification (à personnaliser selon vos besoins)
    return Positioned(
      top: 8,
      right: 8,
      child: Container(
        width: 16,
        height: 16,
        decoration: BoxDecoration(
          color: const Color(0xFFFF4757),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
        ),
        child: const Center(
          child: Text(
            '3',
            style: TextStyle(
              color: Colors.white,
              fontSize: 8,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}

// Version alternative avec un design plus minimaliste
class ModernBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final Color selectedColor;

  const ModernBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.selectedColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80 + MediaQuery.of(context).padding.bottom,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
        child: Row(
          children: [
            _buildNavItem(Icons.home_rounded, 'Accueil', 0),
            _buildNavItem(Icons.school_rounded, 'Formation', 1),
            _buildQuizItem(),
            _buildNavItem(Icons.leaderboard_rounded, 'Classement', 3),
            _buildNavItem(Icons.video_library_rounded, 'Tutoriel', 4),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isActive = index == currentIndex;

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onTap(index),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isActive ? selectedColor : Colors.grey,
                size: 24,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isActive ? selectedColor : Colors.grey,
                  fontSize: 10,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuizItem() {
    final isActive = 2 == currentIndex;

    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors:
                    isActive
                        ? [selectedColor, selectedColor.withOpacity(0.8)]
                        : [const Color(0xFF667eea), const Color(0xFF764ba2)],
              ),
              boxShadow: [
                BoxShadow(
                  color: (isActive ? selectedColor : const Color(0xFF667eea))
                      .withOpacity(0.3),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Icon(Icons.quiz_rounded, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 4),
          Text(
            'Quiz',
            style: TextStyle(
              color: isActive ? selectedColor : Colors.grey,
              fontSize: 10,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
