import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:update_camtrans/services/service_lieux.dart';

void main() {
  group('Tests Unitaires : ServiceLieux (avec Mock HTTP)', () {
    test('1. Une requête de moins de 3 caractères renvoie une liste vide sans appel réseau', () async {
      // Un client qui va planter s'il est appelé, pour prouver qu'il n'y a pas d'appel réseau.
      final mockClientFuyant = MockClient((request) async {
        throw Exception('Appel réseau inattendu');
      });
      final service = ServiceLieux(client: mockClientFuyant);
      
      final resultats = await service.rechercher('ya');
      expect(resultats, isEmpty, reason: 'La requête est trop courte (min 3 caractères)');
    });

    test('2. Succès de la recherche : parsing correct de l\'API Nominatim', () async {
      final jsonResponse = [
        {
          "lat": "3.866667",
          "lon": "11.516667",
          "display_name": "Bastos, Yaoundé, Centre, Cameroun",
          "address": {
            "neighbourhood": "Bastos",
            "city": "Yaoundé"
          }
        }
      ];

      final mockClientSuccess = MockClient((request) async {
        expect(request.url.host, 'nominatim.openstreetmap.org');
        expect(request.url.queryParameters['q'], 'bastos');
        return http.Response(jsonEncode(jsonResponse), 200);
      });

      final service = ServiceLieux(client: mockClientSuccess);
      final resultats = await service.rechercher('bastos');

      expect(resultats.length, 1);
      expect(resultats.first.libelle, 'Bastos, Yaoundé');
      expect(resultats.first.latitude, 3.866667);
      expect(resultats.first.longitude, 11.516667);
    });

    test('3. Échec HTTP (ex: 500) géré élégamment (renvoie une liste vide)', () async {
      final mockClientFail = MockClient((request) async {
        return http.Response('Internal Server Error', 500);
      });

      final service = ServiceLieux(client: mockClientFail);
      final resultats = await service.rechercher('douala');

      expect(resultats, isEmpty, reason: 'Une erreur 500 doit être interceptée et renvoyer []');
    });
  });
}
