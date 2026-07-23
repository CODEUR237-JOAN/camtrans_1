import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../modeles/paiement.dart';
import 'service_firestore.dart';

final servicePaiementProvider = Provider<ServicePaiement>((ref) {
  return ServicePaiement(ref.read(serviceFirestoreProvider));
});

class ServicePaiement {
  final ServiceFirestore _firestore;

  ServicePaiement(this._firestore);

  /// Simulation d'un paiement Orange Money
  Future<Paiement> initierPaiementOM({
    required String courseId,
    required String clientId,
    required String transporteurId,
    required double montant,
    required String telephonePayeur,
  }) async {
    await Future.delayed(const Duration(seconds: 3)); // Simulation réseau
    
    // Si c'est un test d'échec
    if (telephonePayeur == "000000000") {
      throw Exception("Solde insuffisant sur le compte Orange Money.");
    }

    return _creerPaiementReussi(
      courseId: courseId,
      clientId: clientId,
      transporteurId: transporteurId,
      montant: montant,
      methode: "Orange Money",
      operateur: "Orange",
      telephone: telephonePayeur,
    );
  }

  /// Simulation d'un paiement MTN Mobile Money
  Future<Paiement> initierPaiementMTN({
    required String courseId,
    required String clientId,
    required String transporteurId,
    required double montant,
    required String telephonePayeur,
  }) async {
    await Future.delayed(const Duration(seconds: 3)); // Simulation réseau
    
    if (telephonePayeur == "000000000") {
      throw Exception("Transaction refusée par MTN.");
    }

    return _creerPaiementReussi(
      courseId: courseId,
      clientId: clientId,
      transporteurId: transporteurId,
      montant: montant,
      methode: "MTN Mobile Money",
      operateur: "MTN",
      telephone: telephonePayeur,
    );
  }

  /// Simulation d'un paiement par Carte Bancaire
  Future<Paiement> initierPaiementCarte({
    required String courseId,
    required String clientId,
    required String transporteurId,
    required double montant,
    required String nomTitulaire,
  }) async {
    await Future.delayed(const Duration(seconds: 4)); // Simulation de la passerelle 3D Secure
    
    return _creerPaiementReussi(
      courseId: courseId,
      clientId: clientId,
      transporteurId: transporteurId,
      montant: montant,
      methode: "Carte Bancaire",
      operateur: "Stripe/Visa",
      telephone: nomTitulaire, // On utilise ce champ pour le nom pour l'instant
    );
  }

  Future<Paiement> _creerPaiementReussi({
    required String courseId,
    required String clientId,
    required String transporteurId,
    required double montant,
    required String methode,
    required String operateur,
    required String telephone,
  }) async {
    final id = "PAY-${DateTime.now().millisecondsSinceEpoch}";
    final transaction = "TXN-${DateTime.now().microsecondsSinceEpoch}";

    final paiement = Paiement(
      id: id,
      courseId: courseId,
      clientId: clientId,
      transporteurId: transporteurId,
      montant: montant,
      devise: "FCFA",
      methodePaiement: methode,
      numeroTransaction: transaction,
      statut: "Succès",
      datePaiement: DateTime.now(),
      paiementConfirme: true,
      reference: "Ref-$courseId",
      operateur: operateur,
      telephonePayeur: telephone,
      commentaire: "Paiement simulé avec succès",
      fraisTransaction: montant * 0.02, // 2% simulé
      montantNet: montant * 0.98,
      remboursementEffectue: false,
      motifRemboursement: "",
      facturePdf: "https://camtrans.com/facture/$id.pdf", // Lien factice
    );

    // Enregistrement dans Firestore pour simuler l'historique
    await _firestore.ajouterDocument(
      collection: 'paiements',
      id: paiement.id,
      donnees: paiement.toMap(),
    );

    // On pourrait aussi mettre à jour le statut de la course ici
    await _firestore.modifierDocument(
      collection: 'courses',
      id: courseId,
      donnees: {'paiementEffectue': true},
    );

    return paiement;
  }
}
