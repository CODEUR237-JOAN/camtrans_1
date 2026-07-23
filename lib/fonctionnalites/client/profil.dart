import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../coeur/constantes/couleurs.dart';
import '../../coeur/constantes/images.dart';
import '../../coeur/constantes/tailles.dart';
import '../../services/service_authentification.dart';

class Profil extends ConsumerWidget {
  const Profil({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(serviceAuthentificationProvider);
    final user = auth.utilisateur;
    final userName = user?.displayName ?? "Utilisateur";
    final userEmail = user?.email ?? "Non renseigné";
    final userPhone = user?.phoneNumber ?? "Non renseigné";

    return Scaffold(
      backgroundColor: CouleursApp.fond,
      appBar: AppBar(
        title: const Text("Mon Profil", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: CouleursApp.fond,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(TaillesApp.margePage),
        child: Column(
          children: [
            const SizedBox(height: 10),

            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: CouleursApp.primaire.withValues(alpha: 0.1),
                    backgroundImage: user?.photoURL != null ? NetworkImage(user!.photoURL!) : null,
                    child: user?.photoURL == null 
                      ? const Icon(Icons.person, size: 60, color: CouleursApp.primaire)
                      : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(color: CouleursApp.primaire, shape: BoxShape.circle),
                      child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            Text(
              userName,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),

            const Text(
              "Client TransConnect",
              style: TextStyle(color: CouleursApp.texteSecondaire, fontWeight: FontWeight.w500),
            ),

            const SizedBox(height: 30),

            _carteInformation(Icons.phone, "Téléphone", userPhone),
            _carteInformation(Icons.email, "Adresse e-mail", userEmail),
            _carteInformation(Icons.location_city, "Ville", "Cameroun (Général)"),

            const SizedBox(height: 25),

            _bouton(context, Icons.edit, "Modifier le profil", () => context.push("/modifier-profil")),
            _bouton(context, Icons.lock_reset, "Changer le mot de passe", () {}),
            _bouton(context, Icons.account_balance_wallet, "Moyens de paiement", () {}),
            _bouton(context, Icons.settings, "Paramètres", () {}),
            _bouton(context, Icons.help, "Centre d'assistance", () {}),

            const SizedBox(height: 25),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade50,
                  foregroundColor: Colors.red,
                  minimumSize: const Size(double.infinity, 55),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                    side: BorderSide(color: Colors.red.shade100),
                  ),
                ),
                onPressed: () async {
                  await auth.deconnexion();
                  if (context.mounted) {
                    context.go("/connexion");
                  }
                },
                icon: const Icon(Icons.logout),
                label: const Text("Se déconnecter", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _carteInformation(IconData icone, String titre, String valeur) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: CouleursApp.primaire.withValues(alpha: 0.1), shape: BoxShape.circle),
          child: Icon(icone, color: CouleursApp.primaire, size: 20),
        ),
        title: Text(titre, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        subtitle: Text(valeur, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
      ),
    );
  }

  Widget _bouton(BuildContext context, IconData icone, String texte, VoidCallback action) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(color: Colors.grey.shade100),
      ),
      child: ListTile(
        leading: Icon(icone, color: Colors.black87),
        title: Text(texte, style: const TextStyle(fontWeight: FontWeight.w600)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
        onTap: action,
      ),
    );
  }
}