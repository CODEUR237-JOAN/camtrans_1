import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

final serviceStockageProvider = Provider<ServiceStockage>((ref) {
  return ServiceStockage();
});

class ServiceStockage {
  // Informations Cloudinary
  final String cloudName = 'dl6na6qh7';
  final String uploadPreset = 'camtrans_preset';

  Future<String?> uploaderFichier({
    required XFile fichier,
    required String dossier,
    required String nomFichier,
  }) async {
    try {
      final url = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');
      final request = http.MultipartRequest('POST', url)
        ..fields['upload_preset'] = uploadPreset
        ..fields['folder'] = 'camtrans/$dossier'
        ..fields['public_id'] = nomFichier;

      if (kIsWeb) {
        final bytes = await fichier.readAsBytes();
        request.files.add(http.MultipartFile.fromBytes('file', bytes, filename: fichier.name));
      } else {
        request.files.add(await http.MultipartFile.fromPath('file', fichier.path));
      }

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(responseBody);
        return data['secure_url']; // Retourne l'URL publique de l'image
      } else {
        debugPrint("Erreur Cloudinary: $responseBody");
        return null;
      }
    } catch (e) {
      debugPrint("Erreur lors du téléchargement du fichier: $e");
      return null;
    }
  }

  Future<void> supprimerFichier(String url) async {
    // La suppression directe (Unsigned) n'est pas autorisée par défaut sur Cloudinary 
    // pour des raisons de sécurité. Pour l'instant on se contente de l'ignorer.
    debugPrint("Suppression ignorée (Cloudinary Unsigned)");
  }
}
