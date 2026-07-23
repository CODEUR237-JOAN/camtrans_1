import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../coeur/constantes/couleurs.dart';
import '../../coeur/constantes/tailles.dart';
import '../../coeur/routes/routes.dart';
import '../../coeur/utilitaires/validateurs.dart';
import '../../coeur/widgets/bouton_principal.dart';
import '../../coeur/widgets/champ_texte.dart';

import '../../services/service_authentification.dart';
import '../../services/service_firestore.dart';
import '../../modeles/transporteur.dart';
import '../../coeur/utilitaires/parseur.dart';

class InscriptionTransporteur extends ConsumerStatefulWidget {
  const InscriptionTransporteur({super.key});

  @override
  ConsumerState<InscriptionTransporteur> createState() => _InscriptionTransporteurState();
}

class _InscriptionTransporteurState extends ConsumerState<InscriptionTransporteur> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nom = TextEditingController();
  final TextEditingController _telephone = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _ville = TextEditingController();
  final TextEditingController _numeroPermis = TextEditingController();
  final TextEditingController _immatriculation = TextEditingController();
  final TextEditingController _capacite = TextEditingController();
  final TextEditingController _motDePasse = TextEditingController();
  final TextEditingController _confirmation = TextEditingController();

  bool _chargement = false;
  bool _conditions = false;

  String? _vehicule;

  final List<String> _vehicules = [
    "Moto",
    "Tricycle",
    "Pick-up",
    "Camionnette",
    "Camion léger",
    "Camion moyen",
    "Semi-remorque",
    "Camion Benne",
    "Camion Plateau",
    "Camion Citerne",
    "Conteneur"
  ];

  Future<void> _inscription() async {
    if (!_formKey.currentState!.validate()) return;

    if (_vehicule == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Veuillez choisir un type de véhicule.")),
      );
      return;
    }

    if (!_conditions) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Veuillez accepter les conditions d'utilisation.")),
      );
      return;
    }

    setState(() {
      _chargement = true;
    });

    try {
      final serviceAuth = ref.read(serviceAuthentificationProvider);
      final serviceDb = ref.read(serviceFirestoreProvider);

      // Inscription Firebase Auth
      final userCred = await serviceAuth.inscription(
        email: _email.text,
        motDePasse: _motDePasse.text,
      );

      // Création du document Transporteur
      if (userCred.user != null) {
        final transporteur = Transporteur(
          id: userCred.user!.uid,
          nom: _nom.text.trim(),
          prenom: "", 
          email: _email.text.trim(),
          telephone: _telephone.text.trim(),
          photo: "",
          adresse: "", 
          ville: _ville.text.trim(),
          role: "transporteur",
          actif: true,
          emailVerifie: false,
          dateCreation: DateTime.now(),
          typeVehicule: _vehicule ?? "",
          immatriculation: _immatriculation.text.trim(),
          capaciteM3: Parseur.toDouble(_capacite.text.trim()),
          numeroPermis: _numeroPermis.text.trim(),
        );

        // Sauvegarder dans la collection "transporteurs"
        await serviceDb.ajouterDocument(
          collection: "transporteurs",
          id: transporteur.id,
          donnees: transporteur.toMap(),
        );

        // Envoyer l'email de vérification
        await serviceAuth.envoyerVerificationEmail();
      }

      if (!mounted) return;
      context.go(RoutesApplication.tableauBordTransporteur);

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
    _numeroPermis.dispose();
    _immatriculation.dispose();
    _capacite.dispose();
    _motDePasse.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CouleursApp.fond,
      appBar: AppBar(
        title: const Text("Inscription Transporteur", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: CouleursApp.fond,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(TaillesApp.margePage),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const SizedBox(height: 10),

                // Titre
                const Text(
                  "Devenez Transporteur",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.2, end: 0),
                
                const SizedBox(height: 30),

                // Informations personnelles
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
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text("Informations Personnelles", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: CouleursApp.primaire)),
                      ).animate().fadeIn(delay: 200.ms),
                      const SizedBox(height: 15),

                      ChampTexte(
                        controleur: _nom,
                        libelle: "Nom complet",
                        icone: Icons.person_outline,
                        validateur: Validateurs.nom,
                      ).animate().fadeIn(delay: 300.ms).slideX(begin: -0.1),

                      const SizedBox(height: 15),

                      ChampTexte(
                        controleur: _telephone,
                        libelle: "Téléphone",
                        icone: Icons.phone_outlined,
                        typeClavier: TextInputType.phone,
                        validateur: Validateurs.telephone,
                      ).animate().fadeIn(delay: 400.ms).slideX(begin: -0.1),

                      const SizedBox(height: 15),

                      ChampTexte(
                        controleur: _email,
                        libelle: "Adresse e-mail",
                        icone: Icons.email_outlined,
                        typeClavier: TextInputType.emailAddress,
                        validateur: Validateurs.email,
                      ).animate().fadeIn(delay: 500.ms).slideX(begin: -0.1),

                      const SizedBox(height: 15),

                      ChampTexte(
                        controleur: _ville,
                        libelle: "Ville",
                        icone: Icons.location_city_outlined,
                        validateur: (v) => Validateurs.obligatoire(v, nomChamp: "Ville"),
                      ).animate().fadeIn(delay: 600.ms).slideX(begin: -0.1),
                    ],
                  ),
                ),

                const SizedBox(height: 25),

                // Informations professionnelles
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
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text("Informations Professionnelles", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: CouleursApp.primaire)),
                      ).animate().fadeIn(delay: 700.ms),
                      const SizedBox(height: 15),

                      DropdownButtonFormField<String>(
                        initialValue: _vehicule,
                        decoration: InputDecoration(
                          labelText: "Type de véhicule",
                          prefixIcon: const Icon(Icons.local_shipping_outlined),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                        ),
                        items: _vehicules.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                        onChanged: (v) {
                          setState(() {
                            _vehicule = v;
                          });
                        },
                      ).animate().fadeIn(delay: 800.ms).slideX(begin: -0.1),

                      const SizedBox(height: 15),

                      ChampTexte(
                        controleur: _immatriculation,
                        libelle: "Immatriculation",
                        icone: Icons.directions_car_outlined,
                        validateur: (v) => Validateurs.obligatoire(v, nomChamp: "Immatriculation"),
                      ).animate().fadeIn(delay: 900.ms).slideX(begin: -0.1),

                      const SizedBox(height: 15),

                      ChampTexte(
                        controleur: _numeroPermis,
                        libelle: "Numéro de permis",
                        icone: Icons.badge_outlined,
                        validateur: (v) => Validateurs.obligatoire(v, nomChamp: "Permis"),
                      ).animate().fadeIn(delay: 1000.ms).slideX(begin: -0.1),

                      const SizedBox(height: 15),

                      ChampTexte(
                        controleur: _capacite,
                        libelle: "Capacité (Tonnes)",
                        icone: Icons.scale_outlined,
                        typeClavier: const TextInputType.numberWithOptions(decimal: true),
                        validateur: Validateurs.poids,
                      ).animate().fadeIn(delay: 1100.ms).slideX(begin: -0.1),
                    ],
                  ),
                ),

                const SizedBox(height: 25),
                
                // Documents
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: CouleursApp.primaire.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: CouleursApp.primaire.withValues(alpha: 0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Documents requis (à télécharger plus tard)",
                        style: TextStyle(fontWeight: FontWeight.bold, color: CouleursApp.primaire),
                      ),
                      const SizedBox(height: 12),
                      _docItem(Icons.badge, "Photo du permis de conduire"),
                      _docItem(Icons.description, "Carte grise du véhicule"),
                      _docItem(Icons.shield, "Attestation d'assurance"),
                      _docItem(Icons.photo_camera, "Photos du véhicule (Int/Ext)"),
                    ],
                  ),
                ).animate().fadeIn(delay: 1200.ms),

                const SizedBox(height: 25),

                // Sécurité
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
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text("Sécurité", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: CouleursApp.primaire)),
                      ).animate().fadeIn(delay: 1300.ms),
                      const SizedBox(height: 15),

                      ChampTexte(
                        controleur: _motDePasse,
                        libelle: "Mot de passe",
                        icone: Icons.lock_outline,
                        estMotDePasse: true,
                        validateur: Validateurs.motDePasse,
                      ).animate().fadeIn(delay: 1400.ms).slideX(begin: -0.1),

                      const SizedBox(height: 15),

                      ChampTexte(
                        controleur: _confirmation,
                        libelle: "Confirmer le mot de passe",
                        icone: Icons.lock_outline,
                        estMotDePasse: true,
                        validateur: (v) => Validateurs.confirmerMotDePasse(v, _motDePasse.text),
                      ).animate().fadeIn(delay: 1500.ms).slideX(begin: -0.1),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                CheckboxListTile(
                  value: _conditions,
                  onChanged: (v) {
                    setState(() {
                      _conditions = v ?? false;
                    });
                  },
                  activeColor: CouleursApp.primaire,
                  title: const Text(
                    "J'accepte les conditions d'utilisation et la politique de confidentialité.",
                    style: TextStyle(fontSize: 14),
                  ),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                ).animate().fadeIn(delay: 1600.ms),

                const SizedBox(height: 25),

                BoutonPrincipal(
                  texte: "Créer mon compte",
                  icone: Icons.local_shipping,
                  chargement: _chargement,
                  auClic: _inscription,
                ).animate().fadeIn(delay: 1700.ms).scale(begin: const Offset(0.9, 0.9)),

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
                ).animate().fadeIn(delay: 1800.ms),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _docItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: CouleursApp.texteSecondaire),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: const TextStyle(color: CouleursApp.texteSecondaire, fontSize: 13))),
        ],
      ),
    );
  }
}