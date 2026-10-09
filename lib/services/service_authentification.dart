import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'service_presence.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter/foundation.dart';

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
    clientId: kIsWeb ? '60771248934-o1oi2uvfbpdg4ps2q9pvnbcchqshod7n.apps.googleusercontent.com' : null,
  );

  /// Utilisateur connecté
  User? get utilisateur => _auth.currentUser;

  /// Flux de connexion
  Stream<User?> get changementsAuthentification => _auth.authStateChanges();

  // ⚠️ POLITIQUE D'INSCRIPTION : seules les adresses de comptes Google
  // (vérifiées par Google) peuvent créer un NOUVEAU compte. L'ancienne
  // inscription libre `createUserWithEmailAndPassword` a été retirée pour
  // empêcher tout contournement. La CONNEXION email/mot de passe reste
  // inchangée : les comptes déjà créés continuent de fonctionner.

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

  /// Ouvre le sélecteur de comptes Google et renvoie le compte choisi.
  /// Force l'affichage de la liste (signOut préalable) pour que l'utilisateur
  /// choisisse explicitement son compte. Renvoie `null` en cas d'annulation.
  Future<GoogleSignInAccount?> selectionnerCompteGoogle() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {/* aucune session Google active */}
    try {
      return await _googleSignIn.signIn();
    } catch (e) {
      if (_estAnnulationGoogle(e)) return null;
      throw AuthException(
          'Impossible d\'ouvrir la sélection de compte Google. Vérifiez votre connexion.');
    }
  }

  /// Inscription avec un compte Google RÉEL (adresse vérifiée par Google).
  ///
  /// 1. Authentifie le compte Google auprès de Firebase.
  /// 2. Refuse les comptes déjà existants (→ l'utilisateur doit se connecter).
  /// 3. Lie un mot de passe au compte : la connexion email + mot de passe
  ///    fonctionne ensuite exactement comme pour les anciens comptes.
  /// 4. Réserve atomiquement le numéro de téléphone (`index_telephones`).
  ///
  /// En cas d'échec après création, le compte est supprimé (pas de compte
  /// fantôme). Lève une [AuthException] au message prêt à afficher.
  Future<UserCredential> inscriptionAvecCompteGoogle({
    required GoogleSignInAccount compteGoogle,
    required String motDePasse,
    required String telephone,
  }) async {
    final email = compteGoogle.email.trim().toLowerCase();
    final cleTel = _normaliserTelephone(telephone);

    // 0. Garde-fou : une adresse déjà inscrite par mot de passe ne doit pas
    //    être « reprise » par Google (Firebase retirerait le mot de passe).
    //    Best-effort : renvoie une liste vide si la protection anti-énumération
    //    est active ; les contrôles 2 et 3 prennent alors le relais.
    try {
      // ignore: deprecated_member_use
      final methodes = await _auth.fetchSignInMethodsForEmail(email);
      if (methodes.isNotEmpty) {
        await deconnexionGoogle();
        throw AuthException(_messageCompteExistant);
      }
    } on AuthException {
      rethrow;
    } catch (_) {/* vérification indisponible : on continue */}

    // 1. Authentification Firebase avec le jeton Google.
    late final UserCredential cred;
    try {
      final googleAuth = await compteGoogle.authentication;
      cred = await _auth.signInWithCredential(GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      ));
    } on FirebaseAuthException catch (e) {
      await deconnexionGoogle();
      throw AuthException(_messageErreurAuth(e));
    }

    final user = cred.user;
    if (user == null) {
      throw AuthException('Échec de la vérification du compte Google.');
    }

    // 2. Compte déjà connu de Firebase → ne rien modifier, inviter à se connecter.
    if (!(cred.additionalUserInfo?.isNewUser ?? false)) {
      await _auth.signOut();
      await deconnexionGoogle();
      throw AuthException(_messageCompteExistant);
    }

    // 3. Double sécurité : adresse vérifiée par Google + pas de profil métier
    //    existant avec cette adresse (anciens comptes).
    if (!user.emailVerified || (user.email ?? '').isEmpty) {
      await _annulerCompte(user);
      throw AuthException('Ce compte Google n\'a pas d\'adresse vérifiée.');
    }
    if (await _emailDejaLieAUnProfil(email)) {
      await _annulerCompte(user);
      throw AuthException(_messageCompteExistant);
    }

    // 4. Liaison du mot de passe (connexion email/mot de passe possible).
    try {
      await user.linkWithCredential(
        EmailAuthProvider.credential(email: user.email!, password: motDePasse),
      );
    } on FirebaseAuthException catch (e) {
      if (e.code != 'provider-already-linked') {
        await _annulerCompte(user);
        throw AuthException(_messageErreurAuth(e));
      }
    }

    // 5. Réservation atomique du téléphone.
    await _reserverTelephone(cred, cleTel);

    return cred;
  }

  static const String _messageCompteExistant =
      'Cette adresse est déjà inscrite sur CamTrans. '
      'Connectez-vous depuis l\'écran de connexion.';

  /// Vérifie qu'aucun profil client/transporteur n'utilise déjà cet email.
  Future<bool> _emailDejaLieAUnProfil(String email) async {
    final db = FirebaseFirestore.instance;
    try {
      for (final collection in const ['clients', 'transporteurs']) {
        final snap = await db
            .collection(collection)
            .where('email', isEqualTo: email)
            .limit(1)
            .get();
        if (snap.docs.isNotEmpty) return true;
      }
    } catch (_) {/* index injoignable : FirebaseAuth reste la référence */}
    return false;
  }

  /// Supprime un compte à peine créé et nettoie les sessions.
  Future<void> _annulerCompte(User user) async {
    try {
      await user.delete();
    } catch (_) {
      await _auth.signOut();
    }
    await deconnexionGoogle();
  }

  bool _estAnnulationGoogle(Object e) {
    final msg = e.toString().toLowerCase();
    return msg.contains('cancel') ||
        msg.contains('aborted') ||
        msg.contains('12501') ||
        msg.contains('sign_in_canceled');
  }

  /// Réservation atomique du téléphone (utilisateur authentifié requis).
  Future<void> _reserverTelephone(UserCredential cred, String cleTel) async {
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
        } catch (_) {/* erreur ignorée */}
        rethrow;
      } catch (e) {
        // Index momentanément injoignable : on ne bloque pas l'inscription
        // (l'email reste protégé par FirebaseAuth).
      }
    }
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
      case 'account-exists-with-different-credential':
      case 'credential-already-in-use':
        return _messageCompteExistant;
      case 'requires-recent-login':
        return 'Session expirée. Recommencez l\'inscription.';
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
    // 2. Se deconnecter (Firebase + session Google éventuelle)
    await _auth.signOut();
    await deconnexionGoogle();
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
  /// Firebase. Refuse la connexion si le compte n'existe pas encore.
  /// Retourne `null` si l'utilisateur annule (jamais de crash).
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

      // 4. Blocage strict : l'utilisateur doit d'abord s'inscrire
      //    via la page d'inscription (qui demande téléphone, etc.).
      final user = userCred.user;
      if (user != null && (userCred.additionalUserInfo?.isNewUser ?? false)) {
        // Vérifier si c'est un compte admin pré-configuré
        bool isAdmin = false;
        try {
          final adminDoc = await FirebaseFirestore.instance
              .collection('admin')
              .doc(user.uid)
              .get();
          if (adminDoc.exists) isAdmin = true;
        } catch (_) {
          // Erreur ignorée, n'est pas un admin
        }

        if (!isAdmin) {
          await _annulerCompte(user);
          throw AuthException(
              'Aucun compte n\'existe avec cette adresse Google. Veuillez d\'abord vous inscrire.');
        }
      }

      return userCred;
    } catch (e) {
      if (e is AuthException) rethrow;
      // Annulation côté natif (ex: retour arrière Android) → pas une erreur.
      if (_estAnnulationGoogle(e)) return null;
      rethrow;
    }
  }

  /// Déconnexion Google (nettoie aussi la session Google)
  Future<void> deconnexionGoogle() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {/* erreur ignorée */}
  }
}
