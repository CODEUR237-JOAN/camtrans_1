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
  });

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