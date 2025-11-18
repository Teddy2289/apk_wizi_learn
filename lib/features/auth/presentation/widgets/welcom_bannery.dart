import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:wizi_learn/features/auth/presentation/constants/couleur_palette.dart';

// Local neutral tokens mapped to the shared AppColors palette
const Color kNeutralWhite = AppColors.surface;
const Color kNeutralGrey = AppColors.background;
const Color kNeutralGreyDark = Color(0xFF6C757D);
const Color kNeutralBlack = AppColors.onSurface;

class WelcomeBanner extends StatefulWidget {
  final bool showDismissOption;
  final String variant;

  const WelcomeBanner({
    super.key,
    this.showDismissOption = true,
    this.variant = 'default',
  });

  @override
  State<WelcomeBanner> createState() => _WelcomeBannerState();
}

class _WelcomeBannerState extends State<WelcomeBanner> {
  bool _isVisible = true;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    // Vérifier si l'utilisateur a déjà masqué la bannière
    _checkDismissStatus();
  }

  void _checkDismissStatus() async {
    // Ici vous pouvez implémenter la logique de stockage local
    // Pour l'exemple, on laisse visible par défaut
  }

  void _handleClose() {
    setState(() => _isVisible = false);
    // Stocker la préférence de l'utilisateur
    // localStorage.setItem("welcomeBannerDismissed", "false");
  }

  void _handleDiscover() {
    // Navigation vers la page manuel
    print('User clicked discover platform');
  }

  @override
  Widget build(BuildContext context) {
    if (!_isVisible) return const SizedBox.shrink();

    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 768;
    final isSmallPhone = screenWidth < 375;

    // Version minimaliste
    if (widget.variant == 'minimal') {
      return _buildMinimalVariant();
    }

    // Adaptation automatique selon la taille de l'écran
    if (isSmallPhone) {
      return _buildSmallPhoneVariant();
    } else if (screenWidth < 600) {
      return _buildMobileVariant();
    } else if (isTablet) {
      return _buildTabletVariant();
    } else {
      return _buildDefaultVariant();
    }
  }

  Widget _buildMinimalVariant() {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: kNeutralWhite,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade100),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            if (widget.showDismissOption)
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap: _handleClose,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.close, size: 16, color: kNeutralGreyDark),
                  ),
                ),
              ),
            Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.catInternetLight,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    LucideIcons.megaphone,
                    size: 16,
                    color: AppColors.catInternet,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bienvenue sur Wizi Learn',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: kNeutralBlack,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Votre plateforme d\'apprentissage intelligente',
                        style: TextStyle(fontSize: 12, color: kNeutralGreyDark),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSmallPhoneVariant() {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              kNeutralWhite,
              kNeutralWhite,
              kNeutralWhite,
            ],
          ),
          border: Border.all(color: AppColors.catInternet.withOpacity(0.1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Points décoratifs
            Positioned(
              top: 16,
              right: 80,
              child: _buildAnimatedDot(
                AppColors.catInternet.withOpacity(0.3),
                0,
              ),
            ),
            Positioned(
              bottom: 32,
              left: 64,
              child: _buildAnimatedDot(
                AppColors.catInternet.withOpacity(0.4),
                1000,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // En-tête
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Icône principale
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppColors.catInternet,
                              AppColors.catInternetDark,
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.catInternet.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(
                          LucideIcons.megaphone,
                          color: kNeutralWhite,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Bienvenue sur Wizi Learn',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: kNeutralBlack,
                              ),
                            ),
                            Text(
                              'Votre plateforme d\'apprentissage',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.catInternetDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Description
                  Text(
                    'Wizi Learn est une plateforme d\'apprentissage interactive '
                    'dédiée à la montée en compétences.',
                    style: TextStyle(
                      fontSize: 12,
                      color: kNeutralGreyDark,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Bouton principal
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _handleDiscover,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.catInternet,
                        foregroundColor: kNeutralWhite,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 3,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Découvrir',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(width: 6),
                          Icon(LucideIcons.arrowRight, size: 14),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (widget.showDismissOption)
              Positioned(
                top: 12,
                right: 12,
                child: GestureDetector(
                  onTap: _handleClose,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: kNeutralWhite.withOpacity(0.7),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.close, size: 16, color: kNeutralGreyDark),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileVariant() {
    final features = [
      {
        'icon': LucideIcons.bookOpen,
        'text': 'Formations interactives',
        'color': AppColors.catBureautique,
      },
      {
        'icon': LucideIcons.zap,
        'text': 'Quiz évaluatifs',
        'color': AppColors.ia,
      },
      {
        'icon': LucideIcons.star,
        'text': 'Suivi de progression',
        'color': AppColors.catCreation,
      },
    ];

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              kNeutralWhite,
              kNeutralWhite,
              kNeutralWhite,
            ],
          ),
          border: Border.all(color: AppColors.catInternet.withOpacity(0.1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Fond décoratif
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: RadialGradient(
                    center: Alignment.topLeft,
                    radius: 1.0,
                    colors: [
                      AppColors.catInternet.withOpacity(0.1),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            // Points décoratifs
            Positioned(
              top: 20,
              right: 100,
              child: _buildAnimatedDot(
                AppColors.catInternet.withOpacity(0.3),
                0,
              ),
            ),
            Positioned(
              bottom: 40,
              left: 80,
              child: _buildAnimatedDot(
                AppColors.catInternet.withOpacity(0.4),
                1000,
              ),
            ),
            Positioned(
              top: 60,
              right: 40,
              child: _buildAnimatedDot(
                AppColors.catCreation.withOpacity(0.2),
                2000,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // En-tête
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Icône principale
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppColors.catInternet,
                              AppColors.catInternetDark,
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.catInternet.withOpacity(0.4),
                              blurRadius: 10,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Icon(
                          LucideIcons.megaphone,
                          color: kNeutralWhite,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Bienvenue sur votre espace Wizi Learn',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: kNeutralBlack,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Votre plateforme d\'apprentissage intelligente',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.catInternetDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Description
                  Text(
                    'Wizi Learn est une plateforme d\'apprentissage interactive dédiée '
                    'à la montée en compétences. Découvrez nos formations, testez vos '
                    'connaissances avec nos quiz et progressez à votre rythme.',
                    style: TextStyle(
                      fontSize: 14,
                      color: kNeutralGreyDark,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Fonctionnalités
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children:
                        features.map((feature) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: (feature['color'] as Color).withOpacity(
                                0.1,
                              ),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: (feature['color'] as Color).withOpacity(
                                  0.2,
                                ),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  feature['icon'] as IconData,
                                  size: 14,
                                  color: feature['color'] as Color,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  feature['text'] as String,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: feature['color'] as Color,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                  ),
                  const SizedBox(height: 20),

                  // Boutons d'action
                ],
              ),
            ),
            if (widget.showDismissOption)
              Positioned(
                top: 16,
                right: 16,
                child: GestureDetector(
                  onTap: _handleClose,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: kNeutralWhite.withOpacity(0.7),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.close, size: 18, color: kNeutralGreyDark),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDefaultVariant() {
    return _buildMobileVariant(); // Utilise la version mobile comme défaut
  }

  Widget _buildTabletVariant() {
    final features = [
      {
        'icon': LucideIcons.bookOpen,
        'text': 'Formations interactives',
        'color': AppColors.catBureautique,
      },
      {
        'icon': LucideIcons.zap,
        'text': 'Quiz évaluatifs',
        'color': AppColors.ia,
      },
      {
        'icon': LucideIcons.star,
        'text': 'Suivi de progression',
        'color': AppColors.catCreation,
      },
    ];

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Container(
        margin: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              kNeutralWhite,
              kNeutralWhite,
              kNeutralWhite,
            ],
          ),
          border: Border.all(color: AppColors.catInternet.withOpacity(0.1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Fond décoratif animé
            Positioned.fill(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 700),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: RadialGradient(
                    center: const Alignment(0.3, 0.2),
                    radius: 1.0,
                    colors: [
                      AppColors.catInternet.withOpacity(
                        _isHovered ? 0.15 : 0.1,
                      ),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            // Points décoratifs
            Positioned(
              top: 30,
              right: 160,
              child: _buildAnimatedDot(
                AppColors.catInternet.withOpacity(0.3),
                0,
              ),
            ),
            Positioned(
              bottom: 60,
              left: 120,
              child: _buildAnimatedDot(
                AppColors.catInternet.withOpacity(0.4),
                1000,
              ),
            ),
            Positioned(
              top: 80,
              right: 60,
              child: _buildAnimatedDot(
                AppColors.catCreation.withOpacity(0.2),
                2000,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // En-tête tablette
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Icône principale
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 500),
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppColors.catInternet,
                              AppColors.catInternetDark,
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.catInternet.withOpacity(0.4),
                              blurRadius: 15,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Stack(
                          children: [
                            Icon(
                              LucideIcons.megaphone,
                              color: kNeutralWhite,
                              size: 32,
                            ),
                            // Effet de brillance
                            Positioned.fill(
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 500),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Colors.transparent,
                                      Colors.white.withOpacity(
                                        _isHovered ? 0.4 : 0.2,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 24),
                      // Contenu texte
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Bienvenue sur votre espace Wizi Learn',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: kNeutralBlack,
                                height: 1.1,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Votre plateforme d\'apprentissage intelligente',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: AppColors.catInternetDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Description tablette
                  Text(
                    'Wizi Learn est une plateforme d\'apprentissage interactive dédiée '
                    'à la montée en compétences. Découvrez nos formations, testez vos '
                    'connaissances avec nos quiz et progressez à votre rythme.',
                    style: TextStyle(
                      fontSize: 16,
                      color: kNeutralGreyDark,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Fonctionnalités tablette
                  Row(
                    children:
                        features.map((feature) {
                          return Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: (feature['color'] as Color)
                                      .withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: (feature['color'] as Color)
                                        .withOpacity(0.2),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      feature['icon'] as IconData,
                                      size: 20,
                                      color: feature['color'] as Color,
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      feature['text'] as String,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: feature['color'] as Color,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                  ),
                  const SizedBox(height: 28),

                  // Boutons d'action tablette
                ],
              ),
            ),
            if (widget.showDismissOption)
              Positioned(
                top: 20,
                right: 20,
                child: GestureDetector(
                  onTap: _handleClose,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: kNeutralWhite.withOpacity(0.7),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.close, size: 20, color: kNeutralGreyDark),
                  ),
                ),
              ),
            // Badge "Nouveau" pour la version featured
            if (widget.variant == 'featured')
              Positioned(
                top: -8,
                right: -8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.catInternet,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Nouveau !',
                    style: TextStyle(
                      color: kNeutralWhite,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedDot(Color color, int delay) {
    return TweenAnimationBuilder(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 2000),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        return Opacity(opacity: (value * 0.5 + 0.5) * 0.7, child: child);
      },
      child: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
    );
  }
}
