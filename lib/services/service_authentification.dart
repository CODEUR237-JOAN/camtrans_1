import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final serviceAuthentificationProvider = Provider<ServiceAuthentification>((ref) {
  return ServiceAuthentification();
});

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(serviceAuthentificationProvider).changementsAuthentification;
});

class ServiceAuthentification {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Utilisateur connecté
  User? get utilisateur => _auth.currentUser;

  /// Flux de connexion
  Stream<User?> get changementsAuthentification =>
      _auth.authStateChanges();

  /// Inscription
  Future<UserCredential> inscription({
    required String email,
    required String motDePasse,
  }) async {
    return await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: motDePasse,
    );
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
    if (_auth.currentUser != null &&
        !_auth.currentUser!.emailVerified) {
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
  bool get emailVerifie =>
      _auth.currentUser?.emailVerified ?? false;

  /// Modifier le mot de passe
  Future<void> modifierMotDePasse(
      String nouveauMotDePasse) async {
    await _auth.currentUser?.updatePassword(
      nouveauMotDePasse,
    );
  }

  /// Modifier l'email
  Future<void> modifierEmail(
      String nouvelEmail) async {
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
}
