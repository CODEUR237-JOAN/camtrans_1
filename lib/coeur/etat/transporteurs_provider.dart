import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:update_camtrans/modeles/transporteur.dart';
import 'package:update_camtrans/services/service_firestore.dart';
import 'package:update_camtrans/coeur/etat/demande_expedition_provider.dart';

/// Récupère un transporteur par son ID (photo, plaque, véhicule…).
/// Utilisé notamment par le bottom sheet de suivi pour afficher le chauffeur.
final transporteurParIdProvider =
    FutureProvider.autoDispose.family<Transporteur?, String>((ref, id) async {
  if (id.isEmpty) return null;
  final firestore = ref.watch(serviceFirestoreProvider);
  final doc = await firestore.lireDocument(collection: 'transporteurs', id: id);
  if (!doc.exists || doc.data() == null) return null;
  final data = doc.data()!;
  data['id'] = doc.id;
  return Transporteur.fromMap(data);
});

final transporteursDisponiblesProvider =
    StreamProvider.autoDispose<List<Transporteur>>((ref) {
  final firestoreService = ref.watch(serviceFirestoreProvider);
  final demandeExpedition = ref.watch(demandeExpeditionProvider);

  return firestoreService.fluxTransporteursDisponibles().map((snapshot) {
    return snapshot.docs.map((doc) {
      // Les IDs peuvent ne pas être dans les données map, on s'assure qu'ils y soient
      final data = doc.data();
      data['id'] = doc.id;
      return Transporteur.fromMap(data);
    }).where((t) {
      // Filtrage par gamme
      if (demandeExpedition.optionGamme == "Confort") {
        return t.gamme == "Confort" && t.gammeValidee;
      } else if (demandeExpedition.optionGamme == "Éco") {
        // En Éco, on montre les vrais Éco, ET les Confort en attente de validation (qui sont donc traités comme Éco)
        return t.gamme == "Éco" || (t.gamme == "Confort" && !t.gammeValidee);
      }
      return true; // Si aucune gamme n'a encore été sélectionnée, on affiche tous les disponibles
    }).toList();
  });
});
