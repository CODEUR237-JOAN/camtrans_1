import 'package:cloud_firestore/cloud_firestore.dart';

class MessageChat {
  final String id;
  final String expediteurId;
  final String texte;

  /// URL Cloudinary de l'image jointe. Vide pour un message texte simple.
  final String imageUrl;

  final DateTime timestamp;

  MessageChat({
    required this.id,
    required this.expediteurId,
    required this.texte,
    this.imageUrl = '',
    required this.timestamp,
  });

  /// true si le message contient une image.
  bool get estImage => imageUrl.isNotEmpty;

  factory MessageChat.fromMap(Map<String, dynamic> data, String documentId) {
    return MessageChat(
      id: documentId,
      expediteurId: data['expediteurId'] ?? '',
      texte: data['texte'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'expediteurId': expediteurId,
      'texte': texte,
      'imageUrl': imageUrl,
      'timestamp': FieldValue.serverTimestamp(),
    };
  }
}
