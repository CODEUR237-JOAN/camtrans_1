import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:update_camtrans/services/service_gps.dart';
import 'package:update_camtrans/services/service_routage.dart';
import 'service_ia.dart';

// ============================================================
// CONFIGURATION DE TARIFICATION — USAGE INTERNE UNIQUEMENT
// Cette classe ne doit JAMAIS être exposée dans l'UI client.
// Elle est réservée à l'usage admin, support et logs.
// ============================================================
class ConfigTarificationRemorque {
  /// Frais de prise en charge fixes (FCFA)
  static const double fraisBase = 15000;

  /// Tarif kilométrique de base (FCFA/km)
  static const double tarifKmBase = 1000;

  /// Coefficient de surcoût carburant lié à la masse (FCFA/tonne/km).
  /// À calibrer en conditions réelles terrain Douala/Yaoundé.
  static const double coeffMasseCarburant = 75;

  /// Indexation carburant pilotable à distance (via Remote Config).
  /// 1.0 = pas d'indexation. Augmenter si le prix du carburant monte.
  static const double coeffIndexationCarburant = 1.0;
}

// ============================================================
// MODÈLE DE RÉSULTAT D'ESTIMATION
// Les champs `detail*` sont EXCLUSIVEMENT pour l'usage interne
// (logs, dashboard admin, support litige). Ne jamais les binder dans l'UI client.
// ============================================================
class ResultatEstimation {
  final double distanceKm;
  final double dureeMinutes;
  final double volumeM3;
  final double poidsKg;
  final String vehiculeRecommande;
  final double coutTotal;

  // --- Champs internes admin/support — JAMAIS affichés côté client ---
  final double? detailFraisBase;
  final double? detailCoutDistance;
  final double? detailSurchargeMasseCarburant;

  ResultatEstimation({
    required this.distanceKm,
    required this.dureeMinutes,
    required this.volumeM3,
    required this.poidsKg,
    required this.vehiculeRecommande,
    required this.coutTotal,
    this.detailFraisBase,
    this.detailCoutDistance,
    this.detailSurchargeMasseCarburant,
  });
}


final serviceEstimationProvider = Provider<ServiceEstimation>((ref) {
  final ia = ref.watch(serviceIAProvider);
  final gps = ref.watch(serviceGpsProvider);
  final routage = ref.watch(serviceRoutageProvider);
  return ServiceEstimation(ia, gps, routage);
});

class ServiceEstimation {
  final ServiceIA _ia;
  final ServiceGps _gps;
  final ServiceRoutage _routage;

  ServiceEstimation(this._ia, this._gps, this._routage);

  /// Méthode locale pour calculer une estimation basée sur un vrai routage OSRM.
  Future<ResultatEstimation> genererEstimationLocale({
    required String depart,
    required String arrivee,
    required String typeMarchandise,
    required String description,
    required String categorieVehicule,
  }) async {
    // 1. Géocodage
    final locDepart = await _gps.obtenirCoordonnees(depart);
    final locArrivee = await _gps.obtenirCoordonnees(arrivee);

    double distanceKm = 10.0;
    double dureeMinutes = 30.0;

    if (locDepart != null && locArrivee != null) {
      // 2. Routage réel OSRM
      final infoTrajet = await _routage.obtenirItineraire(
        LatLng(locDepart.latitude, locDepart.longitude),
        LatLng(locArrivee.latitude, locArrivee.longitude),
      );

      if (infoTrajet != null && infoTrajet.distanceMetres > 0) {
        distanceKm = infoTrajet.distanceMetres / 1000.0;
        dureeMinutes = infoTrajet.dureeSecondes / 60.0;
      } else {
        // Fallback: Distance vol d'oiseau
        distanceKm = _gps.calculerDistance(
          latitudeDepart: locDepart.latitude,
          longitudeDepart: locDepart.longitude,
          latitudeArrivee: locArrivee.latitude,
          longitudeArrivee: locArrivee.longitude,
        );
        dureeMinutes = distanceKm * 1.5;
      }
    }

    double volume = 1.0;
    double poids = 50.0;

    if (typeMarchandise.toLowerCase().contains("lourd") || typeMarchandise.toLowerCase().contains("matériaux")) {
      volume = 15.0;
      poids = 800.0;
    } else if (typeMarchandise.toLowerCase().contains("déménagement")) {
      volume = 20.0;
      poids = 500.0;
    } else if (typeMarchandise.toLowerCase().contains("léger")) {
      volume = 0.5;
      poids = 10.0;
    }

    String vehiculeFinal = categorieVehicule;
    if (vehiculeFinal.isEmpty) {
      if (volume > 10 || poids > 400) {
        vehiculeFinal = "Camion lourd";
      } else if (volume > 2 || poids > 100) {
        vehiculeFinal = "Camionnette";
      } else {
        vehiculeFinal = "Moto";
      }
    }

    double prixBase = 2000.0;
    if (vehiculeFinal.toLowerCase().contains("camion")) prixBase = 15000.0;

    // Prix basé sur la VRAIE distance
    final coutTotal = prixBase + (distanceKm * 500) + (volume * 1000);

    return ResultatEstimation(
      distanceKm: distanceKm,
      dureeMinutes: dureeMinutes,
      volumeM3: volume,
      poidsKg: poids,
      vehiculeRecommande: vehiculeFinal.isNotEmpty ? vehiculeFinal : "Voiture",
      coutTotal: coutTotal,
    );
  }

