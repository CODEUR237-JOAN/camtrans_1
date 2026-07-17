import 'package:flutter/material.dart';

import '../constantes/couleurs.dart';

class ThemeApplication {
  ThemeApplication._();

  static ThemeData get themeClair {
    return ThemeData(
      useMaterial3: true,

      brightness: Brightness.light,

      primaryColor: CouleursApp.primaire,

      scaffoldBackgroundColor: CouleursApp.fond,

      colorScheme: ColorScheme.fromSeed(
        seedColor: CouleursApp.primaire,
        primary: CouleursApp.primaire,
        secondary: CouleursApp.secondaire,
        surface: CouleursApp.fond,
        error: CouleursApp.erreur,
        brightness: Brightness.light,
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: CouleursApp.textePrincipal,
        elevation: 0,
        centerTitle: true,
      ),

      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 3,
        shadowColor: CouleursApp.ombre,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: CouleursApp.primaire,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 56),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: CouleursApp.primaire,
          side: const BorderSide(
            color: CouleursApp.primaire,
            width: 1.5,
          ),
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 18,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: CouleursApp.bordure,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: CouleursApp.bordure,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: CouleursApp.primaire,
            width: 2,
          ),
        ),
      ),

      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: CouleursApp.primaire,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        elevation: 10,
      ),

      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: CouleursApp.primaire,
        foregroundColor: Colors.white,
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: CouleursApp.primaireFonce,
        contentTextStyle: const TextStyle(
          color: Colors.white,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: CouleursApp.primaire,
      ),

      dividerTheme: const DividerThemeData(
        color: CouleursApp.bordure,
        thickness: 1,
      ),

      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: CouleursApp.textePrincipal,
        ),
        headlineMedium: TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.bold,
          color: CouleursApp.textePrincipal,
        ),
        headlineSmall: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: CouleursApp.textePrincipal,
        ),
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: CouleursApp.textePrincipal,
        ),
        titleMedium: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w500,
          color: CouleursApp.textePrincipal,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          color: CouleursApp.textePrincipal,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: CouleursApp.texteSecondaire,
        ),
        labelLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }
}