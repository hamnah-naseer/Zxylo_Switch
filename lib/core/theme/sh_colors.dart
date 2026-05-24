import 'package:flutter/material.dart';

abstract class SHColors {
  // New Tiffany & Bondi Theme
  static const Color primaryColor = Color(0xFF0095B6);   // Bondi Blue
  static const Color accentColor = Color(0xFF0ABAB5);    // Tiffany Blue
  static const Color backgroundColor = Color(0xFFF6FDFF); // Light Cyan
  static const Color textColor = Color(0xFF1A1C1E);      // Dark Navy
  static const Color subTextColor = Color(0xFF757575);   // Grey
  static const Color glowColor = Color(0xFF3BCFB6);      // Cyan Glow
  
  static const Color cardColor = Colors.white;
  static const Color hintColor = Color(0xFF9EABB8);
  static const Color trackColor = Color(0xFFE0E0E0);
  static const Color selectedColor = Color(0xFF0095B6);

  static const List<Color> brandingGradient = [
    Color(0xFF0ABAB5), // Tiffany Blue
    Color(0xFF0095B6), // Bondi Blue
  ];

  // Keep these for compatibility if needed, but updated
  static const List<Color> cardColors = [
    Colors.white,
    Colors.white,
    Colors.white,
  ];
  
  static const List<Color> dimmedLightColors = [
    Color(0xFFF6FDFF),
    Color(0xFFE8FAF7),
    Color(0xFFF0F4F7),
  ];
}