  /// Méthode qui appelle l'API Groq/Llama pour analyser sémantiquement la demande.
  /// Logique existante conservée à l'identique — sans régression.
  Future<ResultatEstimation> genererEstimationViaGemini({
    required String depart,
    required String arrivee,
    required String typeMarchandise,
    required String description,
  }) async {
    try {
      final estimationIA = await _ia.estimerExpedition(
        marchandise: typeMarchandise,
        description: description,
        depart: depart,
        destination: arrivee,
      );

      // 1. Géocodage
      final locDepart = await _gps.obtenirCoordonnees(depart);
      final locArrivee = await _gps.obtenirCoordonnees(arrivee);

      double distanceKm = 10.0;
      double dureeMinutes = 30.0;

      if (locDepart != null && locArrivee != null) {
        // 2. Routage réel OSRM
        final infoTrajet = await _routage.obtenirItineraire(
          LatLng(locDepart.latitude, locDepart.longitude),
          LatLng(locArrivee.latitude, locArrivee.longitude),
        );

        if (infoTrajet != null && infoTrajet.distanceMetres > 0) {
          distanceKm = infoTrajet.distanceMetres / 1000.0;
          dureeMinutes = infoTrajet.dureeSecondes / 60.0;
        } else {
          distanceKm = _gps.calculerDistance(
            latitudeDepart: locDepart.latitude,
            longitudeDepart: locDepart.longitude,
            latitudeArrivee: locArrivee.latitude,
            longitudeArrivee: locArrivee.longitude,
          );
          dureeMinutes = distanceKm * 1.5;
        }
      }

      double volume = 1.0;
      if (estimationIA['volume'] != null) {
        final vStr = estimationIA['volume']!.replaceAll(RegExp(r'[^0-9.]'), '');
        if (vStr.isNotEmpty) volume = double.parse(vStr);
      }

      double prixBase = 2000.0;
      if (estimationIA['prix'] != null) {
        final pStr = estimationIA['prix']!.replaceAll(RegExp(r'[^0-9.]'), '');
        if (pStr.isNotEmpty) prixBase = double.parse(pStr);
      }

      // Calcul avec la vraie distance
      final coutTotal = prixBase > 5000 ? prixBase : prixBase + (distanceKm * 500);

      return ResultatEstimation(
        distanceKm: distanceKm,
        dureeMinutes: dureeMinutes,
        volumeM3: volume,
        poidsKg: volume * 50,
        vehiculeRecommande: estimationIA['vehicule'] ?? "Camionnette",
        coutTotal: coutTotal,
      );
    } catch (e) {
      return genererEstimationLocale(
        depart: depart,
        arrivee: arrivee,
        typeMarchandise: typeMarchandise,
        description: description,
        categorieVehicule: "",
      );
    }
  }

  // ============================================================
  // FORMULE REMORQUAGE — USAGE INTERNE
  // Cette méthode ne retourne JAMAIS le détail à l'UI client.
  // Le `coutTotal` est la seule valeur affichée côté client.
  // Les champs `detail*` sont pour logs/admin/support uniquement.
  // ============================================================
  /// Calcule l'estimation d'un remorquage selon une formule continue
  /// proportionnelle à la distance ET à la masse (surconsommation carburant réelle).
  ///
  /// Formule :
  ///   Prix = fraisBase
  ///        + (distanceKm × tarifKmBase)
  ///        + (distanceKm × (masseKg / 1000) × coeffMasseCarburant)
  ///   , multiplié par coeffIndexationCarburant.
  ///
  /// Pas de palier ni de "surge" : le prix est continu et prévisible,
  /// lié uniquement aux coûts réels. Adapté au contexte urgence Cameroun.
  Future<ResultatEstimation> genererEstimationRemorque({
    required double distanceKm,
    required double masseKg,
  }) async {
    final double fraisBase = ConfigTarificationRemorque.fraisBase;
    final double tarifKmBase = ConfigTarificationRemorque.tarifKmBase;
    final double coeffMasse = ConfigTarificationRemorque.coeffMasseCarburant;
    final double indexation = ConfigTarificationRemorque.coeffIndexationCarburant;

    // Composantes du coût — INTERNES uniquement
    final double coutDistance = distanceKm * tarifKmBase;
    final double surchargeMasseCarburant = distanceKm * (masseKg / 1000) * coeffMasse;

    // Prix total visible client (arrondi à 50 FCFA le plus proche)
    final double coutBrut = (fraisBase + coutDistance + surchargeMasseCarburant) * indexation;
    final double coutTotal = (coutBrut / 50).round() * 50.0;

    // Log interne debug — jamais affiché dans l'UI
    debugPrint(
      '[REMORQUE][TARIF_INTERNE] '
      'Masse: ${masseKg.toInt()}kg | Dist: ${distanceKm.toStringAsFixed(1)}km | '
      'FraisBase: ${fraisBase.toInt()} FCFA | '
      'CoutDist: ${coutDistance.toStringAsFixed(0)} FCFA | '
      'SurchargeMasse: ${surchargeMasseCarburant.toStringAsFixed(0)} FCFA | '
      'Total: ${coutTotal.toInt()} FCFA',
    );

    return ResultatEstimation(
      distanceKm: distanceKm,
      dureeMinutes: distanceKm * 1.5,
      volumeM3: 0.0,
      poidsKg: masseKg,
      vehiculeRecommande: "Dépanneuse",
      coutTotal: coutTotal,
      // Champs internes admin/support — ne jamais binder dans l'UI client
      detailFraisBase: fraisBase,
      detailCoutDistance: coutDistance,
      detailSurchargeMasseCarburant: surchargeMasseCarburant,
    );
  }
}
