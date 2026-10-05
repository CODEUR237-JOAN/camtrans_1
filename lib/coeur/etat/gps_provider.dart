import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import 'package:update_camtrans/services/service_authentification.dart';
import 'package:update_camtrans/services/service_firestore.dart';
import 'package:update_camtrans/services/service_gps.dart';
import 'transporteur_provider.dart';
import 'package:update_camtrans/coeur/etat/utilisateur_provider.dart';
import 'package:update_camtrans/coeur/constantes/statuts.dart';

// Provider qui maintient la position actuelle en mémoire (utile pour l'UI)
final positionActuelleProvider = StateProvider<Position?>((ref) => null);

// Provider qui gère la logique de suivi GPS en arrière-plan
final gpsTrackerProvider = Provider<GpsTracker>((ref) {
  final tracker = GpsTracker(ref);
  ref.onDispose(() => tracker.stopTracking());
  return tracker;
});

class GpsTracker {
  final Ref _ref;
  StreamSubscription<Position>? _positionSubscription;

  // Throttling des écritures Firestore (batterie + coût cloud).
  DateTime _dernierEnvoi = DateTime.fromMillisecondsSinceEpoch(0);
  double? _derniereLat;
  double? _derniereLng;

  GpsTracker(this._ref);

  Future<void> startTracking() async {
    final serviceGps = _ref.read(serviceGpsProvider);
    final auth = _ref.read(serviceAuthentificationProvider);
    final firestore = _ref.read(serviceFirestoreProvider);

    final user = auth.utilisateur;
    if (user == null) return;

    // Vérifier les permissions avant de commencer
    bool autorise = await serviceGps.verifierPermissions();
    if (!autorise) return;

    // Arrêter le tracker existant s'il y en a un
    stopTracking();

    // Déterminer le rôle UNE SEULE FOIS → on n'écrit que dans la bonne
    // collection (évite de créer un document parasite dans l'autre).
    String? role;
    try {
      role = await _ref.read(userRoleProvider.future);
    } catch (_) {}
    final collectionCible = role == 'transporteur' ? 'transporteurs' : 'clients';

    _positionSubscription =
        serviceGps.fluxPosition().listen((Position position) {
      // 1. Mettre à jour l'état local pour l'UI
      _ref.read(positionActuelleProvider.notifier).state = position;

      // 1b. Geofencing (Statuts Auto-pilote)
      try {
        final activeCourse = _ref.read(activeCourseProvider);
        if (activeCourse != null) {
          if (activeCourse.statut == StatutCourse.enRouteDepart) {
            final dist = serviceGps.calculerDistance(
              latitudeDepart: position.latitude,
              longitudeDepart: position.longitude,
              latitudeArrivee: activeCourse.latitudeDepart,
              longitudeArrivee: activeCourse.longitudeDepart,
            );
            if (dist < 0.1) {
              // moins de 100m
              _ref.read(transporteurActionsProvider).changerStatutCourse(
                  activeCourse.id, StatutCourse.arriveDepart);
            }
          } else if (activeCourse.statut == StatutCourse.arriveDepart ||
              activeCourse.statut == StatutCourse.charge) {
            final distToDepart = serviceGps.calculerDistance(
              latitudeDepart: position.latitude,
              longitudeDepart: position.longitude,
              latitudeArrivee: activeCourse.latitudeDepart,
              longitudeArrivee: activeCourse.longitudeDepart,
            );
            // S'il s'éloigne de plus de 150m du point de départ, on déduit qu'il est en transit
            if (distToDepart > 0.15) {
              _ref
                  .read(transporteurActionsProvider)
                  .changerStatutCourse(activeCourse.id, StatutCourse.enTransit);
            }
          } else if (activeCourse.statut == StatutCourse.enTransit) {
            final dist = serviceGps.calculerDistance(
              latitudeDepart: position.latitude,
              longitudeDepart: position.longitude,
              latitudeArrivee: activeCourse.latitudeArrivee,
              longitudeArrivee: activeCourse.longitudeArrivee,
            );
            if (dist < 0.1) {
              _ref.read(transporteurActionsProvider).changerStatutCourse(
                  activeCourse.id, StatutCourse.arriveDestination);
            }
          }
        }
      } catch (e) {
        // Ignorer les erreurs de Geofencing
      }

      // 2. Envoyer à Firebase — OPTIMISÉ : au plus une écriture toutes les
      //    8 s ET après ~30 m de déplacement, dans la SEULE bonne collection.
      //    Évite de vider le quota Firestore et de drainer la batterie.
      final maintenant = DateTime.now();
      final assezDeTemps = maintenant.difference(_dernierEnvoi).inSeconds >= 8;
      final assezLoin = _derniereLat == null ||
          serviceGps.calculerDistance(
                latitudeDepart: _derniereLat!,
                longitudeDepart: _derniereLng!,
                latitudeArrivee: position.latitude,
                longitudeArrivee: position.longitude,
              ) >
              0.03; // 30 m (calculerDistance renvoie des km)

      if (assezDeTemps && assezLoin) {
        _dernierEnvoi = maintenant;
        _derniereLat = position.latitude;
        _derniereLng = position.longitude;
        firestore.modifierDocument(
          collection: collectionCible,
          id: user.uid,
          donnees: {
            "latitude": position.latitude,
            "longitude": position.longitude,
          },
        ).catchError((_) {});
      }
    });
  }

  void stopTracking() {
    _positionSubscription?.cancel();
    _positionSubscription = null;
  }
}
