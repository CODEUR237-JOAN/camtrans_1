import 'package:local_auth/local_auth.dart';

// =====================================================================
// SERVICE : Authentification biométrique (empreinte / Face ID)
//
// Encapsule le package natif local_auth. Robuste : toutes les méthodes
// renvoient un résultat sûr en cas d'erreur (jamais d'exception propagée),
// pour ne jamais bloquer l'application.
// =====================================================================
class ServiceBiometrie {
  final LocalAuthentication _auth = LocalAuthentication();

  /// true si l'appareil supporte ET a configuré une biométrie (ou un code).
  Future<bool> disponible() async {
    try {
      final supporte = await _auth.isDeviceSupported();
      final peutVerifier = await _auth.canCheckBiometrics;
      return supporte && peutVerifier;
    } catch (e) {
      return false;
    }
  }

  /// Lance l'invite biométrique. Retourne true si l'identité est confirmée.
  /// `biometricOnly: false` autorise le code/schéma de l'appareil en repli
  /// (évite de bloquer l'utilisateur si le capteur est momentanément indispo).
  Future<bool> authentifier(String raison) async {
    try {
      return await _auth.authenticate(
        localizedReason: raison,
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
          useErrorDialogs: true,
        ),
      );
    } catch (e) {
      return false;
    }
  }
}
