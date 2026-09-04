import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:update_camtrans/services/service_notification.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:update_camtrans/firebase_options.dart';
import 'package:update_camtrans/principal.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:update_camtrans/coeur/constantes/couleurs.dart';

// Gestionnaire des notifications Push reçues en arrière-plan.
// Cette fonction s'exécute même lorsque l'application est fermée.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Initialise l'instance Firebase requise pour traiter le message en tâche de fond.
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint("[INFO] Message push reçu en arrière-plan : ${message.notification?.title}");
}

Future<void> main() async {
  try {
    // S'assure que les liaisons Flutter sont prêtes avant toute initialisation asynchrone.
    WidgetsFlutterBinding.ensureInitialized();
    debugPrint("[INFO] Démarrage de l'application CamTrans en cours...");

    // Initialisation du backend Firebase (authentification, base de données, etc.).
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint("[SUCCÈS] Service Firebase initialisé.");

    // Configuration de Firestore pour permettre un fonctionnement sans connexion internet.
    // Cela garantit que les utilisateurs peuvent consulter leurs données même hors ligne.
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
    debugPrint("[SUCCÈS] Mode hors-ligne de la base de données activé.");

    // Enregistrement du service de notifications pour fonctionner en arrière-plan.
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Initialisation et configuration des notifications locales.
    await ServiceNotification.initialiser();
    debugPrint("[SUCCÈS] Service de notifications configuré.");

    // Démarrage de l'écoute des nouveaux messages et des actions liées aux notifications.
    ServiceNotification.ecouterMessages();
    ServiceNotification.ecouterOuverture();

    // Chargement des variables d'environnement (ex: clés d'API).
    await dotenv.load(fileName: ".env");
    debugPrint("[SUCCÈS] Variables de configuration (.env) chargées avec succès.");

    runApp(
      const ProviderScope(
        child: MonApplication(),
      ),
    );
  } catch (e, stack) {
    debugPrint("[ERREUR FATALE] Le démarrage a échoué :");
    debugPrint(e.toString());
    debugPrint(stack.toString());

    // Affichage d'un écran d'erreur convivial pour l'utilisateur en cas de panne au démarrage.
    runApp(EcranErreurDemarrage(erreur: e.toString()));
  }
}

/// Écran affiché si l'application ne parvient pas à s'initialiser correctement.
/// Présente un message d'erreur clair et offre la possibilité de réessayer le démarrage.
class EcranErreurDemarrage extends StatelessWidget {
  final String erreur;
  const EcranErreurDemarrage({super.key, required this.erreur});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: Scaffold(
        backgroundColor: const Color(0xFF08111F),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icône d'erreur animée
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: CouleursApp.erreur.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: CouleursApp.erreur.withValues(alpha: 0.3),
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.wifi_tethering_error_rounded,
                    size: 52,
                    color: CouleursApp.erreur,
                  ),
                ),
                const SizedBox(height: 28),

                // Logo / Nom de l'app
                Text(
                  "CamTrans",
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 8),

                Text(
                  "Un problème technique est survenu au démarrage.",
                  style: GoogleFonts.inter(
                    color: Colors.white70,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),

                Text(
                  "Vérifiez votre connexion internet et réessayez.\nSi le problème persiste, contactez le support.",
                  style: GoogleFonts.inter(
                    color: Colors.white38,
                    fontSize: 13,
                    height: 1.6,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 32),

                // Bouton réessayer
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // Forcer le redémarrage via Flutter
                      main();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: CouleursApp.primaire,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                    label: Text(
                      "Réessayer",
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Détails techniques (discrets)
                GestureDetector(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        backgroundColor: const Color(0xFF10192A),
                        title: Text(
                          "Détails de l'erreur",
                          style: GoogleFonts.inter(color: Colors.white),
                        ),
                        content: SingleChildScrollView(
                          child: Text(
                            erreur,
                            style: GoogleFonts.robotoMono(
                              color: Colors.white54,
                              fontSize: 11,
                            ),
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text("Fermer", style: GoogleFonts.inter(color: CouleursApp.primaire)),
                          ),
                        ],
                      ),
                    );
                  },
                  child: Text(
                    "Voir les détails techniques",
                    style: GoogleFonts.inter(
                      color: Colors.white24,
                      fontSize: 12,
                      decoration: TextDecoration.underline,
                      decorationColor: Colors.white24,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}