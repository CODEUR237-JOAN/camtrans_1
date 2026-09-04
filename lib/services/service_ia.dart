import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

// ============================================================
// FOURNISSEUR RIVERPOD
// Une seule instance du service est créée pour toute l'application.
// ============================================================
final serviceIAProvider = Provider<ServiceIA>((ref) {
  return ServiceIA();
});

// ============================================================
// SERVICE D'INTELLIGENCE ARTIFICIELLE - CamTrans
//
// Ce service est le point d'entrée unique pour toutes les
// communications avec Google Gemini. Il gère :
//   - Le chat en streaming (effet machine à écrire)
//   - L'estimation logistique (véhicule, volume, prix)
//   - L'estimation de la masse d'un véhicule (remorquage)
//   - L'analyse de commandes vocales
//
// Modèle utilisé : gemini-3.1-flash-lite
// Ce modèle est confirmé disponible et fonctionnel sur le
// plan sans frais de Google AI Studio.
// ============================================================
class ServiceIA {
  // Nombre maximal de tentatives en cas d'échec réseau transitoire
  static const int _maxTentatives = 3;

  // Délai d'attente entre deux tentatives (augmente à chaque essai)
  static const Duration _delaiEntreTentatives = Duration(seconds: 2);

  // Nom du modèle Google Gemini utilisé (confirmé actif sur ce compte)
  static const String _nomModele = 'gemini-3.1-flash-lite';

  // Historique de la conversation pour l'assistant chat (format Gemini)
  final List<Content> _historique = [];

  ServiceIA() {
    _historique.clear();
  }

  // ----------------------------------------------------------
  // MÉTHODE INTERNE : Obtenir une instance du modèle Gemini
  //
  // Paramètre [modeJson] : si true, force les réponses en JSON.
  // Paramètre [contexteSysteme] : instruction de comportement
  //   envoyée au modèle avant chaque conversation.
  // ----------------------------------------------------------
  GenerativeModel _getModele({
    bool modeJson = false,
    String? contexteSysteme,
  }) {
    final apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
    if (apiKey.isEmpty) {
      throw Exception(
        "La clé GEMINI_API_KEY est absente du fichier .env. "
        "Veuillez l'ajouter pour activer l'IA.",
      );
    }

    return GenerativeModel(
      model: _nomModele,
      apiKey: apiKey,
      // En mode JSON, on force une sortie JSON pure (pas de texte autour)
      generationConfig: modeJson
          ? GenerationConfig(responseMimeType: 'application/json')
          : GenerationConfig(temperature: 0.3),
      // L'instruction système conditionne le comportement du modèle
      systemInstruction: contexteSysteme != null
          ? Content.system(contexteSysteme)
          : null,
    );
  }

  // ----------------------------------------------------------
  // MÉTHODE INTERNE : Extraire un JSON depuis une réponse texte
  //
  // Certains modèles entourent le JSON de texte ou de backticks.
  // Cette méthode extrait proprement l'objet JSON pur, même si
  // la réponse contient des blocs ```json ... ```.
  // ----------------------------------------------------------
  Map<String, dynamic>? _extraireJson(String? texte) {
    if (texte == null || texte.isEmpty) return null;

    // Tentative directe : si le texte est déjà un JSON valide
    try {
      return jsonDecode(texte) as Map<String, dynamic>;
    } catch (_) {}

    // Recherche d'un bloc JSON entouré de backticks (```json ... ```)
    final regexBloc = RegExp(r'```(?:json)?\s*([\s\S]*?)```');
    final matchBloc = regexBloc.firstMatch(texte);
    if (matchBloc != null) {
      try {
        return jsonDecode(matchBloc.group(1)!) as Map<String, dynamic>;
      } catch (_) {}
    }

    // Recherche du premier objet JSON dans le texte brut
    final regexObjet = RegExp(r'\{[\s\S]*\}');
    final matchObjet = regexObjet.firstMatch(texte);
    if (matchObjet != null) {
      try {
        return jsonDecode(matchObjet.group(0)!) as Map<String, dynamic>;
      } catch (_) {}
    }

    return null;
  }

  // ----------------------------------------------------------
  // MÉTHODE INTERNE : Appel JSON avec réessais automatiques
  //
  // Envoie un prompt au modèle et s'attend à recevoir un JSON.
  // En cas d'échec réseau (erreur temporaire), réessaie jusqu'à
  // [_maxTentatives] fois avec un délai croissant.
  // ----------------------------------------------------------
  Future<Map<String, dynamic>> _appelJsonAvecReessai({
    required List<Content> contenu,
    required String contexteSysteme,
    required Map<String, dynamic> reponseParDefaut,
  }) async {
    final modele = _getModele(modeJson: true, contexteSysteme: contexteSysteme);

    for (int tentative = 1; tentative <= _maxTentatives; tentative++) {
      try {
        final reponse = await modele.generateContent(contenu);
        final data = _extraireJson(reponse.text);
        if (data != null) return data;

        // Si le JSON est invalide, on réessaie
        debugPrint("[IA] Tentative $tentative : réponse non JSON reçue. Nouvelle tentative...");
      } catch (e) {
        debugPrint("[IA] Tentative $tentative échouée : $e");
        if (tentative == _maxTentatives) {
          // Toutes les tentatives sont épuisées : on retourne le défaut
          debugPrint("[IA] Toutes les tentatives ont échoué. Retour de la réponse par défaut.");
          return reponseParDefaut;
        }
      }

      // Attente avant la prochaine tentative (délai progressif)
      await Future.delayed(_delaiEntreTentatives * tentative);
    }

    return reponseParDefaut;
  }

