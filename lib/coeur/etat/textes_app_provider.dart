import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../modeles/textes_app.dart';
import '../../services/service_firestore.dart';

// Provider pour récupérer les textes globaux de l'application depuis Firestore
final textesAppProvider = StreamProvider<TextesApp>((ref) {
  final firestore = ref.watch(serviceFirestoreProvider);
  return firestore.fluxDocument(collection: 'parametres', id: 'textes_app').map((doc) {
    if (doc.exists && doc.data() != null) {
      return TextesApp.fromMap(doc.data()!);
    }
    return const TextesApp(); // Textes vides par défaut
  });
});

// Provider pour mettre à jour les textes
final updateTextesAppProvider = Provider((ref) {
  final firestore = ref.watch(serviceFirestoreProvider);
  return (TextesApp textes) async {
    await firestore.ajouterDocument(
      collection: 'parametres',
      id: 'textes_app',
      donnees: textes.toMap(),
    );
  };
});
