import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:update_camtrans/coeur/constantes/couleurs.dart';
import 'package:update_camtrans/coeur/constantes/tailles.dart';
import 'package:update_camtrans/coeur/etat/transporteur_provider.dart';
import 'package:update_camtrans/services/service_authentification.dart';
import 'package:update_camtrans/coeur/routes/routes.dart';
import 'package:intl/intl.dart';
import 'package:update_camtrans/coeur/widgets/loader_premium.dart';

class ProfilTransporteur extends ConsumerWidget {
  const ProfilTransporteur({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transporteurAsync = ref.watch(currentTransporteurProvider);
    final auth = ref.watch(serviceAuthentificationProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF08111F),
      appBar: AppBar(
        title: const Text("Mon profil", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF08111F),
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: transporteurAsync.when(
        loading: () => Center(child: LoaderPremium()),
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
                
                // === SECTION ABONNEMENT ===
                _buildAbonnementCard(context, transporteur),

                const SizedBox(height: 25),

                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
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
                    side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
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

                _boutonOption(Icons.workspace_premium, "Mes abonnements", () => context.push(RoutesApplication.abonnement)),
                _boutonOption(Icons.edit, "Modifier le profil", () => context.push(RoutesApplication.modifierProfil)),
                _boutonOption(Icons.lock, "Changer le mot de passe", () => context.push(RoutesApplication.changerMotDePasse)),
                _boutonOption(Icons.settings, "Paramètres", () {}),
                _boutonOption(Icons.help, "Aide & Support", () {}),

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
        side: BorderSide(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: ListTile(
        leading: Icon(icone, color: CouleursApp.primaire),
        title: Text(texte, style: const TextStyle(fontWeight: FontWeight.w600)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.white54),
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
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        children: [
          Icon(icone, color: CouleursApp.primaire, size: 30),
          const SizedBox(height: 10),
          Text(valeur, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 4),
          Text(titre, style: const TextStyle(color: Colors.white54, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildAbonnementCard(BuildContext context, transporteur) {
    bool estValide = transporteur.abonnementValide;
    int joursRestants = 0;
    
    if (transporteur.dateFinAbonnement != null) {
      joursRestants = transporteur.dateFinAbonnement!.difference(DateTime.now()).inDays;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: estValide 
              ? [CouleursApp.primaire.withValues(alpha: 0.8), CouleursApp.primaire]
              : [Colors.orange.shade400, Colors.red.shade400],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (estValide ? CouleursApp.primaire : Colors.red).withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(estValide ? Icons.verified : Icons.warning_amber_rounded, color: Colors.white, size: 28),
              const SizedBox(width: 10),
              Text(
                "Statut de l'abonnement",
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ],
          ),
          const SizedBox(height: 15),
          if (estValide) ...[
            Text(
              "Il vous reste $joursRestants jour(s)",
              style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 5),
            Text(
              "Valide jusqu'au ${DateFormat('dd/MM/yyyy à HH:mm').format(transporteur.dateFinAbonnement!)}",
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ] else ...[
            const Text(
              "Abonnement expiré",
              style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 5),
            const Text(
              "Veuillez renouveler votre abonnement pour continuer à recevoir des courses.",
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ],
          const SizedBox(height: 15),
          ElevatedButton(
            onPressed: () => context.push(RoutesApplication.abonnement),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF08111F),
              foregroundColor: estValide ? CouleursApp.primaire : Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(estValide ? "Prolonger l'abonnement" : "Renouveler maintenant", style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
