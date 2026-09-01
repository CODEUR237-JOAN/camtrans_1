import 'package:update_camtrans/coeur/utilitaires/parseur.dart';
import 'utilisateur.dart';

class Transporteur extends Utilisateur {
  final String typeVehicule;
  final String marqueVehicule;
  final String modeleVehicule;
  final String immatriculation;
  final String gamme;
  final bool gammeValidee;
  final String etatVehicule;
  final int anneeVehicule;
  final List<String> photosInspectionVehicule;
  final DateTime? dateDerniereInspection;
  final int signalementsEtatVehicule;
  final double capaciteM3;
  final double chargeMaxKg;

  final bool disponible;
  final bool documentsValides;

  final double noteMoyenne;
  final int nombreCourses;
  final double revenusTotaux;
  final double soldePortefeuille;

  final String numeroPermis;
  final String numeroCarteGrise;
  final String numeroAssurance;

  final String photoPermis;
  final String photoCarteGrise;
  final String photoAssurance;
  final String photoVehicule;

  final double latitude;
  final double longitude;

  final DateTime? dateFinAbonnement;

  bool get abonnementValide {
    if (dateFinAbonnement == null) return false;
    return dateFinAbonnement!.isAfter(DateTime.now());
  }

  const Transporteur({
    required super.id,
    required super.nom,
    required super.prenom,
    required super.email,
    required super.telephone,
    required super.photo,
    required super.adresse,
    required super.ville,
    required super.role,
    required super.actif,
    required super.emailVerifie,
    required super.dateCreation,

    this.typeVehicule = "",
    this.marqueVehicule = "",
    this.modeleVehicule = "",
    this.immatriculation = "",
    this.gamme = "Éco",
      this.gammeValidee = true,
    this.etatVehicule = "Standard",
    this.anneeVehicule = 0,
    this.photosInspectionVehicule = const [],
    this.dateDerniereInspection,
    this.signalementsEtatVehicule = 0,

    this.capaciteM3 = 0,
    this.chargeMaxKg = 0,

    this.disponible = true,
    this.documentsValides = false,

    this.noteMoyenne = 0,
    this.nombreCourses = 0,

    this.revenusTotaux = 0,
    this.soldePortefeuille = 0,

    this.numeroPermis = "",
    this.numeroCarteGrise = "",
    this.numeroAssurance = "",

    this.photoPermis = "",
    this.photoCarteGrise = "",
    this.photoAssurance = "",
    this.photoVehicule = "",

    this.latitude = 0,
    this.longitude = 0,
    this.dateFinAbonnement,
    super.estEnLigne = false,
    super.derniereConnexion,
  });

