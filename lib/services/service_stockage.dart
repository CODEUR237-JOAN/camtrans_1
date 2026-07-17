import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final serviceStockageProvider = Provider<ServiceStockage>((ref) {
  return ServiceStockage();
});

class ServiceStockage {
  final FirebaseStorage _storage =
      FirebaseStorage.instance;

  // ===========================
  // Téléverser un fichier
  // ===========================

  Future<String> televerserFichier({
    required File fichier,
    required String dossier,
    required String nomFichier,
  }) async {
    final Reference reference = _storage
        .ref()
        .child(dossier)
        .child(nomFichier);

    final UploadTask uploadTask =
    reference.putFile(fichier);

    final TaskSnapshot snapshot =
    await uploadTask;

    return await snapshot.ref.getDownloadURL();
  }

  // ===========================
  // Supprimer un fichier
  // ===========================

  Future<void> supprimerFichier({
    required String url,
  }) async {
    final Reference reference =
    _storage.refFromURL(url);

    await reference.delete();
  }

  // ===========================
  // Télécharger un fichier
  // ===========================

  Future<String> obtenirUrl({
    required String dossier,
    required String nomFichier,
  }) async {
    return await _storage
        .ref()
        .child(dossier)
        .child(nomFichier)
        .getDownloadURL();
  }

  // ===========================
  // Vérifier l'existence
  // ===========================

  Future<bool> fichierExiste({
    required String dossier,
    required String nomFichier,
  }) async {
    try {
      await _storage
          .ref()
          .child(dossier)
          .child(nomFichier)
          .getMetadata();

      return true;
    } catch (_) {
      return false;
    }
  }

  // ===========================
  // Taille d'un fichier
  // ===========================

  Future<int> tailleFichier({
    required String dossier,
    required String nomFichier,
  }) async {
    final metadata = await _storage
        .ref()
        .child(dossier)
        .child(nomFichier)
        .getMetadata();

    return metadata.size ?? 0;
  }

  // ===========================
  // Métadonnées
  // ===========================

  Future<FullMetadata> metadata({
    required String dossier,
    required String nomFichier,
  }) async {
    return await _storage
        .ref()
        .child(dossier)
        .child(nomFichier)
        .getMetadata();
  }
}