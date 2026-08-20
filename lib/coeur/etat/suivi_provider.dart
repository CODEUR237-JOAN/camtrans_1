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
  return SuiviNotifier(ref.read(serviceFirestoreProvider), ref.read(serviceRoutageProvider), ref.read(serviceGpsProvider), courseId);
});

class SuiviNotifier extends StateNotifier<EtatSuivi> {
  final ServiceFirestore _firestore;
  final ServiceRoutage _routage;
  final ServiceGps _gps;
  StreamSubscription? _courseSubscription;
  StreamSubscription? _transporteurSubscription;
  Timer? _simulateurTimer;

  SuiviNotifier(this._firestore, this._routage, this._gps, String courseId) : super(EtatSuivi()) {
    if (courseId == "course_demo_id") {
      _lancerSimulationMock();
    } else {
      _initialiserEcoute(courseId);
    }
  }

  Future<void> _lancerSimulationMock() async {
    // 1. Définir des positions fictives (Client = Douala, Transporteur = un peu plus loin)
    final clientPos = const LatLng(4.0435, 9.6999);
    final transporteurPos = const LatLng(4.0300, 9.7100);

    // 2. Créer une fausse course
    final course = Course(
      id: "course_demo_id",
      clientId: "client1",
      transporteurId: "transp1",
      nomClient: "Client Test",
      nomTransporteur: "Jean le Livreur",
      telephoneClient: "690000000",
      telephoneTransporteur: "690000001",
      adresseDepart: "Douala",
      adresseArrivee: "Bonamoussadi",
      latitudeDepart: clientPos.latitude, // Le client attend ici
      longitudeDepart: clientPos.longitude,
      latitudeArrivee: 4.0500, // Destination finale
      longitudeArrivee: 9.7200,
      distanceKm: 2.0,
      volumeM3: 2.5,
      poidsKg: 0.0,
      typeVehicule: "Camionnette",
      typeMarchandise: "Colis lourd",
      prixEstime: 15000.0,
      prixFinal: 15000.0,
      modePaiement: "Cash",
      paiementEffectue: false,
      statut: StatutCourse.enRouteDepart,
      description: "Simulation",
      photos: [],
      dateCreation: DateTime.now(),
      fragile: false,
      aideChargement: false,
      aideDechargement: false,
      codeSuivi: "CAM-TRACK-001",
      noteClient: 0.0,
      noteTransporteur: 0.0,
      commentaireClient: "",
      commentaireTransporteur: "",
      scoreIA: 0.0,
      vehiculeRecommandeIA: "Camionnette",
      volumeEstimeIA: 2.5,
      conseilIA: "",
    );

    final transporteur = Transporteur(
      id: "transp1",
      nom: "Jean",
      prenom: "le Livreur",
      email: "jean@example.com",
      telephone: "690000000",
      photo: "",
      adresse: "Douala",
      ville: "Douala",
      role: "transporteur",
      actif: true,
      emailVerifie: true,
      dateCreation: DateTime.now(),
      typeVehicule: "Camionnette",
      latitude: transporteurPos.latitude,
      longitude: transporteurPos.longitude,
    );

    state = state.copierAvec(course: course, transporteur: transporteur, positionTransporteurSimule: transporteurPos, chargement: false);

    // 3. Calculer le tracé OSRM du transporteur vers le client
    final info = await _routage.obtenirItineraire(transporteurPos, clientPos);
    
    if (info != null) {
      state = state.copierAvec(
        infoTrajet: info, 
        distanceRestante: info.distanceMetres, 
        tempsRestantSeconds: info.dureeSecondes
      );
      _animerDeplacement(info.points, info.dureeSecondes, info.distanceMetres);
    }
  }

  void _animerDeplacement(List<LatLng> points, double dureeInitiale, double distanceInitiale) {
    if (points.isEmpty) return;
    int indexCourant = 0;
    
    // On met à jour toutes les 2 secondes
    _simulateurTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (indexCourant >= points.length - 1) {
        timer.cancel();
        return;
      }
      indexCourant++;
      
      // Prochaine position
      final nouvellePos = points[indexCourant];
      
      // Calcul approximatif restant
      final progression = indexCourant / points.length;
      final distance = distanceInitiale * (1 - progression);
      final temps = dureeInitiale * (1 - progression);

      state = state.copierAvec(
        positionTransporteurSimule: nouvellePos,
        distanceRestante: distance > 0 ? distance : 0,
        tempsRestantSeconds: temps > 0 ? temps : 0,
      );

      // Mettre à jour le quartier toutes les 10 secondes pour ne pas saturer l'API de géocodage
      if (indexCourant % 5 == 0) {
        _gps.obtenirAdresse(latitude: nouvellePos.latitude, longitude: nouvellePos.longitude).then((adresse) {
          final quartier = adresse.split(',').first;
          state = state.copierAvec(quartierTransporteur: quartier);
        });
      }
    });
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
