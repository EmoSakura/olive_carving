import 'package:flutter/material.dart';

class AppColors {
  static const Color background = Color(0xFF111111);
  static const Color surface = Color(0xFF1C1C1C);
  static const Color surfaceSoft = Color(0xFF26221D);
  static const Color accent = Color(0xFFD4AF37);
  static const Color textPrimary = Color(0xFFF2EEE7);
  static const Color textSecondary = Color(0xFFAEA79B);
  static const Color ink = Color(0xFF3E2F23);
}

extension ColorAlphaX on Color {
  Color withAlphaValue(double value) => withValues(alpha: value);
}
