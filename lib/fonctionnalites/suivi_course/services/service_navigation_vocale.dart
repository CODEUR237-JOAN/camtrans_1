import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:update_camtrans/services/service_routage.dart';

final serviceNavigationVocaleProvider = Provider<ServiceNavigationVocale>((ref) {
  return ServiceNavigationVocale();
});

class ServiceNavigationVocale {
  final FlutterTts _flutterTts = FlutterTts();
  bool _isInit = false;

  Future<void> initialiser() async {
    if (_isInit) return;
    await _flutterTts.setLanguage("fr-FR");
    await _flutterTts.setSpeechRate(0.5); // Vitesse modérée pour la clarté
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
    _isInit = true;
  }

  Future<void> annoncer(String texte, {bool isVoixActive = true}) async {
    if (!isVoixActive) return;
    await initialiser();
    await _flutterTts.speak(texte);
  }

  Future<void> stop() async {
    await _flutterTts.stop();
  }

  String humaniserInstruction(EtapeTrajet etape, {required bool estPreAlerte}) {
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
}
