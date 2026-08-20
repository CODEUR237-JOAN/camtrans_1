import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  final String id;
  final String expediteurId;
  final String destinataireId;
  final String contenu;
  final DateTime dateEnvoi;
  final bool estLu;

  Message({
    required this.id,
    required this.expediteurId,
    required this.destinataireId,
    required this.contenu,
    required this.dateEnvoi,
    this.estLu = false,
  });

  Map<String, dynamic> versMap() {
    return {
      'id': id,
      'expediteurId': expediteurId,
      'destinataireId': destinataireId,
      'contenu': contenu,
      'dateEnvoi': Timestamp.fromDate(dateEnvoi),
      'estLu': estLu,
    };
  }

  factory Message.depuisMap(Map<String, dynamic> map, String docId) {
    return Message(
      id: docId,
      expediteurId: map['expediteurId'] ?? '',
      destinataireId: map['destinataireId'] ?? '',
      contenu: map['contenu'] ?? '',
      dateEnvoi: (map['dateEnvoi'] as Timestamp?)?.toDate() ?? DateTime.now(),
      estLu: map['estLu'] ?? false,
    );
  }
}
