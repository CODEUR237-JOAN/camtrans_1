import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:update_camtrans/coeur/etat/evaluation_provider.dart';
import 'package:go_router/go_router.dart';

import 'package:update_camtrans/coeur/constantes/couleurs.dart';
import 'package:update_camtrans/coeur/constantes/tailles.dart';
import 'package:update_camtrans/coeur/etat/transporteur_provider.dart';
import 'package:update_camtrans/services/service_authentification.dart';
import 'package:update_camtrans/coeur/routes/routes.dart';
import 'package:intl/intl.dart';
import 'package:update_camtrans/coeur/widgets/loader_premium.dart';
import 'package:update_camtrans/coeur/widgets/carte_information.dart';
import 'package:update_camtrans/coeur/widgets/selecteur_theme.dart';
import 'package:update_camtrans/coeur/constantes/statuts.dart';
import 'package:update_camtrans/l10n/app_localizations.dart';

class ProfilTransporteur extends ConsumerWidget {
  const ProfilTransporteur({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transporteurAsync = ref.watch(currentTransporteurProvider);
    final auth = ref.watch(serviceAuthentificationProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Mon profil",
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: transporteurAsync.when(
        loading: () => const Center(child: LoaderPremium()),
        error: (err, stack) => Center(
            child: Text("Oups, impossible de charger votre profil. ($err)")),
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
                  backgroundImage: transporteur.photo.isNotEmpty
                      ? NetworkImage(transporteur.photo)
                      : null,
                  child: transporteur.photo.isEmpty
                      ? const Icon(Icons.person,
                          size: 60, color: CouleursApp.primaire)
                      : null,
                ),

                const SizedBox(height: 15),

                Text(
                  "${transporteur.prenom} ${transporteur.nom}",
                  style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 5),

                Text(
                  transporteur.documentsValides
                      ? "Transporteur Vérifié"
                      : "En attente de vérification",
                  style: TextStyle(
                    color: transporteur.documentsValides
                        ? CouleursApp.succes
                        : CouleursApp.avertissement,
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
                    side: BorderSide(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.08)),
                  ),
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.phone,
                            color: CouleursApp.primaire),
                        title: const Text("Téléphone"),
                        subtitle: Text(transporteur.telephone),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.email,
                            color: CouleursApp.primaire),
                        title: const Text("E-mail"),
                        subtitle: Text(transporteur.email),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.location_city,
                            color: CouleursApp.primaire),
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
                    side: BorderSide(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.08)),
                  ),
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.local_shipping,
                            color: CouleursApp.primaire),
                        title: const Text("Modèle"),
                        subtitle: Text(
                            "${transporteur.marqueVehicule} ${transporteur.modeleVehicule}"),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.confirmation_number,
                            color: CouleursApp.primaire),
                        title: const Text("Immatriculation"),
                        subtitle: Text(transporteur.immatriculation),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.scale,
                            color: CouleursApp.primaire),
                        title: const Text("Capacité Max"),
                        subtitle: Text("${transporteur.chargeMaxKg} kg"),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 25),

                // === SECTION STATISTIQUES (Déplacée depuis le tableau de bord) ===
                ref.watch(fluxMesCoursesProvider).when(
                    loading: () => const SizedBox(
                        height: 100,
                        child: Center(child: CircularProgressIndicator())),
                    error: (err, _) => const SizedBox.shrink(),
                    data: (toutesLesCourses) {
                      final courses = toutesLesCourses
                          .where((c) => c.archivePourTransporteur != true)
                          .toList();
                      int livrees = courses
                          .where((c) =>
                              c.statut == StatutCourse.arriveDestination ||
                              c.statut == StatutCourse.terminee)
                          .length;
                      int enAttente = courses
                          .where((c) => StatutCourse.estActive(c.statut))
                          .length;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              "Mes Statistiques",
                              style: TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(height: 15),
                          // Disposition compacte : icône + valeur en haut,
                          // titre en pleine largeur dessous (plus de « C... 0 »).
                          IntrinsicHeight(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(
                                  child: CarteInformation(
                                      compacte: true,
                                      titre: "Courses",
                                      valeur: "${courses.length}",
                                      icone: Icons.local_shipping),
                                ),
                                const SizedBox(width: 15),
                                Expanded(
                                  child: CarteInformation(
                                      compacte: true,
                                      titre: "Livrées",
                                      valeur: "$livrees",
                                      icone: Icons.check_circle,
                                      couleurIcone: CouleursApp.succes,
                                      couleurValeur: CouleursApp.succes),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 15),
                          IntrinsicHeight(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(
                                  child: CarteInformation(
                                      compacte: true,
                                      titre: "En cours",
                                      valeur: "$enAttente",
                                      icone: Icons.schedule,
                                      couleurIcone: CouleursApp.avertissement,
                                      couleurValeur: CouleursApp.avertissement),
                                ),
                                const SizedBox(width: 15),
                                Expanded(
                                  child: Consumer(builder: (context, ref, _) {
                                    final n = ref.watch(
                                        noteMoyenneTransporteurProvider(
                                            transporteur.id));
                                    final v = n.maybeWhen(
                                      data: (x) => x.nombre > 0
                                          ? x.moyenne.toStringAsFixed(1)
                                          : '—',
                                      orElse: () =>
                                          '${transporteur.noteMoyenne}',
                                    );
                                    return CarteInformation(
                                        compacte: true,
                                        titre: "Note",
                                        valeur: v,
                                        icone: Icons.star,
                                        couleurIcone: CouleursApp.avertissement,
                                        couleurValeur:
                                            CouleursApp.avertissement);
                                  }),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    }),

                const SizedBox(height: 30),

                // === Section : Apparence ===
                const SelecteurTheme(),

                const SizedBox(height: 25),

                _boutonOption(
                    context,
                    Icons.workspace_premium,
                    "Mes abonnements",
                    () => context.push(RoutesApplication.abonnement)),
                _boutonOption(context, Icons.edit, "Modifier le profil",
                    () => context.push(RoutesApplication.modifierProfil)),
                _boutonOption(context, Icons.lock, "Changer le mot de passe",
                    () => context.push(RoutesApplication.changerMotDePasse)),
                _boutonOption(context, Icons.settings, AppLocalizations.of(context)!.settings,
                    () => context.push(RoutesApplication.parametres)),
                _boutonOption(context, Icons.help, "Aide & Support", () {}),

                const SizedBox(height: 25),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          CouleursApp.erreur.withValues(alpha: 0.15),
                      foregroundColor: CouleursApp.erreur,
                      minimumSize: const Size(double.infinity, 55),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                        side: BorderSide(
                            color: CouleursApp.erreur.withValues(alpha: 0.3)),
                      ),
                    ),
                    onPressed: () async {
                      await auth.deconnexion();
                      if (context.mounted) context.go("/connexion");
                    },
                    icon: const Icon(Icons.logout),
                    label: const Text("Déconnexion",
                        style: TextStyle(fontWeight: FontWeight.bold)),
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

  Widget _boutonOption(
      BuildContext context, IconData icone, String texte, VoidCallback action) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(
            color: Theme.of(context)
                .colorScheme
                .onSurface
                .withValues(alpha: 0.07)),
      ),
      child: ListTile(
        leading: Icon(icone, color: CouleursApp.primaire),
        title: Text(texte, style: const TextStyle(fontWeight: FontWeight.w600)),
        trailing: Icon(Icons.arrow_forward_ios,
            size: 16,
            color: Theme.of(context)
                .colorScheme
                .onSurface
                .withValues(alpha: 0.54)),
        onTap: action,
      ),
    );
  }

  Widget _buildAbonnementCard(BuildContext context, transporteur) {
    bool estValide = transporteur.abonnementValide;
    int joursRestants = 0;

    if (transporteur.dateFinAbonnement != null) {
      joursRestants =
          transporteur.dateFinAbonnement!.difference(DateTime.now()).inDays;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: estValide
              ? [
                  CouleursApp.primaire.withValues(alpha: 0.8),
                  CouleursApp.primaire
                ]
              : [CouleursApp.avertissement, CouleursApp.erreur],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (estValide ? CouleursApp.primaire : CouleursApp.erreur)
                .withValues(alpha: 0.3),
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
              Icon(estValide ? Icons.verified : Icons.warning_amber_rounded,
                  color: Theme.of(context).colorScheme.onSurface, size: 28),
              const SizedBox(width: 10),
              Text(
                "Statut de l'abonnement",
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                    fontSize: 18),
              ),
            ],
          ),
          const SizedBox(height: 15),
          if (estValide) ...[
            Text(
              "Il vous reste $joursRestants jour(s)",
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 22,
                  fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 5),
            Text(
              "Valide jusqu'au ${DateFormat('dd/MM/yyyy à HH:mm').format(transporteur.dateFinAbonnement!)}",
              style: TextStyle(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.7),
                  fontSize: 13),
            ),
          ] else ...[
            Text(
              "Abonnement expiré",
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 22,
                  fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 5),
            Text(
              "Veuillez renouveler votre abonnement pour continuer à recevoir des courses.",
              style: TextStyle(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.7),
                  fontSize: 13),
            ),
          ],
          const SizedBox(height: 15),
          ElevatedButton(
            onPressed: () => context.push(RoutesApplication.abonnement),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              foregroundColor:
                  estValide ? CouleursApp.primaire : CouleursApp.erreur,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(
                estValide ? "Prolonger l'abonnement" : "Renouveler maintenant",
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
