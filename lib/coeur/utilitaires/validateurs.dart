class Validateurs {
  Validateurs._();

  // ===============================
  // Champ obligatoire
  // ===============================

  static String? obligatoire(
      String? valeur, {
        String nomChamp = "Ce champ",
      }) {
    if (valeur == null || valeur.trim().isEmpty) {
      return "$nomChamp est obligatoire.";
    }

    return null;
  }

  // ===============================
  // Nom complet
  // ===============================

  static String? nom(String? valeur) {
    if (valeur == null || valeur.trim().isEmpty) {
      return "Veuillez saisir votre nom.";
    }

    if (valeur.trim().length < 3) {
      return "Le nom est trop court.";
    }

    return null;
  }

  // ===============================
  // Email
  // ===============================

  static String? email(String? valeur) {
    if (valeur == null || valeur.trim().isEmpty) {
      return "Veuillez saisir votre adresse e-mail.";
    }

    final expression = RegExp(
      r'^[\w\.-]+@[\w\.-]+\.\w+$',
    );

    if (!expression.hasMatch(valeur.trim())) {
      return "Adresse e-mail invalide.";
    }

    return null;
  }

  // ===============================
  // Téléphone Cameroun
  // ===============================

  static String? telephone(String? valeur) {
    if (valeur == null || valeur.trim().isEmpty) {
      return "Veuillez saisir votre numéro de téléphone.";
    }

    final numero = valeur.replaceAll(" ", "");

    final expression = RegExp(
      r'^(6|2)[0-9]{8}$',
    );

    if (!expression.hasMatch(numero)) {
      return "Numéro camerounais invalide.";
    }

    return null;
  }

  // ===============================
  // Mot de passe
  // ===============================

  static String? motDePasse(String? valeur) {
    if (valeur == null || valeur.isEmpty) {
      return "Veuillez saisir votre mot de passe.";
    }

    if (valeur.length < 8) {
      return "Le mot de passe doit contenir au moins 8 caractères.";
    }

    return null;
  }

  // ===============================
  // Confirmation mot de passe
  // ===============================

  static String? confirmerMotDePasse(
      String? confirmation,
      String motDePasse,
      ) {
    if (confirmation == null || confirmation.isEmpty) {
      return "Veuillez confirmer votre mot de passe.";
    }

    if (confirmation != motDePasse) {
      return "Les mots de passe ne correspondent pas.";
    }

    return null;
  }

  // ===============================
  // Montant
  // ===============================

  static String? montant(String? valeur) {
    if (valeur == null || valeur.trim().isEmpty) {
      return "Veuillez saisir un montant.";
    }

    final montant = double.tryParse(
      valeur.replaceAll(",", "."),
    );

    if (montant == null) {
      return "Montant invalide.";
    }

    if (montant <= 0) {
      return "Le montant doit être supérieur à zéro.";
    }

    return null;
  }

  // ===============================
  // Poids
  // ===============================

  static String? poids(String? valeur) {
    if (valeur == null || valeur.trim().isEmpty) {
      return "Veuillez saisir le poids.";
    }

    final poids = double.tryParse(
      valeur.replaceAll(",", "."),
    );

    if (poids == null) {
      return "Poids invalide.";
    }

    if (poids <= 0) {
      return "Le poids doit être supérieur à zéro.";
    }

    return null;
  }

  // ===============================
  // Volume
  // ===============================

  static String? volume(String? valeur) {
    if (valeur == null || valeur.trim().isEmpty) {
      return "Veuillez saisir le volume.";
    }

    final volume = double.tryParse(
      valeur.replaceAll(",", "."),
    );

    if (volume == null) {
      return "Volume invalide.";
    }

    if (volume <= 0) {
      return "Le volume doit être supérieur à zéro.";
    }

    return null;
  }
}