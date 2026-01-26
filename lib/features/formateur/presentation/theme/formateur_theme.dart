import 'package:flutter/material.dart';
import 'package:wizi_learn/features/auth/presentation/constants/couleur_palette.dart';

class FormateurTheme {
  // Main Backgrounds
  static const Color background = AppColors.background;
  static const Color cardBackground = Colors.white;
  
  // Text Colors
  static const Color textPrimary = Color(0xFF0F172A); // Slate 900
  static const Color textSecondary = Color(0xFF64748B); // Slate 500
  static const Color textTertiary = Color(0xFF94A3B8); // Slate 400
  
  // Accents (Yellow/Orange aligned with Stagiaire)
  static const Color accent = AppColors.primary;
  static const Color accentDark = AppColors.primaryDark;
  static const Color accentLight = AppColors.primaryAccent;
  static const Color orangeAccent = Color(0xFFF97316); 
  
  // Functional Colors
  static const Color success = AppColors.success;
  static const Color error = AppColors.error;
  static const Color border = Color(0xFFF1F5F9); // Slate 100 
  
  // Radius
  static const double radiusXL = 32.0;
  static const double radius2XL = 40.0;
  
  // Shadows
  static List<BoxShadow> cardShadow = [
    BoxShadow(
      color: const Color(0xFF64748B).withOpacity(0.05),
      blurRadius: 20,
      offset: const Offset(0, 4),
    ),
  ];
  
  static List<BoxShadow> premiumShadow = [
    BoxShadow(
      color: const Color(0xFF0F172A).withOpacity(0.03),
      blurRadius: 40,
      offset: const Offset(0, 10),
    ),
  ];

  // Decoration Helpers
  static BoxDecoration headerDecoration = BoxDecoration(
    color: Colors.white,
    border: Border(bottom: BorderSide(color: border)),
  );

  static BoxDecoration premiumCardDecoration = BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(radiusXL),
    boxShadow: cardShadow,
    border: Border.all(color: border),
  );

  // Gradients
  static const LinearGradient premiumGradient = LinearGradient(
    colors: [accentDark, accent],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient textGradient = LinearGradient(
    colors: [accentDark, Color(0xFFFACC15)],
  );

  static const LinearGradient yellowWhiteGradient = LinearGradient(
    colors: [Color(0xFFFACC15), Colors.white],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
