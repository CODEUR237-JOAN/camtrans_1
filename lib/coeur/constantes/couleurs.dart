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
  // Couleurs principales
  // ==========================

  static const Color primaire = Color(0xFF4DA6FF);
  static const Color primaireFonce = Color(0xFF1D3557);
  static const Color primaireClair = Color(0xFFEAF5FF);

  // ==========================
  // Couleurs secondaires
  // ==========================

  static const Color secondaire = Color(0xFF00B4D8);
  static const Color secondaireClair = Color(0xFF90E0EF);

  // ==========================
  // Couleurs de fond
  // ==========================

  static const Color fond = Color(0xFFF8FAFC);
  static const Color fondSecondaire = Color(0xFFF1F5F9);

  // ==========================
  // Cartes
  // ==========================

  static const Color carte = Colors.white;
  static const Color carteSecondaire = Color(0xFFFDFDFD);

  // ==========================
  // Texte
  // ==========================

  static const Color textePrincipal = Color(0xFF1E293B);
  static const Color texteSecondaire = Color(0xFF64748B);
  static const Color texteBlanc = Colors.white;

  // ==========================
  // Boutons
  // ==========================

  static const Color boutonPrincipal = primaire;
  static const Color boutonSecondaire = secondaire;

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
  // Ombres
  // ==========================

  static const Color ombre = Color.fromRGBO(15, 23, 42, 0.08);

  // ==========================
  // Dégradé principal
  // ==========================

  static const LinearGradient degradePrincipal = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      primaire,
      secondaire,
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