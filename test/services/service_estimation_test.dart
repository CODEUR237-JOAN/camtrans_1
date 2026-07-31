import 'package:flutter_test/flutter_test.dart';
import 'package:update_camtrans/services/service_estimation.dart';

void main() {
  group('ServiceEstimation Tests', () {
    late ServiceEstimation service;

    setUp(() {
      service = ServiceEstimation();
    });

    test('genererEstimationLocale - estimation de base (léger)', () async {
      final resultat = await service.genererEstimationLocale(
        depart: 'Paris', // 5 chars
        arrivee: 'Lyon', // 4 chars
        typeMarchandise: 'léger',
        description: 'Un petit colis',
        categorieVehicule: '',
      );

      // Distance estimée: (5 + 4) * 1.5 = 13.5
      expect(resultat.distanceKm, 13.5);
      // Volume simulé pour léger: 0.5
      expect(resultat.volumeM3, 0.5);
      // Poids simulé pour léger: 10.0
      expect(resultat.poidsKg, 10.0);
      
      // Véhicule recommandé par défaut si léger et petit volume: Moto
      expect(resultat.vehiculeRecommande, 'Moto');
      
      // Coût: 2000 (base Moto) + (13.5 * 500) + (0.5 * 1000)
      // 2000 + 6750 + 500 = 9250
      expect(resultat.coutTotal, 9250.0);
    });

    test('genererEstimationLocale - estimation lourd (camion)', () async {
      final resultat = await service.genererEstimationLocale(
        depart: 'Marseille', // 9 chars
        arrivee: 'Lille', // 5 chars
        typeMarchandise: 'lourd',
        description: 'Des matériaux',
        categorieVehicule: '',
      );

      // Distance estimée: (9 + 5) * 1.5 = 21.0
      expect(resultat.distanceKm, 21.0);
      // Lourd: volume 15.0, poids 800.0
      expect(resultat.volumeM3, 15.0);
      expect(resultat.poidsKg, 800.0);
      
      // Véhicule recommandé: Camion lourd
      expect(resultat.vehiculeRecommande, 'Camion lourd');
      
      // Coût: 15000 (base Camion) + (21 * 500) + (15 * 1000)
      // 15000 + 10500 + 15000 = 40500
      expect(resultat.coutTotal, 40500.0);
    });
  });
}
