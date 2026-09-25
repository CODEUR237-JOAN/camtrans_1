import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:update_camtrans/coeur/constantes/statuts.dart';
import 'package:update_camtrans/coeur/etat/utilisateur_provider.dart';
import 'package:update_camtrans/modeles/course.dart';
import 'package:update_camtrans/services/service_routage.dart';

import 'suivi_course_etat.dart';
import '../services/service_navigation_vocale.dart';

final suiviCourseProvider = StateNotifierProvider.family<SuiviCourseNotifier, SuiviCourseEtat, String>((ref, courseId) {
  return SuiviCourseNotifier(ref, courseId);
});

class SuiviCourseNotifier extends StateNotifier<SuiviCourseEtat> {
  final Ref ref;
  final String courseId;
  
  StreamSubscription<DocumentSnapshot>? _courseSub;
  StreamSubscription<Position>? _positionSub;
  
  SuiviCourseNotifier(this.ref, this.courseId) : super(const SuiviCourseEtat()) {
    _initialiser();
  }

  StreamSubscription<DocumentSnapshot>? _transporteurSub;

  void _initialiser() async {
    // 1. Écoute du document de la course dans Firestore
    _courseSub = FirebaseFirestore.instance
        .collection('courses')
        .doc(courseId)
        .snapshots()
        .listen((doc) {
      if (doc.exists && doc.data() != null) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        final course = Course.fromMap(data);
        _mettreAJourCourse(course);
      }
    });

