import 'package:cloud_firestore/cloud_firestore.dart';

class MessageChat {
  final String id;
  final String expediteurId;
  final String texte;
  final DateTime timestamp;

  MessageChat({
    required this.id,
    required this.expediteurId,
    required this.texte,
    required this.timestamp,
  });

  factory MessageChat.fromMap(Map<String, dynamic> data, String documentId) {
    return MessageChat(
      id: documentId,
      expediteurId: data['expediteurId'] ?? '',
      texte: data['texte'] ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'expediteurId': expediteurId,
      'texte': texte,
      'timestamp': FieldValue.serverTimestamp(),
    };
  }
}
