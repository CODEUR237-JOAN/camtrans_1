import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:update_camtrans/modeles/paiement.dart';
import 'package:update_camtrans/services/service_paiement.dart';
import 'package:update_camtrans/services/service_notification.dart';

class EtatTransaction {
  final bool enCours;
  final Paiement? succes;
  final String? erreur;

  EtatTransaction({
    this.enCours = false,
    this.succes,
    this.erreur,
  });

  EtatTransaction copieAvec({
    bool? enCours,
    Paiement? succes,
    String? erreur,
  }) {
    return EtatTransaction(
      enCours: enCours ?? this.enCours,
      succes: succes, // On ne garde pas l'ancien succès s'il y a une nouvelle transaction
      erreur: erreur, // Idem
    );
  }
}

final paiementProvider = StateNotifierProvider<PaiementNotifier, EtatTransaction>((ref) {
  return PaiementNotifier(ref.read(servicePaiementProvider));
});

class PaiementNotifier extends StateNotifier<EtatTransaction> {
  final ServicePaiement _service;

  PaiementNotifier(this._service) : super(EtatTransaction());

  Future<void> payerParOM({
    required String courseId,
    required String clientId,
    required String transporteurId,
    required double montant,
    required String telephone,
  }) async {
    state = EtatTransaction(enCours: true);
    try {
      final paiement = await _service.initierPaiementOM(
        courseId: courseId,
        clientId: clientId,
        transporteurId: transporteurId,
        montant: montant,
        telephonePayeur: telephone,
      );
      state = EtatTransaction(enCours: false, succes: paiement);
      ServiceNotification.afficherNotification(titre: " Paiement validé", message: "Votre reçu de $montant FCFA a été généré avec succès.");
    } catch (e) {
      state = EtatTransaction(enCours: false, erreur: e.toString());
    }
  }

  Future<void> payerParMTN({
    required String courseId,
    required String clientId,
    required String transporteurId,
    required double montant,
    required String telephone,
  }) async {
    state = EtatTransaction(enCours: true);
    try {
      final paiement = await _service.initierPaiementMTN(
        courseId: courseId,
        clientId: clientId,
        transporteurId: transporteurId,
        montant: montant,
        telephonePayeur: telephone,
      );
      state = EtatTransaction(enCours: false, succes: paiement);
      ServiceNotification.afficherNotification(titre: " Paiement validé", message: "Votre reçu de $montant FCFA a été généré avec succès.");
    } catch (e) {
      state = EtatTransaction(enCours: false, erreur: e.toString());
    }
  }

  Future<void> payerParCarte({
    required String courseId,
    required String clientId,
    required String transporteurId,
    required double montant,
    required String nomTitulaire,
  }) async {
    state = EtatTransaction(enCours: true);
    try {
      final paiement = await _service.initierPaiementCarte(
        courseId: courseId,
        clientId: clientId,
        transporteurId: transporteurId,
        montant: montant,
        nomTitulaire: nomTitulaire,
      );
      state = EtatTransaction(enCours: false, succes: paiement);
      ServiceNotification.afficherNotification(titre: " Paiement validé", message: "Votre reçu de $montant FCFA a été généré avec succès.");
    } catch (e) {
      state = EtatTransaction(enCours: false, erreur: e.toString());
    }
  }

  Future<void> payerEnEspeces({
    required String courseId,
    required String clientId,
    required String transporteurId,
    required double montant,
  }) async {
    state = EtatTransaction(enCours: true);
    try {
      final paiement = await _service.initierPaiementEspeces(
        courseId: courseId,
        clientId: clientId,
        transporteurId: transporteurId,
        montant: montant,
      );
      state = EtatTransaction(enCours: false, succes: paiement);
      ServiceNotification.afficherNotification(titre: " Paiement validé", message: "Votre reçu de $montant FCFA a été généré avec succès.");
    } catch (e) {
      state = EtatTransaction(enCours: false, erreur: e.toString());
    }
  }
  
  void reinitialiser() {
    state = EtatTransaction();
  }
}
