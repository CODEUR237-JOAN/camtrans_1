import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:update_camtrans/coeur/constantes/couleurs.dart';
import 'package:update_camtrans/coeur/constantes/tailles.dart';
import 'package:update_camtrans/coeur/etat/utilisateur_provider.dart';
import 'package:update_camtrans/services/service_authentification.dart';
import 'package:update_camtrans/coeur/widgets/loader_premium.dart';

class Profil extends ConsumerWidget {
  const Profil({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(serviceAuthentificationProvider);
    final clientAsync = ref.watch(currentClientProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF08111F),
      appBar: AppBar(
        title: const Text("Mon Profil", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF08111F),
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: clientAsync.when(
        loading: () => Center(child: LoaderPremium()),
        error: (err, stack) => Center(child: Text("Erreur: $err")),
        data: (client) {
          final user = auth.utilisateur;
          final userName = client != null ? "${client.prenom} ${client.nom}" : (user?.displayName ?? "Utilisateur");
          final userEmail = client?.email ?? user?.email ?? "Non renseigné";
          final userPhone = client?.telephone ?? user?.phoneNumber ?? "Non renseigné";
          final userPhoto = client?.photo ?? user?.photoURL;
          final userVille = client?.ville ?? "Cameroun (Général)";

          return SingleChildScrollView(
            padding: EdgeInsets.all(TaillesApp.margePage),
            child: Column(
              children: [
                const SizedBox(height: 10),

                Center(
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundColor: CouleursApp.primaire.withValues(alpha: 0.1),
                        backgroundImage: userPhoto != null && userPhoto.isNotEmpty ? NetworkImage(userPhoto) : null,
                        child: (userPhoto == null || userPhoto.isEmpty)
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
                  style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w500),
                ),

                const SizedBox(height: 30),

                _carteInformation(Icons.phone, "Téléphone", userPhone),
                _carteInformation(Icons.email, "Adresse e-mail", userEmail),
                _carteInformation(Icons.location_city, "Ville", userVille),

                const SizedBox(height: 25),

                _bouton(context, Icons.location_on, "Mes Adresses", () => context.push("/adresses-favorites")),
                _bouton(context, Icons.edit, "Modifier le profil", () => context.push("/modifier-profil")),
                _bouton(context, Icons.lock_reset, "Changer le mot de passe", () => context.push("/changer-mot-de-passe")),
                _bouton(context, Icons.account_balance_wallet, "Moyens de paiement", () {}),
                _bouton(context, Icons.settings, "Paramètres", () {}),
                _bouton(context, Icons.help, "Centre d'assistance", () {}),

                const SizedBox(height: 25),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.withValues(alpha: 0.15),
                      foregroundColor: Colors.red,
                      minimumSize: const Size(double.infinity, 55),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                        side: BorderSide(color: Colors.red.withValues(alpha: 0.3)),
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

                const SizedBox(height: 120),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _carteInformation(IconData icone, String titre, String valeur) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: CouleursApp.primaire.withValues(alpha: 0.1), shape: BoxShape.circle),
          child: Icon(icone, color: CouleursApp.primaire, size: 20),
        ),
        title: Text(titre, style: const TextStyle(fontSize: 12, color: Colors.white54)),
        subtitle: Text(valeur, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
      ),
    );
  }

  Widget _bouton(BuildContext context, IconData icone, String texte, VoidCallback action) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(color: const Color(0xFFEEEEEE)),
      ),
      child: ListTile(
        leading: Icon(icone, color: Colors.white),
        title: Text(texte, style: const TextStyle(fontWeight: FontWeight.w600)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.white54),
        onTap: action,
      ),
    );
  }
}
