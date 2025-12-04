import 'package:flutter/material.dart';

/// Color constants for the commercial interface
class CommercialColors {
  // Private constructor to prevent instantiation
  CommercialColors._();

  // Primary colors
  static const Color primaryOrange = Color(0xFFFF6B35);
  static const Color primaryAmber = Color(0xFFF7931E);
  static const Color accentYellow = Color(0xFFFFC300);
  static const Color lightYellow = Color(0xFFFFD60A);

  // Gradients
  static const LinearGradient orangeGradient = LinearGradient(
    colors: [primaryOrange, primaryAmber],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient yellowGradient = LinearGradient(
    colors: [primaryAmber, accentYellow],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient amberGradient = LinearGradient(
    colors: [Color(0xFFF59E0B), Color(0xFFFBBF24)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Background colors
  static const Color backgroundLight = Color(0xFFFFFBF0);
  static const Color cardBackground = Colors.white;

  // Text colors
  static const Color textPrimary = Color(0xFF1F2937);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textLight = Color(0xFF9CA3AF);

  // Border colors
  static const Color borderOrange = Color(0xFFFED7AA);
  static const Color borderYellow = Color(0xFFFDE68A);

  // Status colors
  static const Color success = Color(0xFF10B981);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF3B82F6);
}
