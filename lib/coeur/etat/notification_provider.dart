import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../modeles/notification.dart';
import '../../services/service_authentification.dart';
import '../../services/service_firestore.dart';

/// Stream des notifications de l'utilisateur connecté depuis Firestore
final fluxNotificationsProvider = StreamProvider.autoDispose<List<NotificationApp>>((ref) {
  final auth = ref.watch(serviceAuthentificationProvider);
  final firestore = ref.watch(serviceFirestoreProvider);
  final userId = auth.utilisateur?.uid;

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
