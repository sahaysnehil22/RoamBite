import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryColor = Color(0xFFFF5722); // Vibrant Street Flame
  static const Color primaryVariant = Color(0xFFE64A19);
  static const Color secondaryColor = Color(0xFFFFB300); // Warm Golden Amber
  static const Color accentGreen = Color(0xFF00C853); // Live Serving Green

  // Light Theme (DEFAULT)
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    primaryColor: primaryColor,
    scaffoldBackgroundColor: const Color(0xFFF8F9FA),
    colorScheme: const ColorScheme.light(
      primary: primaryColor,
      secondary: secondaryColor,
      surface: Color(0xFFFFFFFF),
      onPrimary: Colors.white,
      onSecondary: Colors.black,
      onSurface: Color(0xFF1E232A),
      error: Color(0xFFD32F2F),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFFFFFFFF),
      foregroundColor: Color(0xFF1E232A),
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: Color(0xFF1E232A),
        fontSize: 18,
        fontWeight: FontWeight.bold,
        letterSpacing: -0.3,
      ),
      iconTheme: IconThemeData(color: Color(0xFF1E232A)),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE9ECEF), width: 1),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: const Color(0xFFEDF2F7),
      selectedColor: primaryColor,
      secondarySelectedColor: primaryColor,
      labelStyle: const TextStyle(color: Color(0xFF2D3748), fontSize: 13),
      secondaryLabelStyle: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
      side: const BorderSide(color: Color(0xFFE2E8F0)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white,
      indicatorColor: primaryColor.withValues(alpha: 0.15),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 12);
        }
        return const TextStyle(color: Color(0xFF718096), fontSize: 12);
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const IconThemeData(color: primaryColor);
        }
        return const IconThemeData(color: Color(0xFF718096));
      }),
    ),
  );

  // Dark Theme (User Toggleable)
  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    primaryColor: primaryColor,
    scaffoldBackgroundColor: const Color(0xFF0F1218),
    colorScheme: const ColorScheme.dark(
      primary: primaryColor,
      secondary: secondaryColor,
      surface: Color(0xFF161A22),
      onPrimary: Colors.white,
      onSecondary: Colors.black,
      onSurface: Color(0xFFF1F5F9),
      error: Color(0xFFEF5350),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF161A22),
      foregroundColor: Color(0xFFF1F5F9),
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: Color(0xFFF1F5F9),
        fontSize: 18,
        fontWeight: FontWeight.bold,
        letterSpacing: -0.3,
      ),
      iconTheme: IconThemeData(color: Color(0xFFF1F5F9)),
    ),
    cardTheme: CardThemeData(
      color: const Color(0xFF161A22),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFF262D3D), width: 1),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: const Color(0xFF1C222E),
      selectedColor: primaryColor,
      secondarySelectedColor: primaryColor,
      labelStyle: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 13),
      secondaryLabelStyle: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
      side: const BorderSide(color: Color(0xFF2E384D)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: const Color(0xFF141820),
      indicatorColor: primaryColor.withValues(alpha: 0.2),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 12);
        }
        return const TextStyle(color: Color(0xFF94A3B8), fontSize: 12);
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const IconThemeData(color: primaryColor);
        }
        return const IconThemeData(color: Color(0xFF94A3B8));
      }),
    ),
  );
}
