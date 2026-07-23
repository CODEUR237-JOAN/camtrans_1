import 'package:flutter/material.dart';

import '../../coeur/constantes/couleurs.dart';
import '../../coeur/constantes/tailles.dart';
import '../../coeur/routes/routes.dart';
import '../../coeur/utilitaires/validateurs.dart';
import '../../coeur/widgets/bouton_principal.dart';
import '../../coeur/widgets/champ_texte.dart';

class MotDePasseOublie extends StatefulWidget {
  const MotDePasseOublie({super.key});

  @override
  State<MotDePasseOublie> createState() =>
      _MotDePasseOublieState();
}

class _MotDePasseOublieState
    extends State<MotDePasseOublie> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _email =
  TextEditingController();

  bool _chargement = false;

  Future<void> _envoyerLien() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _chargement = true;
    });

    await Future.delayed(
      const Duration(seconds: 2),
    );

    if (!mounted) return;

    setState(() {
      _chargement = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          "Le lien de réinitialisation a été envoyé à votre adresse e-mail.",
        ),
      ),
    );

    Navigator.pushReplacementNamed(
      context,
      RoutesApplication.connexion,
    );
  }

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CouleursApp.fond,
      appBar: AppBar(
        title: const Text(
          "Mot de passe oublié",
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(
            TaillesApp.margePage,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const SizedBox(height: 20),

                const Icon(
                  Icons.local_shipping,
                  size: 120,
                  color: CouleursApp.primaire,
                ),

                const SizedBox(height: 30),

                const Icon(
                  Icons.lock_reset,
                  size: 90,
                  color: CouleursApp.primaire,
                ),

                const SizedBox(height: 25),

                const Text(
                  "Réinitialisation du mot de passe",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 15),

                const Text(
                  "Saisissez votre adresse e-mail. Nous vous enverrons un lien permettant de créer un nouveau mot de passe.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: CouleursApp.texteSecondaire,
                    height: 1.5,
                  ),
                ),

                const SizedBox(height: 35),

                ChampTexte(
                  controleur: _email,
                  libelle: "Adresse e-mail",
                  icone: Icons.email_outlined,
                  typeClavier:
                  TextInputType.emailAddress,
                  validateur: Validateurs.email,
                ),

                const SizedBox(height: 35),

                BoutonPrincipal(
                  texte: "Envoyer le lien",
                  icone: Icons.send,
                  chargement: _chargement,
                  auClic: _envoyerLien,
                ),

                const SizedBox(height: 20),

                TextButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  icon: const Icon(
                    Icons.arrow_back,
                  ),
                  label: const Text(
                    "Retour à la connexion",
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}