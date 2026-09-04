import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import 'package:update_camtrans/services/service_authentification.dart';
import 'package:update_camtrans/services/service_firestore.dart';
import 'package:update_camtrans/services/service_gps.dart';
import 'transporteur_provider.dart';
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

    _positionSubscription = serviceGps.fluxPosition().listen((Position position) {
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
            if (dist < 0.1) { // moins de 100m
               _ref.read(transporteurActionsProvider).changerStatutCourse(activeCourse.id, StatutCourse.arriveDepart);
            }
          } else if (activeCourse.statut == StatutCourse.arriveDepart || activeCourse.statut == StatutCourse.charge) {
            final distToDepart = serviceGps.calculerDistance(
              latitudeDepart: position.latitude,
              longitudeDepart: position.longitude,
              latitudeArrivee: activeCourse.latitudeDepart,
              longitudeArrivee: activeCourse.longitudeDepart,
            );
            // S'il s'éloigne de plus de 150m du point de départ, on déduit qu'il est en transit
            if (distToDepart > 0.15) {
               _ref.read(transporteurActionsProvider).changerStatutCourse(activeCourse.id, StatutCourse.enTransit);
            }
          } else if (activeCourse.statut == StatutCourse.enTransit) {
            final dist = serviceGps.calculerDistance(
              latitudeDepart: position.latitude,
              longitudeDepart: position.longitude,
              latitudeArrivee: activeCourse.latitudeArrivee,
              longitudeArrivee: activeCourse.longitudeArrivee,
            );
            if (dist < 0.1) {
               _ref.read(transporteurActionsProvider).changerStatutCourse(activeCourse.id, StatutCourse.arriveDestination);
            }
          }
        }
      } catch (e) {
        // Ignorer les erreurs de Geofencing
      }

      // 2. Envoyer à Firebase (En supposant que le rôle est connu, ici on met à jour 'transporteurs' et 'utilisateurs')
      // Dans une appli réelle, on optimiserait pour ne pas écrire à Firebase chaque seconde, mais par exemple toutes les 10s ou quand la distance change beaucoup.
      
      try {
        // Mise à jour générique dans la table des transporteurs
        firestore.modifierDocument(
          collection: "transporteurs",
          id: user.uid,
          donnees: {
            "latitude": position.latitude,
            "longitude": position.longitude,
          },
        ).catchError((_) {});
        
        // Optionnel : Mise à jour côté client si besoin de tracker les clients
        firestore.modifierDocument(
          collection: "clients",
          id: user.uid,
          donnees: {
            "latitude": position.latitude,
            "longitude": position.longitude,
          },
        ).catchError((_) {});
      } catch (e) {
        debugPrint("Erreur locale maj GPS: $e");
      }
    });
  }

  void stopTracking() {
    _positionSubscription?.cancel();
    _positionSubscription = null;
  }
}
