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
}
