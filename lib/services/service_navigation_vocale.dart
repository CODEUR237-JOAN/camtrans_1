import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import 'package:update_camtrans/services/service_routage.dart';

// =====================================================================
// SERVICE : Navigation vocale "Turn-by-Turn" premium (CamTrans)
//
// Guidage vocal fluide et intelligent pour les transporteurs, de niveau
// Yango / Google Maps. Toute la logique est isolée ici (MVVM) : à
// injecter dans les ViewModels, aucune dépendance à l'UI de la carte.
//
// Fonctionnalités :
//   1. Configuration avancée du TTS (fr-FR, débit/hauteur naturels,
//      audio focus / ducking des autres apps, interruption prioritaire).
//   2. Déclenchement spatial par paliers (500 m / 100 m / 20 m) avec
//      anti-spam (un palier annoncé une seule fois par étape).
//   3. Recalcul d'itinéraire (rerouting) annoncé calmement.
//   4. Humanisation / nettoyage des instructions (suppression du HTML).
//
// Rétro-compatibilité : conserve l'API utilisée par suivi_provider
// (demarrerNavigation / mettreAJourPosition / arreterNavigation /
// basculerMute / estMute).
// =====================================================================

/// Palier de distance avant une manœuvre.
enum PalierAnnonce { loin, approche, immediat }

final serviceNavigationVocaleProvider =
    ChangeNotifierProvider<ServiceNavigationVocale>((ref) {
  return ServiceNavigationVocale();
});

class ServiceNavigationVocale extends ChangeNotifier {
  final FlutterTts _tts = FlutterTts();
  final Distance _distanceTool = const Distance();

  // --- Paliers de déclenchement (mètres) ---
  static const double _seuilLoin = 500;
  static const double _seuilApproche = 100;
  static const double _seuilImmediat = 20;

  // Bandes de tolérance : évitent de rater un palier si le GPS "saute".
  static const double _bandeLoinMin = 150; // au-dessus = encore trop loin
  static const double _bandeApprocheMin = 35;

  // --- État ---
  bool _estMute = false;
  bool _navigationActive = false;
  bool _ttsPret = false;

  InfoTrajet? _trajetEnCours;
  int _indexEtapeCourante = 0;

  // Mémorisation des annonces déjà faites pour l'étape courante (anti-spam).
  bool _aAnnonceLoin = false;
  bool _aAnnonceApproche = false;
  bool _aAnnonceImmediat = false;

  // Identité de l'étape suivie via l'API externe onLocationUpdate(),
  // pour réinitialiser les paliers au changement d'étape.
  String? _cleEtapeSuivie;

  // Anti-spam du recalcul.
  DateTime? _dernierRerouting;

  ServiceNavigationVocale() {
    _initialiserTTS();
  }

  bool get estMute => _estMute;
  bool get navigationActive => _navigationActive;

  // ------------------------------------------------------------------
  // 1. CONFIGURATION AVANCÉE DU TTS
  // ------------------------------------------------------------------
  Future<void> _initialiserTTS() async {
    try {
      await _tts.setLanguage('fr-FR');
      // Débit légèrement ralenti pour la clarté en conduite.
      await _tts.setSpeechRate(0.46);
      // Hauteur proche du naturel (évite l'effet "robot").
      await _tts.setPitch(1.05);
      await _tts.setVolume(1.0);

      // Attendre la fin de chaque énoncé (séquencement fiable).
      await _tts.awaitSpeakCompletion(true);

      // QUEUE_FLUSH : une nouvelle annonce interrompt celle en cours
      // (les consignes de navigation priment toujours sur l'ancienne).
      try {
        await _tts.setQueueMode(0);
      } catch (_) {/* non supporté sur certaines plateformes */}

      // Audio Focus / Ducking : baisse le volume des autres apps
      // (musique, radio) pendant l'annonce, puis le restaure. iOS.
      try {
        await _tts.setIosAudioCategory(
          IosTextToSpeechAudioCategory.playback,
          [
            IosTextToSpeechAudioCategoryOptions.duckOthers,
            IosTextToSpeechAudioCategoryOptions.mixWithOthers,
          ],
          IosTextToSpeechAudioMode.voicePrompt,
        );
      } catch (_) {/* iOS uniquement */}

      _ttsPret = true;
    } catch (e) {/* erreur ignorée */}
  }

