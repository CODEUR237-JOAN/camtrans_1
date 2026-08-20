import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:update_camtrans/services/service_estimation.dart';

class EtatEstimation {
  final bool enCours;
  final ResultatEstimation? resultat;
  final String? erreur;

  EtatEstimation({this.enCours = false, this.resultat, this.erreur});

  EtatEstimation copierAvec({bool? enCours, ResultatEstimation? resultat, String? erreur}) {
    return EtatEstimation(
      enCours: enCours ?? this.enCours,
      resultat: resultat ?? this.resultat,
      erreur: erreur ?? this.erreur,
    );
  }
}

class EstimationNotifier extends StateNotifier<EtatEstimation> {
  final ServiceEstimation _service;

  EstimationNotifier(this._service) : super(EtatEstimation());

  Future<void> lancerEstimation({
    required String depart,
    required String arrivee,
    required String typeMarchandise,
    required String description,
    required String categorieVehicule,
    bool isRemorque = false,
    double masseRemorqueKg = 0.0,
    double distanceKm = 10.0, // Default for simulation if not provided
  }) async {
    state = EtatEstimation(enCours: true);
    
    try {
      ResultatEstimation resultat;
      if (isRemorque) {
        resultat = await _service.genererEstimationRemorque(
          distanceKm: distanceKm,
          masseKg: masseRemorqueKg,
        );
      } else {
        resultat = await _service.genererEstimationViaGemini(
          depart: depart,
          arrivee: arrivee,
          typeMarchandise: typeMarchandise,
          description: description,
        );
      }
      state = EtatEstimation(enCours: false, resultat: resultat);
    } catch (e) {
      state = EtatEstimation(enCours: false, erreur: e.toString());
    }
  }

  void reinitialiser() {
    state = EtatEstimation();
  }
}

final estimationProvider = StateNotifierProvider<EstimationNotifier, EtatEstimation>((ref) {
  return EstimationNotifier(ref.read(serviceEstimationProvider));
});
