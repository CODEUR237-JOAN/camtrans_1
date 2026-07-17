import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final serviceGpsProvider = Provider<ServiceGps>((ref) {
  return ServiceGps();
});

class ServiceGps {
  // ===========================
  // Vérifier les permissions GPS
  // ===========================

  Future<bool> verifierPermissions() async {
    bool serviceActive = await Geolocator.isLocationServiceEnabled();

    if (!serviceActive) {
      return false;
    }

    LocationPermission permission =
    await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();

      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  // ===========================
  // Position actuelle
  // ===========================

  Future<Position?> obtenirPositionActuelle() async {
    final autorise = await verifierPermissions();

    if (!autorise) {
      return null;
    }

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.best,
    );
  }

  // ===========================
  // Flux de localisation
  // ===========================

  Stream<Position> fluxPosition() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 10,
      ),
    );
  }

  // ===========================
  // Coordonnées -> Adresse
  // ===========================

  Future<String> obtenirAdresse({
    required double latitude,
    required double longitude,
  }) async {
    final places = await placemarkFromCoordinates(
      latitude,
      longitude,
    );

    if (places.isEmpty) {
      return "";
    }

    final p = places.first;

    return "${p.street}, ${p.locality}, ${p.country}";
  }

  // ===========================
  // Adresse -> Coordonnées
  // ===========================

  Future<Location?> obtenirCoordonnees(
      String adresse,
      ) async {
    final locations = await locationFromAddress(
      adresse,
    );

    if (locations.isEmpty) {
      return null;
    }

    return locations.first;
  }

  // ===========================
  // Distance entre deux points
  // ===========================

  double calculerDistance({
    required double latitudeDepart,
    required double longitudeDepart,
    required double latitudeArrivee,
    required double longitudeArrivee,
  }) {
    return Geolocator.distanceBetween(
      latitudeDepart,
      longitudeDepart,
      latitudeArrivee,
      longitudeArrivee,
    ) /
        1000;
  }

  // ===========================
  // Ouvrir les paramètres GPS
  // ===========================

  Future<void> ouvrirParametres() async {
    await Geolocator.openLocationSettings();
  }

  // ===========================
  // Ouvrir les paramètres des permissions
  // ===========================

  Future<void> ouvrirParametresApplication() async {
    await Geolocator.openAppSettings();
  }
}