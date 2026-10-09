import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

import 'package:update_camtrans/coeur/constantes/couleurs.dart';

// =====================================================================
// ÉCRAN : Contenu informatif (CGU, Confidentialité, Centre d'aide)
//
// Affiche un contenu Markdown EN LOCAL (pas de dépendance à un site
// externe) → toujours fonctionnel, même hors ligne.
// =====================================================================
class EcranContenuInfo extends StatelessWidget {
  final String titre;
  final String contenuMarkdown;

  const EcranContenuInfo({
    super.key,
    required this.titre,
    required this.contenuMarkdown,
  });

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(color: onSurface),
        title: Text(titre,
            style: TextStyle(color: onSurface, fontWeight: FontWeight.bold)),
      ),
      body: Markdown(
        data: contenuMarkdown,
        padding: const EdgeInsets.all(20),
        styleSheet: MarkdownStyleSheet(
          h1: TextStyle(
              color: onSurface, fontSize: 20, fontWeight: FontWeight.bold),
          h2: TextStyle(
              color: onSurface, fontSize: 16, fontWeight: FontWeight.bold),
          p: TextStyle(
              color: onSurface.withValues(alpha: 0.8),
              fontSize: 14,
              height: 1.6),
          listBullet: TextStyle(color: onSurface.withValues(alpha: 0.8)),
          a: const TextStyle(color: CouleursApp.primaire),
        ),
      ),
    );
  }
}

// =====================================================================
// Contenus (modifiables). Centralisés ici pour être réutilisables.
// =====================================================================
class ContenusLegaux {
  ContenusLegaux._();

  static const String conditions = '''
# Conditions d'utilisation

Bienvenue sur **CamTrans**, la plateforme camerounaise qui met en relation
clients et transporteurs.

## 1. Utilisation du service
En utilisant CamTrans, vous vous engagez à respecter les lois en vigueur et à
ne pas utiliser nos services à des fins illégales.

## 2. Comptes et sécurité
Vous êtes responsable de la confidentialité de vos identifiants. Toute
activité réalisée depuis votre compte vous est imputable.

## 3. Estimations et tarifs
Les prix affichés sont des **estimations**. Le montant final peut varier selon
les conditions réelles du trajet (distance, volume, options).

## 4. Responsabilité
CamTrans agit en tant qu'**intermédiaire** entre le client et le transporteur.
Nous ne saurions être tenus responsables des retards ou dommages survenus
pendant le transport.

## 5. Paiements
Les paiements s'effectuent via Mobile Money (Orange, MTN). CamTrans ne stocke
jamais vos codes secrets.

_Dernière mise à jour : 2026._
''';

  static const String confidentialite = '''
# Politique de confidentialité

Votre vie privée est importante. Voici comment nous traitons vos données.

## Données collectées
- Identité : nom, téléphone, e-mail.
- Position géographique : **uniquement pendant une course active**, pour le
  suivi en temps réel.
- Informations de course : adresses, type de marchandise.

## Utilisation
Vos données servent **exclusivement** à assurer la prestation de transport et
la mise en relation. Elles ne sont **jamais vendues** à des tiers.

## Partage
Vos coordonnées ne sont partagées qu'avec le transporteur de votre course, le
temps de la prestation.

## Vos droits
Vous pouvez demander la **suppression** de votre compte et de vos données à
tout moment en écrivant à support@camtrans.cm.

_Dernière mise à jour : 2026._
''';

  static const String aide = '''
# Centre d'aide

## Questions fréquentes

**Comment créer une demande de transport ?**
Depuis l'accueil, choisissez un service, renseignez le trajet et validez.

**Comment payer ma course ?**
Via Mobile Money (Orange / MTN). Vous pouvez enregistrer vos numéros dans
« Moyens de paiement » pour aller plus vite.

**Mon chauffeur n'avance pas sur la carte, que faire ?**
Vérifiez votre connexion Internet. Le suivi se met à jour dès que le chauffeur
a du réseau.

**Comment annuler une course ?**
Tant qu'aucun chauffeur n'est en route, un bouton « Annuler » est disponible
sur l'écran de suivi.

## Nous contacter
- E-mail : **support@camtrans.cm**
- Nous répondons sous 24 à 48 h ouvrées.
''';
}
