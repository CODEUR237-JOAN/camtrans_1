import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../coeur/constantes/statuts.dart';
import '../../services/service_firestore.dart';
import '../../modeles/course.dart';
import '../../modeles/transporteur.dart';
import '../../services/service_routage.dart';

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

  EtatSuivi({
    this.chargement = true,
    this.course,
    this.transporteur,
    this.erreur,
    this.infoTrajet,
    this.positionTransporteurSimule,
    this.distanceRestante = 0.0,
    this.tempsRestantSeconds = 0.0,
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
    );
  }
}

// Provider paramétré par l'ID de la course
final suiviProvider = StateNotifierProvider.autoDispose.family<SuiviNotifier, EtatSuivi, String>((ref, courseId) {
  return SuiviNotifier(ref.read(serviceFirestoreProvider), ref.read(serviceRoutageProvider), courseId);
});

class SuiviNotifier extends StateNotifier<EtatSuivi> {
  final ServiceFirestore _firestore;
  final ServiceRoutage _routage;
  StreamSubscription? _courseSubscription;
  StreamSubscription? _transporteurSubscription;
  Timer? _simulateurTimer;

  SuiviNotifier(this._firestore, this._routage, String courseId) : super(EtatSuivi()) {
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
      statut: StatutCourse.enRoute,
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
        state = state.copierAvec(transporteur: transporteur);
      }
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
