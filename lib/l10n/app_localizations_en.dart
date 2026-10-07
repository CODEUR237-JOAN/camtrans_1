// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'CamTrans';

  @override
  String get welcomeMessage => 'Welcome to CamTrans';

  @override
  String get searchTransport => 'Search for a driver';

  @override
  String get settings => 'Settings';

  @override
  String get language => 'Language';

  @override
  String get course => 'Ride';

  @override
  String get client => 'Client';

  @override
  String get driver => 'Driver';

  @override
  String get pending => 'Pending';

  @override
  String get cancel => 'Cancel';

  @override
  String get confirm => 'Confirm';
}
