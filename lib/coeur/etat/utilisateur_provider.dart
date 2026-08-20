import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../modeles/client.dart';
import '../../services/service_authentification.dart';
import '../../services/service_firestore.dart';

/// Détecte le rôle de l'utilisateur connecté en vérifiant les collections Firestore
final userRoleProvider = FutureProvider.autoDispose<String?>((ref) async {
  final authState = ref.watch(authStateProvider);
  final userId = authState.value?.uid;
  if (userId == null) return null;

  final firestore = ref.read(serviceFirestoreProvider);
  
  // 1. Check Admin
  if (authState.value?.email == 'admintrans@gmail.com') return 'admin';
  final adminDoc = await firestore.lireDocument(collection: 'admin', id: userId);
  if (adminDoc.exists) return 'admin';

  // 2. Check Client
  final clientDoc = await firestore.lireDocument(collection: 'clients', id: userId);
  if (clientDoc.exists) return 'client';

  // 3. Check Transporteur
  final transpDoc = await firestore.lireDocument(collection: 'transporteurs', id: userId);
  if (transpDoc.exists) return 'transporteur';

  return null;
});

/// Client connecté (objet complet depuis Firestore)
final currentClientProvider = StreamProvider.autoDispose<Client?>((ref) {
  final authState = ref.watch(authStateProvider);
  final userId = authState.value?.uid;
  if (userId == null) return Stream.value(null);

  final firestore = ref.watch(serviceFirestoreProvider);
  
  return firestore
      .fluxDocument(collection: 'clients', id: userId)
      .map((doc) {
    if (!doc.exists || doc.data() == null) return null;
    return Client.fromMap(doc.data()!);
  });
});
