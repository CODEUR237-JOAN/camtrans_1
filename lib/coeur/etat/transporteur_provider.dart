import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/service_firestore.dart';
import '../../services/service_authentification.dart';
import '../../modeles/transporteur.dart';
import '../../modeles/course.dart';
import '../../modeles/paiement.dart';

// ID du transporteur actuellement connecté (lié à Firebase Auth)
final currentTransporteurIdProvider = Provider<String>((ref) {
  final auth = ref.watch(serviceAuthentificationProvider);
  return auth.utilisateur?.uid ?? "";
});

// Transporteur connecté (objet complet)
final currentTransporteurProvider = StreamProvider.autoDispose<Transporteur?>((ref) {
  final firestore = ref.watch(serviceFirestoreProvider);
  final transporteurId = ref.watch(currentTransporteurIdProvider);
  
  if (transporteurId.isEmpty) return Stream.value(null);

  return firestore.fluxDocument(collection: 'transporteurs', id: transporteurId).map((doc) {
    if (!doc.exists) return null;
    return Transporteur.fromMap(doc.data()!);
  });
});

// ==========================================
// 1. GESTION DES COURSES
// ==========================================

// Flux de TOUTES les courses en attente
final fluxCoursesDisponiblesProvider = StreamProvider.autoDispose<List<Course>>((ref) {
  final firestore = ref.watch(serviceFirestoreProvider);
  return firestore.fluxCollectionCondition(
    collection: 'courses',
    champ: 'statut',
    valeur: 'en_attente',
  ).map((snapshot) => snapshot.docs.map((doc) => Course.fromMap(doc.data())).toList());
});

// Flux des courses assignées à ce transporteur
final fluxMesCoursesProvider = StreamProvider.autoDispose<List<Course>>((ref) {
  final firestore = ref.watch(serviceFirestoreProvider);
  final transporteurId = ref.watch(currentTransporteurIdProvider);
  
  return firestore.fluxCollectionCondition(
    collection: 'courses',
    champ: 'transporteurId',
    valeur: transporteurId,
  ).map((snapshot) {
    var courses = snapshot.docs.map((doc) => Course.fromMap(doc.data())).toList();
    // Tri par date de création décroissante
    courses.sort((a, b) => b.dateCreation.compareTo(a.dateCreation));
    return courses;
  });
});

// Course active (celle en cours de livraison)
final activeCourseProvider = Provider.autoDispose<Course?>((ref) {
  final coursesAsync = ref.watch(fluxMesCoursesProvider);
  return coursesAsync.maybeWhen(
    data: (courses) {
      try {
        return courses.firstWhere((c) => c.statut == 'acceptee' || c.statut == 'en_transit');
      } catch (_) {
        return null;
      }
    },
    orElse: () => null,
  );
});

// Actions sur les courses
final transporteurActionsProvider = Provider<TransporteurActions>((ref) {
  return TransporteurActions(ref.read(serviceFirestoreProvider), ref.read(currentTransporteurIdProvider));
});

class TransporteurActions {
  final ServiceFirestore _firestore;
  final String _transporteurId;

  TransporteurActions(this._firestore, this._transporteurId);

  Future<void> accepterCourse(String courseId) async {
    await _firestore.modifierDocument(
      collection: 'courses',
      id: courseId,
      donnees: {
        'statut': 'acceptee',
        'transporteurId': _transporteurId,
      },
    );
  }

  Future<void> changerStatutCourse(String courseId, String nouveauStatut) async {
    await _firestore.modifierDocument(
      collection: 'courses',
      id: courseId,
      donnees: {'statut': nouveauStatut},
    );
  }
}

// ==========================================
// 2. GESTION DES REVENUS ET PAIEMENTS
// ==========================================

// Flux des paiements destinés à ce transporteur
final fluxMesRevenusProvider = StreamProvider.autoDispose<List<Paiement>>((ref) {
  final firestore = ref.watch(serviceFirestoreProvider);
  final transporteurId = ref.watch(currentTransporteurIdProvider);
  
  return firestore.fluxCollectionCondition(
    collection: 'paiements',
    champ: 'transporteurId',
    valeur: transporteurId,
  ).map((snapshot) {
    var paiements = snapshot.docs.map((doc) => Paiement.fromMap(doc.data())).toList();
    paiements.sort((a, b) => b.datePaiement.compareTo(a.datePaiement));
    return paiements;
  });
});

// Calculs statistiques basés sur le flux
final statsRevenusProvider = Provider.autoDispose<Map<String, double>>((ref) {
  final paiementsAsync = ref.watch(fluxMesRevenusProvider);
  
  return paiementsAsync.maybeWhen(
    data: (paiements) {
      double total = 0;
      double ceMois = 0;
      double cetteSemaine = 0;
      
      final now = DateTime.now();
      
      for (var p in paiements) {
        if (p.statut == 'Succès' || p.statut == 'Confirmé') {
          total += p.montantNet; // On prend le montant net du transporteur
          
          if (p.datePaiement.month == now.month && p.datePaiement.year == now.year) {
            ceMois += p.montantNet;
          }
          
          if (now.difference(p.datePaiement).inDays <= 7) {
            cetteSemaine += p.montantNet;
          }
        }
      }
      return {
        'total': total,
        'ceMois': ceMois,
        'cetteSemaine': cetteSemaine,
      };
    },
    orElse: () => {'total': 0, 'ceMois': 0, 'cetteSemaine': 0},
  );
});
