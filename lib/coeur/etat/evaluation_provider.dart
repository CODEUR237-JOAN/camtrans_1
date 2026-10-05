import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// =====================================================================
// Note moyenne d'un transporteur, DÉRIVÉE de la collection `evaluations`.
//
// Approche sans Cloud Function : on calcule la moyenne en direct à partir
// des avis. Lisible par tout utilisateur connecté (règles Firestore).
// =====================================================================
class NoteTransporteur {
  final double moyenne;
  final int nombre;
  const NoteTransporteur(this.moyenne, this.nombre);
}

final noteMoyenneTransporteurProvider = StreamProvider.autoDispose
    .family<NoteTransporteur, String>((ref, transporteurId) {
  if (transporteurId.isEmpty) {
    return Stream.value(const NoteTransporteur(0, 0));
  }
  return FirebaseFirestore.instance
      .collection('evaluations')
      .where('transporteurId', isEqualTo: transporteurId)
      .snapshots()
      .map((snap) {
    if (snap.docs.isEmpty) return const NoteTransporteur(0, 0);
    double somme = 0;
    for (final d in snap.docs) {
      somme += ((d.data()['note'] ?? 0) as num).toDouble();
    }
    return NoteTransporteur(somme / snap.docs.length, snap.docs.length);
  });
});
