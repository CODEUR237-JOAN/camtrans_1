import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final serviceRoutageProvider = Provider<ServiceRoutage>((ref) {
  return ServiceRoutage();
});

class EtapeTrajet {
  final LatLng coordonnee;
  final String instruction;
  final double distance;
  final String type;
  final String modifier;
  final String nomRue;
  
  EtapeTrajet({
    required this.coordonnee,
    required this.instruction,
    required this.distance,
    required this.type,
    required this.modifier,
    required this.nomRue,
  });
}

class InfoTrajet {
  final List<LatLng> points;
  final double distanceMetres;
  final double dureeSecondes;
  final List<EtapeTrajet> etapes; // Nouvelles étapes vocales

  InfoTrajet({
    required this.points,
    required this.distanceMetres,
    required this.dureeSecondes,
    required this.etapes,
  });
}

class ServiceRoutage {
  final Dio _dio = Dio();

  /// Demande le tracé OSRM entre deux points avec les étapes de navigation (steps=true)
  Future<InfoTrajet?> obtenirItineraire(LatLng depart, LatLng arrivee) async {
    try {
      // Ajout de steps=true et language=fr pour avoir les instructions
      final String url = 'http://router.project-osrm.org/route/v1/driving/'
          '${depart.longitude},${depart.latitude};'
          '${arrivee.longitude},${arrivee.latitude}'
          '?overview=full&geometries=geojson&steps=true&language=fr';

      final response = await _dio.get(url);

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['routes'] != null && (data['routes'] as List).isNotEmpty) {
          final route = data['routes'][0];

          final geometry = route['geometry'];
          final coordinates = geometry['coordinates'] as List;

          List<LatLng> points = coordinates.map((coord) {
            return LatLng(
                (coord[1] as num).toDouble(), (coord[0] as num).toDouble());
          }).toList();

          // Extraction des étapes (turn-by-turn)
          List<EtapeTrajet> etapes = [];
          if (route['legs'] != null && (route['legs'] as List).isNotEmpty) {
            final leg = route['legs'][0];
            if (leg['steps'] != null) {
              for (var step in leg['steps']) {
                final maneuver = step['maneuver'];
                final location = maneuver['location'] as List;
                
                etapes.add(EtapeTrajet(
                  coordonnee: LatLng((location[1] as num).toDouble(), (location[0] as num).toDouble()),
                  instruction: maneuver['instruction'] ?? step['name'] ?? 'Continuez',
                  distance: (step['distance'] as num).toDouble(),
                  type: maneuver['type'] ?? '',
                  modifier: maneuver['modifier'] ?? '',
                  nomRue: step['name'] ?? '',
                ));
              }
            }
          }

          return InfoTrajet(
            points: points,
            distanceMetres: (route['distance'] as num).toDouble(),
            dureeSecondes: (route['duration'] as num).toDouble(),
            etapes: etapes,
          );
        }
      }
      return null;
    } catch (e) {
      debugPrint("Erreur de routage OSRM : $e");
      return null;
    }
  }
}
