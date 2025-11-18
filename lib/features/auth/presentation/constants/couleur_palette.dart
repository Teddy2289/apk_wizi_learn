import 'package:flutter/material.dart';

class AppColors {
  // Brand colors (keep in sync with web Tailwind variables)
  static const Color primary = Color(0xFFFEB823); // brand primary (Wizi)
  static const Color primaryAccent = Color(0xFFFFE082);
  static const Color primaryDark = Color(0xFFFE9E00);
  static const Color primaryLight = Color(0xFFFFD166);

  static const Color secondary = Color(0xFF2B2D42);
  static const Color accent = Color(0xFFEF233C);

  // Surface & background
  static const Color background = Color(0xFFF8F9FA);
  static const Color surface = Color(0xFFFFFFFF);

  // Semantic
  static const Color success = Color(0xFF10B981);
  static const Color error = Color(0xFFD32F2F);

  // Category colors (web uses --cat-ia / Tailwind `ia`)
  static const Color ia = Color(0xFFABDA96); // IA category color
  static const Color iaLight = Color(0xFFF0F9ED);
  static const Color iaDark = Color(0xFF7BBF5E);

  // Category colors to align with web tokens (--cat-*)
  static const Color catBureautique = Color(0xFF3D9BE9);
  static const Color catBureautiqueLight = Color(0xFFE8F4FE);
  static const Color catBureautiqueDark = Color(0xFF2A7BC8);

  static const Color catLangues = Color(0xFFA55E6E);

  static const Color catInternet = Color(0xFFFEB823);
  static const Color catInternetLight = Color(0xFFFFF8E8);
  static const Color catInternetDark = Color(0xFFE6A400);

  static const Color catCreation = Color(0xFF9392BE);
  static const Color catCreationLight = Color(0xFFF5F4FF);
  static const Color catCreationDark = Color(0xFF6A6896);

  // On colors
  static const Color onPrimary = Color(0xFF000000);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color onBackground = Color(0xFF000000);
  static const Color onSurface = Color(0xFF000000);
  static const Color onError = Color(0xFFFFFFFF);
}
