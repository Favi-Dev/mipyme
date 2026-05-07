import 'package:flutter/material.dart';
import '../design_system/colors.dart';
import '../design_system/typography.dart';

class AppTheme {
  // 4️⃣ Colores para Glassmorphism (Efecto Vidrio) - Manteniendo para compatibilidad temporal si es necesario
  static Color get glassWhite => SoyPlusColors.onPrimary.withOpacity(0.85);
  static Color get glassGreen => SoyPlusColors.primary.withOpacity(0.85);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      
      // Definición de colores base
      colorScheme: ColorScheme.fromSeed(
        seedColor: SoyPlusColors.primary,
        primary: SoyPlusColors.primary,
        onPrimary: SoyPlusColors.onPrimary, // Botones con texto blanco
        secondary: SoyPlusColors.accentGreen,
        onSecondary: SoyPlusColors.onPrimary,
        surface: SoyPlusColors.surfaceLight, // Fondo claro
        onSurface: SoyPlusColors.textPrimaryLight, // Texto oscuro sobre fondo claro
        tertiary: SoyPlusColors.accentBrown,
        error: SoyPlusColors.error,
      ),

      // Fondo principal de la app
      scaffoldBackgroundColor: SoyPlusColors.backgroundLight,

      // Configuración del AppBar
      appBarTheme: AppBarTheme(
        backgroundColor: SoyPlusColors.primary,
        foregroundColor: SoyPlusColors.onPrimary,
        centerTitle: true,
        titleTextStyle: SoyPlusTypography.textTheme.titleLarge?.copyWith(
          color: SoyPlusColors.onPrimary,
        ),
      ),

      // Configuración de textos
      textTheme: SoyPlusTypography.textTheme.apply(
        bodyColor: SoyPlusColors.textPrimaryLight,
        displayColor: SoyPlusColors.textPrimaryLight,
      ),

      // Configuración de botones
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: SoyPlusColors.primary,
          foregroundColor: SoyPlusColors.onPrimary,
          textStyle: SoyPlusTypography.textTheme.labelLarge,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
      ),

      // Botones secundarios (Outlined o Text)
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: SoyPlusColors.primary,
          side: const BorderSide(color: SoyPlusColors.primary),
          textStyle: SoyPlusTypography.textTheme.labelLarge,
        ),
      ),

  // Inputs y Formularios
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: SoyPlusColors.surfaceLight,
        labelStyle: SoyPlusTypography.textTheme.bodyMedium?.copyWith(color: SoyPlusColors.primary),
        hintStyle: SoyPlusTypography.textTheme.bodyMedium?.copyWith(color: SoyPlusColors.primary.withOpacity(0.7)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: SoyPlusColors.primary),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.withOpacity(0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: SoyPlusColors.primary, width: 2),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      
      colorScheme: ColorScheme.fromSeed(
        brightness: Brightness.dark,
        seedColor: SoyPlusColors.accentGreen,
        primary: SoyPlusColors.accentGreen,
        onPrimary: SoyPlusColors.onPrimary,
        secondary: SoyPlusColors.primary,
        onSecondary: SoyPlusColors.onPrimary,
        surface: SoyPlusColors.surfaceDark, // Fondo de tarjetas
        onSurface: SoyPlusColors.textPrimaryDark,
        tertiary: SoyPlusColors.accentBrown,
        error: SoyPlusColors.error,
      ),

      scaffoldBackgroundColor: SoyPlusColors.backgroundDark,

      appBarTheme: AppBarTheme(
        backgroundColor: SoyPlusColors.surfaceDark,
        foregroundColor: SoyPlusColors.textPrimaryDark,
        centerTitle: true,
        titleTextStyle: SoyPlusTypography.textTheme.titleLarge?.copyWith(
          color: SoyPlusColors.textPrimaryDark,
        ),
      ),

      textTheme: SoyPlusTypography.textTheme.apply(
        bodyColor: SoyPlusColors.textPrimaryDark,
        displayColor: SoyPlusColors.textPrimaryDark,
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: SoyPlusColors.accentGreen,
          foregroundColor: SoyPlusColors.onPrimary,
          textStyle: SoyPlusTypography.textTheme.labelLarge,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: SoyPlusColors.accentGreen,
          side: const BorderSide(color: SoyPlusColors.accentGreen),
          textStyle: SoyPlusTypography.textTheme.labelLarge,
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: SoyPlusColors.surfaceDark,
        labelStyle: SoyPlusTypography.textTheme.bodyMedium?.copyWith(color: SoyPlusColors.textPrimaryDark.withOpacity(0.8)),
        hintStyle: SoyPlusTypography.textTheme.bodyMedium?.copyWith(color: SoyPlusColors.textPrimaryDark.withOpacity(0.5)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: SoyPlusColors.accentGreen.withOpacity(0.5)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.withOpacity(0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: SoyPlusColors.accentGreen, width: 2),
        ),
      ),
    );
  }
}
