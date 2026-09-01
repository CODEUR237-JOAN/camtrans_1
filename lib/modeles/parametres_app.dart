class ParametresApp {
  final double commissionPlateforme;
  final double prixKmMoto;
  final double prixKmCamion;
  final double prixKmFourgon;
  final bool approbationAutomatique;
  final bool paiementEspeceActif;
  final double prixAbonnementJour;
  final double prixAbonnementMois;
  final double prixAbonnementAn;

  const ParametresApp({
    this.commissionPlateforme = 10.0,
    this.prixKmMoto = 200.0,
    this.prixKmCamion = 1000.0,
    this.prixKmFourgon = 700.0,
    this.approbationAutomatique = false,
    this.paiementEspeceActif = true,
    this.prixAbonnementJour = 1000.0,
    this.prixAbonnementMois = 25000.0,
    this.prixAbonnementAn = 250000.0,
  });

  factory ParametresApp.fromMap(Map<String, dynamic> map) {
    return ParametresApp(
      commissionPlateforme: (map['commissionPlateforme'] ?? 10.0).toDouble(),
      prixKmMoto: (map['prixKmMoto'] ?? 200.0).toDouble(),
      prixKmCamion: (map['prixKmCamion'] ?? 1000.0).toDouble(),
      prixKmFourgon: (map['prixKmFourgon'] ?? 700.0).toDouble(),
      approbationAutomatique: map['approbationAutomatique'] ?? false,
      paiementEspeceActif: map['paiementEspeceActif'] ?? true,
      prixAbonnementJour: (map['prixAbonnementJour'] ?? 1000.0).toDouble(),
      prixAbonnementMois: (map['prixAbonnementMois'] ?? 25000.0).toDouble(),
      prixAbonnementAn: (map['prixAbonnementAn'] ?? 250000.0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'commissionPlateforme': commissionPlateforme,
      'prixKmMoto': prixKmMoto,
      'prixKmCamion': prixKmCamion,
      'prixKmFourgon': prixKmFourgon,
      'approbationAutomatique': approbationAutomatique,
      'paiementEspeceActif': paiementEspeceActif,
      'prixAbonnementJour': prixAbonnementJour,
      'prixAbonnementMois': prixAbonnementMois,
      'prixAbonnementAn': prixAbonnementAn,
    };
  }

  ParametresApp copyWith({
    double? commissionPlateforme,
    double? prixKmMoto,
    double? prixKmCamion,
    double? prixKmFourgon,
    bool? approbationAutomatique,
    bool? paiementEspeceActif,
    double? prixAbonnementJour,
    double? prixAbonnementMois,
    double? prixAbonnementAn,
  }) {
    return ParametresApp(
      commissionPlateforme: commissionPlateforme ?? this.commissionPlateforme,
      prixKmMoto: prixKmMoto ?? this.prixKmMoto,
      prixKmCamion: prixKmCamion ?? this.prixKmCamion,
      prixKmFourgon: prixKmFourgon ?? this.prixKmFourgon,
      approbationAutomatique: approbationAutomatique ?? this.approbationAutomatique,
      paiementEspeceActif: paiementEspeceActif ?? this.paiementEspeceActif,
      prixAbonnementJour: prixAbonnementJour ?? this.prixAbonnementJour,
      prixAbonnementMois: prixAbonnementMois ?? this.prixAbonnementMois,
      prixAbonnementAn: prixAbonnementAn ?? this.prixAbonnementAn,
    );
  }
}
