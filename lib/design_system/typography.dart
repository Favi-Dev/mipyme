import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SoyPlusTypography {
  static TextTheme get textTheme {
    return GoogleFonts.interTextTheme().copyWith(
      displayLarge: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 32),
      displayMedium: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 28),
      displaySmall: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 24),
      headlineLarge: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 22),
      headlineMedium: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 20),
      headlineSmall: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 18),
      titleLarge: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16),
      titleMedium: GoogleFonts.poppins(fontWeight: FontWeight.w500, fontSize: 14),
      titleSmall: GoogleFonts.poppins(fontWeight: FontWeight.w500, fontSize: 12),
      bodyLarge: GoogleFonts.inter(fontSize: 16),
      bodyMedium: GoogleFonts.inter(fontSize: 14),
      bodySmall: GoogleFonts.inter(fontSize: 12),
      labelLarge: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14),
      labelMedium: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 12),
      labelSmall: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 11),
    );
  }
}
