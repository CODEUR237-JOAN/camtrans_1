import 'package:cloud_firestore/cloud_firestore.dart';

class Parseur {
  /// Convertit n'importe quelle valeur en double de manière sécurisée.
  /// Utile pour éviter les crashs si Firebase renvoie un String ("10.5") ou un int (10) au lieu d'un double.
  static double toDouble(dynamic valeur, {double valeurParDefaut = 0.0}) {
    if (valeur == null) return valeurParDefaut;
    if (valeur is double) return valeur;
    if (valeur is int) return valeur.toDouble();
    if (valeur is String) {
      return double.tryParse(valeur) ?? valeurParDefaut;
    }
    return valeurParDefaut;
  }

  /// Convertit n'importe quelle valeur (Timestamp, String ISO, DateTime) en DateTime.
  static DateTime toDateTime(dynamic valeur, {DateTime? valeurParDefaut}) {
    if (valeur == null) return valeurParDefaut ?? DateTime.now();
    if (valeur is Timestamp) return valeur.toDate();
    if (valeur is DateTime) return valeur;
    if (valeur is String) {
      return DateTime.tryParse(valeur) ?? valeurParDefaut ?? DateTime.now();
    }
    return valeurParDefaut ?? DateTime.now();
  }
}
