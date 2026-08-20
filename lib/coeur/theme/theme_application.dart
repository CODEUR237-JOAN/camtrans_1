import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:update_camtrans/coeur/constantes/couleurs.dart';

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
        surfaceContainerHighest: CouleursApp.fondSecondaire,
        error: CouleursApp.erreur,
        brightness: Brightness.light,
      ),

      // AppBar ultra minimaliste (Stripe/Apple style)
      appBarTheme: AppBarTheme(
        backgroundColor: CouleursApp.fond.withValues(alpha: 0.9),
        foregroundColor: CouleursApp.textePrincipal,
        elevation: 0,
        centerTitle: true,
        scrolledUnderElevation: 4,
        shadowColor: CouleursApp.ombre,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: CouleursApp.textePrincipal,
          letterSpacing: -0.5,
        ),
        iconTheme: const IconThemeData(
          color: CouleursApp.textePrincipal,
          size: 24,
        ),
      ),

      // Cartes premium : Blanches, bords très arrondis, ombre ultra douce
      cardTheme: CardThemeData(
        color: CouleursApp.carte,
        elevation: 0,
        margin: EdgeInsets.zero,
        shadowColor: CouleursApp.ombre,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: CouleursApp.bordure.withValues(alpha: 0.5), width: 1),
        ),
      ),

      // Boutons primaires (Look iOS / Stripe)
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: CouleursApp.primaire,
          foregroundColor: Colors.white,
          minimumSize: Size(double.infinity, 56),
          elevation: 0, // Pas d'élévation par défaut pour un look flat premium
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.3,
          ),
        ),
      ),

      // Boutons secondaires
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: CouleursApp.textePrincipal,
          side: const BorderSide(color: CouleursApp.bordure, width: 1.5),
          minimumSize: Size(double.infinity, 56),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.3,
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: CouleursApp.primaire,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Inputs très épurés
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: CouleursApp.fondSecondaire,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: CouleursApp.primaire, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: CouleursApp.erreur, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: CouleursApp.erreur, width: 2),
        ),
        labelStyle: GoogleFonts.inter(
          fontSize: 15,
          color: CouleursApp.texteSecondaire,
        ),
        hintStyle: GoogleFonts.inter(
          fontSize: 15,
          color: CouleursApp.texteTertiaire,
        ),
      ),

      // Bottom Navigation transparente
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: CouleursApp.fond,
        selectedItemColor: CouleursApp.primaire,
        unselectedItemColor: CouleursApp.iconeInactive,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 11),
        unselectedLabelStyle: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 11),
      ),

      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: CouleursApp.primaire,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: CircleBorder(),
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: CouleursApp.textePrincipal,
        contentTextStyle: GoogleFonts.inter(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: CouleursApp.carte,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
      ),

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: CouleursApp.carte,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: CouleursApp.fondSecondaire,
        selectedColor: CouleursApp.primaire,
        checkmarkColor: Colors.white,
        labelStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: CouleursApp.textePrincipal),
        secondaryLabelStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(100), // Pill shape
          side: BorderSide.none,
        ),
      ),

      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: CouleursApp.primaire,
        linearTrackColor: CouleursApp.fondSecondaire,
        circularTrackColor: CouleursApp.fondSecondaire,
      ),

      dividerTheme: const DividerThemeData(
        color: CouleursApp.bordure,
        thickness: 1,
        space: 24,
      ),

      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),

      // Typographie : Inter (Très clean, moderne)
      textTheme: GoogleFonts.interTextTheme(
        TextTheme(
          headlineLarge: TextStyle(
            fontSize: 34,
            fontWeight: FontWeight.w800,
            color: CouleursApp.textePrincipal,
            letterSpacing: -1.0,
            height: 1.1,
          ),
          headlineMedium: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: CouleursApp.textePrincipal,
            letterSpacing: -0.8,
            height: 1.2,
          ),
          headlineSmall: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: CouleursApp.textePrincipal,
            letterSpacing: -0.5,
            height: 1.3,
          ),
          titleLarge: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: CouleursApp.textePrincipal,
            letterSpacing: -0.5,
            height: 1.3,
          ),
          titleMedium: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: CouleursApp.textePrincipal,
            letterSpacing: -0.3,
            height: 1.4,
          ),
          titleSmall: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: CouleursApp.texteSecondaire,
            letterSpacing: -0.2,
            height: 1.4,
          ),
          bodyLarge: TextStyle(
            fontSize: 17,
            color: CouleursApp.textePrincipal,
            letterSpacing: -0.2,
            height: 1.5,
          ),
          bodyMedium: TextStyle(
            fontSize: 15,
            color: CouleursApp.texteSecondaire,
            letterSpacing: -0.1,
            height: 1.5,
          ),
          bodySmall: TextStyle(
            fontSize: 13,
            color: CouleursApp.texteTertiaire,
            height: 1.4,
          ),
          labelLarge: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.white,
            letterSpacing: -0.1,
          ),
          labelMedium: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: CouleursApp.texteSecondaire,
          ),
        ),
      ),
    );
  }

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
        surfaceContainerHighest: CouleursApp.fondSombreSecondaire,
        error: CouleursApp.erreur,
        brightness: Brightness.dark,
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: CouleursApp.fondSombre.withValues(alpha: 0.9),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        scrolledUnderElevation: 4,
        shadowColor: Colors.black,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: Colors.white,
          letterSpacing: -0.5,
        ),
      ),

      cardTheme: CardThemeData(
        color: CouleursApp.carteSombre,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: CouleursApp.bordureSombre, width: 1),
        ),
      ),

      elevatedButtonTheme: ThemeData.light().elevatedButtonTheme, // On garde la logique du theme clair pour le bouton principal
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          side: const BorderSide(color: CouleursApp.bordureSombre, width: 1.5),
          minimumSize: Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: CouleursApp.fondSombreSecondaire,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: CouleursApp.primaire, width: 1.5),
        ),
        labelStyle: GoogleFonts.inter(
          fontSize: 15,
          color: CouleursApp.texteSombreSecondaire,
        ),
        hintStyle: GoogleFonts.inter(
          fontSize: 15,
          color: CouleursApp.texteSombreSecondaire.withValues(alpha: 0.7),
        ),
      ),

      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: CouleursApp.fondSombre,
        selectedItemColor: CouleursApp.primaire,
        unselectedItemColor: CouleursApp.texteSombreSecondaire,
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

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: CouleursApp.carteSombre,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: CouleursApp.fondSombreSecondaire,
        selectedColor: CouleursApp.primaire,
        checkmarkColor: Colors.white,
        labelStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(100),
          side: BorderSide.none,
        ),
      ),

      textTheme: GoogleFonts.interTextTheme(
        ThemeData.dark().textTheme,
      ).apply(
        bodyColor: Colors.white,
        displayColor: Colors.white,
      ),
    );
  }
}
