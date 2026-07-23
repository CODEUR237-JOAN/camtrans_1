import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../coeur/constantes/couleurs.dart';
import '../../coeur/constantes/tailles.dart';
import '../../coeur/constantes/textes.dart';
import '../../coeur/routes/routes.dart';
import '../../coeur/utilitaires/validateurs.dart';
import '../../coeur/widgets/bouton_principal.dart';
import '../../coeur/widgets/champ_texte.dart';

import '../../services/service_authentification.dart';
import '../../services/service_firestore.dart';

class Connexion extends ConsumerStatefulWidget {
  const Connexion({super.key});

  @override
  ConsumerState<Connexion> createState() => _ConnexionState();
}

class _ConnexionState extends ConsumerState<Connexion> {
  final _cleFormulaire = GlobalKey<FormState>();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _motDePasse = TextEditingController();
  bool _chargement = false;

  void _connexion() async {
    if (!_cleFormulaire.currentState!.validate()) return;

    setState(() {
      _chargement = true;
    });

    try {
      final serviceAuth = ref.read(serviceAuthentificationProvider);
      final serviceDb = ref.read(serviceFirestoreProvider);

      final userCred = await serviceAuth.connexion(
        email: _email.text,
        motDePasse: _motDePasse.text,
      );

      if (!mounted) return;

      if (userCred.user != null) {
        // Déterminer si c'est un client ou un transporteur
        final docClient = await serviceDb.lireDocument(
          collection: 'clients', 
          id: userCred.user!.uid
        );

        if (!mounted) return;

        if (docClient.exists) {
          context.go(RoutesApplication.tableauBordClient);
        } else {
          // Si ce n'est pas un client, on suppose que c'est un transporteur
          context.go(RoutesApplication.tableauBordTransporteur);
        }
      }

    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Oups, la connexion a échoué. Vérifiez vos identifiants !"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _chargement = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _email.dispose();
    _motDePasse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CouleursApp.fond,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: TaillesApp.margePage),
            child: Form(
              key: _cleFormulaire,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),

                  // Logo
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: CouleursApp.primaire.withValues(alpha: 0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.local_shipping,
                      size: 60,
                      color: CouleursApp.primaire,
                    ),
                  ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack).fadeIn(),

                  const SizedBox(height: 30),

                  // Titre
                  const Text(
                    TextesApp.bienvenue,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: CouleursApp.textePrincipal,
                      letterSpacing: -0.5,
                    ),
                  ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.3, end: 0),

                  const SizedBox(height: 8),

                  const Text(
                    "Connectez-vous pour continuer",
                    style: TextStyle(
                      color: CouleursApp.texteSecondaire,
                      fontSize: 16,
                    ),
                  ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.3, end: 0),

                  const SizedBox(height: 40),

                  // Formulaire (Glassmorphism look)
                  Container(
                    padding: const EdgeInsets.all(25),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        ChampTexte(
                          controleur: _email,
                          libelle: TextesApp.adresseEmail,
                          icone: Icons.email_outlined,
                          typeClavier: TextInputType.emailAddress,
                          validateur: Validateurs.email,
                        ).animate().fadeIn(delay: 400.ms).slideX(begin: 0.1, end: 0),

                        const SizedBox(height: 20),

                        ChampTexte(
                          controleur: _motDePasse,
                          libelle: TextesApp.motDePasse,
                          icone: Icons.lock_outline,
                          estMotDePasse: true,
                          validateur: Validateurs.motDePasse,
                        ).animate().fadeIn(delay: 500.ms).slideX(begin: 0.1, end: 0),

                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () => context.push(RoutesApplication.motDePasseOublie),
                            child: const Text(
                              TextesApp.motDePasseOublie,
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ).animate().fadeIn(delay: 600.ms),

                        const SizedBox(height: 15),

                        BoutonPrincipal(
                          texte: TextesApp.connexion,
                          icone: Icons.login,
                          chargement: _chargement,
                          auClic: _connexion,
                        ).animate().fadeIn(delay: 700.ms).scale(begin: const Offset(0.9, 0.9)),
                      ],
                    ),
                  ),

                  const SizedBox(height: 25),

                  // Pas de compte ?
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Vous n'avez pas de compte ?", style: TextStyle(color: CouleursApp.texteSecondaire)),
                      TextButton(
                        onPressed: () => context.push(RoutesApplication.choixProfil),
                        child: const Text("S'inscrire", style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ).animate().fadeIn(delay: 800.ms),

                  const SizedBox(height: 20),
                  
                  // Connexion rapide
                  Row(
                    children: [
                      Expanded(child: Divider(color: Colors.grey.shade300)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Text("Ou avec", style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
                      ),
                      Expanded(child: Divider(color: Colors.grey.shade300)),
                    ],
                  ).animate().fadeIn(delay: 900.ms),

                  const SizedBox(height: 20),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _boutonSocial(Icons.g_mobiledata, Colors.red, Colors.red.shade50),
                      const SizedBox(width: 20),
                      _boutonSocial(Icons.facebook, Colors.blue, Colors.blue.shade50),
                      const SizedBox(width: 20),
                      _boutonSocial(Icons.apple, Colors.black, Colors.black12),
                    ],
                  ).animate().fadeIn(delay: 1000.ms).slideY(begin: 0.2, end: 0),

                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _boutonSocial(IconData icone, Color couleur, Color fond) {
    return Container(
      decoration: BoxDecoration(
        color: fond,
        shape: BoxShape.circle,
      ),
      child: IconButton(
        iconSize: 32,
        padding: const EdgeInsets.all(12),
        onPressed: () {},
        icon: Icon(icone, color: couleur),
      ),
    );
  }
}