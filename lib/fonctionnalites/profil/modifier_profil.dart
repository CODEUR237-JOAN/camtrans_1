import 'package:flutter/material.dart';

import '../../coeur/constantes/couleurs.dart';
import '../../coeur/constantes/images.dart';
import '../../coeur/constantes/tailles.dart';

class ModifierProfil extends StatefulWidget {
  const ModifierProfil({super.key});

  @override
  State<ModifierProfil> createState() => _ModifierProfilState();
}

class _ModifierProfilState extends State<ModifierProfil> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController nomController =
  TextEditingController(text: "Jean Dupont");

  final TextEditingController emailController =
  TextEditingController(text: "jean@email.com");

  final TextEditingController telephoneController =
  TextEditingController(text: "+237 699 12 34 56");

  final TextEditingController villeController =
  TextEditingController(text: "Douala");

  final TextEditingController adresseController =
  TextEditingController(text: "Bonamoussadi");

  final TextEditingController motDePasseController =
  TextEditingController();

  bool masquerMotDePasse = true;

  @override
  void dispose() {
    nomController.dispose();
    emailController.dispose();
    telephoneController.dispose();
    villeController.dispose();
    adresseController.dispose();
    motDePasseController.dispose();
    super.dispose();
  }

  InputDecoration decorationChamp(
      String label,
      IconData icone,
      ) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(
        icone,
        color: CouleursApp.primaire,
      ),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide.none,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CouleursApp.fond,
      appBar: AppBar(
        title: const Text("Modifier mon profil"),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(
          TaillesApp.margePage,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundImage:
                    AssetImage(ImagesApp.avatar),
                  ),
                  FloatingActionButton.small(
                    heroTag: "photo",
                    backgroundColor:
                    CouleursApp.primaire,
                    onPressed: () {},
                    child: const Icon(
                      Icons.camera_alt,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 30),

              TextFormField(
                controller: nomController,
                decoration: decorationChamp(
                  "Nom complet",
                  Icons.person,
                ),
                validator: (value) {
                  if (value == null ||
                      value.trim().isEmpty) {
                    return "Veuillez saisir votre nom.";
                  }
                  return null;
                },
              ),

              const SizedBox(height: 18),

              TextFormField(
                controller: emailController,
                keyboardType:
                TextInputType.emailAddress,
                decoration: decorationChamp(
                  "Adresse e-mail",
                  Icons.email,
                ),
                validator: (value) {
                  if (value == null ||
                      !value.contains("@")) {
                    return "Adresse e-mail invalide.";
                  }
                  return null;
                },
              ),

              const SizedBox(height: 18),

              TextFormField(
                controller: telephoneController,
                keyboardType: TextInputType.phone,
                decoration: decorationChamp(
                  "Téléphone",
                  Icons.phone,
                ),
              ),

              const SizedBox(height: 18),

              TextFormField(
                controller: villeController,
                decoration: decorationChamp(
                  "Ville",
                  Icons.location_city,
                ),
              ),

              const SizedBox(height: 18),

              TextFormField(
                controller: adresseController,
                decoration: decorationChamp(
                  "Adresse",
                  Icons.home,
                ),
                maxLines: 2,
              ),

              const SizedBox(height: 18),

              TextFormField(
                controller: motDePasseController,
                obscureText: masquerMotDePasse,
                decoration: InputDecoration(
                  labelText:
                  "Nouveau mot de passe",
                  prefixIcon: const Icon(
                    Icons.lock,
                    color: CouleursApp.primaire,
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      masquerMotDePasse
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        masquerMotDePasse =
                        !masquerMotDePasse;
                      });
                    },
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius:
                    BorderRadius.circular(15),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 35),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                    CouleursApp.primaire,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                      BorderRadius.circular(15),
                    ),
                  ),
                  onPressed: () {
                    if (_formKey.currentState!
                        .validate()) {
                      ScaffoldMessenger.of(context)
                          .showSnackBar(
                        const SnackBar(
                          content: Text(
                            "Profil mis à jour avec succès.",
                          ),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.save),
                  label: const Text(
                    "Enregistrer les modifications",
                  ),
                ),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}