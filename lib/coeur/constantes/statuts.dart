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
  // Statuts du cycle de vie (Sprint 13)
  // ============================

  /// Commande créée, recherche en cours
  static const String recherche = 'recherche';

  /// ✅ NOUVEAU (Phase 4.4) : La course est proposée en exclusivité à un chauffeur spécifique
  static const String propose = 'propose';


  /// Un transporteur a été attribué
  static const String attribue = 'attribue';

  /// Le transporteur est en route vers le point de départ
  static const String enRouteDepart = 'en_route_depart';

  /// Le transporteur est arrivé au point de départ
  static const String arriveDepart = 'arrive_depart';

  /// La marchandise est chargée dans le véhicule
  static const String charge = 'charge';

  /// Le transport est en cours vers la destination
  static const String enTransit = 'en_transit';

  /// Le transporteur est arrivé à la destination
  static const String arriveDestination = 'arrive_destination';

  /// La course est clôturée et payée/validée
  static const String terminee = 'terminee';

  /// Course annulée (par le client ou le système)
  static const String annulee = 'annulee';

  // ============================
  // Helpers
  // ============================

  /// Retourne true si la course est "active" (en cours de traitement)
  static bool estActive(String statut) {
    return statut == attribue ||
        statut == enRouteDepart ||
        statut == arriveDepart ||
        statut == charge ||
        statut == enTransit ||
        statut == arriveDestination;
  }

  /// Retourne true si la course est terminée (succès ou échec)
  static bool estTerminee(String statut) {
    return statut == terminee || statut == annulee;
  }

  /// Retourne true si le transporteur peut modifier le statut
  static bool peutTransitionnerVers(String actuel, String suivant) {
    const transitions = {
      recherche: [propose, attribue, annulee],
      propose: [attribue, recherche, annulee],
      attribue: [enRouteDepart, annulee],
      enRouteDepart: [arriveDepart, annulee],
      arriveDepart: [charge],
      charge: [enTransit],
      enTransit: [arriveDestination],
      arriveDestination: [terminee],
    };
    return transitions[actuel]?.contains(suivant) ?? false;
  }

  /// Libellé lisible par l'humain
  static String libelle(String statut) {
    switch (statut) {
      case recherche:
        return 'Recherche...';
      case propose:
        return 'En proposition';

      case attribue:
        return 'Attribué';
      case enRouteDepart:
        return 'En route';
      case arriveDepart:
        return 'Arrivé (Départ)';
      case charge:
        return 'Chargé';
      case enTransit:
        return 'En transit';
      case arriveDestination:
        return 'À destination';
      case terminee:
        return 'Terminée';
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
