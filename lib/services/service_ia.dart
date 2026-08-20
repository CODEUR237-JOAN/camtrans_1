import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';

final serviceIAProvider = Provider<ServiceIA>((ref) {
  return ServiceIA();
});

class ServiceIA {
  final Dio _dio = Dio();
  final String _baseUrl = "https://api.groq.com/openai/v1/chat/completions";
  
  // Historique local pour la session de chat
  final List<Map<String, String>> _historique = [];

  ServiceIA() {
    _initialiserService();
  }

  void _initialiserService() {
    _historique.clear();
    _historique.add({
      "role": "system",
      "content": "Tu es l'assistant IA officiel de CamTrans, une application de logistique et de transport de marchandises. "
          "Ton rôle est d'aider les clients à estimer les prix, choisir le bon véhicule (moto, voiture, camionnette, camion léger, camion lourd), "
          "estimer les volumes et donner des conseils d'emballage ou de transport. "
          "Sois concis, professionnel, rassurant et formatte tes réponses de manière claire (utilise des listes si nécessaire)."
    });
  }

  /// Envoie un message et retourne un flux de texte pour l'effet "machine à écrire"
  Stream<String> envoyerMessageStream(String prompt, {List<XFile>? fichiersImages}) async* {
    final apiKey = dotenv.env['GROQ_API_KEY'] ?? '';
    if (apiKey.isEmpty) {
      yield "Désolé, l'assistant est indisponible pour le moment (Clé API manquante).";
      return;
    }

    try {
      // Préparation du contenu (Texte + Images en Base64 si présentes)
      List<Map<String, dynamic>> content = [
        {"type": "text", "text": prompt}
      ];

      bool hasImages = fichiersImages != null && fichiersImages.isNotEmpty;

      if (hasImages) {
        for (var file in fichiersImages) {
          final bytes = await file.readAsBytes();
          final base64Image = base64Encode(bytes);
          content.add({
            "type": "image_url",
            "image_url": {"url": "data:image/jpeg;base64,$base64Image"}
          });
        }
      }

      // Ajout du message utilisateur à l'historique (pour le contexte, on ne stocke que le texte)
      _historique.add({"role": "user", "content": prompt});

      final response = await _dio.post(
        _baseUrl,
        data: {
          "model": hasImages ? "meta-llama/llama-4-scout-17b-16e-instruct" : "llama-3.3-70b-versatile",
          "messages": _historique,
          "stream": true,
        },
        options: Options(
          headers: {
            "Authorization": "Bearer $apiKey",
            "Content-Type": "application/json",
          },
          responseType: ResponseType.stream,
        ),
      );

      String completeResponse = "";

      await for (final List<int> chunk in response.data.stream) {
        final lines = utf8.decode(chunk).split('\n');
        for (final line in lines) {
          if (line.startsWith('data: ')) {
            final data = line.substring(6).trim();
            if (data == '[DONE]') break;
            try {
              final json = jsonDecode(data);
              final content = json['choices'][0]['delta']['content'] ?? "";
              if (content.isNotEmpty) {
                completeResponse += content;
                yield content;
              }
            } catch (_) {}
          }
        }
      }

      // Sauvegarde de la réponse de l'IA dans l'historique
      _historique.add({"role": "assistant", "content": completeResponse});

    } catch (e) {
      yield "\n[Erreur de connexion avec Groq. Veuillez réessayer. Détails: $e]";
    }
  }

