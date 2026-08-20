import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:update_camtrans/coeur/constantes/couleurs.dart';
import 'package:update_camtrans/coeur/constantes/tailles.dart';
import 'package:update_camtrans/coeur/utilitaires/validateurs.dart';
import 'package:update_camtrans/services/service_authentification.dart';

class ChangerMotDePasse extends ConsumerStatefulWidget {
  const ChangerMotDePasse({super.key});

  @override
  ConsumerState<ChangerMotDePasse> createState() => _ChangerMotDePasseState();
}

class _ChangerMotDePasseState extends ConsumerState<ChangerMotDePasse> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _actuelController = TextEditingController();
  final TextEditingController _nouveauController = TextEditingController();
  final TextEditingController _confirmerController = TextEditingController();

  bool _masquerActuel = true;
  bool _masquerNouveau = true;
  bool _masquerConfirmer = true;
  bool _chargement = false;

  @override
  void dispose() {
    _actuelController.dispose();
    _nouveauController.dispose();
    _confirmerController.dispose();
    super.dispose();
  }

  Future<void> _changerMotDePasse() async {
    if (!_formKey.currentState!.validate()) return;

    if (_nouveauController.text != _confirmerController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Les nouveaux mots de passe ne correspondent pas."), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _chargement = true);

    try {
      final auth = ref.read(serviceAuthentificationProvider);
      final email = auth.utilisateur?.email;

      if (email != null) {
        // 1. Ré-authentifier pour des raisons de sécurité (exigé par Firebase)
        await auth.reauthentifier(email, _actuelController.text);
        
        // 2. Changer le mot de passe
        await auth.modifierMotDePasse(_nouveauController.text);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Mot de passe modifié avec succès !"), backgroundColor: Colors.green),
          );
          context.pop();
        }
      }
    } catch (e) {
      if (mounted) {
        String message = "Erreur lors du changement. Vérifiez votre mot de passe actuel.";
        if (e.toString().contains("wrong-password")) message = "Mot de passe actuel incorrect.";
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _chargement = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CouleursApp.fond,
      appBar: AppBar(
        title: const Text("Changer le mot de passe"),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(TaillesApp.margePage),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Pour sécuriser votre compte, veuillez entrer votre mot de passe actuel avant d'en choisir un nouveau.",
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
              const SizedBox(height: 30),

              _buildPasswordField(
                label: "Mot de passe actuel",
                controller: _actuelController,
                masquer: _masquerActuel,
                onToggle: () => setState(() => _masquerActuel = !_masquerActuel),
              ),

              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 20),

              _buildPasswordField(
                label: "Nouveau mot de passe",
                controller: _nouveauController,
                masquer: _masquerNouveau,
                onToggle: () => setState(() => _masquerNouveau = !_masquerNouveau),
                validator: Validateurs.motDePasse,
              ),

              const SizedBox(height: 20),

              _buildPasswordField(
                label: "Confirmer le nouveau mot de passe",
                controller: _confirmerController,
                masquer: _masquerConfirmer,
                onToggle: () => setState(() => _masquerConfirmer = !_masquerConfirmer),
              ),

              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _chargement ? null : _changerMotDePasse,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: CouleursApp.primaire,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  child: _chargement 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Mettre à jour le mot de passe", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required String label,
    required TextEditingController controller,
    required bool masquer,
    required VoidCallback onToggle,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: masquer,
      validator: validator ?? (v) => (v == null || v.isEmpty) ? "Ce champ est requis" : null,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Iconsax.lock_copy, color: CouleursApp.primaire),
        suffixIcon: IconButton(
          icon: Icon(masquer ? Iconsax.eye_copy : Iconsax.eye_slash_copy),
          onPressed: onToggle,
        ),
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
    );
  }
}
