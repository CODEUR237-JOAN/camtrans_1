import 'package:flutter_test/flutter_test.dart';
import 'package:update_camtrans/coeur/utilitaires/validateurs.dart';

void main() {
  group('Tests Unitaires : Processus d\'Authentification', () {
    
    test('1. Validation stricte des adresses e-mail', () {
      // Cas de succès (Emails valides)
      expect(Validateurs.email('client@camtrans.cm'), isNull, reason: "Un email correct ne doit retourner aucune erreur");
      expect(Validateurs.email('transporteur.123@gmail.com'), isNull);

      // Cas d'échec (Emails invalides)
      expect(Validateurs.email(''), equals('Veuillez saisir votre adresse e-mail.'));
      expect(Validateurs.email('client@'), equals('Adresse e-mail invalide.'));
      expect(Validateurs.email('client.com'), equals('Adresse e-mail invalide.'));
      expect(Validateurs.email('client@domaine'), equals('Adresse e-mail invalide.'));
    });

    test('2. Validation des mots de passe (Sécurité)', () {
      // Cas de succès (Mot de passe fort/valide)
      expect(Validateurs.motDePasse('Securite123!'), isNull);
      
      // Cas d'échec (Trop court ou vide)
      expect(Validateurs.motDePasse(''), equals('Veuillez saisir votre mot de passe.'));
      expect(Validateurs.motDePasse('12345'), equals('Le mot de passe doit contenir au moins 8 caractères.'));
    });

    test('3. Confirmation du mot de passe', () {
      // Cas de succès
      expect(Validateurs.confirmerMotDePasse('Mdp12345', 'Mdp12345'), isNull);

      // Cas d'échec (Non correspondance)
      expect(Validateurs.confirmerMotDePasse('Mdp12345', 'Different!'), equals('Les mots de passe ne correspondent pas.'));
      expect(Validateurs.confirmerMotDePasse('', 'Mdp12345'), equals('Veuillez confirmer votre mot de passe.'));
    });

    test('4. Validation des numéros de téléphone (Format Camerounais)', () {
      // Cas de succès (Commence par 6 ou 2, suivi de 8 chiffres)
      expect(Validateurs.telephone('699123456'), isNull);
      expect(Validateurs.telephone('222123456'), isNull);
      // Doit gérer les espaces
      expect(Validateurs.telephone('699 12 34 56'), isNull);

      // Cas d'échec
      expect(Validateurs.telephone('599123456'), equals('Numéro camerounais invalide.')); // Ne commence pas par 6 ou 2
      expect(Validateurs.telephone('69912345'), equals('Numéro camerounais invalide.')); // Trop court
    });
  });
}
