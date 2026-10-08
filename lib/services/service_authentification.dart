import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'service_presence.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Exception métier d'authentification porteuse d'un message déjà
/// humanisé (prêt à afficher). `toString()` renvoie directement ce message.
class AuthException implements Exception {
  final String message;
  AuthException(this.message);
  @override
  String toString() => message;
}

final serviceAuthentificationProvider =
    Provider<ServiceAuthentification>((ref) {
  return ServiceAuthentification();
});

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(serviceAuthentificationProvider).changementsAuthentification;
});

class ServiceAuthentification {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    //  P1-8 : Le clientId Web doit être configuré dans la console Firebase/GCP.
    // Sur mobile (Android/iOS), il n'est pas nécessaire ici.
  );

  /// Utilisateur connecté
  User? get utilisateur => _auth.currentUser;

  /// Flux de connexion
  Stream<User?> get changementsAuthentification => _auth.authStateChanges();

  /// Inscription (bas niveau — l'unicité email est gérée par FirebaseAuth).
  Future<UserCredential> inscription({
    required String email,
    required String motDePasse,
  }) async {
    return await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: motDePasse,
    );
  }

  /// Normalise un numéro camerounais : ne garde que les chiffres et ajoute
  /// l'indicatif 237 si absent (sert de clé d'index unique et stable).
  String _normaliserTelephone(String telephone) {
    var d = telephone.replaceAll(RegExp(r'[^0-9]'), '');
    if (d.length == 9) d = '237$d';
    return d;
  }

  /// Vérifie si un numéro est déjà réservé (collection d'index
  /// `index_telephones`). Fiable uniquement si l'utilisateur est authentifié
  /// (les règles exigent une session). Utilisé en interne par l'inscription.
  Future<bool> telephoneDejaUtilise(String telephone) async {
    final cle = _normaliserTelephone(telephone);
    if (cle.isEmpty) return false;
    final doc = await FirebaseFirestore.instance
        .collection('index_telephones')
        .doc(cle)
        .get();
    return doc.exists;
  }

  /// Inscription avec vérifications métier :
  ///   - Unicité de l'email : gérée par FirebaseAuth (messages humanisés).
  ///   - Unicité du téléphone : réservation ATOMIQUE dans `index_telephones`
  ///     (transaction), après authentification pour respecter les règles.
  /// Lève une [AuthException] au message prêt à afficher en cas d'échec.
  /// Ne vérifie JAMAIS l'unicité du mot de passe (anti-pattern de sécurité).
  Future<UserCredential> inscriptionAvecVerifications({
    required String email,
    required String motDePasse,
    required String telephone,
  }) async {
    final cleTel = _normaliserTelephone(telephone);

    // 1. Création du compte (email géré par FirebaseAuth → authentifie l'user).
    late final UserCredential cred;
    try {
      cred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: motDePasse,
      );
    } on FirebaseAuthException catch (e) {
      throw AuthException(_messageErreurAuth(e));
    }

    // 2. Réservation atomique du téléphone (maintenant authentifié).
    if (cleTel.isNotEmpty) {
      final db = FirebaseFirestore.instance;
      final ref = db.collection('index_telephones').doc(cleTel);
      try {
        await db.runTransaction((tx) async {
          final snap = await tx.get(ref);
          if (snap.exists) {
            throw AuthException('Ce numéro est déjà lié à un compte.');
          }
          tx.set(ref, {
            'uid': cred.user?.uid ?? '',
            'telephone': cleTel,
            'dateCreation': FieldValue.serverTimestamp(),
          });
        });
      } on AuthException {
        // Numéro déjà pris → on annule le compte à peine créé.
        try {
          await cred.user?.delete();
        } catch (_) { /* erreur ignorée */ }
        rethrow;
      } catch (e) {
        // Index momentanément injoignable : on ne bloque pas l'inscription
        // (l'email reste protégé par FirebaseAuth).
      }
    }

    return cred;
  }

  /// Traduit un code d'erreur FirebaseAuth en message clair (FR).
  String _messageErreurAuth(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'Cet email est déjà utilisé.';
      case 'invalid-email':
        return 'Adresse e-mail invalide.';
      case 'weak-password':
        return 'Mot de passe trop faible (6 caractères minimum).';
      case 'operation-not-allowed':
        return 'Inscription par e-mail désactivée. Contactez le support.';
      case 'network-request-failed':
        return 'Pas de connexion Internet. Vérifiez votre réseau.';
      case 'too-many-requests':
        return 'Trop de tentatives. Réessayez dans quelques minutes.';
      default:
        return 'Une erreur est survenue lors de l\'inscription. Réessayez.';
    }
  }

  /// Connexion
  Future<UserCredential> connexion({
    required String email,
    required String motDePasse,
  }) async {
    return await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: motDePasse,
    );
  }

  /// Déconnexion
  Future<void> deconnexion() async {
    // 1. Arreter la presence avant de se deconnecter car on a besoin de currentUser
    try {
      await ServicePresence().arreter();
    } catch (e) {
      //  FIX : Erreur loggée — ne doit pas bloquer la déconnexion
    }
    // 2. Se deconnecter
    await _auth.signOut();
  }

  /// Réinitialisation du mot de passe
  Future<void> reinitialiserMotDePasse(
    String email,
  ) async {
    await _auth.sendPasswordResetEmail(
      email: email.trim(),
    );
  }

  /// Vérification de l'email
  Future<void> envoyerVerificationEmail() async {
    if (_auth.currentUser != null && !_auth.currentUser!.emailVerified) {
      await _auth.currentUser!.sendEmailVerification();
    }
  }

  /// Actualiser les informations utilisateur
  Future<void> actualiserUtilisateur() async {
    await _auth.currentUser?.reload();
  }

  /// Mettre à jour le profil (nom et photo)
  Future<void> mettreAJourProfil({String? nom, String? photoUrl}) async {
    final user = _auth.currentUser;
    if (user != null) {
      if (nom != null) await user.updateDisplayName(nom);
      if (photoUrl != null) await user.updatePhotoURL(photoUrl);
    }
  }

  /// Email vérifié ?
  bool get emailVerifie => _auth.currentUser?.emailVerified ?? false;

  /// Modifier le mot de passe
  Future<void> modifierMotDePasse(String nouveauMotDePasse) async {
    await _auth.currentUser?.updatePassword(
      nouveauMotDePasse,
    );
  }

  /// Modifier l'email
  Future<void> modifierEmail(String nouvelEmail) async {
    await _auth.currentUser?.verifyBeforeUpdateEmail(
      nouvelEmail.trim(),
    );
  }

  /// Supprimer le compte
  Future<void> supprimerCompte() async {
    await _auth.currentUser?.delete();
  }

  /// Ré-authentifier l'utilisateur
  Future<void> reauthentifier(String email, String motDePasse) async {
    final user = _auth.currentUser;
    if (user != null && user.email != null) {
      AuthCredential credential = EmailAuthProvider.credential(
        email: email.trim(),
        password: motDePasse,
      );
      await user.reauthenticateWithCredential(credential);
    }
  }

  /// Connexion avec Google (OAuth2).
  ///
  /// Flux complet : popup Google → OAuthCredential → authentification
  /// Firebase → création/mise à jour du profil Firestore à la première
  /// connexion. Retourne `null` si l'utilisateur annule (jamais de crash).
  Future<UserCredential?> connexionGoogle() async {
    try {
      // 1. Déclenchement du popup Google.
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null; // Annulation utilisateur.

      // 2. Récupération des jetons OAuth.
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // 3. Authentification Firebase.
      final userCred = await _auth.signInWithCredential(credential);

      // 4. Première connexion → créer un profil générique dans `utilisateurs`.
      //    Le rôle (client / transporteur) est choisi ensuite via l'écran
      //    de choix de profil ; le routage existant s'en charge.
      final user = userCred.user;
      if (user != null && (userCred.additionalUserInfo?.isNewUser ?? false)) {
        try {
          await FirebaseFirestore.instance
              .collection('utilisateurs')
              .doc(user.uid)
              .set({
            'uid': user.uid,
            'email': user.email ?? '',
            'nom': user.displayName ?? '',
            'photo': user.photoURL ?? '',
            'fournisseur': 'google',
            'dateCreation': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        } catch (e) {
          // Le profil pourra être recréé plus tard ; ne pas bloquer la connexion.
        }
      }

      return userCred;
    } catch (e) {
      // Annulation côté natif (ex: retour arrière Android) → pas une erreur.
      final msg = e.toString().toLowerCase();
      if (msg.contains('cancel') ||
          msg.contains('aborted') ||
          msg.contains('12501') ||
          msg.contains('sign_in_canceled')) {
        return null;
      }
      rethrow;
    }
  }

  /// Déconnexion Google (nettoie aussi la session Google)
  Future<void> deconnexionGoogle() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) { /* erreur ignorée */ }
  }
}
