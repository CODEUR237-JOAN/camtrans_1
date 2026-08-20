import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:update_camtrans/services/service_firestore.dart';
import 'package:update_camtrans/services/service_authentification.dart';
import 'package:update_camtrans/modeles/transporteur.dart';
import 'package:update_camtrans/modeles/course.dart';
import 'package:update_camtrans/modeles/paiement.dart';
import 'package:update_camtrans/coeur/constantes/statuts.dart';

// ID du transporteur actuellement connecté (lié à Firebase Auth)
final currentTransporteurIdProvider = Provider<String>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.value?.uid ?? "";
});

// Transporteur connecté (objet complet)
final currentTransporteurProvider = StreamProvider.autoDispose<Transporteur?>((ref) {
  final firestore = ref.watch(serviceFirestoreProvider);
  final transporteurId = ref.watch(currentTransporteurIdProvider);

  if (transporteurId.isEmpty) return Stream.value(null);

  return firestore
      .fluxDocument(collection: 'transporteurs', id: transporteurId)
      .map((doc) {
    if (!doc.exists) return null;
    return Transporteur.fromMap(doc.data()!);
  });
});

// ==========================================
// 1. GESTION DES COURSES
// ==========================================

// Flux de TOUTES les courses en attente (statut normalisé)
final fluxCoursesDisponiblesProvider =
    StreamProvider.autoDispose<List<Course>>((ref) {
  final firestore = ref.watch(serviceFirestoreProvider);
  return firestore
      .fluxCollectionCondition(
        collection: 'courses',
        champ: 'statut',
        valeur: StatutCourse.recherche, // ✅ statut normalisé
      )
      .map((snapshot) =>
          snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return Course.fromMap(data);
          }).toList());
});

// Flux des courses assignées à ce transporteur
final fluxMesCoursesProvider =
    StreamProvider.autoDispose<List<Course>>((ref) {
  final firestore = ref.watch(serviceFirestoreProvider);
  final transporteurId = ref.watch(currentTransporteurIdProvider);

  return firestore
      .fluxCollectionCondition(
        collection: 'courses',
        champ: 'transporteurId',
        valeur: transporteurId,
      )
      .map((snapshot) {
    var courses = snapshot.docs
        .map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          return Course.fromMap(data);
        })
        .toList();
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
        return courses.firstWhere(
            (c) => StatutCourse.estActive(c.statut)); // ✅ helper unifié
      } catch (_) {
        return null;
      }
    },
    orElse: () => null,
  );
});

// Actions sur les courses
final transporteurActionsProvider = Provider<TransporteurActions>((ref) {
  return TransporteurActions(
    ref.read(serviceFirestoreProvider),
    ref.read(currentTransporteurIdProvider),
    ref,
  );
});

class TransporteurActions {
  final ServiceFirestore _firestore;
  final String _transporteurId;
  final Ref _ref;

  TransporteurActions(this._firestore, this._transporteurId, this._ref);

