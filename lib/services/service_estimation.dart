import 'package:flutter_riverpod/flutter_riverpod.dart';

class ResultatEstimation {
  final double distanceKm;
  final double dureeMinutes;
  final double volumeM3;
  final double poidsKg;
  final String vehiculeRecommande;
  final double coutTotal;

  ResultatEstimation({
    required this.distanceKm,
    required this.dureeMinutes,
    required this.volumeM3,
    required this.poidsKg,
    required this.vehiculeRecommande,
    required this.coutTotal,
  });
}

final serviceEstimationProvider = Provider<ServiceEstimation>((ref) {
  return ServiceEstimation();
});

class ServiceEstimation {
  /// Méthode locale (heuristiques basiques) pour calculer une estimation
  Future<ResultatEstimation> genererEstimationLocale({
    required String depart,
    required String arrivee,
    required String typeMarchandise,
    required String description,
    required String categorieVehicule,
  }) async {
    // Simuler un temps de calcul (ex: requête réseau ou IA)
    await Future.delayed(const Duration(seconds: 2));

    // 1. Estimation Distance / Durée (Simulée)
    // En réalité, on appellerait Google Maps Distance Matrix API
    final distanceSimulee = (depart.length + arrivee.length) * 1.5; 
    final dureeSimulee = distanceSimulee * 1.2; 

    // 2. Estimation Volume / Poids
    double volumeSimule = 1.0;
    double poidsSimule = 50.0;
    
    if (typeMarchandise.toLowerCase().contains("lourd") || typeMarchandise.toLowerCase().contains("matériaux")) {
      volumeSimule = 15.0;
      poidsSimule = 800.0;
    } else if (typeMarchandise.toLowerCase().contains("déménagement")) {
      volumeSimule = 20.0;
      poidsSimule = 500.0;
    } else if (typeMarchandise.toLowerCase().contains("léger")) {
      volumeSimule = 0.5;
      poidsSimule = 10.0;
    }

    // 3. Recommandation Véhicule (si l'utilisateur n'en a pas forcé un)
    String vehiculeFinal = categorieVehicule;
    if (vehiculeFinal.isEmpty) {
      if (volumeSimule > 10 || poidsSimule > 400) {
        vehiculeFinal = "Camion lourd";
      } else if (volumeSimule > 2 || poidsSimule > 100) {
        vehiculeFinal = "Camionnette";
      } else {
        vehiculeFinal = "Moto";
      }
    }

    // 4. Calcul Coût Total (Prix de base + Prix au km + Prix au volume/poids)
    double prixBase = 2000.0; // FCFA
    if (vehiculeFinal.toLowerCase().contains("camion")) prixBase = 15000.0;
    
    final coutTotal = prixBase + (distanceSimulee * 500) + (volumeSimule * 1000);

    return ResultatEstimation(
      distanceKm: distanceSimulee,
      dureeMinutes: dureeSimulee,
      volumeM3: volumeSimule,
      poidsKg: poidsSimule,
      vehiculeRecommande: vehiculeFinal.isNotEmpty ? vehiculeFinal : "Voiture",
      coutTotal: coutTotal,
    );
  }

  /// TODO: Méthode future pour appeler l'API Gemini afin d'avoir une vraie analyse sémantique
  Future<ResultatEstimation> genererEstimationViaGemini({
    required String depart,
    required String arrivee,
    required String description,
  }) async {
    // throw UnimplementedError("Intégration Gemini prévue dans une future version");
    // Pour l'instant on fallback sur la méthode locale
    return genererEstimationLocale(
      depart: depart,
      arrivee: arrivee,
      typeMarchandise: "Autre",
      description: description,
      categorieVehicule: "Camionnette",
    );
  }
}
