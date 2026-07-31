import 'package:flutter/material.dart';

// =======================================================
//
// FICHIER : couleurs.dart
// PROJET : CamTrans
//
// Palette de couleurs Premium
// Inspirée de Stripe, Apple, Uber
//
// =======================================================

class CouleursApp {
  CouleursApp._();

  // ==========================
  // Couleurs principales
  // ==========================

  static const Color primaire = Color(0xFF2697FF);      // Bleu principal (Stripe style)
  static const Color primaireFonce = Color(0xFF1B6EC2);
  static const Color primaireClair = Color(0xFFE5F1FF); // Très léger
  static const Color primaireNeon = Color(0xFF818CF8);   // Indigo néon

  static const Color secondaire = Color(0xFF1E3A8A);    // Bleu nuit profond
  static const Color secondaireClair = Color(0xFFD6E0FF);
  static const Color secondaireFonce = Color(0xFF152A63);

  static const Color accent = Color(0xFF00C896);        // Émeraude énergique
  static const Color accentOrange = Color(0xFFF97316);   // Orange énergique
  static const Color accentRose = Color(0xFFEC4899);     // Rose vibrant

  // ==========================
  // Couleurs de fond
  // ==========================

  static const Color fond = Color(0xFFF8FAFC);           // Slate 50
  static const Color fondSecondaire = Color(0xFFF1F5F9); // Slate 100
  static const Color fondSombre = Color(0xFF0F172A);     // Slate 900
  static const Color fondSombreSecondaire = Color(0xFF1E293B);

  // ==========================
  // Cartes & Surfaces
  // ==========================

  static const Color carte = Colors.white;
  static const Color surface = Colors.white;
  static const Color carteSombre = Color(0xFF1E293B);

  // ==========================
  // Texte
  // ==========================

  static const Color textePrincipal = Color(0xFF0F172A);
  static const Color texteSecondaire = Color(0xFF64748B);
  static const Color texteTertiaire = Color(0xFF94A3B8);
  static const Color texteBlanc = Colors.white;
  
  static const Color texteSombrePrincipal = Color(0xFFF8FAFC);
  static const Color texteSombreSecondaire = Color(0xFF94A3B8);

  // ==========================
  // États sémantiques
  // ==========================

  static const Color succes = Color(0xFF22C55E);
  static const Color succesClair = Color(0xFFDCFCE7);
  
  static const Color erreur = Color(0xFFEF4444);
  static const Color erreurClair = Color(0xFFFEE2E2);
  
  static const Color avertissement = Color(0xFFF59E0B);  // Ambre
  static const Color avertissementClair = Color(0xFFFEF3C7);
  
  static const Color information = Color(0xFF3B82F6);    // Bleu
  static const Color informationClair = Color(0xFFDBEAFE);

  // ==========================
  // Bordures et Lignes
  // ==========================

  static const Color bordure = Color(0xFFE2E8F0);        // Slate 200
  static const Color bordureActive = primaire;
  static const Color bordureSombre = Color(0xFF334155);

  // ==========================
  // Icônes
  // ==========================

  static const Color icone = Color(0xFF64748B);
  static const Color iconeActive = primaire;
  static const Color iconeInactive = Color(0xFFCBD5E1);

  // ==========================
  // Ombres sophistiquées
  // ==========================

  static const Color ombre = Color.fromRGBO(15, 23, 42, 0.04);
  static const Color ombreMedium = Color.fromRGBO(15, 23, 42, 0.08);

  // ==========================
  // Glassmorphism
  // ==========================

  static const Color glassBlanc = Color.fromRGBO(255, 255, 255, 0.80);
  static const Color glassBlancBorder = Color.fromRGBO(255, 255, 255, 0.50);
  static const Color glassNoir = Color.fromRGBO(15, 23, 42, 0.75);
  static const Color glassNoirBorder = Color.fromRGBO(255, 255, 255, 0.10);

  // ==========================
  // Dégradés Modernes
  // ==========================

  static const LinearGradient degradePrincipal = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF2697FF), Color(0xFF0EA5E9)],
  );

  static const LinearGradient degradeSplash = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF2697FF), Color(0xFF1E3A8A)],
  );

  static const LinearGradient degradeErreur = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFEF4444), Color(0xFFF87171)],
  );

  static const LinearGradient degradeNeon = LinearGradient(
    colors: [Color(0xFF818CF8), Color(0xFF06B6D4)],
  );

  // ==========================
  // Méthodes utilitaires
  // ==========================

  static BoxShadow ombrePersonnalisee({
    Color? couleur,
    double blurRadius = 24,
    double spreadRadius = 0,
    Offset offset = const Offset(0, 10),
  }) {
    return BoxShadow(
      color: (couleur ?? ombre).withValues(alpha: 0.15),
      blurRadius: blurRadius,
      spreadRadius: spreadRadius,
      offset: offset,
    );
  }

  static BoxShadow ombreNeon({
    Color couleur = primaireNeon,
    double blurRadius = 16,
  }) {
    return BoxShadow(
      color: couleur.withValues(alpha: 0.35),
      blurRadius: blurRadius,
      spreadRadius: 2,
    );
  }
}