  // ------------------------------------------------------------------
  // CONTRÔLE GÉNÉRAL
  // ------------------------------------------------------------------
  void basculerMute() {
    _estMute = !_estMute;
    notifyListeners();
    if (_estMute) {
      _tts.stop();
    } else {
      _parler('Guidage vocal activé.');
    }
  }

  void demarrerNavigation(InfoTrajet trajet, {required bool versClient}) {
    _trajetEnCours = trajet;
    _navigationActive = true;
    _indexEtapeCourante = 0;
    _cleEtapeSuivie = null;
    _reinitialiserPaliers();

    _parler(
      versClient
          ? 'Navigation démarrée. Direction : récupération du client.'
          : 'Navigation démarrée. Direction : livraison à destination.',
      prioritaire: true,
    );
  }

  void arreterNavigation() {
    _navigationActive = false;
    _trajetEnCours = null;
    _cleEtapeSuivie = null;
    _tts.stop();
    notifyListeners();
  }

  /// Remplace l'itinéraire suivi (après un recalcul) SANS ré-annoncer le
  /// démarrage : réinitialise l'index d'étape et les paliers d'annonce.
  /// À appeler juste après [announceRerouting].
  void rafraichirItineraire(InfoTrajet trajet) {
    _trajetEnCours = trajet;
    _navigationActive = true;
    _indexEtapeCourante = 0;
    _cleEtapeSuivie = null;
    _reinitialiserPaliers();
  }

  // ------------------------------------------------------------------
  // 2a. API INTERNE : avance automatique le long des étapes du trajet
  //     (conservée pour suivi_provider — reçoit une LatLng).
  // ------------------------------------------------------------------
  void mettreAJourPosition(LatLng positionActuelle) {
    if (!_navigationActive || _trajetEnCours == null || _estMute) return;

    final etapes = _trajetEnCours!.etapes;
    if (_indexEtapeCourante >= etapes.length) return;

    final etape = etapes[_indexEtapeCourante];
    final distance =
        _distanceTool.as(LengthUnit.Meter, positionActuelle, etape.coordonnee);

    // Les points de départ sont passés silencieusement.
    if (etape.type == 'depart' && distance < 50) {
      _passerEtapeSuivante();
      return;
    }

    _declencherPaliers(distance, etape);

    // Manœuvre franchie → étape suivante.
    if (distance <= _seuilImmediat) {
      final etaitDerniere =
          _indexEtapeCourante >= etapes.length - 1 || etape.type == 'arrive';
      _passerEtapeSuivante();
      if (etaitDerniere) {
        _parler('Vous êtes arrivé à destination. Bonne fin de course !',
            prioritaire: true);
        arreterNavigation();
      }
    }
  }

  // ------------------------------------------------------------------
  // 2b. API EXTERNE : déclenchement spatial pour une étape donnée.
  //     Signature demandée : onLocationUpdate(Position, étape suivante).
  // ------------------------------------------------------------------
  void onLocationUpdate(Position currentPosition, EtapeTrajet nextStep) {
    if (!_navigationActive || _estMute) return;

    final cle =
        '${nextStep.coordonnee.latitude.toStringAsFixed(5)},${nextStep.coordonnee.longitude.toStringAsFixed(5)}';
    // Nouvelle étape → on réinitialise les marqueurs d'annonce.
    if (cle != _cleEtapeSuivie) {
      _cleEtapeSuivie = cle;
      _reinitialiserPaliers();
    }

    final distance = _distanceTool.as(
      LengthUnit.Meter,
      LatLng(currentPosition.latitude, currentPosition.longitude),
      nextStep.coordonnee,
    );

    _declencherPaliers(distance, nextStep);
  }

