import 'package:flutter_test/flutter_test.dart';
import 'package:update_camtrans/coeur/constantes/statuts.dart';

void main() {
  group('StatutCourse', () {
    test('estActive retourne true pour les statuts en cours', () {
      expect(StatutCourse.estActive(StatutCourse.attribue), isTrue);
      expect(StatutCourse.estActive(StatutCourse.enRouteDepart), isTrue);
      expect(StatutCourse.estActive(StatutCourse.arriveDepart), isTrue);
      expect(StatutCourse.estActive(StatutCourse.charge), isTrue);
      expect(StatutCourse.estActive(StatutCourse.enTransit), isTrue);
      expect(StatutCourse.estActive(StatutCourse.arriveDestination), isTrue);
      
      expect(StatutCourse.estActive(StatutCourse.recherche), isFalse);
      expect(StatutCourse.estActive(StatutCourse.terminee), isFalse);
      expect(StatutCourse.estActive(StatutCourse.annulee), isFalse);
    });

    test('estTerminee retourne true pour terminee et annulee', () {
      expect(StatutCourse.estTerminee(StatutCourse.terminee), isTrue);
      expect(StatutCourse.estTerminee(StatutCourse.annulee), isTrue);
      
      expect(StatutCourse.estTerminee(StatutCourse.enTransit), isFalse);
      expect(StatutCourse.estTerminee(StatutCourse.attribue), isFalse);
    });

    test('peutTransitionnerVers vérifie le cycle de vie de la course', () {
      // Transitions valides
      expect(StatutCourse.peutTransitionnerVers(StatutCourse.recherche, StatutCourse.attribue), isTrue);
      expect(StatutCourse.peutTransitionnerVers(StatutCourse.attribue, StatutCourse.enRouteDepart), isTrue);
      expect(StatutCourse.peutTransitionnerVers(StatutCourse.enRouteDepart, StatutCourse.arriveDepart), isTrue);
      expect(StatutCourse.peutTransitionnerVers(StatutCourse.arriveDepart, StatutCourse.charge), isTrue);
      expect(StatutCourse.peutTransitionnerVers(StatutCourse.charge, StatutCourse.enTransit), isTrue);
      expect(StatutCourse.peutTransitionnerVers(StatutCourse.enTransit, StatutCourse.arriveDestination), isTrue);
      expect(StatutCourse.peutTransitionnerVers(StatutCourse.arriveDestination, StatutCourse.terminee), isTrue);
      
      // Annulations valides
      expect(StatutCourse.peutTransitionnerVers(StatutCourse.recherche, StatutCourse.annulee), isTrue);
      expect(StatutCourse.peutTransitionnerVers(StatutCourse.attribue, StatutCourse.annulee), isTrue);
      
      // Transitions invalides (saut d'étape)
      expect(StatutCourse.peutTransitionnerVers(StatutCourse.attribue, StatutCourse.charge), isFalse);
      expect(StatutCourse.peutTransitionnerVers(StatutCourse.recherche, StatutCourse.terminee), isFalse);
      expect(StatutCourse.peutTransitionnerVers(StatutCourse.arriveDestination, StatutCourse.enTransit), isFalse); // Pas de retour en arrière
    });
  });

  group('StatutPaiement', () {
    test('libelle retourne la bonne chaîne', () {
      expect(StatutPaiement.libelle(StatutPaiement.enAttente), 'En attente');
      expect(StatutPaiement.libelle(StatutPaiement.succes), 'Réussi');
      expect(StatutPaiement.libelle(StatutPaiement.echec), 'Échoué');
      expect(StatutPaiement.libelle(StatutPaiement.rembourse), 'Remboursé');
      expect(StatutPaiement.libelle('statut_inconnu'), 'statut_inconnu'); // par défaut
    });
  });
}
