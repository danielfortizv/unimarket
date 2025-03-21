import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData lightTheme = ThemeData(
    primaryColor: const Color(0xFF2B4C7E),
    scaffoldBackgroundColor: const Color(0xFFF8F9FB),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF2B4C7E),
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: Color(0xFF2B4C7E),
      unselectedItemColor: Color(0xFF9CA3AF),
      showUnselectedLabels: true,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF2B4C7E),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Color(0xFF1F2A37)),
      bodyMedium: TextStyle(color: Color(0xFF1F2A37)),
      bodySmall: TextStyle(color: Color(0xFF6B7280)),
    ),
    cardColor: Colors.white,
    iconTheme: const IconThemeData(color: Color(0xFF2B4C7E)),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Color(0xFF2B4C7E)),
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    useMaterial3: true,
  );
}
