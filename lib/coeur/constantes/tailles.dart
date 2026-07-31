import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

// =======================================================
//
// FICHIER : tailles.dart
// PROJET : TransConnect Cameroun
//
// Dimensions, espacements, rayons et constantes d'animation.
//
// =======================================================

class TaillesApp {
  TaillesApp._();

  // ==========================
  // Espacements
  // ==========================

  static double get espaceTresPetit => 4.w;
  static double get espacePetit => 8.w;
  static double get espaceMoyen => 16.w;
  static double get espaceGrand => 24.w;
  static double get espaceTresGrand => 32.w;
  static double get espaceGeant => 48.w;
  static double get espaceMax => 64.w;

  // ==========================
  // Marges
  // ==========================

  static double get margePage => 20.w;
  static double get margeSection => 24.w;
  static double get margeCarte => 16.w;

  // ==========================
  // Rayon des bordures
  // ==========================

  static double get rayonPetit => 8.r;
  static double get rayonMoyen => 12.r;
  static double get rayonGrand => 16.r;
  static double get rayonTresGrand => 20.r;
  static double get rayonBouton => 30.r;
  static double get rayonCarte => 24.r;
  static double get rayonChamp => 16.r;
  static double get rayonPill => 999.r;

  // ==========================
  // Boutons
  // ==========================

  static double get hauteurBouton => 56.h;
  static double get hauteurBoutonPetit => 44.h;
  static double get largeurBouton => double.infinity;

  // ==========================
  // Champs de saisie
  // ==========================

  static double get hauteurChamp => 56.h;

  // ==========================
  // Icônes
  // ==========================

  static double get iconePetite => 18.w;
  static double get iconeNormale => 24.w;
  static double get iconeGrande => 32.w;
  static double get iconeTresGrande => 48.w;
  static double get iconeGeante => 64.w;
  static double get iconeSplash => 120.w;

  // ==========================
  // Images
  // ==========================

  static double get imagePetite => 80.w;
  static double get imageMoyenne => 140.w;
  static double get imageGrande => 220.w;

  // ==========================
  // Logo
  // ==========================

  static double get logoPetit => 60.w;
  static double get logoMoyen => 100.w;
  static double get logoGrand => 160.w;

  // ==========================
  // Cartes
  // ==========================

  static double get hauteurCarte => 140.h;
  static double get hauteurCarteStatistique => 110.h;
  static double get hauteurCarteTransport => 170.h;

  // ==========================
  // Barre de navigation
  // ==========================

  static double get hauteurBarreNavigation => 70.h;
  static double get hauteurAppBar => 60.h;

  // ==========================
  // Avatar
  // ==========================

  static double get avatarPetit => 40.w;
  static double get avatarMoyen => 60.w;
  static double get avatarGrand => 90.w;

  // ==========================
  // Ombres
  // ==========================

  static double get flouOmbre => 12.r;
  static double get elevation => 4;

  // ==========================
  // Glassmorphism
  // ==========================

  static double get blurGlass => 20;
  static double get blurGlassIntense => 40;
  static double get opacityGlass => 0.72;

  // ==========================
  // Animations (durées en ms)
  // ==========================

  static const int animationRapide = 200;
  static const int animationNormale = 350;
  static const int animationLente = 600;
  static const int animationTresLente = 900;
  static const int animationSplash = 3000;

  // ==========================
  // Courbes d'animation
  // ==========================

  static const Curve courbeRapide = Curves.easeInOut;
  static const Curve courbeNormale = Curves.easeOutCubic;
  static const Curve courbeRebond = Curves.elasticOut;
  static const Curve courbeDeceleration = Curves.decelerate;
  static const Curve courbeBounce = Curves.bounceOut;
  static const Curve courbeSpring = Curves.easeOutBack;
}