  @override
  Transporteur copyWith({
    String? id,
    String? nom,
    String? prenom,
    String? email,
    String? telephone,
    String? photo,
    String? adresse,
    String? ville,
    String? role,
    bool? actif,
    bool? emailVerifie,
    DateTime? dateCreation,
    bool? estEnLigne,
    DateTime? derniereConnexion,

    String? typeVehicule,
    String? marqueVehicule,
    String? modeleVehicule,
    String? immatriculation,
    String? gamme,
      bool? gammeValidee,
    String? etatVehicule,
    int? anneeVehicule,
    List<String>? photosInspectionVehicule,
    DateTime? dateDerniereInspection,
    int? signalementsEtatVehicule,

    double? capaciteM3,
    double? chargeMaxKg,

    bool? disponible,
    bool? documentsValides,

    double? noteMoyenne,
    int? nombreCourses,

    double? revenusTotaux,
    double? soldePortefeuille,

    String? numeroPermis,
    String? numeroCarteGrise,
    String? numeroAssurance,

    String? photoPermis,
    String? photoCarteGrise,
    String? photoAssurance,
    String? photoVehicule,

    double? latitude,
    double? longitude,
    DateTime? dateFinAbonnement,
  }) {
    return Transporteur(
      id: id ?? this.id,
      nom: nom ?? this.nom,
      prenom: prenom ?? this.prenom,
      email: email ?? this.email,
      telephone: telephone ?? this.telephone,
      photo: photo ?? this.photo,
      adresse: adresse ?? this.adresse,
      ville: ville ?? this.ville,
      role: role ?? this.role,
      actif: actif ?? this.actif,
      emailVerifie: emailVerifie ?? this.emailVerifie,
      dateCreation: dateCreation ?? this.dateCreation,
      estEnLigne: estEnLigne ?? this.estEnLigne,
      derniereConnexion: derniereConnexion ?? this.derniereConnexion,

      typeVehicule: typeVehicule ?? this.typeVehicule,
      marqueVehicule: marqueVehicule ?? this.marqueVehicule,
      modeleVehicule: modeleVehicule ?? this.modeleVehicule,
      immatriculation: immatriculation ?? this.immatriculation,
      gamme: gamme ?? this.gamme,
        gammeValidee: gammeValidee ?? this.gammeValidee,
      etatVehicule: etatVehicule ?? this.etatVehicule,
      anneeVehicule: anneeVehicule ?? this.anneeVehicule,
      photosInspectionVehicule: photosInspectionVehicule ?? this.photosInspectionVehicule,
      dateDerniereInspection: dateDerniereInspection ?? this.dateDerniereInspection,
      signalementsEtatVehicule: signalementsEtatVehicule ?? this.signalementsEtatVehicule,

      capaciteM3: capaciteM3 ?? this.capaciteM3,
      chargeMaxKg: chargeMaxKg ?? this.chargeMaxKg,

      disponible: disponible ?? this.disponible,
      documentsValides: documentsValides ?? this.documentsValides,

      noteMoyenne: noteMoyenne ?? this.noteMoyenne,
      nombreCourses: nombreCourses ?? this.nombreCourses,

      revenusTotaux: revenusTotaux ?? this.revenusTotaux,
      soldePortefeuille: soldePortefeuille ?? this.soldePortefeuille,

      numeroPermis: numeroPermis ?? this.numeroPermis,
      numeroCarteGrise: numeroCarteGrise ?? this.numeroCarteGrise,
      numeroAssurance: numeroAssurance ?? this.numeroAssurance,

      photoPermis: photoPermis ?? this.photoPermis,
      photoCarteGrise: photoCarteGrise ?? this.photoCarteGrise,
      photoAssurance: photoAssurance ?? this.photoAssurance,
      photoVehicule: photoVehicule ?? this.photoVehicule,

      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      dateFinAbonnement: dateFinAbonnement ?? this.dateFinAbonnement,
    );
  }

  @override
  Map<String, dynamic> toMap() {
    final map = super.toMap();

    map.addAll({
      "typeVehicule": typeVehicule,
      "marqueVehicule": marqueVehicule,
      "modeleVehicule": modeleVehicule,
      "immatriculation": immatriculation,
      "gamme": gamme,
        "gammeValidee": gammeValidee,
      "etatVehicule": etatVehicule,
      "anneeVehicule": anneeVehicule,
      "photosInspectionVehicule": photosInspectionVehicule,
      "dateDerniereInspection": dateDerniereInspection?.millisecondsSinceEpoch,
      "signalementsEtatVehicule": signalementsEtatVehicule,
      "capaciteM3": capaciteM3,
      "chargeMaxKg": chargeMaxKg,
      "disponible": disponible,
      "documentsValides": documentsValides,
      "noteMoyenne": noteMoyenne,
      "nombreCourses": nombreCourses,
      "revenusTotaux": revenusTotaux,
      "soldePortefeuille": soldePortefeuille,
      "numeroPermis": numeroPermis,
      "numeroCarteGrise": numeroCarteGrise,
      "numeroAssurance": numeroAssurance,
      "photoPermis": photoPermis,
      "photoCarteGrise": photoCarteGrise,
      "photoAssurance": photoAssurance,
      "photoVehicule": photoVehicule,
      "latitude": latitude,
      "longitude": longitude,
      "dateFinAbonnement": dateFinAbonnement?.millisecondsSinceEpoch,
    });

    return map;
  }