  // ============================================================
  // MÉTHODE PUBLIQUE 1 : Chat en streaming
  //
  // Envoie un message de l'utilisateur et renvoie la réponse
  // de l'IA mot par mot (streaming). Cela permet d'afficher le
  // texte au fur et à mesure, comme une vraie conversation.
  //
  // Paramètre [prompt] : Le texte envoyé par l'utilisateur.
  // Paramètre [fichiersImages] : Optionnel, images jointes.
  // ============================================================
  Stream<String> envoyerMessageStream(
    String prompt, {
    List<XFile>? fichiersImages,
  }) async* {
    final apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
    if (apiKey.isEmpty) {
      yield "L'assistant est indisponible : clé API Gemini manquante dans le fichier .env.";
      return;
    }

    try {
      final modele = _getModele(
        contexteSysteme:
            "Tu es l'assistant IA officiel de CamTrans, une application de logistique et de transport de marchandises au Cameroun. "
            "Ton rôle est d'aider les clients à estimer les prix, choisir le bon véhicule (moto, voiture, camionnette, camion léger, camion lourd), "
            "estimer les volumes et donner des conseils d'emballage ou de transport. "
            "Sois concis, professionnel et rassurant. Formate tes réponses clairement.",
      );

      // Construction du contenu (texte + éventuelles images)
      final List<Part> parties = [TextPart(prompt)];
      if (fichiersImages != null && fichiersImages.isNotEmpty) {
        for (final fichier in fichiersImages) {
          final octets = await fichier.readAsBytes();
          parties.add(DataPart('image/jpeg', octets));
        }
      }

      final contenuUtilisateur = Content.multi(parties);

      // Démarrage du chat avec l'historique de la session en cours
      final chat = modele.startChat(history: List.from(_historique));
      _historique.add(contenuUtilisateur);

      String reponseComplete = "";

      // Réception du flux de tokens de l'IA
      await for (final morceau in chat.sendMessageStream(contenuUtilisateur)) {
        final texte = morceau.text;
        if (texte != null && texte.isNotEmpty) {
          reponseComplete += texte;
          yield texte;
        }
      }

      // Ajout de la réponse complète dans l'historique
      _historique.add(Content.model([TextPart(reponseComplete)]));
    } on GenerativeAIException catch (e) {
      // Erreur spécifique à l'API Gemini (quota, clé invalide, etc.)
      debugPrint("[IA][Chat] Erreur API Gemini : $e");
      yield "\n[IA indisponible] Une erreur est survenue. Réessayez dans un moment.";
    } catch (e) {
      // Toute autre erreur (réseau, timeout, etc.)
      debugPrint("[IA][Chat] Erreur inattendue : $e");
      yield "\n[IA indisponible] Impossible de contacter le serveur. Vérifiez votre connexion.";
    }
  }

  // ============================================================
  // MÉTHODE PUBLIQUE 2 : Estimation d'une expédition
  //
  // Analyse le type de marchandise, le départ et l'arrivée pour
  // recommander le meilleur véhicule et estimer le prix.
  //
  // Retourne une Map avec les clés : vehicule, volume, prix, conseil.
  // En cas d'erreur persistante, retourne des valeurs par défaut
  // pour ne pas bloquer l'interface.
  // ============================================================
  Future<Map<String, String>> estimerExpedition({
    required String marchandise,
    required String description,
    required String depart,
    required String destination,
    List<XFile>? fichiersImages,
  }) async {
    final prompt =
        "Tu es un expert en logistique pour CamTrans au Cameroun. "
        "Estime cette expédition :\n"
        "- Départ : ${depart.isEmpty ? 'Non précisé' : depart}\n"
        "- Destination : ${destination.isEmpty ? 'Non précisé' : destination}\n"
        "- Catégorie : ${marchandise.isEmpty ? 'Non précisé' : marchandise}\n"
        "- Détails : ${description.isEmpty ? 'Non précisé' : description}\n\n"
        "Réponds UNIQUEMENT en JSON avec ces clés :\n"
        "- vehicule : le véhicule idéal parmi (Moto, Voiture, Camionnette, Camion léger, Camion lourd, Camion Plateau)\n"
        "- volume : estimation en m³ (ex: '2.5 m³')\n"
        "- prix : estimation en FCFA (ex: '15 000 FCFA')\n"
        "- conseil : un court conseil de 1 à 2 phrases";

    // Construction du contenu avec éventuelles images
    final List<Part> parties = [TextPart(prompt)];
    if (fichiersImages != null && fichiersImages.isNotEmpty) {
      for (final fichier in fichiersImages) {
        final octets = await fichier.readAsBytes();
        parties.add(DataPart('image/jpeg', octets));
      }
    }

    final data = await _appelJsonAvecReessai(
      contenu: [Content.multi(parties)],
      contexteSysteme:
          "Tu es un extracteur JSON expert en logistique au Cameroun. "
          "Réponds UNIQUEMENT en JSON valide, sans texte avant ni après.",
      reponseParDefaut: const {
        "vehicule": "Camionnette",
        "volume": "Non estimé",
        "prix": "Sur devis",
        "conseil": "Contactez un agent CamTrans pour une estimation précise.",
      },
    );

    return {
      "vehicule": data["vehicule"]?.toString() ?? "Camionnette",
      "volume": data["volume"]?.toString() ?? "Non estimé",
      "prix": data["prix"]?.toString() ?? "Sur devis",
      "conseil": data["conseil"]?.toString() ??
          "Emballez soigneusement vos articles.",
    };
  }

