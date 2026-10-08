import 'package:flutter_test/flutter_test.dart';
import 'package:update_camtrans/services/service_ia.dart';

void main() {
  group('ServiceIA - Tests de Fallback et Extraction JSON', () {
    final serviceIA = ServiceIA();

    test('Doit extraire un JSON pur', () {
      const jsonPur = '{"vehicule": "Moto", "prix": "5000 FCFA"}';
      final res = serviceIA.extraireJson(jsonPur);
      expect(res, isNotNull);
      expect(res!['vehicule'], equals('Moto'));
    });

    test('Doit extraire un JSON entouré de backticks markdown', () {
      const markdownJson = '''
Voici votre réponse :
```json
{
  "vehicule": "Camionnette",
  "volume": "10 m3"
}
```
Bonne journée !
''';
      final res = serviceIA.extraireJson(markdownJson);
      expect(res, isNotNull);
      expect(res!['vehicule'], equals('Camionnette'));
      expect(res['volume'], equals('10 m3'));
    });

    test('Doit extraire le premier objet JSON dans un texte brut', () {
      const texteBrut = 'Je pense que le véhicule idéal est {"vehicule": "Plateau", "prix": "15000"} car c\'est grand.';
      final res = serviceIA.extraireJson(texteBrut);
      expect(res, isNotNull);
      expect(res!['vehicule'], equals('Plateau'));
    });

    test('Doit retourner null si aucun JSON n\'est présent', () {
      const texteInvalide = 'Il n\'y a pas de données JSON ici.';
      final res = serviceIA.extraireJson(texteInvalide);
      expect(res, isNull);
    });
  });
}
