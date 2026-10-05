import 'package:update_camtrans/coeur/utilitaires/parseur.dart';

// =====================================================================
// MODÈLE : Entretien du véhicule (transporteur)
//
// Un enregistrement d'entretien effectué sur le véhicule d'un
// transporteur : vidange, pneus, visite technique, freinage, etc.
// Stocké dans la collection Firestore "entretiens".
// =====================================================================
class Entretien {
  final String id;
  final String transporteurId;

  /// Intitulé libre (ex: "Vidange moteur")
  final String titre;

  /// Catégorie normalisée, sert à choisir l'icône/la couleur côté UI.
  /// Valeurs : 'vidange' | 'pneus' | 'visite' | 'freinage' | 'autre'
  final String type;

  /// Date du dernier entretien effectué.
  final DateTime dateDernier;

  /// Date prévue du prochain entretien (optionnelle).
  final DateTime? dateProchain;

  /// Note / commentaire libre (kilométrage, garage, pièces...).
  final String note;

  final DateTime dateCreation;

  const Entretien({
    required this.id,
    required this.transporteurId,
    required this.titre,
    required this.type,
    required this.dateDernier,
    this.dateProchain,
    this.note = '',
    required this.dateCreation,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'transporteurId': transporteurId,
      'titre': titre,
      'type': type,
      'dateDernier': dateDernier.millisecondsSinceEpoch,
      'dateProchain': dateProchain?.millisecondsSinceEpoch,
      'note': note,
      'dateCreation': dateCreation.millisecondsSinceEpoch,
    };
  }

  factory Entretien.fromMap(Map<String, dynamic> map) {
    return Entretien(
      id: (map['id'] ?? '').toString(),
      transporteurId: (map['transporteurId'] ?? '').toString(),
      titre: (map['titre'] ?? '').toString(),
      type: (map['type'] ?? 'autre').toString(),
      dateDernier: _parseDate(map['dateDernier']) ?? DateTime.now(),
      dateProchain: _parseDate(map['dateProchain']),
      note: (map['note'] ?? '').toString(),
      dateCreation: _parseDate(map['dateCreation']) ?? DateTime.now(),
    );
  }

  /// true si le prochain entretien est passé ou prévu dans les 15 jours.
  bool get bientotDu {
    if (dateProchain == null) return false;
    final diff = dateProchain!.difference(DateTime.now()).inDays;
    return diff <= 15;
  }

  Entretien copyWith({
    String? titre,
    String? type,
    DateTime? dateDernier,
    DateTime? dateProchain,
    String? note,
  }) {
    return Entretien(
      id: id,
      transporteurId: transporteurId,
      titre: titre ?? this.titre,
      type: type ?? this.type,
      dateDernier: dateDernier ?? this.dateDernier,
      dateProchain: dateProchain ?? this.dateProchain,
      note: note ?? this.note,
      dateCreation: dateCreation,
    );
  }

  /// Parse robuste : accepte int (millisecondes) ou String (ISO 8601).
  static DateTime? _parseDate(dynamic valeur) {
    if (valeur == null) return null;
    if (valeur is int) {
      return DateTime.fromMillisecondsSinceEpoch(valeur);
    }
    if (valeur is String && valeur.isNotEmpty) {
      return DateTime.tryParse(valeur);
    }
    final asInt = Parseur.toDouble(valeur);
    if (asInt > 0) {
      return DateTime.fromMillisecondsSinceEpoch(asInt.toInt());
    }
    return null;
  }
}
