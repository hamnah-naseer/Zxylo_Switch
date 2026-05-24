import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'sh_colors.dart';

abstract class SHTheme {
  static ThemeData light = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    primaryColor: SHColors.primaryColor,
    colorScheme: ColorScheme.fromSeed(
      seedColor: SHColors.primaryColor,
      primary: SHColors.primaryColor,
      secondary: SHColors.accentColor,
      surface: SHColors.backgroundColor,
    ),
    scaffoldBackgroundColor: SHColors.backgroundColor,
    
    textTheme: TextTheme(
      bodyLarge: GoogleFonts.montserrat(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: SHColors.textColor,
      ),
      bodyMedium: GoogleFonts.montserrat(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: SHColors.textColor,
      ),
      bodySmall: GoogleFonts.montserrat(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: SHColors.subTextColor,
      ),
      displayLarge: GoogleFonts.montserrat(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: SHColors.textColor,
      ),
      displayMedium: GoogleFonts.montserrat(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: SHColors.textColor,
      ),
      displaySmall: GoogleFonts.montserrat(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: SHColors.textColor,
      ),
      titleLarge: GoogleFonts.montserrat(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: SHColors.textColor,
      ),
    ),
    
    appBarTheme: AppBarTheme(
      elevation: 0,
      backgroundColor: SHColors.backgroundColor,
      centerTitle: true,
      titleTextStyle: GoogleFonts.montserrat(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: SHColors.textColor,
      ),
      iconTheme: const IconThemeData(color: SHColors.textColor),
    ),
    
    iconTheme: const IconThemeData(color: SHColors.textColor),
    
    cardTheme: CardThemeData(
      color: SHColors.cardColor,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: SHColors.primaryColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: GoogleFonts.montserrat(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
    
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: SHColors.primaryColor.withValues(alpha: 0.1)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: SHColors.primaryColor.withValues(alpha: 0.1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: SHColors.primaryColor, width: 2),
      ),
    ),

    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: SHColors.primaryColor,
      unselectedItemColor: SHColors.hintColor,
      selectedLabelStyle: GoogleFonts.montserrat(
        fontSize: 12,
        fontWeight: FontWeight.bold,
      ),
      unselectedLabelStyle: GoogleFonts.montserrat(
        fontSize: 11,
      ),
    ),
  );

  // Keep 'dark' alias for compatibility if referenced, but make it light
  static ThemeData dark = light;
}