  // ------------------------------------------------------------------
  // Cœur du système de paliers (anti-spam).
  // ------------------------------------------------------------------
  void _declencherPaliers(double distance, EtapeTrajet etape) {
    // Palier LOIN (~500 m) : annonce informative.
    if (!_aAnnonceLoin && distance <= _seuilLoin && distance > _bandeLoinMin) {
      _aAnnonceLoin = true;
      _parler(
          'Dans ${_arrondirDistance(distance)} mètres, ${_instruction(etape, PalierAnnonce.loin)}.');
      return;
    }

    // Palier APPROCHE (~100 m) : préparation. Prioritaire.
    if (!_aAnnonceApproche &&
        distance <= _seuilApproche &&
        distance > _bandeApprocheMin) {
      _aAnnonceApproche = true;
      _parler('Préparez-vous à ${_instruction(etape, PalierAnnonce.approche)}.',
          prioritaire: true);
      return;
    }

    // Palier IMMÉDIAT (~20 m) : exécution. Prioritaire.
    if (!_aAnnonceImmediat && distance <= _seuilImmediat) {
      _aAnnonceImmediat = true;
      _parler(_instruction(etape, PalierAnnonce.immediat), prioritaire: true);
    }
  }

  void _passerEtapeSuivante() {
    _indexEtapeCourante++;
    _reinitialiserPaliers();
  }

  void _reinitialiserPaliers() {
    _aAnnonceLoin = false;
    _aAnnonceApproche = false;
    _aAnnonceImmediat = false;
  }

  /// Arrondit à la dizaine (ex: 480 → 480, 437 → 440) pour un rendu naturel.
  int _arrondirDistance(double d) {
    if (d >= 100) return (d / 50).round() * 50; // pas de 50 m
    return math.max(10, (d / 10).round() * 10); // pas de 10 m
  }

  // ------------------------------------------------------------------
  // 3. RECALCUL D'ITINÉRAIRE
  // ------------------------------------------------------------------
  Future<void> announceRerouting() async {
    if (_estMute) return;
    // Anti-spam : au plus une annonce de recalcul toutes les 8 s.
    final now = DateTime.now();
    if (_dernierRerouting != null &&
        now.difference(_dernierRerouting!).inSeconds < 8) {
      return;
    }
    _dernierRerouting = now;

    // L'itinéraire change : les paliers de l'ancienne étape n'ont plus de sens.
    _reinitialiserPaliers();
    _cleEtapeSuivie = null;

    await _parler('Recalcul de l\'itinéraire en cours.', prioritaire: true);
  }

  // ------------------------------------------------------------------
  // 4. HUMANISATION DES INSTRUCTIONS
  // ------------------------------------------------------------------

  /// Nettoie une instruction brute (Google Directions / OSRM) : supprime
  /// les balises HTML (`<b>`, `<div>`…) et les entités, pour ne jamais
  /// faire lire de code au moteur vocal.
  String nettoyerInstruction(String brut) {
    if (brut.isEmpty) return brut;
    var t = brut.replaceAll(RegExp(r'<[^>]*>'), ' '); // balises
    t = t
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', ' et ')
        .replaceAll(RegExp(r'&[a-zA-Z]+;'), ' ');
    t = t.replaceAll(RegExp(r'\s+'), ' ').trim();
    return t;
  }

