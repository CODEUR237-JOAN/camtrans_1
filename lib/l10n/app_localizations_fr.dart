// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'CamTrans';

  @override
  String get welcomeMessage => 'Bienvenue sur CamTrans';

  @override
  String get searchTransport => 'Rechercher un transporteur';

  @override
  String get settings => 'Paramètres';

  @override
  String get language => 'Langue';

  @override
  String get course => 'Course';

  @override
  String get client => 'Client';

  @override
  String get driver => 'Transporteur';

  @override
  String get pending => 'En attente';

  @override
  String get cancel => 'Annuler';

  @override
  String get confirm => 'Confirmer';

  @override
  String get securePayment => 'Paiement Sécurisé';

  @override
  String get rideAmount => 'Montant de la course';

  @override
  String get paymentMethod => 'Méthode de paiement';

  @override
  String get mobilePayment => 'Paiement Mobile';

  @override
  String get bankCard => 'Carte Bancaire';

  @override
  String get comingSoon => 'Bientôt disponible';

  @override
  String get cash => 'Espèces';

  @override
  String get directToDriver => 'Paiement direct au chauffeur';

  @override
  String get cashInstructions =>
      'Vous réglerez le montant directement au chauffeur lors de la prestation.';

  @override
  String get nameOnCard => 'Nom sur la carte';

  @override
  String get phoneNumber => 'Numéro de téléphone';

  @override
  String payButton(String amount) {
    return 'Payer $amount FCFA';
  }

  @override
  String get trackingLostSignalTitle => 'Oups, nous avons perdu le signal';

  @override
  String get trackingLostSignalMessage =>
      'La connexion est momentanément interrompue. Nous tentons de rétablir le suivi de votre course...';

  @override
  String get trackingSearchingTitle =>
      'Recherche du transporteur idéal en cours...';

  @override
  String get trackingSearchingMessage =>
      'Notre algorithme sélectionne le meilleur véhicule à proximité.';
}
