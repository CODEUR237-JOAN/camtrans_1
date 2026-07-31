import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final serviceRoutageProvider = Provider<ServiceRoutage>((ref) {
  return ServiceRoutage();
});

class InfoTrajet {
  final List<LatLng> points;
  final double distanceMetres;
  final double dureeSecondes;

  InfoTrajet({
    required this.points,
    required this.distanceMetres,
    required this.dureeSecondes,
  });
}

class ServiceRoutage {
  final Dio _dio = Dio();

  /// Demande le tracé OSRM entre deux points.
  Future<InfoTrajet?> obtenirItineraire(LatLng depart, LatLng arrivee) async {
    try {
      final String url = 
          'http://router.project-osrm.org/route/v1/driving/'
          '${depart.longitude},${depart.latitude};'
          '${arrivee.longitude},${arrivee.latitude}'
          '?overview=full&geometries=geojson';

      final response = await _dio.get(url);

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['routes'] != null && (data['routes'] as List).isNotEmpty) {
          final route = data['routes'][0];
          
          final geometry = route['geometry'];
          final coordinates = geometry['coordinates'] as List;
          
          List<LatLng> points = coordinates.map((coord) {
            // OSRM renvoie [longitude, latitude]
            return LatLng((coord[1] as num).toDouble(), (coord[0] as num).toDouble());
          }).toList();

          return InfoTrajet(
            points: points,
            distanceMetres: (route['distance'] as num).toDouble(),
            dureeSecondes: (route['duration'] as num).toDouble(),
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
