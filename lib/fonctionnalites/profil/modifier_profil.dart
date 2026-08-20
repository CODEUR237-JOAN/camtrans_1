import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:io' as io;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';

import 'package:update_camtrans/coeur/constantes/couleurs.dart';
import 'package:update_camtrans/coeur/constantes/tailles.dart';
import 'package:update_camtrans/services/service_authentification.dart';
import 'package:update_camtrans/services/service_firestore.dart';
import 'package:update_camtrans/services/service_stockage.dart';

class ModifierProfil extends ConsumerStatefulWidget {
  const ModifierProfil({super.key});

  @override
  ConsumerState<ModifierProfil> createState() => _ModifierProfilState();
}

class _ModifierProfilState extends ConsumerState<ModifierProfil> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController prenomController;
  late TextEditingController nomController;
  late TextEditingController telephoneController;
  late TextEditingController villeController;
  late TextEditingController adresseController;

  bool _chargement = false;
  bool _initialise = false;
  String _photoUrl = "";
  XFile? _nouvellePhoto;

  @override
  void initState() {
    super.initState();
    prenomController = TextEditingController();
    nomController = TextEditingController();
    telephoneController = TextEditingController();
    villeController = TextEditingController();
    adresseController = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialise) {
      _chargerDonnees();
    }
  }

  void _chargerDonnees() async {
    final userId = ref.read(serviceAuthentificationProvider).utilisateur?.uid;
    if (userId == null) return;

    setState(() => _chargement = true);

    try {
      final firestore = ref.read(serviceFirestoreProvider);
      
      // Essayer de charger comme client
      var doc = await firestore.lireDocument(collection: 'clients', id: userId);
      bool estClient = doc.exists;
      
      if (!estClient) {
        // Essayer comme transporteur
        doc = await firestore.lireDocument(collection: 'transporteurs', id: userId);
      }

      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        setState(() {
          prenomController.text = data['prenom'] ?? "";
          nomController.text = data['nom'] ?? "";
          telephoneController.text = data['telephone'] ?? "";
          villeController.text = data['ville'] ?? "";
          adresseController.text = data['adresse'] ?? "";
          _photoUrl = data['photo'] ?? "";
          _initialise = true;
        });
      }
    } catch (e) {
      debugPrint("Erreur chargement profil: $e");
    } finally {
      setState(() => _chargement = false);
    }
  }

  Future<void> _choisirPhoto() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() => _nouvellePhoto = image);
    }
  }

  Future<void> _enregistrer() async {
    if (!_formKey.currentState!.validate()) return;

    final userId = ref.read(serviceAuthentificationProvider).utilisateur?.uid;
    if (userId == null) return;

    setState(() => _chargement = true);

    try {
      final firestore = ref.read(serviceFirestoreProvider);
      final stockage = ref.read(serviceStockageProvider);
      
      // 1. Upload photo si nouvelle
      String photoFinale = _photoUrl;
      if (_nouvellePhoto != null) {
        final url = await stockage.uploaderFichier(
          fichier: _nouvellePhoto!,
          dossier: 'avatars',
          nomFichier: userId,
        );
        if (url != null) photoFinale = url;
      }

      // 2. Déterminer la collection
      final clientDoc = await firestore.lireDocument(collection: 'clients', id: userId);
      final collection = clientDoc.exists ? 'clients' : 'transporteurs';

      // 3. Mettre à jour Firestore
      final Map<String, dynamic> donnees = {
        'prenom': prenomController.text.trim(),
        'nom': nomController.text.trim(),
        'telephone': telephoneController.text.trim(),
        'ville': villeController.text.trim(),
        'adresse': adresseController.text.trim(),
        'photo': photoFinale,
      };

      await firestore.modifierDocument(
        collection: collection,
        id: userId,
        donnees: donnees,
      );

      // Mettre à jour le profil Firebase Auth aussi (nom d'affichage)
      await ref.read(serviceAuthentificationProvider).utilisateur?.updateDisplayName(
        "${prenomController.text.trim()} ${nomController.text.trim()}"
      );
      if (photoFinale.isNotEmpty) {
        await ref.read(serviceAuthentificationProvider).utilisateur?.updatePhotoURL(photoFinale);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profil mis à jour avec succès !"), backgroundColor: Colors.green),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur lors de la mise à jour: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _chargement = false);
    }
  }

  @override
  void dispose() {
    prenomController.dispose();
    nomController.dispose();
    telephoneController.dispose();
    villeController.dispose();
    adresseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CouleursApp.fond,
      appBar: AppBar(
        title: const Text("Modifier mon profil"),
        actions: [
          if (!_chargement)
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _enregistrer,
            )
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: EdgeInsets.all(TaillesApp.margePage),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  
                  // Photo de profil
                  Center(
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 65,
                          backgroundColor: CouleursApp.primaire.withValues(alpha: 0.1),
                          backgroundImage: _nouvellePhoto != null 
                            ? (kIsWeb 
                                ? NetworkImage(_nouvellePhoto!.path) 
                                : FileImage(io.File(_nouvellePhoto!.path)) as ImageProvider)
                            : (_photoUrl.isNotEmpty ? NetworkImage(_photoUrl) : null),
                          child: (_nouvellePhoto == null && _photoUrl.isEmpty)
                            ? const Icon(Icons.person, size: 65, color: CouleursApp.primaire)
                            : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: _choisirPhoto,
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: CouleursApp.primaire,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 3),
                              ),
                              child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 35),

                  _buildField("Prénom", prenomController, Icons.person_outline),
                  const SizedBox(height: 16),
                  _buildField("Nom", nomController, Icons.person_outline),
                  const SizedBox(height: 16),
                  _buildField("Téléphone", telephoneController, Icons.phone_outlined, keyboardType: TextInputType.phone),
                  const SizedBox(height: 16),
                  _buildField("Ville", villeController, Icons.location_city_outlined),
                  const SizedBox(height: 16),
                  _buildField("Adresse", adresseController, Icons.home_outlined, maxLines: 2),

                  const SizedBox(height: 40),

                  BoutonPrincipal(
                    texte: "Enregistrer les modifications",
                    chargement: _chargement,
                    auClic: _enregistrer,
                  ),
                  
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
          if (_chargement)
            Container(
              color: Colors.black.withValues(alpha: 0.3),
              child: const Center(child: CircularProgressIndicator()),
            )
        ],
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller, IconData icon, {TextInputType? keyboardType, int maxLines = 1}) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: CouleursApp.primaire),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      validator: (v) => (v == null || v.isEmpty) ? "Ce champ est requis" : null,
    );
  }
}

class BoutonPrincipal extends StatelessWidget {
  final String texte;
  final bool chargement;
  final VoidCallback auClic;

  const BoutonPrincipal({super.key, required this.texte, this.chargement = false, required this.auClic});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: chargement ? null : auClic,
        style: ElevatedButton.styleFrom(
          backgroundColor: CouleursApp.primaire,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        ),
        child: chargement 
          ? const CircularProgressIndicator(color: Colors.white)
          : Text(texte, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
