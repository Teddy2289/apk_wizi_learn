import 'package:flutter/material.dart';
import 'package:wizi_learn/features/auth/presentation/constants/couleur_palette.dart';

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

  const CustomAppBar({
    super.key,
    this.actions,
    this.title,
    this.leading,
    this.centerTitle = true,
    this.backgroundColor = AppColors.primary,
    this.foregroundColor = Colors.black87,
    this.elevation = 1,
    this.automaticallyImplyLeading = true,
    this.titleSpacing,
    this.titleStyle,
    this.shape,
    this.toolbarHeight,
    this.bottom,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSmallScreen = MediaQuery.of(context).size.width < 600;

    return AppBar(
      elevation: elevation,
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      centerTitle: centerTitle,
      automaticallyImplyLeading: automaticallyImplyLeading,
      titleSpacing: titleSpacing,
      shape: shape ?? const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(10),
        ),
      ),
      toolbarHeight: toolbarHeight ?? (isSmallScreen ? kToolbarHeight : kToolbarHeight * 1.1),
      leading: leading,
      title: title != null
          ? Text(
        title!,
        style: titleStyle ?? TextStyle(
          color: foregroundColor,
          fontWeight: FontWeight.w600,
          fontSize: isSmallScreen ? 18 : 20,
          letterSpacing: 0.5,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      )
          : null,
      iconTheme: IconThemeData(
        color: foregroundColor,
        size: isSmallScreen ? 24 : 28,
      ),
      actions: actions?.map((action) {
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 8.0 : 12.0),
          child: action,
        );
      }).toList(),
      bottom: bottom,
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(
    toolbarHeight ?? kToolbarHeight + (bottom?.preferredSize.height ?? 0),
  );
}