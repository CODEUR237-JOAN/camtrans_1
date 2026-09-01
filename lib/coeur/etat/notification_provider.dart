import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:update_camtrans/modeles/notification.dart';
import 'package:update_camtrans/services/service_authentification.dart';
import 'package:update_camtrans/services/service_firestore.dart';
import 'package:update_camtrans/services/service_notification.dart';

/// Provider pour initialiser l'écoute et l'enregistrement du token FCM
final gestionTokenFCMProvider = Provider.autoDispose<void>((ref) {
  final authState = ref.watch(authStateProvider);
  final firestore = ref.watch(serviceFirestoreProvider);
  final userId = authState.value?.uid;

  if (userId != null) {
    // 1. Obtenir le token actuel au démarrage
    ServiceNotification.obtenirToken().then((token) {
      if (token != null) {
        firestore.modifierDocument(
          collection: 'utilisateurs',
          id: userId,
          donnees: {'fcmToken': token},
        ).catchError((_) {}); // Ignore si le doc utilisateur n'existe pas encore
      }
    }).catchError((_) {});

    // 2. Détecter le rôle (Anciennement pour la simulation locale, maintenant géré par Cloud Functions)

    // 3. Écouter les changements de token
    final sub = ServiceNotification.changementToken().listen((token) {
      firestore.modifierDocument(
        collection: 'utilisateurs',
        id: userId,
        donnees: {'fcmToken': token},
      ).catchError((_) {});
    }, onError: (e) {
      debugPrint("Erreur changementToken FCM: $e");
    });

    ref.onDispose(() {
      sub.cancel();
      // ServiceNotification.arreterEcouteAutomatique();
    });
  }
});

/// Stream des notifications de l'utilisateur connecté depuis Firestore
final fluxNotificationsProvider = StreamProvider.autoDispose<List<NotificationApp>>((ref) {
  final authState = ref.watch(authStateProvider);
  final firestore = ref.watch(serviceFirestoreProvider);
  final userId = authState.value?.uid;

  if (userId == null) return Stream.value([]);

  return firestore.fluxCollectionCondition(
    collection: 'notifications',
    champ: 'utilisateurId',
    valeur: userId,
  ).map((snapshot) {
    var notifications = snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return NotificationApp.fromMap(data);
    }).toList();
    // Tri par date décroissante
    notifications.sort((a, b) => b.dateCreation.compareTo(a.dateCreation));
    return notifications;
  });
});

/// Nombre de notifications non lues (pour le badge)
final badgeNotificationsProvider = Provider.autoDispose<int>((ref) {
  final notifs = ref.watch(fluxNotificationsProvider);
  return notifs.maybeWhen(
    data: (list) => list.where((n) => !n.lue).length,
    orElse: () => 0,
  );
});

final notificationActionsProvider = Provider<NotificationActions>((ref) {
  return NotificationActions(ref.read(serviceFirestoreProvider));
});

class NotificationActions {
  final ServiceFirestore _firestore;
  NotificationActions(this._firestore);

  Future<void> marquerCommeLue(String id) async {
    await _firestore.modifierDocument(
      collection: 'notifications',
      id: id,
      donnees: {'lue': true, 'dateLecture': DateTime.now().toIso8601String()},
    );
  }

  Future<void> supprimer(String id) async {
    await _firestore.supprimerDocument(collection: 'notifications', id: id);
  }

  Future<void> toutMarquerCommeLu(List<NotificationApp> notifications) async {
    for (var n in notifications) {
      if (!n.lue) {
        await marquerCommeLue(n.id);
      }
    }
  }
}

/// Stream des notifications Admin (id spécial 'ADMIN')
final fluxNotificationsAdminProvider = StreamProvider.autoDispose<List<NotificationApp>>((ref) {
  final firestore = ref.watch(serviceFirestoreProvider);

  return firestore.fluxCollectionCondition(
    collection: 'notifications',
    champ: 'utilisateurId',
    valeur: 'ADMIN',
  ).map((snapshot) {
    var notifications = snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return NotificationApp.fromMap(data);
    }).toList();
    notifications.sort((a, b) => b.dateCreation.compareTo(a.dateCreation));
    return notifications;
  });
});

/// Badge Admin : nombre de notifications non lues pour l'admin
final badgeNotificationsAdminProvider = Provider.autoDispose<int>((ref) {
  final notifs = ref.watch(fluxNotificationsAdminProvider);
  return notifs.maybeWhen(
    data: (list) => list.where((n) => !n.lue).length,
    orElse: () => 0,
  );
});
