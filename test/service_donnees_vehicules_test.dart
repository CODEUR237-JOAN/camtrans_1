import 'package:flutter_test/flutter_test.dart';
import 'package:update_camtrans/services/service_donnees_vehicules.dart';

void main() {
  group('Tests Unitaires : ServiceDonneesVehicules', () {
    late ServiceDonneesVehicules service;

    setUp(() {
      service = ServiceDonneesVehicules();
    });

    test('1. La liste des marques n\'est pas vide et contient des références', () {
      final marques = service.marques;
      
      expect(marques, isNotEmpty, reason: 'La liste des marques doit être renseignée');
      expect(marques.contains('Toyota'), isTrue, reason: 'Toyota doit être présent');
      expect(marques.contains('Autre'), isTrue, reason: 'La marque "Autre" doit être présente');
    });

    test('2. Récupération des modèles pour une marque donnée', () {
      final modelesToyota = service.modelesPour('Toyota');
      final modelesAutre = service.modelesPour('Autre');
      final modelesInconnue = service.modelesPour('MarqueFantome');

      expect(modelesToyota, contains('Corolla'));
      expect(modelesToyota, contains('RAV4'));
      expect(modelesAutre, isEmpty, reason: '"Autre" ne doit pas avoir de modèles prédéfinis');
      expect(modelesInconnue, isEmpty, reason: 'Une marque inconnue doit renvoyer une liste vide');
    });

    test('3. Vérification de la saisie libre', () {
      expect(service.saisieLibreModele('Toyota'), isFalse, reason: 'Toyota a une liste stricte de modèles');
      expect(service.saisieLibreModele('Autre'), isTrue, reason: '"Autre" autorise la saisie libre');
      expect(service.saisieLibreModele('MarqueFantome'), isTrue, reason: 'Une marque inconnue autorise la saisie libre');
    });

    test('4. Recherche et filtrage (insensible à la casse)', () {
      final rechercheCor = service.rechercherModeles('Toyota', 'cor');
      final rechercheVide = service.rechercherModeles('Toyota', '   ');
      
      expect(rechercheCor.length, 1);
      expect(rechercheCor.first, 'Corolla');
      
      expect(rechercheVide.length, greaterThan(10), reason: 'Une requête vide renvoie toute la liste');
    });
  });
}