  // ============================================================
  // MÉTHODE PUBLIQUE 3 : Estimation de la masse d'un véhicule
  //
  // Utilisé pour calculer la capacité de remorquage nécessaire.
  // En cas d'erreur, retourne 1500 kg (valeur moyenne standard).
  // ============================================================
  Future<double> estimerMasseVehicule(String marque, String modele) async {
    final prompt =
        "Tu es un expert automobile. "
        "Donne le poids à vide moyen en kg pour le véhicule suivant :\n"
        "Marque : $marque\n"
        "Modèle : $modele\n\n"
        "Réponds UNIQUEMENT en JSON avec la clé :\n"
        "- masse_kg : un nombre entier (ex: 1500)";

    final data = await _appelJsonAvecReessai(
      contenu: [Content.text(prompt)],
      contexteSysteme:
          "Tu es un expert automobile. Réponds UNIQUEMENT en JSON valide.",
      reponseParDefaut: const {"masse_kg": 1500},
    );

    final valeur = data["masse_kg"];
    if (valeur is num) return valeur.toDouble();
    if (valeur is String) {
      return double.tryParse(
            valeur.replaceAll(RegExp(r'[^0-9.]'), ''),
          ) ??
          1500.0;
    }

    debugPrint("[IA][Masse] Valeur inattendue : $valeur. Retour à 1500 kg.");
    return 1500.0;
  }

  // ============================================================
  // MÉTHODE PUBLIQUE 4 : Analyse d'une commande vocale
  //
  // Prend la transcription brute d'une commande vocale et extrait
  // les informations structurées nécessaires à la création d'une
  // course (départ, arrivée, type de marchandise).
  //
  // En cas d'erreur, retourne une réponse "ERREUR" qui indique
  // à l'assistant vocal de demander à l'utilisateur de répéter.
  // ============================================================
  Future<Map<String, dynamic>> analyserIntentionVocale(String texte) async {
    // Réponse de secours si l'IA est totalement indisponible
    const reponseErreur = {
      "intention": "ERREUR",
      "depart": "",
      "arrivee": "",
      "marchandise": "",
      "complet": false,
      "reponse_vocale":
          "Désolé, je n'ai pas pu comprendre votre demande. Pourriez-vous répéter ?",
    };

    final prompt =
        "L'utilisateur a dit : \"$texte\"\n\n"
        "Analyse cette phrase et extrais une intention de commande de transport.\n"
        "Réponds UNIQUEMENT en JSON avec ces clés :\n"
        "- intention : 'CREER_COURSE' si c'est une demande de transport, sinon 'INCONNU'\n"
        "- depart : lieu de départ (chaîne vide si non mentionné)\n"
        "- arrivee : lieu d'arrivée (chaîne vide si non mentionné)\n"
        "- marchandise : type de marchandise déduit (Déménagement, Marchandise standard, Remorque, etc.) ou chaîne vide\n"
        "- complet : true seulement si on a au moins un départ, une arrivée et un type de marchandise. Sinon false.\n"
        "- reponse_vocale : phrase à dire à l'utilisateur. Si complet=true, confirme la création. Sinon, demande poliment l'information manquante.";

    return await _appelJsonAvecReessai(
      contenu: [Content.text(prompt)],
      contexteSysteme:
          "Tu es CamTrans Voice, l'assistant vocal intelligent de l'application CamTrans "
          "pour commander des transports et déménagements au Cameroun. "
          "Réponds UNIQUEMENT en JSON valide, sans texte avant ni après.",
      reponseParDefaut: reponseErreur,
    );
  }
}
