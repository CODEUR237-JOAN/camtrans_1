import 'package:latlong2/latlong.dart';
import 'package:update_camtrans/modeles/course.dart';

enum PhaseSuivi {
  recherche,   // La course cherche un transporteur
  approche,    // Phase 1 : Le transporteur va vers le client
  trajet,      // Phase 2 : Le transporteur va vers la destination
  terminee,    // La course est finie
}

class SuiviCourseEtat {
  final Course? course;
  final PhaseSuivi phase;
  final LatLng? positionChauffeur;
  final LatLng? positionClient; // Départ
  final LatLng? positionDestination; // Arrivée
  final List<LatLng> pointsItineraire;
  final String instructionVocaleActuelle;
  final int distanceRestanteMetres;
  final int tempsRestantSecondes;
  final bool isVoixActive;
  final bool isLoading;
  final String erreur;

  const SuiviCourseEtat({
    this.course,
    this.phase = PhaseSuivi.recherche,
    this.positionChauffeur,
    this.positionClient,
    this.positionDestination,
    this.pointsItineraire = const [],
    this.instructionVocaleActuelle = "",
    this.distanceRestanteMetres = 0,
    this.tempsRestantSecondes = 0,
    this.isVoixActive = true,
    this.isLoading = true,
    this.erreur = "",
  });

  SuiviCourseEtat copyWith({
    Course? course,
    PhaseSuivi? phase,
    LatLng? positionChauffeur,
    LatLng? positionClient,
    LatLng? positionDestination,
    List<LatLng>? pointsItineraire,
    String? instructionVocaleActuelle,
    int? distanceRestanteMetres,
    int? tempsRestantSecondes,
    bool? isVoixActive,
    bool? isLoading,
    String? erreur,
  }) {
    return SuiviCourseEtat(
      course: course ?? this.course,
      phase: phase ?? this.phase,
      positionChauffeur: positionChauffeur ?? this.positionChauffeur,
      positionClient: positionClient ?? this.positionClient,
      positionDestination: positionDestination ?? this.positionDestination,
      pointsItineraire: pointsItineraire ?? this.pointsItineraire,
      instructionVocaleActuelle: instructionVocaleActuelle ?? this.instructionVocaleActuelle,
      distanceRestanteMetres: distanceRestanteMetres ?? this.distanceRestanteMetres,
      tempsRestantSecondes: tempsRestantSecondes ?? this.tempsRestantSecondes,
      isVoixActive: isVoixActive ?? this.isVoixActive,
      isLoading: isLoading ?? this.isLoading,
      erreur: erreur ?? this.erreur,
    );
  }
}
