import 'package:flutter/material.dart';

class TColors {
  // App theme colors
  // Palette mapping (light and dark use same values for now):
  // Primary: #283618, Secondary: #606C38
  // Background (primary): #FEFAE0, Background (secondary): #DDA15E
  // Buttons & Tiles: #BC6C25
  static const Color primary = Color(0xFF283618);
  static const Color secondary = Color(0xFF606C38);
  static const Color accent = Color(0xFFBC6C25); // Buttons & tiles

  // Dark Mode Text colors (same as light mode for now)
  static const Color darkModePrimaryText = Color(0xFF283618);
  static const Color darkModeSecondaryText = Color(0xFF606C38);

  //Dark Mode Buttons

//Light Mode Text colors (on light background #FEFAE0)
  static const Color lightModePrimaryText = Color(0xFF283618);
  static const Color lightModeSecondaryText = Color(0xFF606C38);
  static const Color lightModeTextWhite = Colors.white;

  // Background colors (same for light/dark)
  static const Color light = Color(0xFFFEFAE0);
  static const Color dark = Color(0xFFFEFAE0);
  static const Color primaryBackground = Color(0xFFFEFAE0);
  static const Color secondaryBackground = Color(0xFFBC6C25);

  // Background Container colors
  static const Color lightContainer = Color(0xFFDDA15E); // Secondary background
  static Color darkContainer = const Color(0xFFDDA15E);

  // Button colors (buttons & tiles)
  static const Color buttonPrimary = Color(0xFFBC6C25);
  static const Color buttonSecondary = Color(0xFFBC6C25);
  static const Color buttonDisabled = Color(0xFFC4C4C4);

  // Border colors
  static const Color borderPrimary = Color(0xFFDDA15E);
  static const Color borderSecondary = Color(0xFF606C38);

  // Error and validation colors
  static const Color error = Color(0xFFD32F2F);
  static const Color success = Color(0xFF388E3C);
  static const Color warning = Color(0xFFF57C00);
  static const Color info = Color(0xFF1976D2);

  // Neutral Shades
  static const Color black = Color(0xFF232323);
  static const Color darkerGrey = Color(0xFF4F4F4F);
  static const Color darkGrey = Color(0xFF939393);
  static const Color grey = Color(0xFFE0E0E0);
  static const Color softGrey = Color(0xFFF4F4F4);
  static const Color lightGrey = Color(0xFFF9F9F9);
  static const Color white = Color(0xFFFFFFFF);
  static const Color softWhite = Color(0xFFF5F5F5); // Light grey-white
  static const Color warmWhite = Color(0xFFFAFAFA); // Gentle warm white
  static const Color neutralWhite = Color(0xFFEFEFEF); // Muted white

  static const Color cream = Color(0xFFFFFDD0); // Classic cream
  static const Color lightCream = Color(0xFFFFFAE5); // Very light cream
  static const Color warmCream = Color(0xFFFFF4CC); // Slightly warmer
}
