import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:geocoding/geocoding.dart';
import 'package:update_camtrans/services/service_estimation.dart';
import 'package:update_camtrans/services/service_gps.dart';
import 'package:update_camtrans/services/service_ia.dart';
import 'package:update_camtrans/services/service_routage.dart';
import 'package:image_picker/image_picker.dart';

class MockServiceIA extends ServiceIA {
  
  @override
  Future<Map<String, String>> estimerExpedition({
    required String marchandise,
    required String description,
    required String depart,
    required String destination,
    List<XFile>? fichiersImages,
  }) async {
    return {
      "volume": "15.0",
      "prix": "25000",
      "conseil": "Bien emballer"
    };
  }
}

class MockServiceGps extends ServiceGps {
  @override
  Future<Location?> obtenirCoordonnees(String adresse) async {
    return Location(
      latitude: 4.05,
      longitude: 9.7,
      timestamp: DateTime.now(),
    );
  }
}

class MockServiceRoutage extends ServiceRoutage {
  
  @override
  Future<InfoTrajet?> obtenirItineraire(LatLng depart, LatLng arrivee) async {
    return InfoTrajet(
      points: [depart, arrivee],
      distanceMetres: 20000, // 20 km
      dureeSecondes: 1800, // 30 min
    );
  }
}

void main() {
  group('ServiceEstimation', () {
    late ServiceEstimation serviceEstimation;

    setUp(() {
      serviceEstimation = ServiceEstimation(
        MockServiceIA(),
        MockServiceGps(),
        MockServiceRoutage(),
      );
    });

    test('genererEstimationLocale calcule correctement le prix (Camion lourd)', () async {
      final resultat = await serviceEstimation.genererEstimationLocale(
        depart: 'Douala',
        arrivee: 'Yaoundé',
        typeMarchandise: 'Matériaux de construction',
        description: 'Ciment',
        categorieVehicule: '',
      );

      // Le routage mock retourne 20km
      expect(resultat.distanceKm, 20.0);
      
      // Matériaux -> volume = 15, vehicule = Camion lourd (prix de base 15000)
      expect(resultat.volumeM3, 15.0);
      expect(resultat.vehiculeRecommande, "Camion lourd");
      
      // cout = 15000 (base) + (20 * 500) (distance) + (15 * 1000) (volume)
      // = 15000 + 10000 + 15000 = 40000.0
      expect(resultat.coutTotal, 40000.0);
    });

    test('genererEstimationLocale calcule correctement le prix (Déménagement)', () async {
      final resultat = await serviceEstimation.genererEstimationLocale(
        depart: 'Douala',
        arrivee: 'Bonaberi',
        typeMarchandise: 'Déménagement maison',
        description: 'Meubles',
        categorieVehicule: 'Camionnette',
      );

      // Volume for deménagement is 20
      expect(resultat.volumeM3, 20.0);
      // Even though volume > 10, explicit categorieVehicule 'Camionnette' is provided
      expect(resultat.vehiculeRecommande, "Camionnette");
      
      // cout = 15000 (base camion) + (20 * 500) + (20 * 1000)
      // = 15000 + 10000 + 20000 = 45000.0
      expect(resultat.coutTotal, 45000.0);
    });
  });
}
