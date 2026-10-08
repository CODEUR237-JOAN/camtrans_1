import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:update_camtrans/coeur/constantes/statuts.dart';
import 'package:update_camtrans/services/service_firestore.dart';
import 'package:update_camtrans/services/service_gps.dart';
import 'package:update_camtrans/modeles/course.dart';
import 'package:update_camtrans/modeles/transporteur.dart';
import 'package:update_camtrans/services/service_routage.dart';
import 'package:update_camtrans/services/service_navigation_vocale.dart';

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
      positionTransporteurSimule:
          positionTransporteurSimule ?? this.positionTransporteurSimule,
      distanceRestante: distanceRestante ?? this.distanceRestante,
      tempsRestantSeconds: tempsRestantSeconds ?? this.tempsRestantSeconds,
      quartierTransporteur: quartierTransporteur ?? this.quartierTransporteur,
    );
  }
}

// Provider paramétré par l'ID de la course
final suiviProvider = StateNotifierProvider.autoDispose
    .family<SuiviNotifier, EtatSuivi, String>((ref, courseId) {
  return SuiviNotifier(
      ref.read(serviceFirestoreProvider),
      ref.read(serviceGpsProvider),
      ref.read(serviceRoutageProvider),
      ref.read(serviceNavigationVocaleProvider),
      courseId);
});

class SuiviNotifier extends StateNotifier<EtatSuivi> {
  final ServiceFirestore _firestore;
  final ServiceRoutage _routage;
  final ServiceGps _gps;
  final ServiceNavigationVocale _navVocale;
  StreamSubscription? _courseSubscription;
  StreamSubscription? _transporteurSubscription;
  String? _transporteurIdActuel;
  Timer? _simulateurTimer;

  //  AMÉLIORATION 2.3: Dernier point de géocodage — évite les appels redondants
  LatLng? _dernierePositionGeocodee;
  static const double _seuilGeocodingMetres = 100.0;
  bool _itineraireDemande = false;

  // --- Détection de déviation / recalcul d'itinéraire (rerouting) ---
  // Distance au tracé au-delà de laquelle on considère le chauffeur "hors route".
  static const double _seuilDeviationMetres = 60.0;
  // Nombre de relevés consécutifs hors-route avant de recalculer (anti-jitter GPS).
  static const int _relevesPourRecalcul = 3;
  // Délai minimal entre deux recalculs (anti-spam réseau).
  static const Duration _cooldownRecalcul = Duration(seconds: 15);
  int _devationsConsecutives = 0;
  DateTime? _dernierRecalcul;
  bool _recalculEnCours = false;

  SuiviNotifier(this._firestore, this._gps, this._routage, this._navVocale,
      String courseId)
      : super(EtatSuivi()) {
    _initialiserEcoute(courseId);
  }

