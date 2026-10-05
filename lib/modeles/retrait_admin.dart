import 'package:update_camtrans/coeur/utilitaires/parseur.dart';

// =====================================================================
// MODÈLE : RetraitAdmin
//
// Représente un retrait effectué par l'administrateur sur ses revenus
// propres (frais d'abonnements + frais de plateforme sur les courses).
// Stocké dans la collection Firestore "historique_retraits".
// =====================================================================
class RetraitAdmin {
  final String id;
  final String adminId;
  final double montant;
  final DateTime date;
  final String methodePaiement; // 'Orange Money' | 'MTN Mobile Money' | 'Virement bancaire'
  final String statut; // 'succes' | 'en_attente' | 'echoue'
  final String reference;

  /// Compte / numéro bénéficiaire (téléphone ou IBAN).
  final String beneficiaire;

  const RetraitAdmin({
    required this.id,
    required this.adminId,
    required this.montant,
    required this.date,
    required this.methodePaiement,
    this.statut = 'succes',
    this.reference = '',
    this.beneficiaire = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'adminId': adminId,
      'montant': montant,
      'date': date.millisecondsSinceEpoch,
      'methodePaiement': methodePaiement,
      'statut': statut,
      'reference': reference,
      'beneficiaire': beneficiaire,
    };
  }

  factory RetraitAdmin.fromMap(Map<String, dynamic> map) {
    return RetraitAdmin(
      id: (map['id'] ?? '').toString(),
      adminId: (map['adminId'] ?? '').toString(),
      montant: Parseur.toDouble(map['montant']),
      date: _parseDate(map['date']),
      methodePaiement: (map['methodePaiement'] ?? '').toString(),
      statut: (map['statut'] ?? 'succes').toString(),
      reference: (map['reference'] ?? '').toString(),
      beneficiaire: (map['beneficiaire'] ?? '').toString(),
    );
  }

  static DateTime _parseDate(dynamic valeur) {
    if (valeur is int) return DateTime.fromMillisecondsSinceEpoch(valeur);
    if (valeur is String && valeur.isNotEmpty) {
      return DateTime.tryParse(valeur) ?? DateTime.now();
    }
    return DateTime.now();
  }
}
