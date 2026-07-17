import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../coeur/constantes/couleurs.dart';
import '../../coeur/constantes/images.dart';
import '../../coeur/constantes/tailles.dart';
import '../../coeur/routes/routes.dart';
import '../../coeur/widgets/bouton_principal.dart';

class VerificationEmail extends StatefulWidget {
  const VerificationEmail({super.key});

  @override
  State<VerificationEmail> createState() =>
      _VerificationEmailState();
}

class _VerificationEmailState
    extends State<VerificationEmail> {
  bool _chargement = false;

  Future<void> _continuer() async {
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

    context.go(RoutesApplication.connexion);
  }

  Future<void> _renvoyerEmail() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          "Un nouvel e-mail de vérification a été envoyé.",
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CouleursApp.fond,
      appBar: AppBar(
        title: const Text(
          "Vérification de l'adresse e-mail",
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(
            TaillesApp.margePage,
          ),
          child: Column(
            children: [
              const SizedBox(height: 30),

              const Icon(
                Icons.mark_email_read,
                size: 80,
                color: CouleursApp.primaire,
              ),

              const SizedBox(height: 30),

              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.mark_email_read,
                  size: 70,
                  color: Colors.green,
                ),
              ),

              const SizedBox(height: 30),

              const Text(
                "Vérifiez votre adresse e-mail",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 20),

              const Text(
                "Nous avons envoyé un e-mail de confirmation à votre adresse.\n\nCliquez sur le lien reçu afin d'activer votre compte avant de continuer.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: CouleursApp.texteSecondaire,
                  height: 1.6,
                ),
              ),

              const SizedBox(height: 40),

              BoutonPrincipal(
                texte:
                "J'ai vérifié mon adresse e-mail",
                icone: Icons.verified,
                chargement: _chargement,
                auClic: _continuer,
              ),

              const SizedBox(height: 20),

              OutlinedButton.icon(
                onPressed: _renvoyerEmail,
                icon: const Icon(Icons.refresh),
                label: const Text(
                  "Renvoyer l'e-mail",
                ),
                style: OutlinedButton.styleFrom(
                  minimumSize:
                  const Size(double.infinity, 55),
                ),
              ),

              const SizedBox(height: 20),

              TextButton.icon(
                onPressed: () {
                  context.go(RoutesApplication.connexion);
                },
                icon: const Icon(Icons.arrow_back),
                label: const Text(
                  "Retour à la connexion",
                ),
              ),

              const SizedBox(height: 40),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius:
                  BorderRadius.circular(15),
                  border: Border.all(
                    color: Colors.amber.shade300,
                  ),
                ),
                child: const Row(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.orange,
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        "Si vous ne trouvez pas l'e-mail, vérifiez le dossier Spam ou Courrier indésirable.",
                        style: TextStyle(
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}