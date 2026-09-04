import 'package:update_camtrans/coeur/utilitaires/parseur.dart';
import 'package:update_camtrans/coeur/constantes/statuts.dart';

class Course {
  final String id;
  final String clientId;
  final String transporteurId;
  final String nomClient;
  final String nomTransporteur;
  final String telephoneClient;
  final String telephoneTransporteur;
  final String adresseDepart;
  final String adresseArrivee;
  final double latitudeDepart;
  final double longitudeDepart;
  final double latitudeArrivee;
  final double longitudeArrivee;
  final double distanceKm;
  final double volumeM3;
  final double poidsKg;
  final String typeVehicule;
  final String typeMarchandise;
  final double prixEstime;
  final double prixFinal;
  final String modePaiement;
  final bool paiementEffectue;
  final String statut;
  final String description;
  final List<String> photos;
  final DateTime dateCreation;
  final DateTime? dateDebut;
  final DateTime? dateFin;
  final bool fragile;
  final bool aideChargement;
  final bool aideDechargement;
  final String codeSuivi;
  final double noteClient;
  final double noteTransporteur;
  final String commentaireClient;
  final String commentaireTransporteur;

  //---------------- IA ----------------//
  final double scoreIA;
  final String vehiculeRecommandeIA;
  final double volumeEstimeIA;
  final String conseilIA;

  //---------------- Sprint 10 ---------//
  final String categorieService;
  final String optionGamme;
  final String detailsSpecifiques;
  final double distanceApprocheKm;
  final int tempsApprocheMin;

  //---------------- Phase 4 (Dispatch Automatique) ---------//
  final List<String> candidats;
  final int indexCandidatActuel;
  final DateTime? expirationProposition;

  //---------------- Escrow PIN -------------//
  final String codePinLivraison;
  final bool fondsDebloques;

  //---------------- Archivage logique -------//
  /// Si true, la course est masquée dans l'historique du transporteur
  final bool archivePourTransporteur;
  /// Si true, la course est masquée dans l'historique du client
  final bool archivePourClient;

  const Course({
    required this.id,
    required this.clientId,
    required this.transporteurId,
    required this.nomClient,
    required this.nomTransporteur,
    required this.telephoneClient,
    required this.telephoneTransporteur,
    required this.adresseDepart,
    required this.adresseArrivee,
    required this.latitudeDepart,
    required this.longitudeDepart,
    required this.latitudeArrivee,
    required this.longitudeArrivee,
    required this.distanceKm,
    required this.volumeM3,
    required this.poidsKg,
    required this.typeVehicule,
    required this.typeMarchandise,
    required this.prixEstime,
    required this.prixFinal,
    required this.modePaiement,
    required this.paiementEffectue,
    required this.statut,
    required this.description,
    required this.photos,
    required this.dateCreation,
    this.dateDebut,
    this.dateFin,
    required this.fragile,
    required this.aideChargement,
    required this.aideDechargement,
    required this.codeSuivi,
    required this.noteClient,
    required this.noteTransporteur,
    required this.commentaireClient,
    required this.commentaireTransporteur,
    required this.scoreIA,
    required this.vehiculeRecommandeIA,
    required this.volumeEstimeIA,
    required this.conseilIA,
    this.categorieService = "",
    this.optionGamme = "",
    this.detailsSpecifiques = "",
    this.distanceApprocheKm = 0.0,
    this.tempsApprocheMin = 0,
    this.candidats = const [],
    this.indexCandidatActuel = 0,
    this.expirationProposition,
    this.codePinLivraison = "",
    this.fondsDebloques = false,
    this.archivePourTransporteur = false,
    this.archivePourClient = false,
  });

