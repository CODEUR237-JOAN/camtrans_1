import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:update_camtrans/coeur/etat/admin_provider.dart';
import 'package:update_camtrans/modeles/portefeuille_admin.dart';
import 'package:update_camtrans/modeles/retrait_admin.dart';
import 'package:update_camtrans/services/service_authentification.dart';
import 'package:update_camtrans/services/service_firestore.dart';

// =====================================================================
// PORTEFEUILLE ADMINISTRATEUR — couche State/Logique (MVVM)
//
// Revenus de la plateforme (abonnements + frais de courses) et retraits.
// Le solde est DÉRIVÉ (revenus − retraits) : voir modèle PortefeuilleAdmin.
// =====================================================================

/// Flux temps réel de l'historique des retraits admin (collection
/// `historique_retraits`), trié du plus récent au plus ancien.
final adminHistoriqueRetraitsProvider =
    StreamProvider.autoDispose<List<RetraitAdmin>>((ref) {
  final firestore = ref.watch(serviceFirestoreProvider);
  return firestore
      .fluxCollection(collection: 'historique_retraits')
      .map((snapshot) {
    final list = snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return RetraitAdmin.fromMap(data);
    }).toList();
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  });
});

/// Instantané calculé du portefeuille admin, réactif aux abonnements,
/// paiements et retraits.
final adminPortefeuilleProvider =
    Provider.autoDispose<AsyncValue<PortefeuilleAdmin>>((ref) {
  final abonnementsAsync = ref.watch(adminAbonnementsProvider);
  final paiementsAsync = ref.watch(adminPaiementsProvider);
  final retraitsAsync = ref.watch(adminHistoriqueRetraitsProvider);

  if (abonnementsAsync is AsyncLoading ||
      paiementsAsync is AsyncLoading ||
      retraitsAsync is AsyncLoading) {
    return const AsyncValue.loading();
  }
  if (abonnementsAsync is AsyncError) {
    return AsyncValue.error(
        abonnementsAsync.error!, abonnementsAsync.stackTrace!);
  }
  if (paiementsAsync is AsyncError) {
    return AsyncValue.error(paiementsAsync.error!, paiementsAsync.stackTrace!);
  }
  if (retraitsAsync is AsyncError) {
    return AsyncValue.error(retraitsAsync.error!, retraitsAsync.stackTrace!);
  }

  // Revenus abonnements = somme des montants.
  final revenusAbonnements = (abonnementsAsync.value ?? []).fold<double>(
    0,
    (sum, a) => sum + ((a['montant'] as num?)?.toDouble() ?? 0),
  );

  // Revenus courses = somme des frais de plateforme prélevés sur les
  // paiements de COURSES uniquement (on exclut les retraits et les
  // paiements d'abonnement, déjà comptés ci-dessus).
  double revenusCourses = 0;
  for (final p in (paiementsAsync.value ?? [])) {
    if (p.courseId == 'RETRAIT' || p.courseId.startsWith('SUB-')) continue;
    revenusCourses += p.fraisTransaction;
  }

  final totalRetire = (retraitsAsync.value ?? [])
      .fold<double>(0, (sum, r) => sum + r.montant);

  return AsyncValue.data(PortefeuilleAdmin(
    revenusAbonnements: revenusAbonnements,
    revenusCourses: revenusCourses,
    totalRetire: totalRetire,
  ));
});

/// Actions du portefeuille admin (opérations d'écriture).
final adminPortefeuilleActionsProvider =
    Provider<AdminPortefeuilleActions>((ref) {
  return AdminPortefeuilleActions(ref);
});

class AdminPortefeuilleActions {
  final Ref _ref;
  AdminPortefeuilleActions(this._ref);

  /// Demande de retrait sécurisée :
  ///  1. Recalcule le solde en direct (source de vérité).
  ///  2. Vérifie que le solde est suffisant.
  ///  3. Écrit de façon ATOMIQUE (batch) : l'entrée dans `historique_retraits`
  ///     + la copie en cache (`soldeDisponible`, `revenusTotaux`) sur `admin/{uid}`.
  ///
  /// Retourne le [RetraitAdmin] créé. Lève une [Exception] explicite sinon.
  Future<RetraitAdmin> demanderRetrait({
    required double montant,
    required String methode,
    String beneficiaire = '',
    String statut = 'succes',
  }) async {
    final db = FirebaseFirestore.instance;
    final uid = _ref.read(serviceAuthentificationProvider).utilisateur?.uid;

    if (uid == null) {
      throw Exception('Administrateur non connecté.');
    }
    if (montant <= 0) {
      throw Exception('Le montant doit être supérieur à 0.');
    }

    // 1. Recalcul du solde en direct (indépendant de l'affichage).
    final portefeuille = await _calculerPortefeuille(db);
    if (montant > portefeuille.soldeDisponible) {
      throw Exception(
          'Solde insuffisant. Disponible : ${portefeuille.soldeDisponible.toStringAsFixed(0)} FCFA.');
    }

    // 2. Préparer le retrait.
    final retraitRef = db.collection('historique_retraits').doc();
    final retrait = RetraitAdmin(
      id: retraitRef.id,
      adminId: uid,
      montant: montant,
      date: DateTime.now(),
      methodePaiement: methode,
      statut: statut,
      reference: 'RET-ADM-${DateTime.now().millisecondsSinceEpoch}',
      beneficiaire: beneficiaire,
    );
    final nouveauSolde = portefeuille.soldeDisponible - montant;

    // 3. Écriture atomique.
    final batch = db.batch();
    batch.set(retraitRef, retrait.toMap());
    batch.set(
      db.collection('admin').doc(uid),
      {
        'soldeDisponible': nouveauSolde,
        'revenusTotaux': portefeuille.revenusTotaux,
        'revenusAbonnements': portefeuille.revenusAbonnements,
        'revenusCourses': portefeuille.revenusCourses,
        'derniereMajPortefeuille': DateTime.now().toIso8601String(),
      },
      SetOptions(merge: true),
    );
    await batch.commit();

    return retrait;
  }

  /// Recalcule le portefeuille à partir des collections sources.
  Future<PortefeuilleAdmin> _calculerPortefeuille(FirebaseFirestore db) async {
    double revenusAbonnements = 0;
    final abosSnap = await db.collection('abonnements').get();
    for (final d in abosSnap.docs) {
      revenusAbonnements += (d.data()['montant'] as num?)?.toDouble() ?? 0;
    }

    double revenusCourses = 0;
    final paiementsSnap = await db.collection('paiements').get();
    for (final d in paiementsSnap.docs) {
      final data = d.data();
      final courseId = (data['courseId'] ?? '').toString();
      if (courseId == 'RETRAIT' || courseId.startsWith('SUB-')) continue;
      revenusCourses += (data['fraisTransaction'] as num?)?.toDouble() ?? 0;
    }

    double totalRetire = 0;
    final retraitsSnap = await db.collection('historique_retraits').get();
    for (final d in retraitsSnap.docs) {
      totalRetire += (d.data()['montant'] as num?)?.toDouble() ?? 0;
    }

    return PortefeuilleAdmin(
      revenusAbonnements: revenusAbonnements,
      revenusCourses: revenusCourses,
      totalRetire: totalRetire,
    );
  }
}