  void _initialiserEcoute(String courseId) {
    _courseSubscription = _firestore
        .fluxDocument(collection: 'courses', id: courseId)
        .listen((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        final course = Course.fromMap(snapshot.data()!);

        state = state.copierAvec(course: course, chargement: false);

        // Si le transporteur est défini, on écoute sa position
        if (course.transporteurId.isNotEmpty) {
          if (_transporteurIdActuel != course.transporteurId) {
            _transporteurSubscription?.cancel();
            _transporteurIdActuel = course.transporteurId;
            _ecouterTransporteur(course.transporteurId);
          }
        } else {
          _transporteurSubscription?.cancel();
          _transporteurSubscription = null;
          _transporteurIdActuel = null;
        }

        // Charger l'itinéraire s'il n'est pas encore fait et qu'on a le départ/arrivée
        if (!_itineraireDemande &&
            course.latitudeDepart != 0 &&
            course.latitudeArrivee != 0) {
          _itineraireDemande = true;
          _routage
              .obtenirItineraire(
            LatLng(course.latitudeDepart, course.longitudeDepart),
            LatLng(course.latitudeArrivee, course.longitudeArrivee),
          )
              .then((infoTrajet) {
            if (infoTrajet != null && mounted) {
              state = state.copierAvec(infoTrajet: infoTrajet);
              // Démarrer la navigation vocale dès que le transporteur est en route
              final statutsActifs = [
                StatutCourse.enRouteDepart,
                StatutCourse.arriveDepart,
                StatutCourse.charge,
                StatutCourse.enTransit,
              ];
              if (statutsActifs.contains(course.statut)) {
                final versClient =
                    course.statut == StatutCourse.enRouteDepart ||
                        course.statut == StatutCourse.arriveDepart;
                _navVocale.demarrerNavigation(infoTrajet,
                    versClient: versClient);
              }
            }
          });
        }
      } else {
        state =
            state.copierAvec(erreur: "Course introuvable", chargement: false);
      }
    }, onError: (e) {
      state = state.copierAvec(erreur: e.toString(), chargement: false);
    });
  }

  void _ecouterTransporteur(String transporteurId) {
    _transporteurSubscription = _firestore
        .fluxDocument(collection: 'transporteurs', id: transporteurId)
        .listen((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        final transporteur = Transporteur.fromMap(snapshot.data()!);

        // Calcul dynamique de la distance et du temps si la course est en cours
        double distanceRestante = state.distanceRestante;
        double tempsRestant = state.tempsRestantSeconds;

        if (state.course != null &&
            transporteur.latitude != 0 &&
            transporteur.longitude != 0) {
          final course = state.course!;
          // Destination cible : point de départ si pas encore chargé, sinon point d'arrivée
          double latCible = course.latitudeDepart;
          double lngCible = course.longitudeDepart;

          if (course.statut == StatutCourse.charge ||
              course.statut == StatutCourse.enTransit) {
            latCible = course.latitudeArrivee;
            lngCible = course.longitudeArrivee;
          }

          // On utilise une distance en ligne droite pour l'approximation temps réel (pour la fluidité)
          final distance = const Distance().as(
              LengthUnit.Meter,
              LatLng(transporteur.latitude, transporteur.longitude),
              LatLng(latCible, lngCible));
          distanceRestante = distance.toDouble();
          // Estimation : 30 km/h en moyenne en ville (8.3 m/s)
          tempsRestant = distanceRestante / 8.3;

          // Mise à jour de la navigation vocale pour le chauffeur
          final positionChauffeur =
              LatLng(transporteur.latitude, transporteur.longitude);
          _navVocale.mettreAJourPosition(positionChauffeur);

          // Détection de déviation → annonce + recalcul de l'itinéraire
          _verifierDeviation(positionChauffeur);
        }

        state = state.copierAvec(
          transporteur: transporteur,
          distanceRestante: distanceRestante,
          tempsRestantSeconds: tempsRestant,
        );

        //  AMÉLIORATION 2.3: Ne géocoder que si la position a changé de >100m
        // Cela réduit massivement les appels API inutiles à chaque update Firestore
        if (transporteur.latitude != 0 && transporteur.longitude != 0) {
          final positionNavVocale =
              LatLng(transporteur.latitude, transporteur.longitude);
          final bool doitGeocoderDernierePosition =
              _dernierePositionGeocodee == null;
          final bool positionChangeeSignificativement =
              !doitGeocoderDernierePosition &&
                  const Distance().as(
                        LengthUnit.Meter,
                        _dernierePositionGeocodee!,
                        positionNavVocale,
                      ) >
                      _seuilGeocodingMetres;

          if (doitGeocoderDernierePosition ||
              positionChangeeSignificativement) {
            _dernierePositionGeocodee = positionNavVocale;
            _gps
                .obtenirAdresse(
              latitude: transporteur.latitude,
              longitude: transporteur.longitude,
            )
                .then((adresse) {
              final quartier = adresse.split(',').first.trim();
              if (mounted) {
                state = state.copierAvec(quartierTransporteur: quartier);
              }
            }).catchError((_) {});
          }
        }
      }
    }, onError: (e) {
      state = state.copierAvec(erreur: e.toString());
    });
  }

  // ------------------------------------------------------------------
  // REROUTING : détection de déviation + recalcul de l'itinéraire
  // ------------------------------------------------------------------

  /// Phases où le chauffeur roule réellement (donc où une déviation a du sens).
  static const List<String> _phasesDeConduite = [
    StatutCourse.enRouteDepart,
    StatutCourse.charge,
    StatutCourse.enTransit,
  ];

  void _verifierDeviation(LatLng position) {
    final trajet = state.infoTrajet;
    final course = state.course;
    if (trajet == null || course == null || _recalculEnCours) return;
    if (trajet.points.length < 2) return;
    if (!_phasesDeConduite.contains(course.statut)) {
      _devationsConsecutives = 0;
      return;
    }

    final distanceAuTrace = _distanceMinAuTrace(position, trajet.points);

    if (distanceAuTrace > _seuilDeviationMetres) {
      _devationsConsecutives++;
    } else {
      _devationsConsecutives = 0; // De retour sur la route.
      return;
    }

    if (_devationsConsecutives < _relevesPourRecalcul) return;

    // Anti-spam : respecter le délai minimal entre deux recalculs.
    final maintenant = DateTime.now();
    if (_dernierRecalcul != null &&
        maintenant.difference(_dernierRecalcul!) < _cooldownRecalcul) {
      return;
    }
    _dernierRecalcul = maintenant;
    _devationsConsecutives = 0;
    _recalculerItineraire(position);
  }

  Future<void> _recalculerItineraire(LatLng depuis) async {
    final course = state.course;
    if (course == null) return;
    _recalculEnCours = true;

    // 1. Annonce vocale calme (coupe la voix en cours).
    _navVocale.announceRerouting();

    try {
      // 2. Cible selon la phase : point de départ (vers client) ou arrivée.
      final versDestination = course.statut == StatutCourse.charge ||
          course.statut == StatutCourse.enTransit;
      final cible = versDestination
          ? LatLng(course.latitudeArrivee, course.longitudeArrivee)
          : LatLng(course.latitudeDepart, course.longitudeDepart);

      final nouveau = await _routage.obtenirItineraire(depuis, cible);
      if (nouveau != null && mounted) {
        state = state.copierAvec(infoTrajet: nouveau);
        // 3. Le guidage suit le nouveau tracé (sans ré-annoncer le démarrage).
        _navVocale.rafraichirItineraire(nouveau);
      }
    } catch (e) {
      debugPrint('[Suivi] Échec du recalcul d\'itinéraire : $e');
    } finally {
      _recalculEnCours = false;
    }
  }

  /// Distance minimale (mètres) entre un point et le tracé (polyligne),
  /// en projetant sur chaque segment — pas seulement sur les sommets.
  double _distanceMinAuTrace(LatLng p, List<LatLng> points) {
    double min = double.infinity;
    for (int i = 0; i < points.length - 1; i++) {
      final d = _distancePointSegmentMetres(p, points[i], points[i + 1]);
      if (d < min) min = d;
    }
    return min;
  }

  /// Distance point→segment en mètres (projection équirectangulaire locale,
  /// précise à l'échelle urbaine).
  double _distancePointSegmentMetres(LatLng p, LatLng a, LatLng b) {
    const double rayonTerre = 6371000.0;
    double rad(double deg) => deg * math.pi / 180.0;
    final double lat0 = rad((a.latitude + b.latitude) / 2.0);
    double projX(LatLng q) => rayonTerre * rad(q.longitude) * math.cos(lat0);
    double projY(LatLng q) => rayonTerre * rad(q.latitude);

    final px = projX(p), py = projY(p);
    final ax = projX(a), ay = projY(a);
    final bx = projX(b), by = projY(b);

    final dx = bx - ax, dy = by - ay;
    final longueur2 = dx * dx + dy * dy;
    double t =
        longueur2 == 0 ? 0.0 : ((px - ax) * dx + (py - ay) * dy) / longueur2;
    if (t < 0.0) t = 0.0;
    if (t > 1.0) t = 1.0;

    final cx = ax + t * dx, cy = ay + t * dy;
    final ex = px - cx, ey = py - cy;
    return math.sqrt(ex * ex + ey * ey);
  }

  @override
  void dispose() {
    _courseSubscription?.cancel();
    _transporteurSubscription?.cancel();
    _simulateurTimer?.cancel();
    _navVocale.arreterNavigation();
    super.dispose();
  }
}