  /// Construit la phrase de manœuvre adaptée au palier.
  String _instruction(EtapeTrajet etape, PalierAnnonce palier) {
    final type = etape.type.toLowerCase();
    final mod = etape.modifier.toLowerCase();

    // Arrivée.
    if (type == 'arrive') {
      switch (palier) {
        case PalierAnnonce.loin:
          return 'vous approchez de votre destination';
        case PalierAnnonce.approche:
          return 'arriver à destination';
        case PalierAnnonce.immediat:
          return 'Vous êtes arrivé à destination';
      }
    }

    // Tout droit.
    if (mod.contains('straight') || type == 'continue') {
      switch (palier) {
        case PalierAnnonce.loin:
          return 'continuez tout droit';
        case PalierAnnonce.approche:
          return 'continuer tout droit';
        case PalierAnnonce.immediat:
          return 'Continuez tout droit';
      }
    }

    // Demi-tour.
    if (mod.contains('uturn')) {
      switch (palier) {
        case PalierAnnonce.loin:
          return 'faites demi-tour';
        case PalierAnnonce.approche:
          return 'faire demi-tour';
        case PalierAnnonce.immediat:
          return 'Faites demi-tour maintenant';
      }
    }

    // Tourner à gauche / droite.
    String? direction;
    if (mod.contains('left')) direction = 'à gauche';
    if (mod.contains('right')) direction = 'à droite';

    if (direction != null) {
      final nuance = mod.contains('slight')
          ? 'légèrement '
          : (mod.contains('sharp') ? 'franchement ' : '');
      final rue = etape.nomRue.isNotEmpty
          ? ' sur ${nettoyerInstruction(etape.nomRue)}'
          : '';
      switch (palier) {
        case PalierAnnonce.loin:
          return 'tournez $nuance$direction$rue';
        case PalierAnnonce.approche:
          return 'tourner $nuance$direction$rue';
        case PalierAnnonce.immediat:
          return 'Tournez $nuance$direction$rue maintenant';
      }
    }

    // Repli : on lit l'instruction brute nettoyée (OSRM est en français).
    final brut = nettoyerInstruction(etape.instruction);
    if (brut.isNotEmpty) return brut;
    return palier == PalierAnnonce.immediat ? 'Continuez' : 'continuez';
  }

  // ------------------------------------------------------------------
  // MOTEUR VOCAL
  // ------------------------------------------------------------------
  Future<void> _parler(String texte, {bool prioritaire = false}) async {
    if (_estMute) return;
    if (!_ttsPret) await _initialiserTTS();

    final propre = nettoyerInstruction(texte);
    if (propre.isEmpty) return;

    try {
      // Une annonce prioritaire coupe immédiatement l'énoncé en cours.
      if (prioritaire) {
        await _tts.stop();
      }
      await _tts.speak(propre);
    } catch (e) {/* erreur ignorée */}
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  // ------------------------------------------------------------------
  // 5. RÉTRO-COMPATIBILITÉ AVEC L'ANCIEN SERVICE
  // ------------------------------------------------------------------
  Future<void> annoncer(String texte, {bool isVoixActive = true}) async {
    if (!isVoixActive) return;
    await _parler(texte);
  }

  void stop() {
    _tts.stop();
  }

  String humaniserInstruction(EtapeTrajet etape, {required bool estPreAlerte}) {
    String mod = etape.modifier.toLowerCase();
    String type = etape.type.toLowerCase();

    if (type == 'arrive') {
      return estPreAlerte
          ? "préparez-vous à arriver à destination"
          : "vous êtes arrivé à destination";
    }

    String action = "tournez";

    if (mod.contains("slight")) {
      action = "tournez légèrement";
    } else if (mod.contains("sharp")) {
      action = "tournez serré";
    }

    String direction = "";
    if (mod.contains("left")) {
      direction = "à gauche";
    } else if (mod.contains("right")) {
      direction = "à droite";
    } else if (mod.contains("straight")) {
      return estPreAlerte
          ? "préparez-vous à continuer tout droit"
          : "continuez tout droit";
    } else if (mod.contains("uturn")) {
      return estPreAlerte
          ? "préparez-vous à faire demi-tour"
          : "faites demi-tour";
    } else {
      if (etape.instruction.isNotEmpty) {
        return nettoyerInstruction(etape.instruction).toLowerCase();
      }
      return "continuez";
    }

    String rue = etape.nomRue.isNotEmpty
        ? " sur ${nettoyerInstruction(etape.nomRue)}"
        : "";

    if (estPreAlerte) {
      return "préparez-vous à tourner $direction$rue";
    } else {
      return "$action $direction$rue";
    }
  }
}
