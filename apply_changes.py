import re

with open('lib/fonctionnalites/authentification/inscription_transporteur.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Imports
content = content.replace("import 'package:image_picker/image_picker.dart';", "")
content = content.replace("import 'package:update_camtrans/services/service_stockage.dart';", "")
content = content.replace("import 'package:update_camtrans/coeur/utilitaires/parseur.dart';",
    "import 'package:update_camtrans/coeur/utilitaires/parseur.dart';\nimport 'package:image_picker/image_picker.dart';\nimport 'package:update_camtrans/services/service_stockage.dart';")

# 2. State variables
state_vars = '''  bool _chargement = false;
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
  String? _gammeChoisie;'''
content = re.sub(r'  bool _chargement = false;\n  bool _conditions = false;\n\n  String\? _vehicule;', state_vars, content)

# 3. _pickImage
pick_image = '''  Future<void> _pickImage(String docType) async {
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

  Future<void> _inscription() async {'''
content = content.replace('  Future<void> _inscription() async {', pick_image)

# 4. Validation
validation = '''    if (_vehicule == null) {
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

    setState(() {'''
content = re.sub(r'    if \(!_conditions\) \{.*?setState\(\(\) \{', validation, content, flags=re.DOTALL)

# 5. Upload logic
upload = '''      if (userCred.user != null) {
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
          immatriculation: _immatriculation.text.trim(),
          capaciteM3: Parseur.toDouble(_capacite.text.trim()),
          numeroPermis: _numeroPermis.text.trim(),
          photoPermis: urlPermis,
          photoCarteGrise: urlCarteGrise,
          photoAssurance: urlAssurance,
          photosInspectionVehicule: urlsVehicule,
          dateFinAbonnement: DateTime.now().add(const Duration(days: 7)),
        );'''
content = re.sub(r'      if \(userCred\.user != null\) \{.*?dateFinAbonnement: DateTime\.now\(\)\.add\(const Duration\(days: 7\)\),\n        \);', upload, content, flags=re.DOTALL)

# 6. Conditions Dialog
conditions_dialog = '''  void _afficherConditions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Conditions d'utilisation", style: TextStyle(color: CouleursApp.primaire, fontWeight: FontWeight.bold)),
        content: const SingleChildScrollView(
          child: Text(
            "Voici les conditions générales d'utilisation de Camtrans pour les transporteurs...\\n\\n"
            "1. Engagements du Transporteur\\n"
            "Le transporteur s'engage à maintenir son véhicule en bon état et à respecter les délais de livraison.\\n\\n"
            "2. Gammes et Tarification\\n"
            "La gamme 'Confort' requiert une validation stricte. Tout signalement client peut entraîner une rétrogradation vers la gamme 'Éco'.\\n\\n"
            "3. Confidentialité\\n"
            "Vos documents et données personnelles sont stockés de manière sécurisée et ne seront partagés qu'avec l'administration pour validation.\\n\\n"
            "(Ce texte sera mis à jour par l'administrateur.)",
            style: TextStyle(height: 1.4, fontSize: 14),
          ),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Fermer"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _conditions = true;
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: CouleursApp.primaire,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text("J'accepte", style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  @override
  void dispose() {'''
content = content.replace('  @override\n  void dispose() {', conditions_dialog)

# 7. UI: Gamme dropdown and info box
gamme_ui = '''                          onChanged: (v) {
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

                      ChampTexte('''
content = re.sub(r'                          onChanged: \(v\) \{\n                            setState\(\(\) \{\n                              _vehicule = v;\n                            \}\);\n                          \},\n                        \),\n                      \),\n\n                      const SizedBox\(height: 15\),\n\n                      ChampTexte\(', gamme_ui, content)

# 8. UI: Documents
docs_ui = '''                // Documents
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
                ),'''
content = re.sub(r'                // Documents.*?_docItem\(Icons\.photo_camera, "Photos du véhicule \(Int/Ext\)"\),\n                    \],\n                  \),\n                \),', docs_ui, content, flags=re.DOTALL)

# 9. UI: Checkbox
checkbox_ui = '''                CheckboxListTile(
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
                ),'''
content = re.sub(r'                CheckboxListTile\([\s\S]*?contentPadding: EdgeInsets\.zero,\n                \),', checkbox_ui, content)

# 10. Helper _buildDocItem
build_doc = '''  Widget _buildDocItem(String titre, IconData icone, bool isUploaded, VoidCallback onTap, {int? count}) {
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
}'''
content = re.sub(r'  Widget _docItem[\s\S]*?\}', build_doc, content)

content = content.replace('.withValues(alpha:', '.withOpacity(').replace('))', ')')

with open('lib/fonctionnalites/authentification/inscription_transporteur.dart', 'w', encoding='utf-8') as f:
    f.write(content)
