import '../../coeur/utilitaires/parseur.dart';

class NotificationApp {
  final String id;

  final String utilisateurId;

  final String titre;

  final String message;

  final String type;

  final String categorie;

  final bool lue;

  final bool envoyee;

  final DateTime dateCreation;

  final DateTime? dateLecture;

  final String image;

  final String lien;

  final String action;

  final String expediteurId;

  final String expediteurNom;

  final String priorite;

  final bool notificationPush;

  final bool notificationEmail;

  final bool notificationSms;

  final Map<String, dynamic> donnees;

  const NotificationApp({
    required this.id,
    required this.utilisateurId,
    required this.titre,
    required this.message,
    required this.type,
    required this.categorie,
    required this.lue,
    required this.envoyee,
    required this.dateCreation,
    this.dateLecture,
    required this.image,
    required this.lien,
    required this.action,
    required this.expediteurId,
    required this.expediteurNom,
    required this.priorite,
    required this.notificationPush,
    required this.notificationEmail,
    required this.notificationSms,
    required this.donnees,
  });

  Map<String, dynamic> toMap() {
    return {
      "id": id,
      "utilisateurId": utilisateurId,
      "titre": titre,
      "message": message,
      "type": type,
      "categorie": categorie,
      "lue": lue,
      "envoyee": envoyee,
      "dateCreation": dateCreation.toIso8601String(),
      "dateLecture": dateLecture?.toIso8601String(),
      "image": image,
      "lien": lien,
      "action": action,
      "expediteurId": expediteurId,
      "expediteurNom": expediteurNom,
      "priorite": priorite,
      "notificationPush": notificationPush,
      "notificationEmail": notificationEmail,
      "notificationSms": notificationSms,
      "donnees": donnees,
    };
  }

  factory NotificationApp.fromMap(
      Map<String, dynamic> map) {
    return NotificationApp(
      id: map["id"] ?? "",
      utilisateurId: map["utilisateurId"] ?? "",
      titre: map["titre"] ?? "",
      message: map["message"] ?? "",
      type: map["type"] ?? "",
      categorie: map["categorie"] ?? "",
      lue: map["lue"] ?? false,
      envoyee: map["envoyee"] ?? false,
      dateCreation: Parseur.toDateTime(map["dateCreation"]),
      dateLecture: map["dateLecture"] != null
          ? Parseur.toDateTime(map["dateLecture"])
          : null,
      image: map["image"] ?? "",
      lien: map["lien"] ?? "",
      action: map["action"] ?? "",
      expediteurId: map["expediteurId"] ?? "",
      expediteurNom:
      map["expediteurNom"] ?? "",
      priorite: map["priorite"] ?? "Normale",
      notificationPush:
      map["notificationPush"] ?? true,
      notificationEmail:
      map["notificationEmail"] ?? false,
      notificationSms:
      map["notificationSms"] ?? false,
      donnees: Map<String, dynamic>.from(
        map["donnees"] ?? {},
      ),
    );
  }

  Map<String, dynamic> toJson() => toMap();

  factory NotificationApp.fromJson(
      Map<String, dynamic> json) =>
      NotificationApp.fromMap(json);

  NotificationApp copyWith({
    String? id,
    String? utilisateurId,
    String? titre,
    String? message,
    String? type,
    String? categorie,
    bool? lue,
    bool? envoyee,
    DateTime? dateCreation,
    DateTime? dateLecture,
    String? image,
    String? lien,
    String? action,
    String? expediteurId,
    String? expediteurNom,
    String? priorite,
    bool? notificationPush,
    bool? notificationEmail,
    bool? notificationSms,
    Map<String, dynamic>? donnees,
  }) {
    return NotificationApp(
      id: id ?? this.id,
      utilisateurId:
      utilisateurId ?? this.utilisateurId,
      titre: titre ?? this.titre,
      message: message ?? this.message,
      type: type ?? this.type,
      categorie: categorie ?? this.categorie,
      lue: lue ?? this.lue,
      envoyee: envoyee ?? this.envoyee,
      dateCreation:
      dateCreation ?? this.dateCreation,
      dateLecture:
      dateLecture ?? this.dateLecture,
      image: image ?? this.image,
      lien: lien ?? this.lien,
      action: action ?? this.action,
      expediteurId:
      expediteurId ?? this.expediteurId,
      expediteurNom:
      expediteurNom ?? this.expediteurNom,
      priorite: priorite ?? this.priorite,
      notificationPush:
      notificationPush ??
          this.notificationPush,
      notificationEmail:
      notificationEmail ??
          this.notificationEmail,
      notificationSms:
      notificationSms ??
          this.notificationSms,
      donnees: donnees ?? this.donnees,
    );
  }
}