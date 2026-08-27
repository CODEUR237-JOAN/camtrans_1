import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:update_camtrans/coeur/constantes/couleurs.dart';
import 'package:update_camtrans/coeur/constantes/tailles.dart';
import 'package:update_camtrans/coeur/constantes/textes.dart';
import 'package:update_camtrans/coeur/routes/routes.dart';
import 'package:update_camtrans/coeur/utilitaires/validateurs.dart';
import 'package:update_camtrans/coeur/widgets/bouton_principal.dart';
import 'package:update_camtrans/coeur/widgets/champ_texte.dart';
import 'package:update_camtrans/coeur/widgets/page_responsive.dart';

import 'package:update_camtrans/services/service_authentification.dart';
import 'package:update_camtrans/services/service_firestore.dart';
import 'package:update_camtrans/services/service_notification.dart';
import 'package:update_camtrans/modeles/client.dart';

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
      debugPrint("--- DÉBUT DE L'INSCRIPTION ---");
      final serviceAuth = ref.read(serviceAuthentificationProvider);
      final serviceDb = ref.read(serviceFirestoreProvider);

      debugPrint("1. Appel de Firebase Auth...");
      // Inscription Firebase Auth avec Timeout
      final userCred = await serviceAuth.inscription(
        email: _email.text,
        motDePasse: _motDePasse.text,
      ).timeout(const Duration(seconds: 15), onTimeout: () {
        throw Exception("Délai d'attente dépassé pour l'authentification (Problème de connexion internet ou serveur Firebase injoignable).");
      });

      debugPrint("2. Auth réussie. UID: ${userCred.user?.uid}");

      // Création du document Client
      if (userCred.user != null) {
        final nomComplet = _nom.text.trim().split(' ');
        final prenom = nomComplet.length > 1 ? nomComplet.sublist(0, nomComplet.length - 1).join(' ') : "";
        final nom = nomComplet.last;

        final client = Client(
          id: userCred.user!.uid,
          nom: nom,
          prenom: prenom, 
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

        debugPrint("3. Enregistrement dans Firestore...");
        // Sauvegarder dans la collection "clients" avec Timeout
        await serviceDb.ajouterDocument(
          collection: "clients",
          id: client.id,
          donnees: client.toMap(),
        ).timeout(const Duration(seconds: 10), onTimeout: () {
          throw Exception("Délai d'attente dépassé pour la base de données (Firestore injoignable).");
        });

        debugPrint("4. Enregistrement du Token FCM...");
        await ServiceNotification.enregistrerTokenUtilisateur(client.id, 'client');

        debugPrint("5. Mise à jour du profil Auth...");
        await serviceAuth.mettreAJourProfil(nom: _nom.text.trim());

        debugPrint("6. Envoi de l'email de vérification...");
        // Envoyer l'email de vérification
        await serviceAuth.envoyerVerificationEmail().timeout(const Duration(seconds: 10), onTimeout: () {
           debugPrint("Attention: L'envoi de l'e-mail a pris trop de temps, mais le compte est créé.");
        });
        debugPrint("--- FIN DE L'INSCRIPTION ---");
      }

      await serviceAuth.deconnexion();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Inscription réussie. Veuillez vous connecter pour accéder à votre tableau de bord."),
          backgroundColor: Colors.green,
        ),
      );
      context.go(RoutesApplication.connexion);

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

  void _afficherConditions(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Conditions d'utilisation et Politique de confidentialité"),
        content: const SingleChildScrollView(
          child: Text(
            "Bienvenue sur la plateforme CamTrans.\n\n"
            "1. Utilisation du service\n"
            "En utilisant notre plateforme, vous vous engagez à respecter les lois en vigueur et à ne pas utiliser nos services à des fins illégales.\n\n"
            "2. Données personnelles et Confidentialité\n"
            "Nous collectons et traitons vos données personnelles (nom, téléphone, adresse, position géographique) uniquement pour assurer la prestation de transport. "
            "Vos données ne sont pas vendues à des tiers.\n\n"
            "3. Paiements et Facturation\n"
            "Les tarifs affichés sont des estimations. Le montant final peut varier en fonction des conditions réelles du trajet.\n\n"
            "4. Responsabilité\n"
            "CamTrans agit en tant qu'intermédiaire entre le client et le transporteur. Nous ne saurions être tenus responsables des retards ou des dommages causés pendant le transport.\n\n"
            "(Ces conditions sont données à titre indicatif et doivent être complétées par vos conditions légales.)"
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Fermer"),
          ),
        ],
      ),
    );
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
        child: PageResponsive(
          child: SingleChildScrollView(
          padding: EdgeInsets.all(TaillesApp.margePage),
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
                ),
                
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
                      ),

                      const SizedBox(height: 16),

                      ChampTexte(
                        controleur: _telephone,
                        libelle: TextesApp.telephone,
                        icone: Icons.phone_outlined,
                        typeClavier: TextInputType.phone,
                        validateur: Validateurs.telephone,
                      ),

                      const SizedBox(height: 16),

                      ChampTexte(
                        controleur: _email,
                        libelle: TextesApp.adresseEmail,
                        icone: Icons.email_outlined,
                        typeClavier: TextInputType.emailAddress,
                        validateur: Validateurs.email,
                      ),

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
                      ),

                      const SizedBox(height: 16),

                      ChampTexte(
                        controleur: _adresse,
                        libelle: TextesApp.adresse,
                        icone: Icons.home_outlined,
                        lignesMax: 2,
                        validateur: (valeur) => Validateurs.obligatoire(valeur, nomChamp: "L'adresse"),
                      ),
                      
                      const SizedBox(height: 16),

                      ChampTexte(
                        controleur: _motDePasse,
                        libelle: TextesApp.motDePasse,
                        icone: Icons.lock_outline,
                        estMotDePasse: true,
                        validateur: Validateurs.motDePasse,
                      ),

                      const SizedBox(height: 16),

                      ChampTexte(
                        controleur: _confirmation,
                        libelle: TextesApp.confirmerMotDePasse,
                        icone: Icons.lock_outline,
                        estMotDePasse: true,
                        validateur: (valeur) => Validateurs.confirmerMotDePasse(valeur, _motDePasse.text),
                      ),
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
                  title: RichText(
                    text: TextSpan(
                      text: "J'accepte les ",
                      style: TextStyle(fontSize: 14, color: Theme.of(context).textTheme.bodyMedium?.color),
                      children: [
                        TextSpan(
                          text: "conditions d'utilisation et la politique de confidentialité",
                          style: TextStyle(
                            fontSize: 14,
                            color: CouleursApp.primaire,
                            decoration: TextDecoration.underline,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () {
                              _afficherConditions(context);
                            },
                        ),
                        const TextSpan(text: "."),
                      ],
                    ),
                  ),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                ),

                const SizedBox(height: 25),

                BoutonPrincipal(
                  texte: "Créer mon compte",
                  icone: Icons.person_add,
                  chargement: _chargement,
                  auClic: _creerCompte,
                ),

                const SizedBox(height: 20),

                Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    const Text("Vous avez déjà un compte ?", style: TextStyle(color: CouleursApp.texteSecondaire)),
                    TextButton(
                      onPressed: () {
                        context.pop();
                      },
                      child: const Text("Se connecter", style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                
                const SizedBox(height: 30),
              ],
            ),
            ),
          ),
        ),
      ),
    );
  }
}