import 'package:update_camtrans/coeur/utilitaires/parseur.dart';

class Utilisateur {
  final String id;
  final String nom;
  final String prenom;
  final String email;
  final String telephone;
  final String photo;
  final String adresse;
  final String ville;
  final String role;
  final bool actif;
  final bool emailVerifie;
  final DateTime dateCreation;
  final bool estEnLigne;
  final DateTime? derniereConnexion;

  const Utilisateur({
    required this.id,
    required this.nom,
    required this.prenom,
    required this.email,
    required this.telephone,
    required this.photo,
    required this.adresse,
    required this.ville,
    required this.role,
    required this.actif,
    required this.emailVerifie,
    required this.dateCreation,
    this.estEnLigne = false,
    this.derniereConnexion,
  });

  /// Copie de l'objet avec modification de certaines valeurs
  Utilisateur copyWith({
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
  }) {
    return Utilisateur(
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
    );
  }

  /// Conversion vers Firestore
  Map<String, dynamic> toMap() {
    return {
      "id": id,
      "nom": nom,
      "prenom": prenom,
      "email": email,
      "telephone": telephone,
      "photo": photo,
      "adresse": adresse,
      "ville": ville,
      "role": role,
      "actif": actif,
      "emailVerifie": emailVerifie,
      "dateCreation": dateCreation.toIso8601String(),
      "estEnLigne": estEnLigne,
      "derniereConnexion": derniereConnexion?.toIso8601String(),
    };
  }

  /// Création depuis Firestore
  factory Utilisateur.fromMap(Map<String, dynamic> map) {
    return Utilisateur(
      id: map["id"] ?? "",
      nom: map["nom"] ?? "",
      prenom: map["prenom"] ?? "",
      email: map["email"] ?? "",
      telephone: map["telephone"] ?? "",
      photo: map["photo"] ?? "",
      adresse: map["adresse"] ?? "",
      ville: map["ville"] ?? "",
      role: map["role"] ?? "",
      actif: map["actif"] ?? true,
      emailVerifie: map["emailVerifie"] ?? false,
      dateCreation: Parseur.toDateTime(map["dateCreation"]),
      
      // LOGIQUE DE PRESENCE : Si pas de signal depuis 1 minute, on force a hors ligne
      estEnLigne: (map["estEnLigne"] ?? false) && 
                  (map["derniereConnexion"] != null && 
                   DateTime.now().difference(Parseur.toDateTime(map["derniereConnexion"])).inSeconds <= 60),

      derniereConnexion: map["derniereConnexion"] != null ? Parseur.toDateTime(map["derniereConnexion"]) : null,
    );
  }

  /// Conversion JSON
  Map<String, dynamic> toJson() => toMap();

  factory Utilisateur.fromJson(Map<String, dynamic> json) =>
      Utilisateur.fromMap(json);

  @override
  String toString() {
    return '''
Utilisateur(
 id: $id,
 nom: $nom,
 prenom: $prenom,
 email: $email,
 telephone: $telephone,
 ville: $ville,
 role: $role
)
''';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is Utilisateur &&
            runtimeType == other.runtimeType &&
            id == other.id;
  }

  @override
  int get hashCode => id.hashCode;
}