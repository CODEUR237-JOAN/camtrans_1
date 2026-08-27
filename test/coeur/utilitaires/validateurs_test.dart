import 'package:flutter_test/flutter_test.dart';
import 'package:update_camtrans/coeur/utilitaires/validateurs.dart';

void main() {
  group('Validateurs', () {
    test('obligatoire retourne null si valide, erreur sinon', () {
      expect(Validateurs.obligatoire('Test'), isNull);
      expect(Validateurs.obligatoire(''), "Ce champ est obligatoire.");
      expect(Validateurs.obligatoire(null, nomChamp: 'Nom'), "Nom est obligatoire.");
    });

    test('nom valide la longueur', () {
      expect(Validateurs.nom('Jean'), isNull);
      expect(Validateurs.nom('Jo'), "Le nom est trop court.");
      expect(Validateurs.nom(''), "Veuillez saisir votre nom.");
    });

    test('email valide le format', () {
      expect(Validateurs.email('test@example.com'), isNull);
      expect(Validateurs.email('test@'), "Adresse e-mail invalide.");
      expect(Validateurs.email('test.com'), "Adresse e-mail invalide.");
    });

    test('telephone valide le format camerounais', () {
      expect(Validateurs.telephone('691234567'), isNull);
      expect(Validateurs.telephone('6 91 23 45 67'), isNull);
      expect(Validateurs.telephone('222334455'), isNull);
      expect(Validateurs.telephone('555334455'), "Numéro camerounais invalide.");
      expect(Validateurs.telephone('69123456'), "Numéro camerounais invalide."); // 8 chiffres au lieu de 9
    });

    test('motDePasse valide la longueur', () {
      expect(Validateurs.motDePasse('12345678'), isNull);
      expect(Validateurs.motDePasse('1234567'), "Le mot de passe doit contenir au moins 8 caractères.");
    });
  });
}
