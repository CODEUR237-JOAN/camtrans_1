import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:update_camtrans/modeles/transporteur.dart';
import 'package:update_camtrans/services/service_firestore.dart';

final transporteursDisponiblesProvider = StreamProvider.autoDispose<List<Transporteur>>((ref) {
  final firestoreService = ref.watch(serviceFirestoreProvider);
  
  return firestoreService.fluxTransporteursDisponibles().map((snapshot) {
    return snapshot.docs.map((doc) {
      // Les IDs peuvent ne pas être dans les données map, on s'assure qu'ils y soient
      final data = doc.data();
      data['id'] = doc.id;
      return Transporteur.fromMap(data);
    }).toList();
  });
});
