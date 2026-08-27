import 'package:update_camtrans/coeur/utilitaires/parseur.dart';
import 'utilisateur.dart';

class Client extends Utilisateur {
  final int nombreCourses;
  final int nombreDemenagements;
  final List<String> adressesFavorites;
  final List<String> entreprisesFavorites;
  final double noteMoyenne;
  final String moyenPaiementPrefere;

  const Client({
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
    super.estEnLigne = false,
    super.derniereConnexion,
    this.nombreCourses = 0,
    this.nombreDemenagements = 0,
    this.adressesFavorites = const [],
    this.entreprisesFavorites = const [],
    this.noteMoyenne = 0.0,
    this.moyenPaiementPrefere = "",
  });

  @override
  Client copyWith({
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
    int? nombreCourses,
    int? nombreDemenagements,
    List<String>? adressesFavorites,
    List<String>? entreprisesFavorites,
    double? noteMoyenne,
    String? moyenPaiementPrefere,
  }) {
    return Client(
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
      nombreCourses: nombreCourses ?? this.nombreCourses,
      nombreDemenagements:
      nombreDemenagements ?? this.nombreDemenagements,
      adressesFavorites:
      adressesFavorites ?? this.adressesFavorites,
      entreprisesFavorites:
      entreprisesFavorites ??
          this.entreprisesFavorites,
      noteMoyenne:
      noteMoyenne ?? this.noteMoyenne,
      moyenPaiementPrefere:
      moyenPaiementPrefere ??
          this.moyenPaiementPrefere,
    );
  }

  @override
  Map<String, dynamic> toMap() {
    final map = super.toMap();

    map.addAll({
      "nombreCourses": nombreCourses,
      "nombreDemenagements": nombreDemenagements,
      "adressesFavorites": adressesFavorites,
      "entreprisesFavorites": entreprisesFavorites,
      "noteMoyenne": noteMoyenne,
      "moyenPaiementPrefere":
      moyenPaiementPrefere,
    });

    return map;
  }

  factory Client.fromMap(
      Map<String, dynamic> map) {
    return Client(
      id: map["id"] ?? "",
      nom: map["nom"] ?? "",
      prenom: map["prenom"] ?? "",
      email: map["email"] ?? "",
      telephone: map["telephone"] ?? "",
      photo: map["photo"] ?? "",
      adresse: map["adresse"] ?? "",
      ville: map["ville"] ?? "",
      role: map["role"] ?? "client",
      actif: map["actif"] ?? true,
      emailVerifie:
      map["emailVerifie"] ?? false,
      dateCreation: Parseur.toDateTime(map["dateCreation"]),
      nombreCourses:
      map["nombreCourses"] ?? 0,
      nombreDemenagements:
      map["nombreDemenagements"] ?? 0,
      adressesFavorites:
      List<String>.from(
          map["adressesFavorites"] ??
              []),
      entreprisesFavorites:
      List<String>.from(
          map["entreprisesFavorites"] ??
              []),
      noteMoyenne: Parseur.toDouble(map["noteMoyenne"]),
      moyenPaiementPrefere:
      map["moyenPaiementPrefere"] ??
          "",
    );
  }

  @override
  Map<String, dynamic> toJson() =>
      toMap();

  factory Client.fromJson(
      Map<String, dynamic> json) =>
      Client.fromMap(json);
}