    // 2. Écoute de la position GPS selon le rôle
    final role = await ref.read(userRoleProvider.future);
    if (role == 'transporteur') {
      _positionSub = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10, // Mise à jour tous les 10 mètres
        ),
      ).listen(
        (Position position) {
          // Si on retrouve le signal, on enlève l'erreur
          if (state.erreur.isNotEmpty) {
            state = state.copyWith(erreur: '');
          }
          _mettreAJourPositionChauffeur(LatLng(position.latitude, position.longitude));
        },
        onError: (error) {
          state = state.copyWith(erreur: "Signal GPS faible ou perdu. Recherche de position en cours...");
        },
      );
    }
  }

  void _ecouterTransporteur(String transporteurId) {
    _transporteurSub?.cancel();
    _transporteurSub = FirebaseFirestore.instance
        .collection('transporteurs')
        .doc(transporteurId)
        .snapshots()
        .listen((doc) {
      if (doc.exists && doc.data() != null) {
        final data = doc.data() as Map<String, dynamic>;
        final lat = data['latitude'] as double?;
        final lng = data['longitude'] as double?;
        if (lat != null && lng != null && lat != 0 && lng != 0) {
          _mettreAJourPositionChauffeur(LatLng(lat, lng));
        }
      }
    });
  }

  void _mettreAJourCourse(Course course) {
    PhaseSuivi nouvellePhase = PhaseSuivi.recherche;

    if (course.statut == StatutCourse.attribue || course.statut == StatutCourse.enRouteDepart) {
      nouvellePhase = PhaseSuivi.approche;
    } else if (course.statut == StatutCourse.arriveDepart || course.statut == StatutCourse.charge || course.statut == StatutCourse.enTransit || course.statut == StatutCourse.arriveDestination) {
      nouvellePhase = PhaseSuivi.trajet;
    } else if (StatutCourse.estTerminee(course.statut)) {
      nouvellePhase = PhaseSuivi.terminee;
    }

    final changementDePhase = state.phase != nouvellePhase && state.phase != PhaseSuivi.recherche;

    state = state.copyWith(
      course: course,
      phase: nouvellePhase,
      positionClient: LatLng(course.latitudeDepart, course.longitudeDepart),
      positionDestination: LatLng(course.latitudeArrivee, course.longitudeArrivee),
      isLoading: false,
    );

    if (changementDePhase) {
      _annoncerChangementPhase(nouvellePhase);
      _calculerItineraire(); // Recalculer l'itinéraire car la cible a changé
    }
    
    // Si client, écouter le transporteur si la course est assignée
    final role = ref.read(userRoleProvider).valueOrNull;
    if (role == 'client' && course.transporteurId.isNotEmpty && _transporteurSub == null) {
      _ecouterTransporteur(course.transporteurId);
    }
  }

  void _mettreAJourPositionChauffeur(LatLng position) {
    state = state.copyWith(positionChauffeur: position);
    _calculerItineraire();
    _verifierProximite();
  }

  int _tentativesRoutage = 0;

  Future<void> _calculerItineraire() async {
    if (state.positionChauffeur == null || state.course == null) return;

    LatLng cible;
    try {
      if (state.phase == PhaseSuivi.approche) {
        cible = state.positionClient ?? LatLng(0, 0);
      } else if (state.phase == PhaseSuivi.trajet) {
        cible = state.positionDestination ?? LatLng(0, 0);
      } else {
        return;
      }
    } catch (e) {
      state = state.copyWith(erreur: "Erreur d'accès à la cible : \$e");
      return;
    }

    // Protection contre les coordonnées invalides (ex: 0,0) qui font planter OSRM
    if (cible.latitude == 0.0 && cible.longitude == 0.0) {
      state = state.copyWith(erreur: "Coordonnées de destination invalides.");
      return;
    }

    try {
      final serviceRoutage = ref.read(serviceRoutageProvider);
      final info = await serviceRoutage.obtenirItineraire(state.positionChauffeur!, cible);
      
      if (info != null) {
        _tentativesRoutage = 0; // Succès, on réinitialise
        state = state.copyWith(
          pointsItineraire: info.points,
          distanceRestanteMetres: info.distanceMetres.toInt(),
          tempsRestantSecondes: info.dureeSecondes.toInt(),
          erreur: "", // On efface les erreurs précédentes
        );

        // Annonce vocale VTC
        if (info.etapes.isNotEmpty) {
          final prochaineEtape = info.etapes.first;
          final svc = ref.read(serviceNavigationVocaleProvider);
          
          if (prochaineEtape.distance <= 500 && prochaineEtape.distance > 150) {
            final phrase = svc.humaniserInstruction(prochaineEtape, estPreAlerte: true);
            final texteAnnonce = "Dans environ ${((prochaineEtape.distance/50).round()*50)} mètres, $phrase";
            if (state.instructionVocaleActuelle != texteAnnonce) {
              state = state.copyWith(instructionVocaleActuelle: texteAnnonce);
              _annoncer(texteAnnonce);
            }
          } else if (prochaineEtape.distance <= 100 && prochaineEtape.distance > 25) {
            final phrase = svc.humaniserInstruction(prochaineEtape, estPreAlerte: false);
            final texteAnnonce = "Maintenant, $phrase";
            if (state.instructionVocaleActuelle != texteAnnonce) {
              state = state.copyWith(instructionVocaleActuelle: texteAnnonce);
              _annoncer(texteAnnonce);
            }
          } else if (prochaineEtape.distance <= 25 && prochaineEtape.type == 'arrive') {
            const texteAnnonce = "Vous êtes arrivé à destination.";
            if (state.instructionVocaleActuelle != texteAnnonce) {
              state = state.copyWith(instructionVocaleActuelle: texteAnnonce);
              _annoncer(texteAnnonce);
            }
          }
        }
      } else {
        throw Exception("Réponse OSRM vide ou invalide");
      }
    } catch (e) {
      print("Erreur de calcul d'itinéraire : \$e");
      
      // Gestion robuste avec Retry automatique
      if (_tentativesRoutage < 3) {
        _tentativesRoutage++;
        state = state.copyWith(erreur: "Impossible de calculer le nouvel itinéraire, nouvelle tentative (\$_tentativesRoutage/3)...");
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) _calculerItineraire();
        });
      } else {
        state = state.copyWith(erreur: "Échec du tracé de l'itinéraire après plusieurs tentatives.");
      }
    }
  }

  void _verifierProximite() {
    if (state.positionChauffeur == null || state.distanceRestanteMetres == 0) return;

    // Si on est à moins de 50 mètres de la cible
    if (state.distanceRestanteMetres < 50) {
       // La logique d'affichage du bouton "Commencer la course" se fera dans la vue (si phase == approche && distance < 50)
    }
  }

  Future<void> _annoncerChangementPhase(PhaseSuivi phase) async {
    if (phase == PhaseSuivi.approche) {
      await _annoncer("Direction : récupération du client.");
    } else if (phase == PhaseSuivi.trajet) {
      await _annoncer("Direction : livraison à destination.");
    } else if (phase == PhaseSuivi.terminee) {
      await _annoncer("Course terminée. Vous êtes arrivé à destination.");
    }
  }

  Future<void> _annoncer(String texte) async {
    final tts = ref.read(serviceNavigationVocaleProvider);
    await tts.annoncer(texte, isVoixActive: state.isVoixActive);
  }

  void basculerVoix() {
    state = state.copyWith(isVoixActive: !state.isVoixActive);
    if (!state.isVoixActive) {
      ref.read(serviceNavigationVocaleProvider).stop();
    }
  }

  Future<void> commencerCourse() async {
    if (state.course == null) return;
    try {
      await FirebaseFirestore.instance.collection('courses').doc(courseId).update({
        'statut': StatutCourse.enTransit,
        'dateModification': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      state = state.copyWith(erreur: "Erreur lors du démarrage : \$e");
    }
  }

  Future<void> terminerCourse() async {
    if (state.course == null) return;
    try {
      print("APPEL DE terminerCourse POUR courseId : \$courseId");
      await FirebaseFirestore.instance.collection('courses').doc(courseId).update({
        'statut': StatutCourse.arriveDestination,
        'dateModification': FieldValue.serverTimestamp(),
      });
      print("MISE A JOUR FIREBASE REUSSIE : arrive_destination");
    } catch (e) {
      print("ERREUR DANS terminerCourse : \$e");
      state = state.copyWith(erreur: "Erreur lors de la fin de course : \$e");
    }
  }

  Future<void> validerPaiementEspeces() async {
    if (state.course == null) return;
    try {
      await FirebaseFirestore.instance.collection('courses').doc(courseId).update({
        'statut': 'terminee',
        'dateModification': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      state = state.copyWith(erreur: "Erreur validation paiement : \$e");
    }
  }

  @override
  void dispose() {
    _courseSub?.cancel();
    _positionSub?.cancel();
    _transporteurSub?.cancel();
    ref.read(serviceNavigationVocaleProvider).stop();
    super.dispose();
  }
}