  factory Transporteur.fromMap(Map<String, dynamic> map) {
    return Transporteur(
      id: map["id"] ?? "",
      nom: map["nom"] ?? "",
      prenom: map["prenom"] ?? "",
      email: map["email"] ?? "",
      telephone: map["telephone"] ?? "",
      photo: map["photo"] ?? "",
      adresse: map["adresse"] ?? "",
      ville: map["ville"] ?? "",
      role: map["role"] ?? "transporteur",
      actif: map["actif"] ?? true,
      emailVerifie: map["emailVerifie"] ?? false,
      dateCreation: Parseur.toDateTime(map["dateCreation"]),

      typeVehicule: map["typeVehicule"] ?? "",
      marqueVehicule: map["marqueVehicule"] ?? "",
      modeleVehicule: map["modeleVehicule"] ?? "",
      immatriculation: map["immatriculation"] ?? "",
      gamme: map["gamme"] ?? "Éco",
        gammeValidee: map["gammeValidee"] ?? true,
      etatVehicule: map["etatVehicule"] ?? "Standard",
      anneeVehicule: map["anneeVehicule"] ?? 0,
      photosInspectionVehicule: List<String>.from(map["photosInspectionVehicule"] ?? []),
      dateDerniereInspection: map["dateDerniereInspection"] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map["dateDerniereInspection"]) 
          : null,
      signalementsEtatVehicule: map["signalementsEtatVehicule"] ?? 0,

      capaciteM3: Parseur.toDouble(map["capaciteM3"]),
      chargeMaxKg: Parseur.toDouble(map["chargeMaxKg"]),

      disponible: map["disponible"] ?? true,
      documentsValides: map["documentsValides"] ?? false,

      noteMoyenne: Parseur.toDouble(map["noteMoyenne"]),
      nombreCourses: map["nombreCourses"] ?? 0,

      revenusTotaux: Parseur.toDouble(map["revenusTotaux"]),
      soldePortefeuille: Parseur.toDouble(map["soldePortefeuille"]),

      numeroPermis: map["numeroPermis"] ?? "",
      numeroCarteGrise: map["numeroCarteGrise"] ?? "",
      numeroAssurance: map["numeroAssurance"] ?? "",

      photoPermis: map["photoPermis"] ?? "",
      photoCarteGrise: map["photoCarteGrise"] ?? "",
      photoAssurance: map["photoAssurance"] ?? "",
      photoVehicule: map["photoVehicule"] ?? "",

      latitude: Parseur.toDouble(map["latitude"]),
      longitude: Parseur.toDouble(map["longitude"]),
      dateFinAbonnement: map["dateFinAbonnement"] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map["dateFinAbonnement"]) 
          : null,
      estEnLigne: map["estEnLigne"] ?? false,
      derniereConnexion: map["derniereConnexion"] != null ? Parseur.toDateTime(map["derniereConnexion"]) : null,
    );
  }

  @override
  Map<String, dynamic> toJson() => toMap();

  factory Transporteur.fromJson(Map<String, dynamic> json) =>
      Transporteur.fromMap(json);

  /// Méthode métier : Traiter un signalement client concernant l'état du véhicule.
  /// Si le nombre de signalements atteint ou dépasse 2, le transporteur perd son statut "Confort".
  Transporteur traiterSignalementClient() {
    int nouveauxSignalements = signalementsEtatVehicule + 1;
    String nouvelleGamme = gamme ?? "Éco";
    
    if (nouveauxSignalements >= 2 && nouvelleGamme == "Confort") {
      nouvelleGamme = "Éco"; // Rétrogradation automatique
    }
    
    return copyWith(
      signalementsEtatVehicule: nouveauxSignalements,
      gamme: nouvelleGamme,
      gammeValidee: nouvelleGamme == "Confort" ? gammeValidee : true,
    );
  }
}