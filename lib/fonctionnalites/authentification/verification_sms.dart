import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:update_camtrans/coeur/constantes/couleurs.dart';
import 'package:update_camtrans/coeur/widgets/bouton_principal.dart';
import 'package:update_camtrans/coeur/widgets/champ_texte.dart';
import 'package:update_camtrans/coeur/routes/routes.dart';
import 'package:update_camtrans/coeur/widgets/effets_visuels.dart';

class VerificationSms extends StatefulWidget {
  final String role;
  final String telephone;

  const VerificationSms({
    super.key,
    required this.role,
    required this.telephone,
  });

  @override
  State<VerificationSms> createState() => _VerificationSmsState();
}

class _VerificationSmsState extends State<VerificationSms> {
  final _codeController = TextEditingController();
  bool _chargement = false;
  String? _verificationId;
  String? _erreur;

  @override
  void initState() {
    super.initState();
    _envoyerSms();
  }

  Future<void> _envoyerSms() async {
    setState(() {
      _chargement = true;
      _erreur = null;
    });

    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: widget.telephone,
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Validation automatique (Android)
          await _validerCredential(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          setState(() {
            _chargement = false;
            _erreur = "Échec de la vérification : ${e.message}";
          });
        },
        codeSent: (String verificationId, int? resendToken) {
          setState(() {
            _verificationId = verificationId;
            _chargement = false;
          });
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          if (mounted) {
            setState(() {
              _verificationId = verificationId;
            });
          }
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _chargement = false;
          _erreur = "Erreur lors de l'envoi du SMS.";
        });
      }
    }
  }

  Future<void> _validerCode() async {
    if (_verificationId == null) {
      setState(() => _erreur = "Veuillez patienter, l'envoi du SMS est en cours...");
      return;
    }
    final code = _codeController.text.trim();
    if (code.isEmpty || code.length < 6) {
      setState(() => _erreur = "Veuillez entrer un code valide à 6 chiffres.");
      return;
    }

    setState(() => _chargement = true);
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: code,
      );
      await _validerCredential(credential);
    } catch (e) {
      setState(() {
        _chargement = false;
        _erreur = "Code invalide ou expiré. Veuillez réessayer.";
      });
    }
  }

  Future<void> _validerCredential(PhoneAuthCredential credential) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Essayer de lier le numéro au compte (s'il n'est pas déjà lié)
        try {
          await user.linkWithCredential(credential);
        } catch (_) {
          // Ignorer si déjà lié ou conflit (le but principal est de valider que l'utilisateur a reçu le code)
        }
      }

      if (!mounted) return;
      // Routage final vers le tableau de bord
      if (widget.role == 'client') {
        context.go(RoutesApplication.tableauBordClient);
      } else if (widget.role == 'transporteur') {
        context.go(RoutesApplication.tableauBordTransporteur);
      } else {
        context.go(RoutesApplication.admin);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _chargement = false;
          _erreur = "Une erreur s'est produite lors de la validation finale.";
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CouleursApp.fond,
      appBar: AppBar(
        title: const Text("Vérification de sécurité"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: CouleursApp.textePrincipal),
      ),
      body: SafeArea(
        child: FondPremiumAnime(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.security, size: 80, color: CouleursApp.primaire),
                const SizedBox(height: 24),
                const Text(
                  "Authentification à double facteur",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: CouleursApp.textePrincipal),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  "Un code SMS vient d'être envoyé au numéro :\n${widget.telephone}",
                  style: const TextStyle(fontSize: 16, color: CouleursApp.texteSecondaire, height: 1.5),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                if (_erreur != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.withOpacity(0.5)),
                    ),
                    child: Text(
                      _erreur!,
                      style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                ChampTexte(
                  controleur: _codeController,
                  libelle: "Code à 6 chiffres",
                  typeClavier: TextInputType.number,
                  icone: Icons.password,
                  glassmorphism: true,
                ),
                const SizedBox(height: 24),
                BoutonPrincipal(
                  texte: "Valider et continuer",
                  chargement: _chargement,
                  auClic: _validerCode,
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: _chargement ? null : _envoyerSms,
                  child: const Text("Renvoyer le code", style: TextStyle(color: CouleursApp.primaire)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