  /// Accepte une course. Vérifie d'abord qu'aucune course n'est active.
  Future<void> accepterCourse(String courseId) async {
    // 1. Vérification : le transporteur n'a pas déjà une course active
    final activeCourse = _ref.read(activeCourseProvider);
    if (activeCourse != null) {
      throw Exception(
          "Vous avez déjà une course en cours (${activeCourse.id}). "
          "Terminez-la avant d'en accepter une nouvelle.");
    }

    // 2. Récupérer les infos du transporteur pour les copier dans la course
    final transporteurDoc = await _firestore.lireDocument(
        collection: 'transporteurs', id: _transporteurId);
    String nomTransporteur = '';
    String telephoneTransporteur = '';
    if (transporteurDoc.exists && transporteurDoc.data() != null) {
      final data = transporteurDoc.data()!;
      // ✅ Nouvelle vérification : bloquer si les documents ne sont pas validés
      if (data['documentsValides'] != true) {
        throw Exception(
            "Votre compte est en attente de validation. Vous ne pouvez pas accepter de courses.");
      }
      
      nomTransporteur =
          "${data['nom'] ?? ''} ${data['prenom'] ?? ''}".trim();
      telephoneTransporteur = data['telephone'] ?? '';
    }

    // 3. Vérifier que la course est toujours disponible (éviter les doubles acceptations)
    final courseDoc = await _firestore.lireDocument(
        collection: 'courses', id: courseId);
    if (!courseDoc.exists || courseDoc.data() == null) {
      throw Exception("Cette course n'existe plus.");
    }
    final statut = courseDoc.data()!['statut'];
    if (statut != StatutCourse.recherche) {
      throw Exception(
          "Cette course a déjà été acceptée par un autre transporteur.");
    }

    // 4. Mise à jour atomique
    await _firestore.modifierDocument(
      collection: 'courses',
      id: courseId,
      donnees: {
        'statut': StatutCourse.attribue,
        'transporteurId': _transporteurId,
        'nomTransporteur': nomTransporteur,
        'telephoneTransporteur': telephoneTransporteur,
        'dateAcceptation': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Change le statut d'une course en validant la transition
  Future<void> changerStatutCourse(String courseId, String nouveauStatut) async {
    // Lire le statut actuel pour valider la transition
    final courseDoc = await _firestore.lireDocument(
        collection: 'courses', id: courseId);
    if (!courseDoc.exists || courseDoc.data() == null) {
      throw Exception("Course introuvable.");
    }
    final statutActuel = courseDoc.data()!['statut'] as String? ?? '';

    if (!StatutCourse.peutTransitionnerVers(statutActuel, nouveauStatut)) {
      throw Exception(
          "Transition invalide : $statutActuel → $nouveauStatut");
    }

    final Map<String, dynamic> miseAJour = {'statut': nouveauStatut};

    // Enrichir la mise à jour selon le nouveau statut
    if (nouveauStatut == StatutCourse.arriveDestination) {
      miseAJour['dateFin'] = DateTime.now().toIso8601String();
    }
    if (nouveauStatut == StatutCourse.enRouteDepart) {
      miseAJour['dateDebut'] = DateTime.now().toIso8601String();
    }

    await _firestore.modifierDocument(
      collection: 'courses',
      id: courseId,
      donnees: miseAJour,
    );
  }

  /// Met à jour la disponibilité du transporteur dans Firestore
  Future<void> changerDisponibilite(bool estDisponible) async {
    if (_transporteurId.isEmpty) return;

    if (estDisponible) {
      final transporteurDoc = await _firestore.lireDocument(
          collection: 'transporteurs', id: _transporteurId);
      if (transporteurDoc.exists && transporteurDoc.data() != null) {
        if (transporteurDoc.data()!['documentsValides'] != true) {
          throw Exception(
              "Impossible de passer en ligne. Vos documents sont en cours de validation par l'administration.");
        }
      }
    }

    await _firestore.modifierDocument(
      collection: 'transporteurs',
      id: _transporteurId,
      donnees: {'disponible': estDisponible},
    );
  }
}

// ==========================================
// 2. GESTION DES REVENUS ET PAIEMENTS
// ==========================================

// Flux des paiements destinés à ce transporteur
final fluxMesRevenusProvider =
    StreamProvider.autoDispose<List<Paiement>>((ref) {
  final firestore = ref.watch(serviceFirestoreProvider);
  final transporteurId = ref.watch(currentTransporteurIdProvider);

  return firestore
      .fluxCollectionCondition(
        collection: 'paiements',
        champ: 'transporteurId',
        valeur: transporteurId,
      )
      .map((snapshot) {
    var paiements = snapshot.docs
        .map((doc) => Paiement.fromMap(doc.data()))
        .toList();
    paiements.sort((a, b) => b.datePaiement.compareTo(a.datePaiement));
    return paiements;
  });
});

// Calculs statistiques basés sur le flux — valeurs corrigées
final statsRevenusProvider =
    Provider.autoDispose<Map<String, double>>((ref) {
  final paiementsAsync = ref.watch(fluxMesRevenusProvider);

  return paiementsAsync.maybeWhen(
    data: (paiements) {
      double total = 0;
      double ceMois = 0;
      double cetteSemaine = 0;
      double ceJour = 0; // ✅ nouveau : revenus du jour

      final now = DateTime.now();
      final debutJour = DateTime(now.year, now.month, now.day);

      for (var p in paiements) {
        if (p.statut == StatutPaiement.succes) {
          total += p.montantNet;

          if (p.datePaiement.month == now.month &&
              p.datePaiement.year == now.year) {
            ceMois += p.montantNet;
          }

          if (now.difference(p.datePaiement).inDays <= 7) {
            cetteSemaine += p.montantNet;
          }

          // ✅ Revenus du jour (depuis minuit)
          if (p.datePaiement.isAfter(debutJour)) {
            ceJour += p.montantNet;
          }
        }
      }
      return {
        'total': total,
        'ceMois': ceMois,
        'cetteSemaine': cetteSemaine,
        'ceJour': ceJour, // ✅ valeur correcte pour le dashboard
      };
    },
    orElse: () =>
        {'total': 0, 'ceMois': 0, 'cetteSemaine': 0, 'ceJour': 0},
  );
});
