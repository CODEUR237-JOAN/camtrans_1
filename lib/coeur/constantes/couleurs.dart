import 'package:flutter/material.dart';

/// =======================================================
///
/// FICHIER : couleurs.dart
/// PROJET : TransConnect Cameroun
///
/// Toutes les couleurs de l'application sont centralisées ici.
///
/// =======================================================

class CouleursApp {
  CouleursApp._();

  // ==========================
  // Couleurs principales (Premium)
  // ==========================

  static const Color primaire = Color(0xFF2697FF);
  static const Color primaireFonce = Color(0xFF1E3A8A);
  static const Color primaireClair = Color(0xFFEAF5FF);

  // ==========================
  // Couleurs secondaires
  // ==========================

  static const Color secondaire = Color(0xFF00B4D8);
  static const Color secondaireClair = Color(0xFF90E0EF);

  // ==========================
  // Couleurs de fond
  // ==========================

  static const Color fond = Color(0xFFF4F7FB);
  static const Color fondSecondaire = Color(0xFFF1F5F9);

  // ==========================
  // Cartes & Surfaces
  // ==========================

  static const Color carte = Colors.white;
  static const Color carteSecondaire = Color(0xFFFDFDFD);
  static const Color surface = Colors.white;

  // ==========================
  // Texte
  // ==========================

  static const Color textePrincipal = Color(0xFF1E293B);
  static const Color texteSecondaire = Color(0xFF64748B);
  static const Color texteBlanc = Colors.white;

  // ==========================
  // Boutons
  // ==========================

  static const Color boutonPrincipal = primaireFonce;
  static const Color boutonSecondaire = primaire;

  // ==========================
  // Etats
  // ==========================

  static const Color succes = Color(0xFF16A34A);
  static const Color erreur = Color(0xFFDC2626);
  static const Color avertissement = Color(0xFFF59E0B);
  static const Color information = Color(0xFF2563EB);

  // ==========================
  // Bordures
  // ==========================

  static const Color bordure = Color(0xFFE2E8F0);
  static const Color bordureActive = primaire;

  // ==========================
  // Icônes
  // ==========================

  static const Color icone = Color(0xFF475569);
  static const Color iconeActive = primaire;

  // ==========================
  // Ombres (Très diffuses pour moderniser)
  // ==========================

  static const Color ombre = Color.fromRGBO(30, 58, 138, 0.06); // Ombre bleutée premium

  // ==========================
  // Dégradé principal
  // ==========================

  static const LinearGradient degradePrincipal = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      primaireFonce,
      primaire,
    ],
  );

  // ==========================
  // Dégradé Splash Screen
  // ==========================

  static const LinearGradient degradeSplash = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      primaire,
      primaireFonce,
    ],
  );

  // ==========================
  // Dégradé Carte
  // ==========================

  static const LinearGradient degradeCarte = LinearGradient(
    colors: [
      Colors.white,
      primaireClair,
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}