import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// =======================================================
//
// FICHIER : theme_application.dart
// PROJET : CamTrans
//
// Deux ThemeData complets (Clair / Sombre) avec ColorScheme
// Material 3. Toutes les couleurs des écrans doivent
// passer par Theme.of(context) et non par des valeurs
// hardcodées.
//
// Palette :
//   Clair → fond #F2F0EA, surface #FFF, primaire #145C43, accent #C1652F
//   Sombre → fond #0E1511, surface #1B2420, primaire #2E8C68, accent #D4845A
//
// Typographie :
//   Titres : Poppins (headline*, title*)
//   Corps  : Inter  (body*, label*)
//
// =======================================================

class ThemeApplication {
  ThemeApplication._();

  // ======================================================
  // THÈME CLAIR
  // ======================================================

  static ThemeData get themeClair {
    const primary = Color(0xFF145C43);
    const secondary = Color(0xFFC1652F);
    const background = Color(0xFFF2F0EA);
    const surface = Color(0xFFFFFFFF);
    const surfaceVariant = Color(0xFFEDE9E1);
    const onBackground = Color(0xFF1A1C1E);
    const onSurface = Color(0xFF1A1C1E);
    const onSurfaceVariant = Color(0xFF6B7280);
    const outline = Color(0xFFD1D5DB);
    const outlineVariant = Color(0xFFE5E7EB);
    const error = Color(0xFFD32F2F);

    const colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: primary,
      onPrimary: Colors.white,
      primaryContainer: Color(0xFFD4EDE3),
      onPrimaryContainer: Color(0xFF0B3D2B),
      secondary: secondary,
      onSecondary: Colors.white,
      secondaryContainer: Color(0xFFFCEADD),
      onSecondaryContainer: Color(0xFF5A2E12),
      tertiary: Color(0xFF3B82F6),
      onTertiary: Colors.white,
      tertiaryContainer: Color(0xFFDBEAFE),
      onTertiaryContainer: Color(0xFF1E3A5F),
      error: error,
      onError: Colors.white,
      errorContainer: Color(0xFFFDECEA),
      onErrorContainer: Color(0xFF5F1A1A),
      surface: surface,
      onSurface: onSurface,
      surfaceContainerHighest: surfaceVariant,
      onSurfaceVariant: onSurfaceVariant,
      outline: outline,
      outlineVariant: outlineVariant,
      shadow: Color(0x0F1A1C1E),
      scrim: Color(0x661A1C1E),
      inverseSurface: Color(0xFF2E3133),
      onInverseSurface: Color(0xFFF2F0EA),
      inversePrimary: Color(0xFF7FDDB8),
      surfaceTint: primary,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: background,
      primaryColor: primary,

      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: onBackground,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: true,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: onBackground,
          letterSpacing: -0.5,
        ),
        iconTheme: const IconThemeData(color: onBackground),
      ),

      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: outlineVariant),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
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
        fillColor: surfaceVariant.withValues(alpha: 0.5),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        labelStyle: GoogleFonts.inter(fontSize: 15, color: onSurfaceVariant),
        hintStyle: GoogleFonts.inter(
            fontSize: 15, color: onSurfaceVariant.withValues(alpha: 0.5)),
      ),

      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: primary,
        unselectedItemColor: onSurfaceVariant,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
      ),

      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
      ),

      dividerTheme: const DividerThemeData(
        color: outlineVariant,
        thickness: 1,
        space: 1,
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return primary;
          return onSurfaceVariant;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primary.withValues(alpha: 0.3);
          }
          return outline;
        }),
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: const Color(0xFF2E3133),
        contentTextStyle: GoogleFonts.inter(color: Colors.white, fontSize: 14),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),

      textTheme: _buildTextTheme(onBackground, onSurfaceVariant),
    );
  }

  // ======================================================
  // THÈME SOMBRE (Brandé — pas de noir pur)
  // ======================================================

  static ThemeData get themeSombre {
    const primary = Color(0xFF2E8C68);
    const secondary = Color(0xFFD4845A);
    const background = Color(0xFF0E1511);
    const surface = Color(0xFF1B2420);
    const surfaceVariant = Color(0xFF243029);
    const surfaceElevated = Color(0xFF2A3630);
    const onBackground = Color(0xFFE8ECE9);
    const onSurface = Color(0xFFE8ECE9);
    const onSurfaceVariant = Color(0xFF9CA3AF);
    const outline = Color(0xFF374151);
    const outlineVariant = Color(0xFF2A3630);
    const error = Color(0xFFEF5350);

    const colorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: primary,
      onPrimary: Colors.white,
      primaryContainer: Color(0xFF1A3D2E),
      onPrimaryContainer: Color(0xFFA3E4C8),
      secondary: secondary,
      onSecondary: Colors.white,
      secondaryContainer: Color(0xFF3D2A1A),
      onSecondaryContainer: Color(0xFFF5D4B8),
      tertiary: Color(0xFF60A5FA),
      onTertiary: Colors.white,
      tertiaryContainer: Color(0xFF1E3A5F),
      onTertiaryContainer: Color(0xFFBFDBFE),
      error: error,
      onError: Colors.white,
      errorContainer: Color(0xFF3D1C1C),
      onErrorContainer: Color(0xFFF5B8B8),
      surface: surface,
      onSurface: onSurface,
      surfaceContainerHighest: surfaceVariant,
      onSurfaceVariant: onSurfaceVariant,
      outline: outline,
      outlineVariant: outlineVariant,
      shadow: Color(0x4D000000),
      scrim: Color(0x99000000),
      inverseSurface: Color(0xFFE8ECE9),
      onInverseSurface: Color(0xFF1B2420),
      inversePrimary: Color(0xFF145C43),
      surfaceTint: primary,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: background,
      primaryColor: primary,

      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: onBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: onBackground,
          letterSpacing: -0.5,
        ),
        iconTheme: const IconThemeData(color: onBackground),
      ),

      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: outlineVariant),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
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
        fillColor: surfaceElevated.withValues(alpha: 0.5),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        labelStyle: GoogleFonts.inter(fontSize: 15, color: onSurfaceVariant),
        hintStyle: GoogleFonts.inter(
            fontSize: 15, color: onSurfaceVariant.withValues(alpha: 0.5)),
      ),

      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.transparent,
        selectedItemColor: primary,
        unselectedItemColor: onSurfaceVariant,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
      ),

      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
      ),

      dividerTheme: const DividerThemeData(
        color: outlineVariant,
        thickness: 1,
        space: 1,
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return primary;
          return onSurfaceVariant;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primary.withValues(alpha: 0.3);
          }
          return outline;
        }),
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: surfaceElevated,
        contentTextStyle: GoogleFonts.inter(color: onSurface, fontSize: 14),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),

      textTheme: _buildTextTheme(onBackground, onSurfaceVariant),
    );
  }

  // ======================================================
  // TYPOGRAPHIE PARTAGÉE
  // ======================================================

  static TextTheme _buildTextTheme(Color primary, Color secondary) {
    // Titres → Poppins
    final titres = GoogleFonts.poppinsTextTheme(
      TextTheme(
        headlineLarge: TextStyle(
            fontSize: 34,
            fontWeight: FontWeight.w900,
            color: primary,
            letterSpacing: -1.0),
        headlineMedium: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: primary,
            letterSpacing: -0.8),
        headlineSmall: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: primary,
            letterSpacing: -0.5),
        titleLarge: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: primary,
            letterSpacing: -0.5),
        titleMedium: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: primary,
            letterSpacing: -0.3),
        titleSmall: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: secondary,
            letterSpacing: -0.2),
      ),
    );

    // Corps → Inter
    final corps = GoogleFonts.interTextTheme(
      TextTheme(
        bodyLarge:
            TextStyle(fontSize: 17, color: primary, letterSpacing: -0.2),
        bodyMedium:
            TextStyle(fontSize: 15, color: secondary, letterSpacing: -0.1),
        bodySmall: TextStyle(fontSize: 13, color: secondary),
        labelLarge: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            letterSpacing: -0.1),
        labelMedium: TextStyle(
            fontSize: 13, fontWeight: FontWeight.w600, color: secondary),
        labelSmall: TextStyle(fontSize: 11, color: secondary),
      ),
    );

    return titres.merge(corps);
  }
}
