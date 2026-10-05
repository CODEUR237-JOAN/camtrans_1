// =====================================================================
// MODÈLE : PortefeuilleAdmin
//
// Instantané (calculé) des revenus de la plateforme pour l'admin.
// Le solde est DÉRIVÉ : revenus − retraits. Impossible à désynchroniser.
//
//  - revenusAbonnements : somme des montants d'abonnements payés.
//  - revenusCourses     : somme des frais de plateforme (fraisTransaction)
//                         prélevés sur les paiements de courses.
//  - totalRetire        : somme des retraits déjà effectués.
// =====================================================================
class PortefeuilleAdmin {
  final double revenusAbonnements;
  final double revenusCourses;
  final double totalRetire;

  const PortefeuilleAdmin({
    this.revenusAbonnements = 0,
    this.revenusCourses = 0,
    this.totalRetire = 0,
  });

  /// Revenus totaux générés par la plateforme (avant retraits).
  double get revenusTotaux => revenusAbonnements + revenusCourses;

  /// Solde que l'admin peut encore retirer.
  double get soldeDisponible {
    final s = revenusTotaux - totalRetire;
    return s < 0 ? 0 : s;
  }
}
