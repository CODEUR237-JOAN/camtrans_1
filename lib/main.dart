import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:update_camtrans/services/service_notification.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:update_camtrans/firebase_options.dart';
import 'package:update_camtrans/principal.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

// Gestionnaire de messages en arrière-plan
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Initialise Firebase si nécessaire pour le processus d'arrière-plan
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint("📩 Message reçu en arrière-plan : ${message.notification?.title}");
}

Future<void> main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    debugPrint("🚀 Initialisation de l'application...");

    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint("✅ Firebase initialisé");

    // Enregistrer le gestionnaire d'arrière-plan
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    await ServiceNotification.initialiser();
    debugPrint("✅ Notifications initialisées");

    ServiceNotification.ecouterMessages();
    ServiceNotification.ecouterOuverture();

    await dotenv.load(fileName: ".env");
    debugPrint("✅ Configuration .env chargée");

    runApp(
      const ProviderScope(
        child: MonApplication(),
      ),
    );
  } catch (e, stack) {
    debugPrint("❌ ERREUR FATALE LORS DU DÉMARRAGE:");
    debugPrint(e.toString());
    debugPrint(stack.toString());
    
    // Afficher une interface d'erreur minimale si l'app crash au démarrage
    runApp(MaterialApp(
      home: Scaffold(
        body: Center(
          child: Text("Erreur de démarrage : $e"),
        ),
      ),
    ));
  }
}