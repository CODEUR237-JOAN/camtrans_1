import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final serviceStockageProvider = Provider<ServiceStockage>((ref) {
  return ServiceStockage();
});

class ServiceStockage {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String?> uploaderFichier({
    required File fichier,
    required String dossier,
    required String nomFichier,
  }) async {
    try {
      final extensionFichier = fichier.path.split('.').last;
      final ref = _storage.ref().child('$dossier/$nomFichier.$extensionFichier');
      
      final uploadTask = await ref.putFile(fichier);
      final url = await uploadTask.ref.getDownloadURL();
      
      return url;
    } catch (e) {
      debugPrint("Erreur lors de l'upload du fichier: $e");
      return null;
    }
  }

  Future<void> supprimerFichier(String url) async {
    try {
      final ref = _storage.refFromURL(url);
      await ref.delete();
    } catch (e) {
      debugPrint("Erreur lors de la suppression du fichier: $e");
    }
  }
}