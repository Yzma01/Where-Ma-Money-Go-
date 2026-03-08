import 'package:flutter/material.dart';

/// Clase que define todos los colores de la aplicación.
/// Soporta tema claro y oscuro.
class AppColors {
  // Evitar instanciación
  AppColors._();

  // ============== TEMA OSCURO ==============
  static const Color darkBackground = Color(0xFF121318);
  static const Color darkSurface = Color(0xFF1E1F24);
  static const Color darkBorder = Color(0xFF2A2B32);
  static const Color darkTextPrimary = Color(0xFFFFFFFF);
  static const Color darkTextSecondary = Color(0xFFC6C6D0);
  static const Color darkIconDefault = Color(0xFFC6C6D0);

  // ============== TEMA CLARO ==============
  static const Color lightBackground = Color(0xFFFFFFFF);
  static const Color lightSurface = Color(0xFFF2F2F7);
  static const Color lightBorder = Color(0xFFD1D1D6);
  static const Color lightTextPrimary = Color(0xFF1C1C1E);
  static const Color lightTextSecondary = Color(0xFF6E6E73);
  static const Color lightIconDefault = Color(0xFF6E6E73);

  // ============== COLORES COMPARTIDOS (ambos temas) ==============
  /// Color primario - botones, iconos especiales, títulos destacados
  static const Color primary = Color(0xFF2196F3);

  /// Color primario claro - hover, pressed, títulos secundarios
  static const Color primaryLight = Color(0xFF6EB8F5);

  /// Color primario más claro - disabled, no seleccionado
  static const Color primaryLighter = Color(0xFF9ACEF8);

  // ============== ESTADOS ==============
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color error = Color(0xFFE53935);
}

/// Clase que provee los colores según el tema actual
class AppThemeColors {
  final bool isDark;

  AppThemeColors({required this.isDark});

  // Fondos
  Color get background =>
      isDark ? AppColors.darkBackground : AppColors.lightBackground;
  Color get surface => isDark ? AppColors.darkSurface : AppColors.lightSurface;
  Color get border => isDark ? AppColors.darkBorder : AppColors.lightBorder;

  // Texto
  Color get textPrimary =>
      isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
  Color get textSecondary =>
      isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

  // Iconos
  Color get iconDefault =>
      isDark ? AppColors.darkIconDefault : AppColors.lightIconDefault;

  // Colores primarios (compartidos)
  Color get primary => AppColors.primary;
  Color get primaryLight => AppColors.primaryLight;
  Color get primaryLighter => AppColors.primaryLighter;

  // Estados (compartidos)
  Color get success => AppColors.success;
  Color get warning => AppColors.warning;
  Color get error => AppColors.error;

  // Sombra
  Color get shadow =>
      isDark ? Colors.black.withOpacity(0.3) : Colors.black.withOpacity(0.1);
}
