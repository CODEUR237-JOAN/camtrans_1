import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';

class ServiceNotification {
  ServiceNotification._();

  static final FirebaseMessaging _messaging =
      FirebaseMessaging.instance;

  static final FlutterLocalNotificationsPlugin
  _notifications =
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
      // Ignorer l'erreur si les permissions sont bloquées
    }

    if (kIsWeb) return; // Pas de notifications locales sur le web pour l'instant

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings("@mipmap/ic_launcher");

    const InitializationSettings settings =
        InitializationSettings(android: androidSettings);

    await _notifications.initialize(settings);
  }

  // ===========================
  // Obtenir le Token FCM
  // ===========================

  static Future<String?> obtenirToken() async {
    return await _messaging.getToken();
  }

  // ===========================
  // Actualisation du Token
  // ===========================

  static Stream<String> changementToken() {
    return _messaging.onTokenRefresh;
  }

  // ===========================
  // Notification locale
  // ===========================

  static Future<void> afficherNotification({
    required String titre,
    required String message,
  }) async {
    const AndroidNotificationDetails details =
    AndroidNotificationDetails(
      "transport_ia",
      "Transport Intelligent IA",
      channelDescription:
      "Notifications de l'application",
      importance: Importance.max,
      priority: Priority.high,
    );

    const NotificationDetails notification =
    NotificationDetails(
      android: details,
    );

    await _notifications.show(
      0,
      titre,
      message,
      notification,
    );
  }

  // ===========================
  // Notifications au premier plan
  // ===========================

  static void ecouterMessages() {
    FirebaseMessaging.onMessage.listen(
      (RemoteMessage message) {
        if (kIsWeb) return;
        afficherNotification(
          titre: message.notification?.title ?? "Notification",
          message: message.notification?.body ?? "",
        );
      },
    );
  }

  // ===========================
  // Notifications ouvertes
  // ===========================

  static void ecouterOuverture() {
    FirebaseMessaging.onMessageOpenedApp.listen(
          (RemoteMessage message) {
        // Navigation future
      },
    );
  }
}