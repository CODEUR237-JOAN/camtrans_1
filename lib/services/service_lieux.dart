import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

// =====================================================================
// SERVICE DE RECHERCHE DE LIEUX — Nominatim (OpenStreetMap)
//
// Recherche prédictive d'adresses/quartiers, STRICTEMENT restreinte au
// Cameroun via `countrycodes=cm` (équivalent gratuit du
// `components=country:cm` de Google Places).
//
// Gratuit, sans carte bancaire ni clé API. Politique d'usage Nominatim :
//   - un User-Agent identifiant l'application est OBLIGATOIRE ;
//   - au plus ~1 requête/seconde → on s'appuie sur un debounce côté UI.
//
// ── POUR PASSER À GOOGLE PLACES PLUS TARD ────────────────────────────
// Si la facturation Google Cloud est un jour activée (carte bancaire),
// il suffit de remplacer le corps de `rechercher()` par un appel à
// l'endpoint Places Autocomplete en ajoutant la clé API ici :
//   static const String _clePlacesGoogle = 'VOTRE_CLE_API_ICI';
// et le paramètre `components=country:cm`. L'interface publique
// (LieuSuggestion / rechercher) ne change pas → aucun impact UI.
// =====================================================================

class LieuSuggestion {
  final String libelle; // Texte affiché (ex : « Bastos, Yaoundé »)
  final double latitude;
  final double longitude;

  const LieuSuggestion({
    required this.libelle,
    required this.latitude,
    required this.longitude,
  });
}

class ServiceLieux {
  static const String _hote = 'nominatim.openstreetmap.org';

  // User-Agent requis par la politique Nominatim (identifie l'app).
  static const Map<String, String> _entetes = {
    'User-Agent': 'CamTrans/1.0 (app de transport, Cameroun)',
    'Accept': 'application/json',
  };

  final http.Client _client;

  /// Permet d'injecter un client HTTP (utile pour les tests avec MockClient).
  ServiceLieux({http.Client? client}) : _client = client ?? http.Client();

  /// Recherche jusqu'à [limite] lieux au Cameroun correspondant à [requete].
  /// Retourne une liste vide si la requête est trop courte, en cas
  /// d'erreur réseau ou si aucun résultat (jamais d'exception vers l'UI).
  Future<List<LieuSuggestion>> rechercher(String requete,
      {int limite = 6}) async {
    final q = requete.trim();
    if (q.length < 3) return const [];

    final uri = Uri.https(_hote, '/search', {
      'q': q,
      'format': 'jsonv2',
      'countrycodes': 'cm', // ← restriction stricte au Cameroun
      'addressdetails': '1',
      'limit': '$limite',
      'accept-language': 'fr',
    });

    try {
      final reponse = await _client
          .get(uri, headers: _entetes)
          .timeout(const Duration(seconds: 8));
      if (reponse.statusCode != 200) return const [];

      final List<dynamic> donnees = jsonDecode(reponse.body) as List<dynamic>;
      final resultats = <LieuSuggestion>[];
      for (final element in donnees) {
        if (element is! Map) continue;
        final lat = double.tryParse('${element['lat']}');
        final lon = double.tryParse('${element['lon']}');
        if (lat == null || lon == null) continue;
        resultats.add(LieuSuggestion(
          libelle: _formaterLibelle(element),
          latitude: lat,
          longitude: lon,
        ));
      }
      return resultats;
    } catch (e) {
      debugPrint('ServiceLieux (Nominatim) indisponible : $e');
      return const [];
    }
  }

  // Construit un libellé court et lisible à partir de la réponse Nominatim :
  // « quartier, ville » quand c'est possible, sinon le nom principal.
  String _formaterLibelle(Map element) {
    final adresse = element['address'];
    if (adresse is Map) {
      final partie = adresse['neighbourhood'] ??
          adresse['suburb'] ??
          adresse['quarter'] ??
          adresse['road'] ??
          adresse['village'] ??
          adresse['town'] ??
          adresse['name'];
      final ville =
          adresse['city'] ?? adresse['town'] ?? adresse['state'] ?? '';
      if (partie != null && ville != '' && partie != ville) {
        return '$partie, $ville';
      }
      if (partie != null) return '$partie';
      if (ville != '') return '$ville';
    }
    // Repli : on raccourcit le display_name (souvent très long).
    final nom = '${element['display_name'] ?? ''}';
    final morceaux = nom.split(',');
    if (morceaux.length >= 2) {
      return '${morceaux[0].trim()}, ${morceaux[1].trim()}';
    }
    return nom.trim();
  }
}

final serviceLieuxProvider = Provider<ServiceLieux>((ref) => ServiceLieux());
