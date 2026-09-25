import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

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

    LocationPermission permission = await Geolocator.checkPermission();

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
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.best),
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
    try {
      final places = await placemarkFromCoordinates(
        latitude,
        longitude,
      );

      if (places.isEmpty) {
        return "Position inconnue ($latitude, $longitude)";
      }

      final p = places.first;

      // Construction d'une adresse descriptive : Quartier, Ville, Pays
      // subLocality correspond souvent au quartier
      final quartier =
          p.subLocality?.isNotEmpty == true ? p.subLocality : p.thoroughfare;
      final ville =
          p.locality?.isNotEmpty == true ? p.locality : p.subAdministrativeArea;
      final pays = p.country;

      List<String> composants = [];
      if (quartier != null && quartier.isNotEmpty) composants.add(quartier);
      if (ville != null && ville.isNotEmpty) composants.add(ville);
      if (pays != null && pays.isNotEmpty) composants.add(pays);

      return composants.join(", ");
    } catch (e) {
      return "Erreur de localisation ($latitude, $longitude)";
    }
  }

  // ===========================
  // Adresse -> Coordonnées
  // ===========================

  Future<Location?> obtenirCoordonnees(
    String adresse,
  ) async {
    try {
      if (adresse.isEmpty) return null;

      // Forcer la recherche au Cameroun pour éviter les homonymes dans d'autres pays
      String requete = adresse;
      if (!requete.toLowerCase().contains("cameroun") &&
          !requete.toLowerCase().contains("cameroon")) {
        requete = "$requete, Cameroun";
      }

      final locations = await locationFromAddress(
        requete,
      );

      if (locations.isEmpty) {
        return await _geocodingFallback(requete);
      }

      return locations.first;
    } catch (e) {
      debugPrint("Erreur geocoding primaire pour $adresse : $e");
      // Fallback vers OpenStreetMap si le geocoder natif échoue (ex: Web ou Google Services manquant)
      return await _geocodingFallback(adresse);
    }
  }

  Future<Location?> _geocodingFallback(String adresse) async {
    try {
      String requete = adresse;
      if (!requete.toLowerCase().contains("cameroun") &&
          !requete.toLowerCase().contains("cameroon")) {
        requete = "$requete, Cameroun";
      }
      final url = Uri.parse('https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(requete)}&format=json&limit=1');
      final reponse = await http.get(url, headers: {'User-Agent': 'CamTransApp'});
      
      if (reponse.statusCode == 200) {
        final List donnees = jsonDecode(reponse.body);
        if (donnees.isNotEmpty) {
          final lat = double.parse(donnees[0]['lat'].toString());
          final lon = double.parse(donnees[0]['lon'].toString());
          return Location(
            latitude: lat,
            longitude: lon,
            timestamp: DateTime.now(),
          );
        }
      }
      return null;
    } catch (e) {
      debugPrint("Erreur geocoding fallback pour $adresse : $e");
      return null;
    }
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
