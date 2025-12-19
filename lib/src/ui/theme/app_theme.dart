import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryBlue = Color(0xFF2010B6); // Custom Blue
  static const Color primaryBlueDark = Color(0xFF1A0D91); // Darker Custom Blue
  static const Color secondaryPurple = Color(0xFF8B5CF6); // Violet-500
  static const Color accentTeal = Color(0xFF06B6D4); // Cyan-500
  static const Color accentGreen = Color(0xFF10B981); // Emerald-500
  static const Color warningAmber = Color(0xFFF59E0B); // Amber-500
  static const Color errorRed = Color(0xFFEF4444); // Red-500

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: const ColorScheme.light(
      // Primary colors
      primary: primaryBlue,
      onPrimary: Colors.white,
      primaryContainer: Color(0xFFEEF2FF), // Indigo-50
      onPrimaryContainer: Color(0xFF1E1B4B), // Indigo-900
      // Secondary colors
      secondary: secondaryPurple,
      onSecondary: Colors.white,
      secondaryContainer: Color(0xFFF3E8FF), // Violet-50
      onSecondaryContainer: Color(0xFF4C1D95), // Violet-900
      // Tertiary colors
      tertiary: accentTeal,
      onTertiary: Colors.white,
      tertiaryContainer: Color(0xFFECFEFF), // Cyan-50
      onTertiaryContainer: Color(0xFF164E63), // Cyan-900
      // Error colors
      error: errorRed,
      onError: Colors.white,
      errorContainer: Color(0xFFFEF2F2), // Red-50
      onErrorContainer: Color(0xFF7F1D1D), // Red-900
      // Surface colors
      surface: Colors.white,
      onSurface: Color(0xFF1F2937), // Gray-800
      surfaceVariant: Color(0xFFF9FAFB), // Gray-50
      onSurfaceVariant: Color(0xFF6B7280), // Gray-500
      // Background colors
      background: Color(0xFFFFFFFF),
      onBackground: Color(0xFF1F2937), // Gray-800
      // Outline
      outline: Color(0xFFD1D5DB), // Gray-300
      outlineVariant: Color(0xFFF3F4F6), // Gray-100
    ),

    // AppBar Theme
    appBarTheme: const AppBarTheme(
      elevation: 0,
      scrolledUnderElevation: 1,
      backgroundColor: primaryBlue,
      foregroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
    ),

    // Card Theme
    cardTheme: CardThemeData(
      elevation: 0,
      shadowColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide.none,
      ),
      clipBehavior: Clip.antiAlias,
      color: Colors.white,
      margin: EdgeInsets.zero,
    ),

    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: primaryBlue,
      foregroundColor: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFFF3F4F6), // Gray-100
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryBlue, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: errorRed),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),

    // Elevated Button Theme
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    ),

    // Filled Button Theme
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    ),

    // Outlined Button Theme
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        side: const BorderSide(color: primaryBlue),
      ),
    ),

    // Text Button Theme
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryBlue,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    ),

    // Icon Theme
    iconTheme: const IconThemeData(
      color: Color(0xFF1F2937), // Gray-800
    ),

    // Popup Menu Theme
    popupMenuTheme: PopupMenuThemeData(
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      textStyle: const TextStyle(color: Color(0xFF1F2937)),
    ),

    // Chip Theme
    chipTheme: const ChipThemeData(
      backgroundColor: Color(0xFFF3F4F6), // Gray-100
      selectedColor: primaryBlue,
      secondarySelectedColor: Color(0xFFEEF2FF), // Indigo-50
      labelStyle: TextStyle(color: Color(0xFF374151)), // Gray-700
      secondaryLabelStyle: TextStyle(color: primaryBlue),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
    ),

    // Text Theme
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: Color(0xFF1F2937), // Gray-800
      ),
      headlineMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        color: Color(0xFF1F2937), // Gray-800
      ),
      titleLarge: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: Color(0xFF1F2937), // Gray-800
      ),
      titleMedium: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w500,
        color: Color(0xFF1F2937), // Gray-800
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: Color(0xFF374151), // Gray-700
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: Color(0xFF6B7280), // Gray-500
      ),
    ),
  );

  // Dark Theme
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      // Primary colors
      primary: primaryBlue,
      onPrimary: Colors.white,
      primaryContainer: primaryBlue,
      onPrimaryContainer: Colors.white,
      // Secondary colors
      secondary: secondaryPurple,
      onSecondary: Colors.white,
      secondaryContainer: Color(0xFF6D28D9), // Violet-700
      onSecondaryContainer: Color(0xFFF3E8FF), // Violet-50
      // Tertiary colors
      tertiary: Color(0xFF22D3EE), // Cyan-400
      onTertiary: Color(0xFF164E63), // Cyan-900
      tertiaryContainer: Color(0xFF0E7490), // Cyan-700
      onTertiaryContainer: Color(0xFFECFEFF), // Cyan-50
      // Error colors
      error: Color(0xFFF87171), // Red-400
      onError: Color(0xFF7F1D1D), // Red-900
      errorContainer: Color(0xFFDC2626), // Red-600
      onErrorContainer: Color(0xFFFEF2F2), // Red-50
      // Surface colors
      surface: Color(0xFF121212),
      onSurface: Color(0xFFF9FAFB), // Gray-50
      surfaceVariant: Color(0xFF374151), // Gray-700
      onSurfaceVariant: Color(0xFF9CA3AF), // Gray-400
      // Background colors
      background: Color(0xFF121212),
      onBackground: Color(0xFFF9FAFB), // Gray-50
      // Outline
      outline: Color(0xFF4B5563), // Gray-600
      outlineVariant: Color(0xFF374151), // Gray-700
    ),

    // AppBar Theme
    appBarTheme: const AppBarTheme(
      elevation: 0,
      scrolledUnderElevation: 1,
      backgroundColor: primaryBlue,
      foregroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
    ),

    // Card Theme
    cardTheme: CardThemeData(
      elevation: 0,
      shadowColor: Colors.transparent,
      color: const Color(0xFF1F2937), // Gray-800
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide.none,
      ),
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
    ),

    // FloatingActionButton Theme
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: primaryBlue,
      foregroundColor: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
    ),

    // Input Decoration Theme
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF374151), // Gray-700
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryBlue, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFF87171)), // Red-400
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),

    // Elevated Button Theme
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    ),

    // Filled Button Theme
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    ),

    // Outlined Button Theme
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        side: const BorderSide(color: primaryBlue),
      ),
    ),

    // Text Button Theme
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryBlue,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    ),

    // Icon Theme
    iconTheme: const IconThemeData(
      color: Color(0xFFF9FAFB), // Gray-50
    ),

    // Popup Menu Theme
    popupMenuTheme: PopupMenuThemeData(
      color: const Color(0xFF1F2937), // Gray-800
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      textStyle: const TextStyle(color: Color(0xFFF9FAFB)),
    ),

    // Chip Theme
    chipTheme: const ChipThemeData(
      backgroundColor: Color(0xFF374151), // Gray-700
      selectedColor: primaryBlue,
      secondarySelectedColor: primaryBlue,
      labelStyle: TextStyle(color: Color(0xFF9CA3AF)), // Gray-400
      secondaryLabelStyle: TextStyle(color: Colors.white),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
    ),

    // Text Theme
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: Color(0xFFF9FAFB), // Gray-50
      ),
      headlineMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        color: Color(0xFFF9FAFB), // Gray-50
      ),
      titleLarge: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: Color(0xFFF9FAFB), // Gray-50
      ),
      titleMedium: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w500,
        color: Color(0xFFF9FAFB), // Gray-50
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: Color(0xFFE5E7EB), // Gray-200
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: Color(0xFF9CA3AF), // Gray-400
      ),
    ),
  );

  // Status colors that work in both themes
  static const Map<String, Color> statusColors = {
    'active': accentGreen,
    'inactive': Color(0xFF9CA3AF), // Gray-400
    'warning': warningAmber,
    'error': errorRed,
    'info': primaryBlue,
  };

  // Gradient definitions for modern effects
  static const List<LinearGradient> gradients = [
    LinearGradient(
      colors: [primaryBlue, secondaryPurple],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    LinearGradient(
      colors: [accentTeal, accentGreen],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    LinearGradient(
      colors: [secondaryPurple, primaryBlueDark],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),
  ];

  // Helper methods
  static Color getStatusColor(String status, {bool isDark = false}) {
    return statusColors[status] ??
        (isDark ? Colors.grey[400]! : Colors.grey[600]!);
  }

  static LinearGradient getPrimaryGradient() => gradients[0];
  static LinearGradient getSecondaryGradient() => gradients[1];
  static LinearGradient getAccentGradient() => gradients[2];
}
