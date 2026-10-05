import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

/// Déclenche le téléchargement d'un fichier dans le navigateur.
///
/// Implémentation basée sur `package:web` + `dart:js_interop`
/// (remplace `dart:html`, déprécié et incompatible WASM).
void telechargerFichier(List<int> bytes, String nomFichier) {
  final donnees = Uint8List.fromList(bytes).toJS;
  final blob = web.Blob(<JSAny>[donnees].toJS);
  final url = web.URL.createObjectURL(blob);
  final lien = web.HTMLAnchorElement()
    ..href = url
    ..download = nomFichier;
  lien.click();
  web.URL.revokeObjectURL(url);
}
