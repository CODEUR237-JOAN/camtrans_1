import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import 'package:update_camtrans/coeur/constantes/couleurs.dart';
import 'package:update_camtrans/coeur/constantes/tailles.dart';
import 'package:update_camtrans/coeur/routes/routes.dart';
import 'package:update_camtrans/coeur/utilitaires/validateurs.dart';
import 'package:update_camtrans/coeur/widgets/bouton_principal.dart';
import 'package:update_camtrans/coeur/widgets/champ_texte.dart';
import 'package:update_camtrans/coeur/widgets/page_responsive.dart';

import 'package:update_camtrans/services/service_authentification.dart';
import 'package:update_camtrans/services/service_firestore.dart';
import 'package:update_camtrans/services/service_notification.dart';
import 'package:update_camtrans/services/service_stockage.dart';
import 'package:update_camtrans/modeles/transporteur.dart';
import 'package:update_camtrans/coeur/utilitaires/parseur.dart';
import 'package:update_camtrans/coeur/etat/textes_app_provider.dart';

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

  XFile? _photoPermis;
  XFile? _photoCarteGrise;
  XFile? _photoAssurance;
  
  XFile? _photoVehiculeAvant;
  XFile? _photoVehiculeArriere;
  XFile? _photoVehiculeProfil;
  XFile? _photoVehiculeInterieur;

  final ImagePicker _picker = ImagePicker();

  String? _vehicule;
  String? _gammeChoisie;

  final List<String> _vehicules = [
    "Moto",
    "Tricycle",
    "Pick-up",
    "Camionnette",
    "Camion léger",
    "Camion moyen",
    "Dépanneuse",
    "Semi-remorque",
    "Camion Benne",
    "Camion Plateau",
    "Camion Citerne",
    "Fourgon",
    "Conteneur"
  ];

  Future<void> _pickImage(String docType) async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        if (docType == 'permis') _photoPermis = image;
        else if (docType == 'carte_grise') _photoCarteGrise = image;
        else if (docType == 'assurance') _photoAssurance = image;
        else if (docType == 'vehicule_avant') _photoVehiculeAvant = image;
        else if (docType == 'vehicule_arriere') _photoVehiculeArriere = image;
        else if (docType == 'vehicule_profil') _photoVehiculeProfil = image;
        else if (docType == 'vehicule_interieur') _photoVehiculeInterieur = image;
      });
    }
  }

  Future<void> _inscription() async {
    if (!_formKey.currentState!.validate()) return;

    if (_vehicule == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Veuillez choisir un type de véhicule.")),
      );
      return;
    }

    if (_gammeChoisie == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Veuillez choisir la gamme souhaitée (Éco ou Confort).")),
      );
      return;
    }

    if (!_conditions) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Veuillez accepter les conditions d'utilisation.")),
      );
      return;
    }

    if (_photoPermis == null || _photoCarteGrise == null || _photoAssurance == null || 
        _photoVehiculeAvant == null || _photoVehiculeArriere == null || 
        _photoVehiculeProfil == null || _photoVehiculeInterieur == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Veuillez fournir tous les documents requis (incluant les 4 photos du véhicule).")),
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
        final uid = userCred.user!.uid;
        final serviceStockage = ref.read(serviceStockageProvider);

        String urlPermis = await serviceStockage.uploaderFichier(fichier: _photoPermis!, dossier: "transporteurs/$uid", nomFichier: "permis") ?? "";
        String urlCarteGrise = await serviceStockage.uploaderFichier(fichier: _photoCarteGrise!, dossier: "transporteurs/$uid", nomFichier: "carte_grise") ?? "";
        String urlAssurance = await serviceStockage.uploaderFichier(fichier: _photoAssurance!, dossier: "transporteurs/$uid", nomFichier: "assurance") ?? "";
        
        String urlAvant = await serviceStockage.uploaderFichier(fichier: _photoVehiculeAvant!, dossier: "transporteurs/$uid", nomFichier: "vehicule_avant") ?? "";
        String urlArriere = await serviceStockage.uploaderFichier(fichier: _photoVehiculeArriere!, dossier: "transporteurs/$uid", nomFichier: "vehicule_arriere") ?? "";
        String urlProfil = await serviceStockage.uploaderFichier(fichier: _photoVehiculeProfil!, dossier: "transporteurs/$uid", nomFichier: "vehicule_profil") ?? "";
        String urlInterieur = await serviceStockage.uploaderFichier(fichier: _photoVehiculeInterieur!, dossier: "transporteurs/$uid", nomFichier: "vehicule_interieur") ?? "";
        
        List<String> urlsVehicule = [urlAvant, urlArriere, urlProfil, urlInterieur].where((url) => url.isNotEmpty).toList();

        final nomComplet = _nom.text.trim().split(' ');
        final prenom = nomComplet.length > 1 ? nomComplet.sublist(0, nomComplet.length - 1).join(' ') : "";
        final nom = nomComplet.last;

        final transporteur = Transporteur(
          id: uid,
          nom: nom,
          prenom: prenom, 
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
          gamme: _gammeChoisie ?? "Éco",
          gammeValidee: _gammeChoisie == "Confort" ? false : true,
          immatriculation: _immatriculation.text.trim(),
          capaciteM3: Parseur.toDouble(_capacite.text.trim()),
          numeroPermis: _numeroPermis.text.trim(),
          photoPermis: urlPermis,
          photoCarteGrise: urlCarteGrise,
          photoAssurance: urlAssurance,
          photosInspectionVehicule: urlsVehicule,
          dateFinAbonnement: DateTime.now().add(const Duration(days: 7)),
        );

        // Sauvegarder dans la collection "transporteurs"
        await serviceDb.ajouterDocument(
          collection: "transporteurs",
          id: transporteur.id,
          donnees: transporteur.toMap(),
        );

        // Enregistrer le Token FCM
        await ServiceNotification.enregistrerTokenUtilisateur(transporteur.id, 'transporteur');

        // Mettre à jour le profil Auth
        await serviceAuth.mettreAJourProfil(nom: _nom.text.trim());

        // Envoyer l'email de vérification
        await serviceAuth.envoyerVerificationEmail();
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

  void _afficherConditions() {
    // Texte par défaut si aucun texte n'a encore été défini par l'admin
    const texteParDefaut =
        "Bienvenue sur CamTrans !\n\n"
        "1. Engagements du Transporteur\n"
        "Vous vous engagez à maintenir votre véhicule en bon état et à respecter les délais de livraison.\n\n"
        "2. Gammes et Tarification\n"
        "La gamme 'Confort' requiert une validation stricte par l'administrateur. Tout signalement client peut entraîner une rétrogradation vers la gamme 'Éco'.\n\n"
        "3. Confidentialité\n"
        "Vos documents et données personnelles sont stockés de manière sécurisée et ne seront partagés qu'avec l'administration pour validation.";

    final textesAsync = ref.read(textesAppProvider);
    final texteConditions = textesAsync.whenOrNull(
      data: (textes) => textes.get('conditions_transporteur', texteParDefaut),
    ) ?? texteParDefaut;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
        contentPadding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
        title: const Row(
          children: [
            Icon(Icons.gavel, color: CouleursApp.primaire, size: 22),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                "Conditions d'utilisation",
                style: TextStyle(color: CouleursApp.primaire, fontWeight: FontWeight.bold, fontSize: 17),
              ),
            ),
          ],
        ),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 400),
          child: SingleChildScrollView(
            child: Text(
              texteConditions,
              style: const TextStyle(height: 1.6, fontSize: 14, color: Colors.black87),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Fermer", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.check_circle_outline, size: 18, color: Colors.white),
            label: const Text("J'accepte", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _conditions = true;
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: CouleursApp.primaire,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
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
        child: PageResponsive(
          child: SingleChildScrollView(
          padding: EdgeInsets.all(TaillesApp.margePage),
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
                ),
                
                const SizedBox(height: 30),

                // Informations personnelles
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
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
                      ),
                      const SizedBox(height: 15),

                      ChampTexte(
                        controleur: _nom,
                        libelle: "Nom complet",
                        icone: Icons.person_outline,
                        validateur: Validateurs.nom,
                      ),

                      const SizedBox(height: 15),

                      ChampTexte(
                        controleur: _telephone,
                        libelle: "Téléphone",
                        icone: Icons.phone_outlined,
                        typeClavier: TextInputType.phone,
                        validateur: Validateurs.telephone,
                      ),

                      const SizedBox(height: 15),

                      ChampTexte(
                        controleur: _email,
                        libelle: "Adresse e-mail",
                        icone: Icons.email_outlined,
                        typeClavier: TextInputType.emailAddress,
                        validateur: Validateurs.email,
                      ),

                      const SizedBox(height: 15),

                      ChampTexte(
                        controleur: _ville,
                        libelle: "Ville",
                        icone: Icons.location_city_outlined,
                        validateur: (v) => Validateurs.obligatoire(v, nomChamp: "Ville"),
                      ),
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
                        color: Colors.black.withOpacity(0.05),
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
                      ),
                      const SizedBox(height: 15),

                      Theme(
                        data: ThemeData.light().copyWith(
                          colorScheme: const ColorScheme.light(
                            primary: CouleursApp.primaire,
                          ),
                          inputDecorationTheme: InputDecorationTheme(
                            fillColor: Colors.grey.shade50,
                            filled: true,
                          ),
                        ),
                        child: DropdownButtonFormField<String>(
                          value: _vehicule,
                          style: const TextStyle(
                            color: Color(0xFF1E293B),
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                          dropdownColor: Colors.white,
                          iconEnabledColor: CouleursApp.primaire,
                          decoration: InputDecoration(
                            labelText: "Type de véhicule *",
                            labelStyle: TextStyle(color: Colors.grey.shade600),
                            prefixIcon: Icon(Icons.local_shipping_outlined, color: Colors.grey.shade500),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: const BorderSide(color: CouleursApp.primaire, width: 2),
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                          ),
                          hint: Text(
                            "Sélectionnez votre véhicule",
                            style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                          ),
                          items: _vehicules.map((e) => DropdownMenuItem(
                            value: e,
                            child: Text(
                              e,
                              style: const TextStyle(
                                color: Color(0xFF1E293B),
                                fontSize: 15,
                              ),
                            ),
                          )).toList(),
                          validator: (v) => v == null ? "Veuillez choisir un type de véhicule" : null,
                          onChanged: (v) {
                            setState(() {
                              _vehicule = v;
                            });
                          },
                        ),
                      ),

                      const SizedBox(height: 15),

                      Theme(
                        data: ThemeData.light().copyWith(
                          colorScheme: const ColorScheme.light(
                            primary: CouleursApp.primaire,
                          ),
                          inputDecorationTheme: InputDecorationTheme(
                            fillColor: Colors.grey.shade50,
                            filled: true,
                          ),
                        ),
                        child: DropdownButtonFormField<String>(
                          value: _gammeChoisie,
                          style: const TextStyle(
                            color: Color(0xFF1E293B),
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                          dropdownColor: Colors.white,
                          iconEnabledColor: CouleursApp.primaire,
                          decoration: InputDecoration(
                            labelText: "Gamme souhaitée *",
                            labelStyle: TextStyle(color: Colors.grey.shade600),
                            prefixIcon: Icon(Icons.workspace_premium_outlined, color: Colors.grey.shade500),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: const BorderSide(color: CouleursApp.primaire, width: 2),
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                          ),
                          hint: Text(
                            "Sélectionnez la gamme",
                            style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                          ),
                          items: ["Éco", "Confort"].map((e) => DropdownMenuItem(
                            value: e,
                            child: Text(
                              e,
                              style: const TextStyle(
                                color: Color(0xFF1E293B),
                                fontSize: 15,
                              ),
                            ),
                          )).toList(),
                          validator: (v) => v == null ? "Veuillez choisir une gamme" : null,
                          onChanged: (v) {
                            setState(() {
                              _gammeChoisie = v;
                            });
                          },
                        ),
                      ),

                      if (_gammeChoisie != null)
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.only(top: 10),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _gammeChoisie == "Confort" ? Colors.amber.withOpacity(0.1) : Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: _gammeChoisie == "Confort" ? Colors.amber.withOpacity(0.5) : Colors.green.withOpacity(0.5)),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                _gammeChoisie == "Confort" ? Icons.star : Icons.eco,
                                color: _gammeChoisie == "Confort" ? Colors.amber[700] : Colors.green[700],
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _gammeChoisie == "Confort" 
                                    ? "Gamme Premium : Tarifs plus élevés et clientèle exigeante. Vous devez garantir un véhicule en excellent état. Soumis à validation stricte de l'administration."
                                    : "Gamme Standard : Plus de courses régulières et grand public. Idéal pour démarrer sans exigences strictes sur l'état visuel du véhicule.",
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: _gammeChoisie == "Confort" ? Colors.amber[900] : Colors.green[900],
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                      const SizedBox(height: 15),

                      ChampTexte(
                        controleur: _immatriculation,
                        libelle: "Immatriculation",
                        icone: Icons.directions_car_outlined,
                        validateur: (v) => Validateurs.obligatoire(v, nomChamp: "Immatriculation"),
                      ),

                      const SizedBox(height: 15),

                      ChampTexte(
                        controleur: _numeroPermis,
                        libelle: "Numéro de permis",
                        icone: Icons.badge_outlined,
                        validateur: (v) => Validateurs.obligatoire(v, nomChamp: "Permis"),
                      ),

                      const SizedBox(height: 15),

                      ChampTexte(
                        controleur: _capacite,
                        libelle: "Capacité (Tonnes)",
                        icone: Icons.scale_outlined,
                        typeClavier: const TextInputType.numberWithOptions(decimal: true),
                        validateur: Validateurs.poids,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 25),
                
                // Documents
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: CouleursApp.primaire.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: CouleursApp.primaire.withOpacity(0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Documents requis (Obligatoire)",
                        style: TextStyle(fontWeight: FontWeight.bold, color: CouleursApp.primaire),
                      ),
                      const SizedBox(height: 12),
                      _buildDocItem("Photo du permis de conduire", Icons.badge, _photoPermis != null, () => _pickImage('permis')),
                      _buildDocItem("Carte grise du véhicule", Icons.description, _photoCarteGrise != null, () => _pickImage('carte_grise')),
                      _buildDocItem("Attestation d'assurance", Icons.shield, _photoAssurance != null, () => _pickImage('assurance')),
                      
                      const Padding(
                        padding: EdgeInsets.only(top: 16, bottom: 8),
                        child: Text("Photos de vérification du véhicule :", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black54)),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: Column(
                          children: [
                            _buildDocItem("Face Avant (Plaque visible)", Icons.front_hand, _photoVehiculeAvant != null, () => _pickImage('vehicule_avant')),
                            _buildDocItem("Face Arrière (Plaque visible)", Icons.directions_car, _photoVehiculeArriere != null, () => _pickImage('vehicule_arriere')),
                            _buildDocItem("Profil (Carrosserie)", Icons.photo_size_select_actual, _photoVehiculeProfil != null, () => _pickImage('vehicule_profil')),
                            _buildDocItem("Intérieur (Cabine / Chargement)", Icons.event_seat, _photoVehiculeInterieur != null, () => _pickImage('vehicule_interieur')),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 25),

                // Sécurité
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      )
                    ],
                  ),
                  child: Column(
                    children: [
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text("Sécurité", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: CouleursApp.primaire)),
                      ),
                      const SizedBox(height: 15),

                      ChampTexte(
                        controleur: _motDePasse,
                        libelle: "Mot de passe",
                        icone: Icons.lock_outline,
                        estMotDePasse: true,
                        validateur: Validateurs.motDePasse,
                      ),

                      const SizedBox(height: 15),

                      ChampTexte(
                        controleur: _confirmation,
                        libelle: "Confirmer le mot de passe",
                        icone: Icons.lock_outline,
                        estMotDePasse: true,
                        validateur: (v) => Validateurs.confirmerMotDePasse(v, _motDePasse.text),
                      ),
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
                  title: GestureDetector(
                    onTap: _afficherConditions,
                    child: RichText(
                      text: const TextSpan(
                        style: TextStyle(fontSize: 14, color: Colors.black87),
                        children: [
                          TextSpan(text: "J'accepte les "),
                          TextSpan(
                            text: "conditions d'utilisation et la politique de confidentialité",
                            style: TextStyle(
                              color: CouleursApp.primaire,
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                          TextSpan(text: "."),
                        ],
                      ),
                    ),
                  ),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                ),

                const SizedBox(height: 25),

                BoutonPrincipal(
                  texte: "Créer mon compte",
                  icone: Icons.local_shipping,
                  chargement: _chargement,
                  auClic: _inscription,
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

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
        ),
      ),
    );
  }

  Widget _buildDocItem(String titre, IconData icone, bool isUploaded, VoidCallback onTap, {int? count}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Row(
          children: [
            Icon(icone, color: isUploaded ? CouleursApp.succes : Colors.grey, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                titre,
                style: TextStyle(
                  color: isUploaded ? CouleursApp.succes : Colors.black87,
                  fontWeight: isUploaded ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
            if (count != null && count > 0)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text("($count/4)", style: TextStyle(fontWeight: FontWeight.bold, color: count >= 4 ? CouleursApp.succes : Colors.orange)),
              ),
            Icon(
              isUploaded ? Icons.check_circle : Icons.upload_file,
              color: isUploaded ? CouleursApp.succes : CouleursApp.primaire,
            ),
          ],
        ),
      ),
    );
  }
}
