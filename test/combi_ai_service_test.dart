import 'package:flutter_test/flutter_test.dart';
import 'package:update_camtrans/services/combi_ai_service.dart';

// =====================================================================
// Tests unitaires de l'assistant vocal « Combi ».
//
// On teste la LOGIQUE PURE et critique (statique) sans toucher aux
// canaux natifs TTS/STT :
//   1. L'Easter egg d'identité (phrase exacte garantie hors LLM).
//   2. Le cloisonnement RBAC du System Prompt (client vs transporteur).
//   3. Le nettoyage du texte avant la synthèse vocale.
// =====================================================================
void main() {
  group('Combi — Easter egg d\'identité', () {
    test('Déclenché par les formulations courantes « qui t\'a créé »', () {
      const phrases = [
        "Qui t'a créé ?",
        "Qui est ton créateur ?",
        "Qui t'a conçu ?",
        "Qui t'a développé ?",
        "Dis-moi, c'est qui ton créateur",
        "Qui t'a fabriqué ?",
      ];
      for (final p in phrases) {
        expect(
          CombiAIService.estQuestionCreateur(p),
          isTrue,
          reason: 'Doit reconnaître la question d\'identité : "$p"',
        );
      }
    });

    test('La phrase exacte du créateur est figée (cahier des charges)', () {
      expect(
        CombiAIService.reponseCreateur,
        equals("Mon créateur est l'ingénieur DONGMO JOAN."),
      );
    });

    test('N\'est PAS déclenché par une demande métier légitime', () {
      // Un client qui veut CRÉER une demande ne doit pas recevoir
      // l'Easter egg : le verbe « créer » seul ne suffit pas.
      const phrasesMetier = [
        "Je veux créer une demande d'expédition",
        "Peux-tu créer ma course ?",
        "Crée une nouvelle réservation",
        "Bonjour, comment ça va ?",
        "Accepter cette course",
        "Quel est le prix pour Douala ?",
      ];
      for (final p in phrasesMetier) {
        expect(
          CombiAIService.estQuestionCreateur(p),
          isFalse,
          reason: 'Ne doit PAS être pris pour une question d\'identité : "$p"',
        );
      }
    });
  });

  group('Combi — Cloisonnement RBAC du System Prompt', () {
    test('Tous les profils portent l\'identité et l\'Easter egg', () {
      for (final role in ['client', 'transporteur', 'admin', null]) {
        final prompt = CombiAIService.genererSystemPrompt(role);
        expect(prompt, contains('Combi'));
        expect(
          prompt,
          contains(CombiAIService.reponseCreateur),
          reason: 'Le prompt ($role) doit figer la phrase du créateur',
        );
        expect(prompt.toLowerCase(), contains('vouvoi'));
      }
    });

    test('Le prompt CLIENT cible la réservation, pas la logistique chauffeur',
        () {
      final p = CombiAIService.genererSystemPrompt('client').toLowerCase();
      expect(p, contains('mobile money'));
      // Cloisonnement : le client est explicitement privé des fonctions
      // transporteur (revenus / documents / abonnements).
      expect(p, contains('réservé')); // « fonctions réservées aux transporteurs »
    });

    test('Le prompt TRANSPORTEUR cible la logistique, pas la réservation', () {
      final p = CombiAIService.genererSystemPrompt('transporteur').toLowerCase();
      expect(p, contains('copilote'));
      expect(p, contains('courses'));
      expect(p, contains('revenus'));
      expect(p, contains('abonnements'));
      // Cloisonnement : il ne crée pas de demande / ne simule pas de prix.
      expect(p, contains('ne crées pas'));
    });

    test('Chaque profil contient une consigne de refus poli hors périmètre',
        () {
      for (final role in ['client', 'transporteur']) {
        final p = CombiAIService.genererSystemPrompt(role).toLowerCase();
        expect(
          p.contains('refuse') || p.contains('réorient'),
          isTrue,
          reason: 'Le profil $role doit savoir refuser/réorienter poliment',
        );
      }
    });
  });

  group('Combi — Nettoyage du texte pour la voix', () {
    test('Retire le markdown de mise en forme', () {
      const brut = "Voici **le prix** estimé : `5000` FCFA. _Merci_ #info";
      final propre = CombiAIService.nettoyerPourVoix(brut);
      expect(propre, isNot(contains('*')));
      expect(propre, isNot(contains('`')));
      expect(propre, isNot(contains('#')));
      expect(propre, isNot(contains('_')));
      expect(propre, contains('le prix'));
      expect(propre, contains('5000'));
    });

    test('Retire les émojis mais garde le texte', () {
      const brut = "Votre colis arrive 🚚 bientôt 😊👍 !";
      final propre = CombiAIService.nettoyerPourVoix(brut);
      expect(propre, contains('Votre colis arrive'));
      expect(propre, contains('bientôt'));
      expect(propre, isNot(contains('🚚')));
      expect(propre, isNot(contains('😊')));
      expect(propre, isNot(contains('👍')));
    });

    test('Transforme un lien markdown en son libellé', () {
      const brut = "Consultez [nos tarifs](https://exemple.com/tarifs) svp";
      final propre = CombiAIService.nettoyerPourVoix(brut);
      expect(propre, contains('nos tarifs'));
      expect(propre, isNot(contains('http')));
      expect(propre, isNot(contains('exemple.com')));
    });

    test('Ne casse pas un texte déjà propre', () {
      const brut = "Bonjour, votre course est en route.";
      expect(CombiAIService.nettoyerPourVoix(brut), equals(brut));
    });
  });
}
