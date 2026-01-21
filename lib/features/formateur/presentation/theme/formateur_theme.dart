import 'package:flutter/material.dart';

class FormateurTheme {
  // Main Backgrounds
  static const Color background = Color(0xFFFDFCFB); // Off-white warm
  static const Color cardBackground = Colors.white;
  
  // Text Colors
  static const Color textPrimary = Color(0xFF0F172A); // Slate 900
  static const Color textSecondary = Color(0xFF64748B); // Slate 500
  static const Color textTertiary = Color(0xFF94A3B8); // Slate 400
  
  // Accents (Yellow/Orange)
  static const Color accent = Color(0xFFEAB308); // Yellow 500
  static const Color accentDark = Color(0xFFCA8A04); // Yellow 600
  static const Color accentLight = Color(0xFFFEF08A); // Yellow 200
  static const Color orangeAccent = Color(0xFFF97316); // Orange 500
  
  // Functional Colors
  static const Color success = Color(0xFF22C55E); // Green 500
  static const Color error = Color(0xFFEF4444); // Red 500
  static const Color border = Color(0xFFE2E8F0); // Slate 200
  
  // Shadows
  static List<BoxShadow> cardShadow = [
    BoxShadow(
      color: const Color(0xFF64748B).withOpacity(0.08),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
  ];
  
  static List<BoxShadow> hoverShadow = [
    BoxShadow(
      color: const Color(0xFFEAB308).withOpacity(0.15),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
  ];

  // Gradients
  static const LinearGradient premiumGradient = LinearGradient(
    colors: [accentDark, accent],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient textGradient = LinearGradient(
    colors: [accentDark, Color(0xFFFACC15)], // Yellow 600 to 400
  );
}
