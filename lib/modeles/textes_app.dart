class TextesApp {
  final Map<String, dynamic> textes;

  const TextesApp({this.textes = const {}});

  factory TextesApp.fromMap(Map<String, dynamic> map) {
    return TextesApp(textes: map);
  }

  Map<String, dynamic> toMap() {
    return textes;
  }

  /// Récupère un texte à partir de sa clé.
  /// Si la clé n'existe pas, retourne [valeurParDefaut].
  String get(String cle, String valeurParDefaut) {
    if (textes.containsKey(cle) && textes[cle] != null && textes[cle].toString().isNotEmpty) {
      return textes[cle].toString();
    }
    return valeurParDefaut;
  }
}
