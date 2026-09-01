import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:update_camtrans/modeles/transporteur.dart';
import 'package:update_camtrans/services/service_firestore.dart';
import 'package:update_camtrans/coeur/etat/demande_expedition_provider.dart';

final transporteursDisponiblesProvider = StreamProvider.autoDispose<List<Transporteur>>((ref) {
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
