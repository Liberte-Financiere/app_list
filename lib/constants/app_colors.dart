import 'package:flutter/material.dart';

/// Palette de couleurs sémantiques et thématiques de l'application.
abstract final class AppColors {
  // Couleurs de marque et d'accent
  static const Color primary = Color(0xFF0D9488); // Teal profond
  static const Color primaryLight = Color(0xFF14B8A6);
  static const Color primaryDark = Color(0xFF0F766E);
  static const Color secondary = Color(0xFF3B82F6); // Bleu moderne
  static const Color accent = Color(0xFFF59E0B); // Ambre

  // Couleurs de fond et surfaces (Mode clair)
  static const Color backgroundLight = Color(0xFFF8FAFC);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color cardBorderLight = Color(0xFFE2E8F0);

  // Couleurs de fond et surfaces (Mode sombre)
  static const Color backgroundDark = Color(0xFF0F172A);
  static const Color surfaceDark = Color(0xFF1E293B);
  static const Color cardBorderDark = Color(0xFF334155);

  // Typographie et textes
  static const Color textPrimaryLight = Color(0xFF0F172A);
  static const Color textSecondaryLight = Color(0xFF64748B);
  static const Color textPrimaryDark = Color(0xFFF8FAFC);
  static const Color textSecondaryDark = Color(0xFF94A3B8);

  // États et retours visuels
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);

  // Badges spécifiques aux applications
  static const Color systemBadgeBg = Color(0xFFFEF3C7);
  static const Color systemBadgeText = Color(0xFFD97706);
  static const Color userBadgeBg = Color(0xFFE0E7FF);
  static const Color userBadgeText = Color(0xFF4338CA);
}
