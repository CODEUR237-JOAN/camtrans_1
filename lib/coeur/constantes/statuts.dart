// =======================================================
//
// FICHIER : statuts.dart
// PROJET : CamTrans
//
// Constantes unifiées pour les statuts des courses.
// Utiliser TOUJOURS ces constantes — jamais de chaînes en dur.
//
// =======================================================

class StatutCourse {
  StatutCourse._();

  // ============================
  // Statuts du cycle de vie
  // ============================

  /// Course créée par le client, en attente d'un transporteur
  static const String enAttente = 'en_attente';

  /// Un transporteur a accepté la course
  static const String acceptee = 'acceptee';

  /// Le transporteur est en route vers le client (pickup)
  static const String enRoute = 'en_route';

  /// Le transporteur est arrivé chez le client
  static const String arrive = 'arrive';

  /// Marchandise chargée, en cours de livraison
  static const String enTransit = 'en_transit';

  /// Livraison effectuée, en attente de confirmation
  static const String livre = 'livre';

  /// Course confirmée et notée par le client
  static const String termine = 'termine';

  /// Course annulée (par le client ou le système)
  static const String annulee = 'annulee';

  // ============================
  // Helpers
  // ============================

  /// Retourne true si la course est "active" (en cours de traitement)
  static bool estActive(String statut) {
    return statut == acceptee ||
        statut == enRoute ||
        statut == arrive ||
        statut == enTransit;
  }

  /// Retourne true si la course est terminée (succès ou échec)
  static bool estTerminee(String statut) {
    return statut == livre || statut == termine || statut == annulee;
  }

  /// Retourne true si le transporteur peut modifier le statut
  static bool peutTransitionnerVers(String actuel, String suivant) {
    const transitions = {
      acceptee: [enRoute, annulee],
      enRoute: [arrive, annulee],
      arrive: [enTransit],
      enTransit: [livre],
      livre: [termine],
    };
    return transitions[actuel]?.contains(suivant) ?? false;
  }

  /// Libellé lisible par l'humain
  static String libelle(String statut) {
    switch (statut) {
      case enAttente:
        return 'En attente';
      case acceptee:
        return 'Acceptée';
      case enRoute:
        return 'En route';
      case arrive:
        return 'Arrivé';
      case enTransit:
        return 'En transit';
      case livre:
        return 'Livré';
      case termine:
        return 'Terminé';
      case annulee:
        return 'Annulée';
      default:
        return statut;
    }
  }
}

class StatutPaiement {
  StatutPaiement._();

  static const String enAttente = 'en_attente';
  static const String succes = 'succes';
  static const String echec = 'echec';
  static const String rembourse = 'rembourse';

  static String libelle(String statut) {
    switch (statut) {
      case enAttente:
        return 'En attente';
      case succes:
        return 'Réussi';
      case echec:
        return 'Échoué';
      case rembourse:
        return 'Remboursé';
      default:
        return statut;
    }
  }
}
