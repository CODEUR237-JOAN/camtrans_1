import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:update_camtrans/coeur/constantes/couleurs.dart';
import 'package:update_camtrans/coeur/constantes/tailles.dart';
import 'package:update_camtrans/coeur/etat/transporteur_provider.dart';
import 'package:update_camtrans/services/service_authentification.dart';

class ProfilTransporteur extends ConsumerWidget {
  const ProfilTransporteur({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transporteurAsync = ref.watch(currentTransporteurProvider);
    final auth = ref.watch(serviceAuthentificationProvider);

    return Scaffold(
      backgroundColor: CouleursApp.fond,
      appBar: AppBar(
        title: const Text("Mon profil", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: CouleursApp.fond,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: transporteurAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text("Erreur: $err")),
        data: (transporteur) {
          if (transporteur == null) {
            return const Center(child: Text("Profil introuvable"));
          }

          return SingleChildScrollView(
            padding: EdgeInsets.all(TaillesApp.margePage),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 60,
                  backgroundColor: CouleursApp.primaire.withValues(alpha: 0.1),
                  backgroundImage: transporteur.photo.isNotEmpty ? NetworkImage(transporteur.photo) : null,
                  child: transporteur.photo.isEmpty 
                    ? const Icon(Icons.person, size: 60, color: CouleursApp.primaire)
                    : null,
                ),

                const SizedBox(height: 15),

                Text(
                  "${transporteur.prenom} ${transporteur.nom}",
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 5),

                Text(
                  transporteur.documentsValides ? "Transporteur Vérifié" : "En attente de vérification",
                  style: TextStyle(
                    color: transporteur.documentsValides ? Colors.green : Colors.orange,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 25),

                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.phone, color: CouleursApp.primaire),
                        title: const Text("Téléphone"),
                        subtitle: Text(transporteur.telephone),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.email, color: CouleursApp.primaire),
                        title: const Text("E-mail"),
                        subtitle: Text(transporteur.email),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.location_city, color: CouleursApp.primaire),
                        title: const Text("Ville"),
                        subtitle: Text(transporteur.ville),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 25),

                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Informations du véhicule",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),

                const SizedBox(height: 15),

                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.local_shipping, color: CouleursApp.primaire),
                        title: const Text("Modèle"),
                        subtitle: Text("${transporteur.marqueVehicule} ${transporteur.modeleVehicule}"),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.confirmation_number, color: CouleursApp.primaire),
                        title: const Text("Immatriculation"),
                        subtitle: Text(transporteur.immatriculation),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.scale, color: CouleursApp.primaire),
                        title: const Text("Capacité Max"),
                        subtitle: Text("${transporteur.chargeMaxKg} kg"),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 25),

                Row(
                  children: [
                    Expanded(
                      child: _statistique(
                        "Courses",
                        "${transporteur.nombreCourses}",
                        Icons.local_shipping,
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: _statistique(
                        "Note",
                        "${transporteur.noteMoyenne} ",
                        Icons.star,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 30),

                _boutonOption(Icons.edit, "Modifier le profil", () => context.push("/modifier-profil")),
                _boutonOption(Icons.lock, "Changer le mot de passe", () => context.push("/changer-mot-de-passe")),
                _boutonOption(Icons.settings, "Paramètres", () {}),
                _boutonOption(Icons.help, "Aide & Support", () {}),

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
                      if (context.mounted) context.go("/connexion");
                    },
                    icon: const Icon(Icons.logout),
                    label: const Text("Déconnexion", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),

                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _boutonOption(IconData icone, String texte, VoidCallback action) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(color: Colors.grey.shade100),
      ),
      child: ListTile(
        leading: Icon(icone, color: CouleursApp.primaire),
        title: Text(texte, style: const TextStyle(fontWeight: FontWeight.w600)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        onTap: action,
      ),
    );
  }

  Widget _statistique(String titre, String valeur, IconData icone) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(icone, color: CouleursApp.primaire, size: 30),
          const SizedBox(height: 10),
          Text(valeur, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 4),
          Text(titre, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }
}
