import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

final serviceIAProvider = Provider<ServiceIA>((ref) {
  return ServiceIA();
});

class ServiceIA {
  GenerativeModel? _modele;
  ChatSession? _chatSession;

  ServiceIA() {
    _initialiserModele();
  }

  void _initialiserModele() {
    final apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
    if (apiKey.isEmpty) {
      // Le service fonctionnera en mode "dégradé" si la clé manque (ou lancera une erreur plus tard)
      return;
    }

    _modele = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: apiKey,
      systemInstruction: Content.system(
        "Tu es l'assistant IA officiel de CamTrans, une application de logistique et de transport de marchandises. "
        "Ton rôle est d'aider les clients à estimer les prix, choisir le bon véhicule (moto, voiture, camionnette, camion léger, camion lourd), "
        "estimer les volumes et donner des conseils d'emballage ou de transport. "
        "Sois concis, professionnel, rassurant et formatte tes réponses de manière claire (utilise des listes si nécessaire).",
      ),
    );
    _chatSession = _modele?.startChat();
  }

  /// Envoie un message et retourne un flux de texte pour l'effet "machine à écrire" (streaming)
  Stream<String> envoyerMessageStream(String prompt, {List<String>? cheminsImages}) async* {
    if (_modele == null || _chatSession == null) {
      // Tentative de réinitialisation si la clé a été ajoutée entre temps
      _initialiserModele();
      if (_modele == null) {
        yield "Désolé, l'assistant est indisponible pour le moment (Clé API manquante).";
        return;
      }
    }

    try {
      final List<Part> parts = [TextPart(prompt)];

      if (cheminsImages != null && cheminsImages.isNotEmpty) {
        for (final chemin in cheminsImages) {
          final file = File(chemin);
          if (file.existsSync()) {
            final bytes = await file.readAsBytes();
            parts.add(DataPart('image/jpeg', bytes));
          }
        }
      }

      final content = Content.multi(parts);
      
      // On utilise le chatSession pour garder l'historique
      final responseStream = _chatSession!.sendMessageStream(content);
      
      await for (final chunk in responseStream) {
        if (chunk.text != null) {
          yield chunk.text!;
        }
      }
    } catch (e) {
      yield "\n[Erreur de connexion avec l'IA. Veuillez réessayer.]";
    }
  }
}
