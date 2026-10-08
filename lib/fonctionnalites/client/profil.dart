import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:update_camtrans/coeur/constantes/couleurs.dart';
import 'package:update_camtrans/coeur/constantes/tailles.dart';
import 'package:update_camtrans/coeur/etat/utilisateur_provider.dart';
import 'package:update_camtrans/services/service_authentification.dart';
import 'package:update_camtrans/coeur/widgets/loader_premium.dart';

import 'package:update_camtrans/coeur/etat/course_provider.dart';
import 'package:update_camtrans/coeur/constantes/statuts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:update_camtrans/coeur/routes/routes.dart';

class Profil extends ConsumerWidget {
  const Profil({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(serviceAuthentificationProvider);
    final clientAsync = ref.watch(currentClientProvider);
    final coursesAsync = ref.watch(coursesClientProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Mon Profil",
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: clientAsync.when(
        loading: () => const Center(child: LoaderPremium()),
        error: (err, stack) => Center(
            child: Text("Oups, impossible de charger votre profil. ($err)")),
        data: (client) {
          final user = auth.utilisateur;
          final userName = client != null
              ? "${client.prenom} ${client.nom}"
              : (user?.displayName ?? "Utilisateur");
          final userEmail = client?.email ?? user?.email ?? "Non renseigné";
          final userPhone =
              client?.telephone ?? user?.phoneNumber ?? "Non renseigné";
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
                        backgroundColor:
                            CouleursApp.primaire.withValues(alpha: 0.1),
                        backgroundImage:
                            userPhoto != null && userPhoto.isNotEmpty
                                ? NetworkImage(userPhoto)
                                : null,
                        child: (userPhoto == null || userPhoto.isEmpty)
                            ? const Icon(Icons.person,
                                size: 60, color: CouleursApp.primaire)
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                              color: CouleursApp.primaire,
                              shape: BoxShape.circle),
                          child: const Icon(Icons.camera_alt,
                              color: Colors.white, size: 20),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                Text(
                  userName,
                  style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.bold),
                ),

                Text(
                  "Client CamTrans",
                  style: TextStyle(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.7),
                      fontWeight: FontWeight.w500),
                ),

                const SizedBox(height: 30),

                // Statistiques extraites de l'accueil
                coursesAsync.when(
                  data: (toutesLesCourses) {
                    final courses = toutesLesCourses
                        .where((c) => c.archivePourClient != true)
                        .toList();
                    final enCours = courses
                        .where((c) => !StatutCourse.estTerminee(c.statut))
                        .toList();
                    final livrees = courses
                        .where((c) =>
                            c.statut == StatutCourse.arriveDestination ||
                            c.statut == StatutCourse.terminee)
                        .toList();

                    double depenses =
                        livrees.fold(0, (sum, c) => sum + c.prixFinal);
                    if (depenses == 0) {
                      depenses =
                          livrees.fold(0, (sum, c) => sum + c.prixEstime);
                    }

                    return _buildStats(
                      context,
                      courses: livrees.length,
                      depenses: depenses,
                      enCours: enCours.length,
                    );
                  },
                  loading: () => const SizedBox(
                      height: 100,
                      child: Center(child: CircularProgressIndicator())),
                  error: (err, stack) => const SizedBox(),
                ),

                const SizedBox(height: 30),

                // Section Infos Contact
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.08)),
                  ),
                  child: Column(
                    children: [
                      _ligneInformation(
                          context, Iconsax.call_copy, "Téléphone", userPhone),
                      Divider(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.1),
                          height: 1,
                          indent: 60,
                          endIndent: 20),
                      _ligneInformation(context, Iconsax.sms_copy,
                          "Adresse e-mail", userEmail),
                      Divider(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.1),
                          height: 1,
                          indent: 60,
                          endIndent: 20),
                      _ligneInformation(
                          context, Iconsax.location_copy, "Ville", userVille),
                    ],
                  ),
                ),

                const SizedBox(height: 25),

                // Section Gestion & Paramètres
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text("Paramètres",
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface)),
                ),
                const SizedBox(height: 15),

                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.08)),
                  ),
                  child: Column(
                    children: [
                      _ligneAction(
                          context,
                          Iconsax.location_add_copy,
                          "Mes Adresses",
                          () => context.push("/adresses-favorites")),
                      Divider(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.1),
                          height: 1,
                          indent: 60,
                          endIndent: 20),
                      _ligneAction(
                          context,
                          Iconsax.user_edit_copy,
                          "Modifier le profil",
                          () => context.push("/modifier-profil")),
                      Divider(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.1),
                          height: 1,
                          indent: 60,
                          endIndent: 20),
                      _ligneAction(context, Iconsax.key_copy, "Mot de passe",
                          () => context.push("/changer-mot-de-passe")),
                      Divider(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.1),
                          height: 1,
                          indent: 60,
                          endIndent: 20),
                      _ligneAction(
                          context,
                          Iconsax.wallet_2_copy,
                          "Moyens de paiement",
                          () => context.push(RoutesApplication.moyensPaiement)),
                      Divider(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.1),
                          height: 1,
                          indent: 60,
                          endIndent: 20),
                      _ligneAction(
                          context,
                          Iconsax.document_copy,
                          "Mes Factures",
                          () => context.push(RoutesApplication.factures)),
                      Divider(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.1),
                          height: 1,
                          indent: 60,
                          endIndent: 20),
                      _ligneAction(
                          context,
                          Iconsax.setting_2_copy,
                          "Paramètres généraux",
                          () => context.push(RoutesApplication.parametres)),
                    ],
                  ),
                ),

                const SizedBox(height: 35),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.withValues(alpha: 0.1),
                      foregroundColor: Colors.redAccent,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                            color: Colors.red.withValues(alpha: 0.2)),
                      ),
                    ),
                    onPressed: () async {
                      await auth.deconnexion();
                      if (context.mounted) {
                        context.go("/connexion");
                      }
                    },
                    icon: const Icon(Iconsax.logout_copy),
                    label: const Text("Se déconnecter",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
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

  Widget _buildStats(BuildContext context,
      {required int courses, required double depenses, required int enCours}) {
    String depensesText = depenses >= 1000
        ? "${(depenses / 1000).toStringAsFixed(1)}k"
        : depenses.toStringAsFixed(0);

    return SizedBox(
      height: 100,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildStatCard(context, "Courses", courses.toString(),
              Iconsax.box_tick_copy, CouleursApp.succes),
          const SizedBox(width: 15),
          _buildStatCard(context, "Dépenses", depensesText, Iconsax.coin_copy,
              CouleursApp.avertissement),
          const SizedBox(width: 15),
          _buildStatCard(context, "En cours", enCours.toString(),
              Iconsax.truck_copy, CouleursApp.primaire),
        ],
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, String title, String value,
      IconData icon, Color color) {
    return Container(
      width: 155,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: color.withValues(alpha: 0.1),
              blurRadius: 15,
              offset: const Offset(0, 5))
        ],
        border: Border.all(color: color.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 24),
              Text(value,
                  style: TextStyle(
                      fontSize: 22, fontWeight: FontWeight.bold, color: color)),
            ],
          ),
          const Spacer(),
          Text(title,
              style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.7),
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _ligneInformation(
      BuildContext context, IconData icone, String titre, String valeur) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: CouleursApp.primaire.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icone, color: CouleursApp.primaire, size: 22),
      ),
      title: Text(titre,
          style: TextStyle(
              fontSize: 13,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.54))),
      subtitle: Text(valeur,
          style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 15)),
    );
  }

  Widget _ligneAction(
      BuildContext context, IconData icone, String texte, VoidCallback action) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Icon(icone,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
          size: 24),
      title: Text(texte,
          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16)),
      trailing: Icon(Icons.arrow_forward_ios,
          size: 14,
          color:
              Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3)),
      onTap: action,
    );
  }
}