  /// Estime les détails d'une expédition et renvoie un dictionnaire structuré.
  Future<Map<String, String>> estimerExpedition({
    required String marchandise,
    required String description,
    required String depart,
    required String destination,
    List<XFile>? fichiersImages,
  }) async {
    final apiKey = dotenv.env['GROQ_API_KEY'] ?? '';
    if (apiKey.isEmpty) throw Exception("Clé API manquante");

    final prompt = """
Tu es un expert en logistique pour CamTrans. Estime cette expédition :
- Départ : ${depart.isEmpty ? 'Non précisé' : depart}
- Destination : ${destination.isEmpty ? 'Non précisé' : destination}
- Catégorie : ${marchandise.isEmpty ? 'Non précisé' : marchandise}
- Détails : ${description.isEmpty ? 'Non précisé' : description}

Réponds UNIQUEMENT au format JSON strict avec les clés suivantes :
- "vehicule" : le véhicule idéal (Moto, Voiture, Camionnette, Camion léger, Camion lourd, Camion Plateau).
- "volume" : estimation du volume en m³ (ex: "2.5 m³").
- "prix" : estimation du prix en FCFA (ex: "15 000 FCFA").
- "conseil" : un court conseil de 1 à 2 phrases.

Ne rajoute aucun autre texte, juste l'objet JSON.
""";

    try {
      bool hasImages = fichiersImages != null && fichiersImages.isNotEmpty;
      
      List<Map<String, dynamic>> userContent = [{"type": "text", "text": prompt}];
      
      if (hasImages) {
        for (var file in fichiersImages) {
          final bytes = await file.readAsBytes();
          final base64Image = base64Encode(bytes);
          userContent.add({
            "type": "image_url",
            "image_url": {"url": "data:image/jpeg;base64,$base64Image"}
          });
        }
      }

      final response = await _dio.post(
        _baseUrl,
        data: {
          "model": hasImages ? "meta-llama/llama-4-scout-17b-16e-instruct" : "llama3-70b-8192",
          "messages": [
            {"role": "system", "content": "Tu es un extracteur JSON logistique. Réponds uniquement en JSON."},
            {"role": "user", "content": userContent}
          ],
          "response_format": {"type": "json_object"}
        },
        options: Options(
          headers: {
            "Authorization": "Bearer $apiKey",
            "Content-Type": "application/json",
          },
        ),
      );

      final Map<String, dynamic> data = response.data['choices'][0]['message']['content'] is String 
          ? jsonDecode(response.data['choices'][0]['message']['content'])
          : response.data['choices'][0]['message']['content'];

      return {
        "vehicule": data["vehicule"]?.toString() ?? "Camionnette",
        "volume": data["volume"]?.toString() ?? "Inconnu",
        "prix": data["prix"]?.toString() ?? "Sur devis",
        "conseil": data["conseil"]?.toString() ?? "Emballez soigneusement vos articles.",
      };
    } catch (e) {
      debugPrint("❌ Erreur Groq : $e");
      throw Exception("Impossible d'estimer : $e");
    }
  }

  /// Estime la masse d'un véhicule (pour le service Remorque)
  Future<double> estimerMasseVehicule(String marque, String modele) async {
    final apiKey = dotenv.env['GROQ_API_KEY'] ?? '';
    if (apiKey.isEmpty) throw Exception("Clé API manquante");

    final prompt = """
Tu es un expert automobile. Quel est le poids à vide (masse) moyen en kg pour le véhicule suivant :
Marque : $marque
Modèle : $modele

Réponds UNIQUEMENT au format JSON strict avec la clé :
- "masse_kg" : un nombre entier représentant le poids en kg (ex: 1500).

Ne rajoute aucun autre texte, juste l'objet JSON.
""";

    try {
      final response = await _dio.post(
        _baseUrl,
        data: {
          "model": "llama3-70b-8192",
          "messages": [
            {"role": "system", "content": "Tu es un extracteur JSON. Réponds uniquement en JSON."},
            {"role": "user", "content": prompt}
          ],
          "response_format": {"type": "json_object"}
        },
        options: Options(
          headers: {
            "Authorization": "Bearer $apiKey",
            "Content-Type": "application/json",
          },
        ),
      );

      final Map<String, dynamic> data = response.data['choices'][0]['message']['content'] is String 
          ? jsonDecode(response.data['choices'][0]['message']['content'])
          : response.data['choices'][0]['message']['content'];

      final masseVal = data["masse_kg"];
      if (masseVal is num) {
        return masseVal.toDouble();
      } else if (masseVal is String) {
        return double.tryParse(masseVal.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 1500.0;
      }
      return 1500.0;
    } catch (e) {
      debugPrint("❌ Erreur Groq Masse : $e");
      return 1500.0; // Poids moyen par défaut
    }
  }
}
