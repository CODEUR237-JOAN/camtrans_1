import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// =======================================================
//
// FICHIER : theme_provider.dart
// PROJET : CamTrans
//
// Gestion du thème (clair, sombre, automatique) avec
// persistance dans SharedPreferences.
//
// Chargé **avant** runApp() pour éviter tout flash blanc
// au démarrage.
//
// =======================================================

/// Clé de persistance dans SharedPreferences.
const String _cleTheme = 'pref_theme_mode';

/// Provider Riverpod exposant le [ThemeProvider].
///
/// Il est initialisé avec une instance pré-chargée dans
/// `main.dart` via un `ProviderScope.overrides`.
final themeProvider = ChangeNotifierProvider<ThemeProvider>(
  (_) => ThemeProvider(),
);

class ThemeProvider extends ChangeNotifier {
  ThemeMode _modeActuel = ThemeMode.system;

  /// Le mode de thème courant.
  ThemeMode get modeActuel => _modeActuel;

  // -----------------------------------------------------------------
  // Chargement depuis le stockage local.
  // Appelé une seule fois, avant runApp.
  // -----------------------------------------------------------------
  Future<void> charger() async {
    final prefs = await SharedPreferences.getInstance();
    final valeur = prefs.getString(_cleTheme);
    switch (valeur) {
      case 'light':
        _modeActuel = ThemeMode.light;
        break;
      case 'dark':
        _modeActuel = ThemeMode.dark;
        break;
      default:
        _modeActuel = ThemeMode.system;
    }
    // Pas de notifyListeners ici : on est avant le premier build.
  }

  // -----------------------------------------------------------------
  // Mise à jour du thème avec persistance.
  // -----------------------------------------------------------------
  Future<void> definir(ThemeMode mode) async {
    if (_modeActuel == mode) return;
    _modeActuel = mode;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    switch (mode) {
      case ThemeMode.light:
        await prefs.setString(_cleTheme, 'light');
        break;
      case ThemeMode.dark:
        await prefs.setString(_cleTheme, 'dark');
        break;
      case ThemeMode.system:
        await prefs.remove(_cleTheme);
        break;
    }
  }

  // -----------------------------------------------------------------
  // Helpers pour l'UI du sélecteur.
  // -----------------------------------------------------------------

  /// Vrai si le thème actif correspond au mode demandé.
  bool estActif(ThemeMode mode) => _modeActuel == mode;

  /// Label humain pour un mode donné.
  static String label(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'Clair';
      case ThemeMode.dark:
        return 'Sombre';
      case ThemeMode.system:
        return 'Auto';
    }
  }

  /// Icône pour un mode donné.
  static IconData icone(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return Icons.wb_sunny_rounded;
      case ThemeMode.dark:
        return Icons.nightlight_round;
      case ThemeMode.system:
        return Icons.brightness_auto_rounded;
    }
  }
}
