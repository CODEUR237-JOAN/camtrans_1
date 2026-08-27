import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// =====================================================
// Stream global pour les notifications in-app (Web + Mobile)
// =====================================================
final StreamController<NotificationInApp> _notificationController =
    StreamController<NotificationInApp>.broadcast();

Stream<NotificationInApp> get fluxNotificationsInApp =>
    _notificationController.stream;

/// Modèle d'une notification in-app
class NotificationInApp {
  final String titre;
  final String message;
  final String type; // 'info' | 'succes' | 'alerte' | 'paiement'
  NotificationInApp({required this.titre, required this.message, this.type = 'info'});
}

class ServiceNotification {
  ServiceNotification._();

  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  // ===========================
  // Initialisation
  // ===========================

  static Future<void> initialiser() async {
    try {
      await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
    } catch (e) {
      debugPrint('️ Permission notification: $e');
    }

    if (!kIsWeb) {
      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings("@mipmap/ic_launcher");
      const InitializationSettings settings =
          InitializationSettings(android: androidSettings);
      await _notifications.initialize(settings);
    }
  }

  // ===========================
  // Obtenir / Enregistrer le Token FCM
  // ===========================

  static Future<String?> obtenirToken() async {
    return await _messaging.getToken();
  }

  static Future<void> enregistrerTokenUtilisateur(
      String userId, String typeUtilisateur) async {
    try {
      final token = await obtenirToken();
      if (token != null) {
        final db = FirebaseFirestore.instance;
        final collection =
            typeUtilisateur == 'client' ? 'clients' : 'transporteurs';
        await db.collection(collection).doc(userId).set({
          'fcmToken': token,
          'derniereConnexion': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        debugPrint(' Token FCM enregistré pour $userId dans $collection');
      }
    } catch (e) {
      debugPrint(" Erreur lors de l'enregistrement du token FCM: $e");
    }
  }

  static Stream<String> changementToken() => _messaging.onTokenRefresh;

  // ===========================
  // Notification locale (Mobile uniquement)
  // ===========================

  static Future<void> afficherNotification({
    required String titre,
    required String message,
    String type = 'info',
  }) async {
    // Émettre dans le stream in-app (fonctionne sur Web ET Mobile)
    _notificationController.add(
      NotificationInApp(titre: titre, message: message, type: type),
    );

    // Sur mobile : afficher aussi la notification système
    if (!kIsWeb) {
      const AndroidNotificationDetails details = AndroidNotificationDetails(
        "transport_ia",
        "Transport Intelligent",
        channelDescription: "Notifications de l'application",
        importance: Importance.max,
        priority: Priority.high,
      );
      await _notifications.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        titre,
        message,
        const NotificationDetails(android: details),
      );
    }
  }

  // ===========================
  // Écoute FCM au premier plan
  // ===========================

  static void ecouterMessages() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final titre = message.notification?.title ?? 'Notification';
      final corps = message.notification?.body ?? '';
      debugPrint(' FCM foreground: $titre');
      afficherNotification(titre: titre, message: corps);
    });
  }


  // ===========================
  // Écoute ouverture notification
  // ===========================

  static void ecouterOuverture() {
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint(' Notification ouverte : ${message.notification?.title}');
    });
  }
}