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
import '../../modeles/client.dart';

class InscriptionClient extends ConsumerStatefulWidget {
  const InscriptionClient({super.key});

  @override
  ConsumerState<InscriptionClient> createState() => _InscriptionClientState();
}

class _InscriptionClientState extends ConsumerState<InscriptionClient> {
  final _cleFormulaire = GlobalKey<FormState>();
  final TextEditingController _nom = TextEditingController();
  final TextEditingController _telephone = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _ville = TextEditingController();
  final TextEditingController _adresse = TextEditingController();
  final TextEditingController _motDePasse = TextEditingController();
  final TextEditingController _confirmation = TextEditingController();
  bool _conditionsAcceptees = false;
  bool _chargement = false;

  void _creerCompte() async {
    if (!_cleFormulaire.currentState!.validate()) return;
    if (!_conditionsAcceptees) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Veuillez accepter les conditions d'utilisation.")),
      );
      return;
    }
    setState(() {
      _chargement = true;
    });

    try {
      print("--- DÉBUT DE L'INSCRIPTION ---");
      final serviceAuth = ref.read(serviceAuthentificationProvider);
      final serviceDb = ref.read(serviceFirestoreProvider);

      print("1. Appel de Firebase Auth...");
      // Inscription Firebase Auth avec Timeout
      final userCred = await serviceAuth.inscription(
        email: _email.text,
        motDePasse: _motDePasse.text,
      ).timeout(const Duration(seconds: 15), onTimeout: () {
        throw Exception("Délai d'attente dépassé pour l'authentification (Problème de connexion internet ou serveur Firebase injoignable).");
      });

      print("2. Auth réussie. UID: ${userCred.user?.uid}");

      // Création du document Client
      if (userCred.user != null) {
        final client = Client(
          id: userCred.user!.uid,
          nom: _nom.text.trim(),
          prenom: "", 
          email: _email.text.trim(),
          telephone: _telephone.text.trim(),
          photo: "",
          adresse: _adresse.text.trim(),
          ville: _ville.text.trim(),
          role: "client",
          actif: true,
          emailVerifie: false,
          dateCreation: DateTime.now(),
        );

        print("3. Enregistrement dans Firestore...");
        // Sauvegarder dans la collection "clients" avec Timeout
        await serviceDb.ajouterDocument(
          collection: "clients",
          id: client.id,
          donnees: client.toMap(),
        ).timeout(const Duration(seconds: 10), onTimeout: () {
          throw Exception("Délai d'attente dépassé pour la base de données (Firestore injoignable).");
        });

        print("4. Envoi de l'email de vérification...");
        // Envoyer l'email de vérification
        await serviceAuth.envoyerVerificationEmail().timeout(const Duration(seconds: 10), onTimeout: () {
           print("Attention: L'envoi de l'e-mail a pris trop de temps, mais le compte est créé.");
        });
        print("--- FIN DE L'INSCRIPTION ---");
      }

      if (!mounted) return;
      context.go(RoutesApplication.tableauBordClient);

    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Erreur lors de l'inscription : ${e.toString().replaceAll('Exception:', '')}"),
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
    _nom.dispose();
    _telephone.dispose();
    _email.dispose();
    _ville.dispose();
    _adresse.dispose();
    _motDePasse.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CouleursApp.fond,
      appBar: AppBar(
        title: const Text("Inscription Client", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: CouleursApp.fond,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(TaillesApp.margePage),
          child: Form(
            key: _cleFormulaire,
            child: Column(
              children: [
                const SizedBox(height: 10),

                // Titre
                const Text(
                  "Créer votre compte",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.2, end: 0),
                
                const SizedBox(height: 30),

                // Formulaire
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      )
                    ]
                  ),
                  child: Column(
                    children: [
                      ChampTexte(
                        controleur: _nom,
                        libelle: TextesApp.nomComplet,
                        icone: Icons.person_outline,
                        validateur: Validateurs.nom,
                      ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.1),

                      const SizedBox(height: 16),

                      ChampTexte(
                        controleur: _telephone,
                        libelle: TextesApp.telephone,
                        icone: Icons.phone_outlined,
                        typeClavier: TextInputType.phone,
                        validateur: Validateurs.telephone,
                      ).animate().fadeIn(delay: 300.ms).slideX(begin: -0.1),

                      const SizedBox(height: 16),

                      ChampTexte(
                        controleur: _email,
                        libelle: TextesApp.adresseEmail,
                        icone: Icons.email_outlined,
                        typeClavier: TextInputType.emailAddress,
                        validateur: Validateurs.email,
                      ).animate().fadeIn(delay: 400.ms).slideX(begin: -0.1),

                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Expanded(
                            child: ChampTexte(
                              controleur: _ville,
                              libelle: TextesApp.ville,
                              icone: Icons.location_city,
                              validateur: (valeur) => Validateurs.obligatoire(valeur, nomChamp: "La ville"),
                            ),
                          ),
                        ],
                      ).animate().fadeIn(delay: 500.ms).slideX(begin: -0.1),

                      const SizedBox(height: 16),

                      ChampTexte(
                        controleur: _adresse,
                        libelle: TextesApp.adresse,
                        icone: Icons.home_outlined,
                        lignesMax: 2,
                        validateur: (valeur) => Validateurs.obligatoire(valeur, nomChamp: "L'adresse"),
                      ).animate().fadeIn(delay: 600.ms).slideX(begin: -0.1),
                      
                      const SizedBox(height: 16),

                      ChampTexte(
                        controleur: _motDePasse,
                        libelle: TextesApp.motDePasse,
                        icone: Icons.lock_outline,
                        estMotDePasse: true,
                        validateur: Validateurs.motDePasse,
                      ).animate().fadeIn(delay: 700.ms).slideX(begin: -0.1),

                      const SizedBox(height: 16),

                      ChampTexte(
                        controleur: _confirmation,
                        libelle: TextesApp.confirmerMotDePasse,
                        icone: Icons.lock_outline,
                        estMotDePasse: true,
                        validateur: (valeur) => Validateurs.confirmerMotDePasse(valeur, _motDePasse.text),
                      ).animate().fadeIn(delay: 800.ms).slideX(begin: -0.1),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                CheckboxListTile(
                  value: _conditionsAcceptees,
                  activeColor: CouleursApp.primaire,
                  onChanged: (valeur) {
                    setState(() {
                      _conditionsAcceptees = valeur ?? false;
                    });
                  },
                  title: const Text(
                    "J'accepte les conditions d'utilisation et la politique de confidentialité.",
                    style: TextStyle(fontSize: 14),
                  ),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                ).animate().fadeIn(delay: 900.ms),

                const SizedBox(height: 25),

                BoutonPrincipal(
                  texte: "Créer mon compte",
                  icone: Icons.person_add,
                  chargement: _chargement,
                  auClic: _creerCompte,
                ).animate().fadeIn(delay: 1000.ms).scale(begin: const Offset(0.9, 0.9)),

                const SizedBox(height: 20),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Vous avez déjà un compte ?", style: TextStyle(color: CouleursApp.texteSecondaire)),
                    TextButton(
                      onPressed: () {
                        context.pop();
                      },
                      child: const Text("Se connecter", style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ).animate().fadeIn(delay: 1100.ms),
                
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}