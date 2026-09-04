import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:update_camtrans/coeur/constantes/couleurs.dart';

class ThemeApplication {
  ThemeApplication._();

  // Mode Clair (Allégé)
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
      textTheme: _getTextTheme(CouleursApp.textePrincipal, CouleursApp.texteSecondaire),
    );
  }

  // Mode Sombre (Par défaut et très travaillé)
  static ThemeData get themeSombre {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: CouleursApp.primaire,
      scaffoldBackgroundColor: CouleursApp.fondSombre,
      
      colorScheme: ColorScheme.fromSeed(
        seedColor: CouleursApp.primaire,
        primary: CouleursApp.primaire,
        secondary: CouleursApp.secondaire,
        surface: CouleursApp.fondSombre,
        error: CouleursApp.erreur,
        brightness: Brightness.dark,
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: Colors.white,
          letterSpacing: -0.5,
        ),
      ),

      // On rend les cartes natives transparentes car on va utiliser GlassContainer
      cardTheme: CardThemeData(
        color: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
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
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.05),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: CouleursApp.primaire, width: 2),
        ),
        labelStyle: GoogleFonts.inter(
          fontSize: 15,
          color: CouleursApp.texteSombreSecondaire,
        ),
        hintStyle: GoogleFonts.inter(
          fontSize: 15,
          color: CouleursApp.texteSombreSecondaire.withValues(alpha: 0.5),
        ),
      ),

      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.transparent,
        selectedItemColor: CouleursApp.primaire,
        unselectedItemColor: CouleursApp.iconeInactive,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: CouleursApp.carteSombre,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
      ),

      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: CouleursApp.carteSombre,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
      ),

      textTheme: _getTextTheme(Colors.white, CouleursApp.texteSombreSecondaire),
    );
  }

  static TextTheme _getTextTheme(Color primaryColor, Color secondaryColor) {
    return GoogleFonts.interTextTheme(
      TextTheme(
        headlineLarge: TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: primaryColor, letterSpacing: -1.0),
        headlineMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: primaryColor, letterSpacing: -0.8),
        headlineSmall: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: primaryColor, letterSpacing: -0.5),
        titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: primaryColor, letterSpacing: -0.5),
        titleMedium: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: primaryColor, letterSpacing: -0.3),
        titleSmall: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: secondaryColor, letterSpacing: -0.2),
        bodyLarge: TextStyle(fontSize: 17, color: primaryColor, letterSpacing: -0.2),
        bodyMedium: TextStyle(fontSize: 15, color: secondaryColor, letterSpacing: -0.1),
        bodySmall: TextStyle(fontSize: 13, color: secondaryColor),
        labelLarge: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: -0.1),
        labelMedium: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: secondaryColor),
      ),
    );
  }
}
