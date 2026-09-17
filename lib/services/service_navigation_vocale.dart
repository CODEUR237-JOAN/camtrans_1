import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:latlong2/latlong.dart';
import 'package:update_camtrans/services/service_routage.dart';

final serviceNavigationVocaleProvider = Provider<ServiceNavigationVocale>((ref) {
  return ServiceNavigationVocale();
});

class ServiceNavigationVocale {
  final FlutterTts _tts = FlutterTts();
  
  bool _estMute = false;
  bool _navigationActive = false;
  
  InfoTrajet? _traiterEnCours;
  int _indexEtapeCourante = 0;
  bool _aAnnoncePreAlerte = false;
  bool _aAnnonceAlerteImmediate = false;
  
  final Distance _distanceTool = const Distance();
  
  ServiceNavigationVocale() {
    _initialiserTTS();
  }
  
  Future<void> _initialiserTTS() async {
    await _tts.setLanguage("fr-FR");
    await _tts.setSpeechRate(0.5);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
  }

  void basculerMute() {
    _estMute = !_estMute;
    if (_estMute) {
      _tts.stop();
    } else {
      _parler("Guidage vocal activé.");
    }
  }
  
  bool get estMute => _estMute;

  void demarrerNavigation(InfoTrajet trajet) {
    _traiterEnCours = trajet;
    _navigationActive = true;
    _indexEtapeCourante = 0;
    _aAnnoncePreAlerte = false;
    _aAnnonceAlerteImmediate = false;
    
    // Message d'accueil humanisé
    final messages = [
      "En route ! Conduisez prudemment.",
      "C'est parti. Suivez l'itinéraire en toute sécurité.",
      "L'itinéraire est prêt. Bonne route !"
    ];
    final msg = messages[Random().nextInt(messages.length)];
    
    _parler(msg);
  }

  void arreterNavigation() {
    _navigationActive = false;
    _traiterEnCours = null;
    _tts.stop();
  }

  void mettreAJourPosition(LatLng positionActuelle) {
    if (!_navigationActive || _traiterEnCours == null || _estMute) return;
    
    final etapes = _traiterEnCours!.etapes;
    if (_indexEtapeCourante >= etapes.length) {
      return; // Arrivé ou plus d'étapes
    }
    
    final etapeCourante = etapes[_indexEtapeCourante];
    final distanceMetres = _distanceTool.as(LengthUnit.Meter, positionActuelle, etapeCourante.coordonnee);
    
    // Si on est à l'étape initiale (départ), on la passe rapidement
    if (etapeCourante.type == 'depart' && distanceMetres < 50) {
      _indexEtapeCourante++;
      return;
    }

    // Logique d'annonce (300m = pré-alerte, 50m = alerte immédiate)
    if (distanceMetres <= 300 && distanceMetres > 100 && !_aAnnoncePreAlerte) {
      _aAnnoncePreAlerte = true;
      String phrase = _humaniserInstruction(etapeCourante, estPreAlerte: true);
      _parler("Dans environ ${((distanceMetres/50).round()*50)} mètres, $phrase");
    } 
    else if (distanceMetres <= 60 && !_aAnnonceAlerteImmediate) {
      _aAnnonceAlerteImmediate = true;
      String phrase = _humaniserInstruction(etapeCourante, estPreAlerte: false);
      _parler("Maintenant, $phrase");
    }
    
    // Passer à l'étape suivante quand on est très proche (passé le point)
    if (distanceMetres <= 25) {
      _indexEtapeCourante++;
      _aAnnoncePreAlerte = false;
      _aAnnonceAlerteImmediate = false;
      
      // Si c'est la dernière étape (arrivée)
      if (_indexEtapeCourante >= etapes.length || 
          (_indexEtapeCourante == etapes.length - 1 && etapes.last.type == 'arrive')) {
        _parler("Vous êtes arrivé à destination. Bon travail !");
        arreterNavigation();
      }
    }
  }

  String _humaniserInstruction(EtapeTrajet etape, {required bool estPreAlerte}) {
    String mod = etape.modifier.toLowerCase();
    String type = etape.type.toLowerCase();
    
    if (type == 'arrive') {
      return estPreAlerte ? "préparez-vous à arriver à destination" : "vous êtes arrivé à destination";
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
      return estPreAlerte ? "préparez-vous à continuer tout droit" : "continuez tout droit";
    } else if (mod.contains("uturn")) {
      return estPreAlerte ? "préparez-vous à faire demi-tour" : "faites demi-tour";
    } else {
      // Rabattement sur le texte brut d'OSRM (qui est en FR grâce à language=fr)
      if (etape.instruction.isNotEmpty) {
        return etape.instruction.toLowerCase();
      }
      return "continuez";
    }

    String rue = etape.nomRue.isNotEmpty ? " sur ${etape.nomRue}" : "";
    
    if (estPreAlerte) {
      return "préparez-vous à tourner $direction$rue";
    } else {
      return "$action $direction$rue";
    }
  }

  Future<void> _parler(String texte) async {
    if (_estMute) return;
    try {
      await _tts.speak(texte);
    } catch (e) {
      debugPrint("Erreur TTS: $e");
    }
  }
}
