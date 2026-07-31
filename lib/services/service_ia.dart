import 'dart:io';
import 'dart:convert';
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
      model: 'gemini-2.0-flash',
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
      yield "\n[Erreur de connexion avec l'IA. Veuillez réessayer. Détails: $e]";
    }
  }

  /// Estime les détails d'une expédition et renvoie un dictionnaire structuré.
  Future<Map<String, String>> estimerExpedition({
    required String marchandise,
    required String description,
    required String depart,
    required String destination,
    List<String>? cheminsImages,
  }) async {
    if (_modele == null) {
      _initialiserModele();
      if (_modele == null) {
        throw Exception("Clé API manquante");
      }
    }

    final prompt = """
Tu es un expert en logistique pour CamTrans. Estime cette expédition :
- Départ : ${depart.isEmpty ? 'Non précisé' : depart}
- Destination : ${destination.isEmpty ? 'Non précisé' : destination}
- Catégorie : ${marchandise.isEmpty ? 'Non précisé' : marchandise}
- Détails du colis : ${description.isEmpty ? 'Non précisé' : description}
- Photos fournies : ${cheminsImages != null && cheminsImages.isNotEmpty ? 'Oui (Analyse attentivement les images pour déduire le volume et le type de colis)' : 'Non'}

Réponds UNIQUEMENT au format JSON strict avec les clés suivantes :
- "vehicule" : le véhicule idéal parmi (Moto, Voiture, Camionnette, Camion léger, Camion lourd).
- "volume" : estimation du volume en m³ (ex: "2.5 m³") basé sur les images et la description.
- "prix" : estimation du prix en FCFA selon la distance et le véhicule (ex: "15 000 FCFA", ou "Sur devis" si les lieux manquent).
- "conseil" : un court conseil de 1 à 2 phrases pour l'emballage ou le transport de ce colis spécifique.

Ne rajoute aucun autre texte, pas de blocs markdown, juste l'objet JSON.
""";

    try {
      final List<Part> parts = [TextPart(prompt)];

      if (cheminsImages != null && cheminsImages.isNotEmpty) {
        for (var chemin in cheminsImages) {
          final bytes = await File(chemin).readAsBytes();
          String mimeType = 'image/jpeg';
          if (chemin.toLowerCase().endsWith('.png')) mimeType = 'image/png';
          if (chemin.toLowerCase().endsWith('.webp')) mimeType = 'image/webp';
          parts.add(DataPart(mimeType, bytes));
        }
      }

      final response = await _modele!.generateContent([Content.multi(parts)]);
      final texte = response.text ?? "";
      // Nettoyer d'éventuels backticks markdown
      final jsonTexte = texte.replaceAll("```json", "").replaceAll("```", "").trim();
      
      final Map<String, dynamic> data = json.decode(jsonTexte);
      return {
        "vehicule": data["vehicule"]?.toString() ?? "Camionnette",
        "volume": data["volume"]?.toString() ?? "Inconnu",
        "prix": data["prix"]?.toString() ?? "Sur devis",
        "conseil": data["conseil"]?.toString() ?? "Emballez soigneusement vos articles.",
      };
    } catch (e) {
      throw Exception("Impossible d'estimer avec l'IA : $e");
    }
  }
}
