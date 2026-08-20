import 'package:flutter/foundation.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

final serviceStockageProvider = Provider<ServiceStockage>((ref) {
  return ServiceStockage();
});

class ServiceStockage {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String?> uploaderFichier({
    required XFile fichier,
    required String dossier,
    required String nomFichier,
  }) async {
    try {
      final extensionFichier = fichier.name.split('.').last;
      final ref = _storage.ref().child('$dossier/$nomFichier.$extensionFichier');
      
      if (kIsWeb) {
        // Sur le Web, on utilise putData ou putBlob
        final bytes = await fichier.readAsBytes();
        final uploadTask = await ref.putData(bytes, SettableMetadata(contentType: 'image/$extensionFichier'));
        return await uploadTask.ref.getDownloadURL();
      } else {
        // Sur Mobile, on peut continuer à utiliser putFile en convertissant en File de dart:io
        // Mais pour éviter l'import de dart:io ici, on peut aussi utiliser putData sur mobile
        // ou un import conditionnel. Utilisons putData pour la simplicité multiplateforme.
        final bytes = await fichier.readAsBytes();
        final uploadTask = await ref.putData(bytes);
        return await uploadTask.ref.getDownloadURL();
      }
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