import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // 1️⃣ Colores principales (identidad núcleo)
  static const Color deepLeafGreen = Color(0xFF2F3F2A); // Verde Hoja Profundo (Fondo)
  static const Color warmWhite = Color(0xFFF4F1EA); // Blanco Cálido (Texto)

  // 2️⃣ Colores secundarios (humanidad y diversidad)
  static const Color earthBrown = Color(0xFF8B5A3C); // Café Tierra
  static const Color skinBeige = Color(0xFFE3B58F); // Beige Piel Claro

  // 3️⃣ Colores de apoyo / acento
  static const Color lightGreen = Color(0xFF6F8F5E); // Verde Claro Apoyo
  static const Color organicGrey = Color(0xFF6E6E6A); // Gris Orgánico

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      
      // Definición de colores base
      colorScheme: ColorScheme.fromSeed(
        seedColor: deepLeafGreen,
        primary: deepLeafGreen,
        onPrimary: warmWhite, // Botones con texto blanco
        secondary: lightGreen,
        onSecondary: warmWhite,
        surface: warmWhite, // Fondo claro
        onSurface: deepLeafGreen, // Texto oscuro sobre fondo claro
        tertiary: earthBrown,
        error: earthBrown,
      ),

      // Fondo principal de la app
      scaffoldBackgroundColor: warmWhite,

      // Configuración del AppBar
      appBarTheme: AppBarTheme(
        backgroundColor: deepLeafGreen,
        foregroundColor: warmWhite,
        centerTitle: true,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: warmWhite,
        ),
      ),

      // Configuración de textos
      textTheme: GoogleFonts.interTextTheme().apply(
        bodyColor: deepLeafGreen,
        displayColor: deepLeafGreen,
      ).copyWith(
        // Títulos con Poppins
        displayLarge: GoogleFonts.poppins(
          color: deepLeafGreen,
          fontWeight: FontWeight.bold,
        ),
        displayMedium: GoogleFonts.poppins(
          color: deepLeafGreen,
          fontWeight: FontWeight.bold,
        ),
        displaySmall: GoogleFonts.poppins(
          color: deepLeafGreen,
          fontWeight: FontWeight.w600,
        ),
        headlineLarge: GoogleFonts.poppins(
          color: deepLeafGreen,
          fontWeight: FontWeight.bold,
        ),
        headlineMedium: GoogleFonts.poppins(
          color: deepLeafGreen,
          fontWeight: FontWeight.w600,
        ),
        headlineSmall: GoogleFonts.poppins(
          color: deepLeafGreen,
          fontWeight: FontWeight.w500,
        ),
        
        // Cuerpo con Inter
        bodyLarge: GoogleFonts.inter(
          color: deepLeafGreen,
          fontSize: 16,
        ),
        bodyMedium: GoogleFonts.inter(
          color: organicGrey, // Textos secundarios
          fontSize: 14,
        ),
        bodySmall: GoogleFonts.inter(
          color: organicGrey.withOpacity(0.8),
          fontSize: 12,
        ),
      ),

      // Configuración de botones
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: deepLeafGreen,
          foregroundColor: warmWhite,
          textStyle: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),

      // Botones secundarios (Outlined o Text)
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: deepLeafGreen,
          side: const BorderSide(color: deepLeafGreen),
          textStyle: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Inputs y Formularios
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: warmWhite,
        labelStyle: GoogleFonts.inter(color: deepLeafGreen),
        hintStyle: GoogleFonts.inter(color: deepLeafGreen.withOpacity(0.7)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: deepLeafGreen),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: organicGrey.withOpacity(0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: deepLeafGreen, width: 2),
        ),
      ),
    );
  }
}
