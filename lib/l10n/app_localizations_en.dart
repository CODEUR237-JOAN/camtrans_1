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

  @override
  String get securePayment => 'Secure Payment';

  @override
  String get rideAmount => 'Ride Amount';

  @override
  String get paymentMethod => 'Payment Method';

  @override
  String get mobilePayment => 'Mobile Payment';

  @override
  String get bankCard => 'Bank Card';

  @override
  String get comingSoon => 'Coming Soon';

  @override
  String get cash => 'Cash';

  @override
  String get directToDriver => 'Direct payment to driver';

  @override
  String get cashInstructions =>
      'You will pay the amount directly to the driver during the service.';

  @override
  String get nameOnCard => 'Name on card';

  @override
  String get phoneNumber => 'Phone number';

  @override
  String payButton(String amount) {
    return 'Pay $amount XAF';
  }

  @override
  String get trackingLostSignalTitle => 'Oops, we lost the signal';

  @override
  String get trackingLostSignalMessage =>
      'The connection is temporarily interrupted. We are trying to restore tracking for your ride...';

  @override
  String get trackingSearchingTitle => 'Searching for the ideal driver...';

  @override
  String get trackingSearchingMessage =>
      'Our algorithm is selecting the best nearby vehicle.';
}
