import 'package:flutter_test/flutter_test.dart';
import 'package:update_camtrans/coeur/constantes/statuts.dart';

void main() {
  group('Tests Unitaires : Cycle de vie d\'une Course (Machine à états)', () {
    
    test('1. Vérification des statuts actifs', () {
      // Act & Assert
      expect(StatutCourse.estActive(StatutCourse.attribue), isTrue, reason: "Une course attribuée doit être active");
      expect(StatutCourse.estActive(StatutCourse.enTransit), isTrue, reason: "Une course en transit doit être active");
      
      expect(StatutCourse.estActive(StatutCourse.recherche), isFalse, reason: "Une course en recherche n'est pas encore active");
      expect(StatutCourse.estActive(StatutCourse.terminee), isFalse, reason: "Une course terminée n'est plus active");
      expect(StatutCourse.estActive(StatutCourse.annulee), isFalse, reason: "Une course annulée n'est pas active");
    });

    test('2. Vérification des statuts terminaux', () {
      // Act & Assert
      expect(StatutCourse.estTerminee(StatutCourse.terminee), isTrue);
      expect(StatutCourse.estTerminee(StatutCourse.annulee), isTrue);
      
      expect(StatutCourse.estTerminee(StatutCourse.enTransit), isFalse);
    });

    test('3. Validation stricte des transitions (peutTransitionnerVers)', () {
      // Vérification du flux normal (Happy Path)
      expect(StatutCourse.peutTransitionnerVers(StatutCourse.recherche, StatutCourse.propose), isTrue);
      expect(StatutCourse.peutTransitionnerVers(StatutCourse.propose, StatutCourse.attribue), isTrue);
      expect(StatutCourse.peutTransitionnerVers(StatutCourse.attribue, StatutCourse.enRouteDepart), isTrue);
      expect(StatutCourse.peutTransitionnerVers(StatutCourse.arriveDestination, StatutCourse.terminee), isTrue);

      // Vérification des transitions interdites (Sécurité métier)
      // On ne peut pas passer de "Recherche" directement à "En Transit"
      expect(StatutCourse.peutTransitionnerVers(StatutCourse.recherche, StatutCourse.enTransit), isFalse);
      
      // On ne peut pas annuler une course déjà terminée
      expect(StatutCourse.peutTransitionnerVers(StatutCourse.terminee, StatutCourse.annulee), isFalse);
    });
  });

  group('Tests Unitaires : StatutPaiement', () {
    test('4. Validation des libellés de paiement', () {
      expect(StatutPaiement.libelle(StatutPaiement.succes), equals('Réussi'));
      expect(StatutPaiement.libelle(StatutPaiement.enAttente), equals('En attente'));
      expect(StatutPaiement.libelle(StatutPaiement.echec), equals('Échoué'));
    });
  });
}