  Course copyWith({
    String? id,
    String? clientId,
    String? transporteurId,
    String? nomClient,
    String? nomTransporteur,
    String? telephoneClient,
    String? telephoneTransporteur,
    String? adresseDepart,
    String? adresseArrivee,
    double? latitudeDepart,
    double? longitudeDepart,
    double? latitudeArrivee,
    double? longitudeArrivee,
    double? distanceKm,
    double? volumeM3,
    double? poidsKg,
    String? typeVehicule,
    String? typeMarchandise,
    double? prixEstime,
    double? prixFinal,
    String? modePaiement,
    bool? paiementEffectue,
    String? statut,
    String? description,
    List<String>? photos,
    DateTime? dateCreation,
    DateTime? dateDebut,
    DateTime? dateFin,
    bool? fragile,
    bool? aideChargement,
    bool? aideDechargement,
    String? codeSuivi,
    double? noteClient,
    double? noteTransporteur,
    String? commentaireClient,
    String? commentaireTransporteur,
    double? scoreIA,
    String? vehiculeRecommandeIA,
    double? volumeEstimeIA,
    String? conseilIA,
    String? categorieService,
    String? optionGamme,
    String? detailsSpecifiques,
    double? distanceApprocheKm,
    int? tempsApprocheMin,
    List<String>? candidats,
    int? indexCandidatActuel,
    DateTime? expirationProposition,
    String? codePinLivraison,
    bool? fondsDebloques,
    bool? archivePourTransporteur,
    bool? archivePourClient,
  }) {
    return Course(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      transporteurId: transporteurId ?? this.transporteurId,
      nomClient: nomClient ?? this.nomClient,
      nomTransporteur: nomTransporteur ?? this.nomTransporteur,
      telephoneClient: telephoneClient ?? this.telephoneClient,
      telephoneTransporteur: telephoneTransporteur ?? this.telephoneTransporteur,
      adresseDepart: adresseDepart ?? this.adresseDepart,
      adresseArrivee: adresseArrivee ?? this.adresseArrivee,
      latitudeDepart: latitudeDepart ?? this.latitudeDepart,
      longitudeDepart: longitudeDepart ?? this.longitudeDepart,
      latitudeArrivee: latitudeArrivee ?? this.latitudeArrivee,
      longitudeArrivee: longitudeArrivee ?? this.longitudeArrivee,
      distanceKm: distanceKm ?? this.distanceKm,
      volumeM3: volumeM3 ?? this.volumeM3,
      poidsKg: poidsKg ?? this.poidsKg,
      typeVehicule: typeVehicule ?? this.typeVehicule,
      typeMarchandise: typeMarchandise ?? this.typeMarchandise,
      prixEstime: prixEstime ?? this.prixEstime,
      prixFinal: prixFinal ?? this.prixFinal,
      modePaiement: modePaiement ?? this.modePaiement,
      paiementEffectue: paiementEffectue ?? this.paiementEffectue,
      statut: statut ?? this.statut,
      description: description ?? this.description,
      photos: photos ?? this.photos,
      dateCreation: dateCreation ?? this.dateCreation,
      dateDebut: dateDebut ?? this.dateDebut,
      dateFin: dateFin ?? this.dateFin,
      fragile: fragile ?? this.fragile,
      aideChargement: aideChargement ?? this.aideChargement,
      aideDechargement: aideDechargement ?? this.aideDechargement,
      codeSuivi: codeSuivi ?? this.codeSuivi,
      noteClient: noteClient ?? this.noteClient,
      noteTransporteur: noteTransporteur ?? this.noteTransporteur,
      commentaireClient: commentaireClient ?? this.commentaireClient,
      commentaireTransporteur: commentaireTransporteur ?? this.commentaireTransporteur,
      scoreIA: scoreIA ?? this.scoreIA,
      vehiculeRecommandeIA: vehiculeRecommandeIA ?? this.vehiculeRecommandeIA,
      volumeEstimeIA: volumeEstimeIA ?? this.volumeEstimeIA,
      conseilIA: conseilIA ?? this.conseilIA,
      categorieService: categorieService ?? this.categorieService,
      optionGamme: optionGamme ?? this.optionGamme,
      detailsSpecifiques: detailsSpecifiques ?? this.detailsSpecifiques,
      distanceApprocheKm: distanceApprocheKm ?? this.distanceApprocheKm,
      tempsApprocheMin: tempsApprocheMin ?? this.tempsApprocheMin,
      candidats: candidats ?? this.candidats,
      indexCandidatActuel: indexCandidatActuel ?? this.indexCandidatActuel,
      expirationProposition: expirationProposition ?? this.expirationProposition,
      codePinLivraison: codePinLivraison ?? this.codePinLivraison,
      fondsDebloques: fondsDebloques ?? this.fondsDebloques,
      archivePourTransporteur: archivePourTransporteur ?? this.archivePourTransporteur,
      archivePourClient: archivePourClient ?? this.archivePourClient,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      "id": id,
      "clientId": clientId,
      "transporteurId": transporteurId,
      "nomClient": nomClient,
      "nomTransporteur": nomTransporteur,
      "telephoneClient": telephoneClient,
      "telephoneTransporteur": telephoneTransporteur,
      "adresseDepart": adresseDepart,
      "adresseArrivee": adresseArrivee,
      "latitudeDepart": latitudeDepart,
      "longitudeDepart": longitudeDepart,
      "latitudeArrivee": latitudeArrivee,
      "longitudeArrivee": longitudeArrivee,
      "distanceKm": distanceKm,
      "volumeM3": volumeM3,
      "poidsKg": poidsKg,
      "typeVehicule": typeVehicule,
      "typeMarchandise": typeMarchandise,
      "prixEstime": prixEstime,
      "prixFinal": prixFinal,
      "modePaiement": modePaiement,
      "paiementEffectue": paiementEffectue,
      "statut": statut,
      "description": description,
      "photos": photos,
      "dateCreation": dateCreation.toIso8601String(),
      "dateDebut": dateDebut?.toIso8601String(),
      "dateFin": dateFin?.toIso8601String(),
      "fragile": fragile,
      "aideChargement": aideChargement,
      "aideDechargement": aideDechargement,
      "codeSuivi": codeSuivi,
      "noteClient": noteClient,
      "noteTransporteur": noteTransporteur,
      "commentaireClient": commentaireClient,
      "commentaireTransporteur": commentaireTransporteur,
      "scoreIA": scoreIA,
      "vehiculeRecommandeIA": vehiculeRecommandeIA,
      "volumeEstimeIA": volumeEstimeIA,
      "conseilIA": conseilIA,
      "categorieService": categorieService,
      "optionGamme": optionGamme,
      "detailsSpecifiques": detailsSpecifiques,
      "distanceApprocheKm": distanceApprocheKm,
      "tempsApprocheMin": tempsApprocheMin,
      "candidats": candidats,
      "indexCandidatActuel": indexCandidatActuel,
      "expirationProposition": expirationProposition?.toIso8601String(),
      "codePinLivraison": codePinLivraison,
      "fondsDebloques": fondsDebloques,
    };
  }

