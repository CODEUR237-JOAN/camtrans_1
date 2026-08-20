import 'package:update_camtrans/coeur/utilitaires/parseur.dart';

class Paiement {
  final String id;

  final String courseId;

  final String clientId;

  final String transporteurId;

  final double montant;

  final String devise;

  final String methodePaiement;

  final String numeroTransaction;

  final String statut;

  final DateTime datePaiement;

  final bool paiementConfirme;

  final String reference;

  final String operateur;

  final String telephonePayeur;

  final String commentaire;

  final double fraisTransaction;

  final double montantNet;

  final bool remboursementEffectue;

  final DateTime? dateRemboursement;

  final String motifRemboursement;

  final String facturePdf;

  const Paiement({
    required this.id,
    required this.courseId,
    required this.clientId,
    required this.transporteurId,
    required this.montant,
    required this.devise,
    required this.methodePaiement,
    required this.numeroTransaction,
    required this.statut,
    required this.datePaiement,
    required this.paiementConfirme,
    required this.reference,
    required this.operateur,
    required this.telephonePayeur,
    required this.commentaire,
    required this.fraisTransaction,
    required this.montantNet,
    required this.remboursementEffectue,
    this.dateRemboursement,
    required this.motifRemboursement,
    required this.facturePdf,
  });

  Map<String, dynamic> toMap() {
    return {
      "id": id,
      "courseId": courseId,
      "clientId": clientId,
      "transporteurId": transporteurId,
      "montant": montant,
      "devise": devise,
      "methodePaiement": methodePaiement,
      "numeroTransaction": numeroTransaction,
      "statut": statut,
      "datePaiement": datePaiement.toIso8601String(),
      "paiementConfirme": paiementConfirme,
      "reference": reference,
      "operateur": operateur,
      "telephonePayeur": telephonePayeur,
      "commentaire": commentaire,
      "fraisTransaction": fraisTransaction,
      "montantNet": montantNet,
      "remboursementEffectue": remboursementEffectue,
      "dateRemboursement":
      dateRemboursement?.toIso8601String(),
      "motifRemboursement": motifRemboursement,
      "facturePdf": facturePdf,
    };
  }

  factory Paiement.fromMap(
      Map<String, dynamic> map) {
    return Paiement(
      id: map["id"] ?? "",
      courseId: map["courseId"] ?? "",
      clientId: map["clientId"] ?? "",
      transporteurId: map["transporteurId"] ?? "",
      montant: Parseur.toDouble(map["montant"]),
      devise: map["devise"] ?? "FCFA",
      methodePaiement:
      map["methodePaiement"] ?? "",
      numeroTransaction:
      map["numeroTransaction"] ?? "",
      statut: map["statut"] ?? "En attente",
      datePaiement: Parseur.toDateTime(map["datePaiement"]),
      paiementConfirme:
      map["paiementConfirme"] ?? false,
      reference: map["reference"] ?? "",
      operateur: map["operateur"] ?? "",
      telephonePayeur:
      map["telephonePayeur"] ?? "",
      commentaire: map["commentaire"] ?? "",
      fraisTransaction: Parseur.toDouble(map["fraisTransaction"]),
      montantNet: Parseur.toDouble(map["montantNet"]),
      remboursementEffectue:
      map["remboursementEffectue"] ??
          false,
      dateRemboursement:
      map["dateRemboursement"] != null
          ? Parseur.toDateTime(map["dateRemboursement"])
          : null,
      motifRemboursement:
      map["motifRemboursement"] ?? "",
      facturePdf: map["facturePdf"] ?? "",
    );
  }

  Map<String, dynamic> toJson() => toMap();

  factory Paiement.fromJson(
      Map<String, dynamic> json) =>
      Paiement.fromMap(json);
}