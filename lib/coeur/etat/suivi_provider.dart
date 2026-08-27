import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:update_camtrans/coeur/constantes/statuts.dart';
import 'package:update_camtrans/services/service_firestore.dart';
import 'package:update_camtrans/services/service_gps.dart';
import 'package:update_camtrans/modeles/course.dart';
import 'package:update_camtrans/modeles/transporteur.dart';
import 'package:update_camtrans/services/service_routage.dart';

// État combiné du suivi
class EtatSuivi {
  final bool chargement;
  final Course? course;
  final Transporteur? transporteur;
  final String? erreur;
  
  // Nouveaux champs pour le routage dynamique
  final InfoTrajet? infoTrajet;
  final LatLng? positionTransporteurSimule;
  final double distanceRestante;
  final double tempsRestantSeconds;
  final String? quartierTransporteur; // Nouveau : Nom du quartier actuel

  EtatSuivi({
    this.chargement = true,
    this.course,
    this.transporteur,
    this.erreur,
    this.infoTrajet,
    this.positionTransporteurSimule,
    this.distanceRestante = 0.0,
    this.tempsRestantSeconds = 0.0,
    this.quartierTransporteur,
  });

  EtatSuivi copierAvec({
    bool? chargement,
    Course? course,
    Transporteur? transporteur,
    String? erreur,
    InfoTrajet? infoTrajet,
    LatLng? positionTransporteurSimule,
    double? distanceRestante,
    double? tempsRestantSeconds,
    String? quartierTransporteur,
  }) {
    return EtatSuivi(
      chargement: chargement ?? this.chargement,
      course: course ?? this.course,
      transporteur: transporteur ?? this.transporteur,
      erreur: erreur ?? this.erreur,
      infoTrajet: infoTrajet ?? this.infoTrajet,
      positionTransporteurSimule: positionTransporteurSimule ?? this.positionTransporteurSimule,
      distanceRestante: distanceRestante ?? this.distanceRestante,
      tempsRestantSeconds: tempsRestantSeconds ?? this.tempsRestantSeconds,
      quartierTransporteur: quartierTransporteur ?? this.quartierTransporteur,
    );
  }
}

// Provider paramétré par l'ID de la course
final suiviProvider = StateNotifierProvider.autoDispose.family<SuiviNotifier, EtatSuivi, String>((ref, courseId) {
  return SuiviNotifier(ref.read(serviceFirestoreProvider), ref.read(serviceGpsProvider), courseId);
});

class SuiviNotifier extends StateNotifier<EtatSuivi> {
  final ServiceFirestore _firestore;
  // final ServiceRoutage _routage;
  final ServiceGps _gps;
  StreamSubscription? _courseSubscription;
  StreamSubscription? _transporteurSubscription;
  Timer? _simulateurTimer;

  SuiviNotifier(this._firestore, this._gps, String courseId) : super(EtatSuivi()) {
    _initialiserEcoute(courseId);
  }

  void _initialiserEcoute(String courseId) {
    _courseSubscription = _firestore.fluxDocument(collection: 'courses', id: courseId).listen((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        final course = Course.fromMap(snapshot.data()!);
        
        state = state.copierAvec(course: course, chargement: false);

        // Si le transporteur est défini, on écoute sa position
        if (course.transporteurId.isNotEmpty && _transporteurSubscription == null) {
          _ecouterTransporteur(course.transporteurId);
        }
      } else {
        state = state.copierAvec(erreur: "Course introuvable", chargement: false);
      }
    }, onError: (e) {
      state = state.copierAvec(erreur: e.toString(), chargement: false);
    });
  }

  void _ecouterTransporteur(String transporteurId) {
    _transporteurSubscription = _firestore.fluxDocument(collection: 'transporteurs', id: transporteurId).listen((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        final transporteur = Transporteur.fromMap(snapshot.data()!);
        
        // Calcul dynamique de la distance et du temps si la course est en cours
        double distanceRestante = state.distanceRestante;
        double tempsRestant = state.tempsRestantSeconds;

        if (state.course != null && transporteur.latitude != 0 && transporteur.longitude != 0) {
          final course = state.course!;
          // Destination cible : point de départ si pas encore chargé, sinon point d'arrivée
          double latCible = course.latitudeDepart;
          double lngCible = course.longitudeDepart;
          
          if (course.statut == StatutCourse.charge || course.statut == StatutCourse.enTransit) {
            latCible = course.latitudeArrivee;
            lngCible = course.longitudeArrivee;
          }

          // On utilise une distance en ligne droite pour l'approximation temps réel (pour la fluidité)
          final distance = const Distance().as(LengthUnit.Meter, 
            LatLng(transporteur.latitude, transporteur.longitude), 
            LatLng(latCible, lngCible)
          );
          distanceRestante = distance.toDouble();
          // Estimation : 30 km/h en moyenne en ville (8.3 m/s)
          tempsRestant = distanceRestante / 8.3;
        }

        state = state.copierAvec(
          transporteur: transporteur,
          distanceRestante: distanceRestante,
          tempsRestantSeconds: tempsRestant,
        );

        // Mettre à jour le quartier si la position a changé significativement
        if (transporteur.latitude != 0 && transporteur.longitude != 0) {
           _gps.obtenirAdresse(latitude: transporteur.latitude, longitude: transporteur.longitude).then((adresse) {
            final quartier = adresse.split(',').first;
            state = state.copierAvec(quartierTransporteur: quartier);
          }).catchError((_) {});
        }
      }
    }, onError: (e) {
       state = state.copierAvec(erreur: e.toString());
    });
  }

  @override
  void dispose() {
    _courseSubscription?.cancel();
    _transporteurSubscription?.cancel();
    _simulateurTimer?.cancel();
    super.dispose();
  }
}