  factory Course.fromMap(Map<String, dynamic> map) {
    return Course(
      id: map["id"] ?? "",
      clientId: map["clientId"] ?? "",
      transporteurId: map["transporteurId"] ?? "",
      nomClient: map["nomClient"] ?? "",
      nomTransporteur: map["nomTransporteur"] ?? "",
      telephoneClient: map["telephoneClient"] ?? "",
      telephoneTransporteur: map["telephoneTransporteur"] ?? "",
      adresseDepart: map["adresseDepart"] ?? "",
      adresseArrivee: map["adresseArrivee"] ?? "",
      latitudeDepart: Parseur.toDouble(map["latitudeDepart"]),
      longitudeDepart: Parseur.toDouble(map["longitudeDepart"]),
      latitudeArrivee: Parseur.toDouble(map["latitudeArrivee"]),
      longitudeArrivee: Parseur.toDouble(map["longitudeArrivee"]),
      distanceKm: Parseur.toDouble(map["distanceKm"]),
      volumeM3: Parseur.toDouble(map["volumeM3"]),
      poidsKg: Parseur.toDouble(map["poidsKg"]),
      typeVehicule: map["typeVehicule"] ?? "",
      typeMarchandise: map["typeMarchandise"] ?? "",
      prixEstime: Parseur.toDouble(map["prixEstime"]),
      prixFinal: Parseur.toDouble(map["prixFinal"]),
      modePaiement: map["modePaiement"] ?? "",
      paiementEffectue: map["paiementEffectue"] ?? false,
      statut: _normalizeStatut(map["statut"] ?? "En attente"),
      description: map["description"] ?? "",
      photos: List<String>.from(map["photos"] ?? []),
      dateCreation: Parseur.toDateTime(map["dateCreation"]),
      dateDebut: map["dateDebut"] != null ? Parseur.toDateTime(map["dateDebut"]) : null,
      dateFin: map["dateFin"] != null ? Parseur.toDateTime(map["dateFin"]) : null,
      fragile: map["fragile"] ?? false,
      aideChargement: map["aideChargement"] ?? false,
      aideDechargement: map["aideDechargement"] ?? false,
      codeSuivi: map["codeSuivi"] ?? "",
      noteClient: Parseur.toDouble(map["noteClient"]),
      noteTransporteur: Parseur.toDouble(map["noteTransporteur"]),
      commentaireClient: map["commentaireClient"] ?? "",
      commentaireTransporteur: map["commentaireTransporteur"] ?? "",
      scoreIA: Parseur.toDouble(map["scoreIA"]),
      vehiculeRecommandeIA: map["vehiculeRecommandeIA"] ?? "",
      volumeEstimeIA: Parseur.toDouble(map["volumeEstimeIA"]),
      conseilIA: map["conseilIA"] ?? "",
      categorieService: map["categorieService"] ?? "",
      optionGamme: map["optionGamme"] ?? "",
      detailsSpecifiques: map["detailsSpecifiques"] ?? "",
      distanceApprocheKm: Parseur.toDouble(map["distanceApprocheKm"]),
      tempsApprocheMin: map["tempsApprocheMin"] ?? 0,
      candidats: map['candidats'] != null ? List<String>.from(map['candidats']) : const [],
      indexCandidatActuel: map['indexCandidatActuel'] ?? 0,
      expirationProposition: map['expirationProposition'] != null ? Parseur.toDateTime(map['expirationProposition']) : null,
      codePinLivraison: map['codePinLivraison'] ?? "",
      fondsDebloques: map['fondsDebloques'] ?? false,
      archivePourTransporteur: map['archivePourTransporteur'] ?? false,
      archivePourClient: map['archivePourClient'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => toMap();
  factory Course.fromJson(Map<String, dynamic> json) => Course.fromMap(json);

  static String _normalizeStatut(String rawStatut) {
    String l = rawStatut.toLowerCase();
    if (l.contains('termin') || l.contains('livr')) return StatutCourse.terminee;
    if (l.contains('annul')) return StatutCourse.annulee;
    if (l.contains('cours') || l.contains('transit') || l.contains('rout') || l.contains('charge')) return StatutCourse.enTransit;
    if (l.contains('attent') || l.contains('recherch')) return StatutCourse.recherche;
    if (l.contains('accept') || l.contains('attribu')) return StatutCourse.attribue;
    return rawStatut; // Fallback
  }
}