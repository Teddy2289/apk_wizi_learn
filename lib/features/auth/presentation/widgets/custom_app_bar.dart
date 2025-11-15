import 'package:flutter/material.dart';
import 'package:wizi_learn/features/auth/presentation/constants/couleur_palette.dart';
import 'package:cached_network_image/cached_network_image.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final List<Widget>? actions;
  final String? title;
  final Widget? leading;
  final bool centerTitle;
  final Color backgroundColor;
  final Color foregroundColor;
  final double elevation;
  final bool automaticallyImplyLeading;
  final double? titleSpacing;
  final TextStyle? titleStyle;
  final ShapeBorder? shape;
  final double? toolbarHeight;
  final PreferredSizeWidget? bottom;
  final bool showLogo;
  final String? logoAssetPath;
  final double? logoSize;

  const CustomAppBar({
    super.key,
    this.actions,
    this.title,
    this.leading,
    this.centerTitle = false, // IMPORTANT: désactiver le centrage
    this.backgroundColor = AppColors.primary,
    this.foregroundColor = Colors.black87,
    this.elevation = 2,
    this.automaticallyImplyLeading = true,
    this.titleSpacing,
    this.titleStyle,
    this.shape,
    this.toolbarHeight,
    this.bottom,
    this.showLogo = true,
    this.logoAssetPath = 'assets/images/logons.png',
    this.logoSize,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSmallScreen = MediaQuery.of(context).size.width < 600;
    final isTablet = MediaQuery.of(context).size.width > 600;

    return AppBar(
      elevation: elevation,
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      centerTitle: centerTitle, // Désactivé pour contrôler la position
      automaticallyImplyLeading: automaticallyImplyLeading,
      titleSpacing: titleSpacing ?? NavigationToolbar.kMiddleSpacing,
      shape:
          shape ??
          const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
          ),
      toolbarHeight:
          toolbarHeight ??
          (isSmallScreen ? kToolbarHeight * 1.1 : kToolbarHeight * 1.2),
      leading: leading,
      // TITLE personnalisé avec logo à GAUCHE et titre
      title: _buildCustomTitle(context, isSmallScreen, isTablet),
      iconTheme: IconThemeData(
        color: foregroundColor,
        size: isSmallScreen ? 24 : 28,
      ),
      // Actions (notifications/points) à DROITE
      actions:
          actions?.map((action) {
            return Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isSmallScreen ? 6.0 : 10.0,
              ),
              child: action,
            );
          }).toList(),
      bottom: bottom,
    );
  }

  Widget _buildCustomTitle(
    BuildContext context,
    bool isSmallScreen,
    bool isTablet,
  ) {
    if (!showLogo && title == null) return const SizedBox.shrink();

    return Row(
      mainAxisAlignment: MainAxisAlignment.start, // Alignement à gauche
      children: [
        // LOGO à GAUCHE
        if (showLogo) _buildLogoImage(isSmallScreen, isTablet),

        // Espacement entre logo et titre
        if (showLogo && title != null) SizedBox(width: isSmallScreen ? 12 : 16),

        // TITRE à droite du logo
        if (title != null)
          Flexible(
            child: Text(
              title!,
              style:
                  titleStyle ??
                  TextStyle(
                    color: foregroundColor,
                    fontWeight: FontWeight.w700,
                    fontSize: isSmallScreen ? 18 : (isTablet ? 22 : 20),
                    letterSpacing: 0.3,
                  ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
    );
  }

  Widget _buildLogoImage(bool isSmallScreen, bool isTablet) {
    final size = logoSize ?? (isSmallScreen ? 70.0 : (isTablet ? 70.0 : 70.0));

    return Image.asset(
      logoAssetPath!,
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        return _buildPlaceholderLogo(size);
      },
    );
  }

  Widget _buildPlaceholderLogo(double size) {
    return Icon(Icons.school_rounded, size: size * 0.7, color: foregroundColor);
  }

  @override
  Size get preferredSize => Size.fromHeight(
    toolbarHeight ?? kToolbarHeight + (bottom?.preferredSize.height ?? 0),
  );
}
