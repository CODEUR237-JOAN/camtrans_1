import 'package:flutter_animate/flutter_animate.dart';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:iconsax_flutter/iconsax_flutter.dart';

import 'package:update_camtrans/coeur/constantes/couleurs.dart';
import 'package:update_camtrans/coeur/constantes/tailles.dart';
import 'package:update_camtrans/coeur/widgets/carte_information.dart';
import 'package:update_camtrans/coeur/widgets/effets_visuels.dart';
import 'package:update_camtrans/coeur/widgets/glass_container.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../coeur/etat/transporteur_provider.dart';
import 'package:update_camtrans/coeur/routes/routes.dart';
import 'package:update_camtrans/coeur/etat/gps_provider.dart';
import 'package:update_camtrans/services/service_authentification.dart';
import 'package:update_camtrans/modeles/course.dart';
import 'package:update_camtrans/coeur/constantes/statuts.dart';

import 'package:update_camtrans/fonctionnalites/transporteur/marche_demandes.dart';
import 'package:update_camtrans/fonctionnalites/transporteur/navigation.dart';
import 'package:update_camtrans/fonctionnalites/notifications/notifications.dart';
import 'package:update_camtrans/coeur/widgets/combi_widget.dart';
import 'package:update_camtrans/services/service_notification.dart';
import 'profil.dart';
import 'package:update_camtrans/coeur/widgets/page_responsive.dart';
import 'package:update_camtrans/fonctionnalites/transporteur/widgets/popup_proposition_course.dart';
import 'page_abonnement.dart';
import 'package:update_camtrans/coeur/widgets/loader_premium.dart';

/// Salutation adaptée à l'heure (matin / après-midi / soir).
String _salutationDuJour() {
  final h = DateTime.now().hour;
  if (h < 12) return 'Bonjour';
  if (h < 18) return 'Bon après-midi';
  return 'Bonsoir';
}

class TableauDeBordTransporteur extends ConsumerStatefulWidget {
  const TableauDeBordTransporteur({super.key});

  @override
  ConsumerState<TableauDeBordTransporteur> createState() =>
      _TableauDeBordTransporteurState();
}

class _TableauDeBordTransporteurState
    extends ConsumerState<TableauDeBordTransporteur> {
  int indexNavigation = 0;
  bool estDisponible = true;
  bool _chargementDisponibilite = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final transporteurAsync = ref.read(currentTransporteurProvider);
      transporteurAsync.whenData((t) {
        if (t != null && mounted) {
          setState(() => estDisponible = t.disponible);
          // Vérification d'expiration de l'abonnement
          _verifierExpirationAbonnement(t.dateFinAbonnement);
        }
      });

      // Démarrer le tracker GPS
      ref.read(gpsTrackerProvider).startTracking();
    });
  }

  void _verifierExpirationAbonnement(DateTime? dateFin) {
    if (dateFin == null) return;
    final now = DateTime.now();
    final joursRestants = dateFin.difference(now).inDays;

    if (joursRestants <= 0) {
      // Abonnement expiré
      ServiceNotification.afficherNotification(
        titre: 'Abonnement expiré',
        message:
            'Votre abonnement est terminé. Renouvelez-le pour continuer à recevoir des courses.',
        type: 'alerte',
      );
    } else if (joursRestants <= 3) {
      // Expire bientôt
      ServiceNotification.afficherNotification(
        titre: 'Abonnement bientôt expiré',
        message:
            'Votre abonnement expire dans $joursRestants jour(s). Pensez à le renouveler.',
        type: 'alerte',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final statsRevenus = ref.watch(statsRevenusProvider);
    final mesCoursesAsync = ref.watch(fluxMesCoursesProvider);
    final transporteurAsync = ref.watch(currentTransporteurProvider);
    final transporteur = transporteurAsync.valueOrNull;
    final documentsValides = transporteur?.documentsValides ?? false;

    // ✅ PILIER 4: DISPATCH AUTOMATIQUE - Écoute de l'attribution (Subit l'attribution)
    ref.listen<Course?>(activeCourseProvider, (previous, next) {
      if (next != null && previous?.id != next.id && next.statut == StatutCourse.attribue) {
        // Déclencher une alerte sonore/système
        ServiceNotification.afficherNotification(
          titre: 'Nouvelle course attribuée !',
          message:
              'Le système vous a sélectionné pour une nouvelle mission. Prenez la route !',
          type: 'succes',
        );

        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => PopupPropositionCourse(course: next),
        );
      }
    });

    // Redirection si l'abonnement est expiré
    if (transporteur != null && !transporteur.abonnementValide) {
      return const PageAbonnement();
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      floatingActionButton: const BoutonCombi(),
      bottomNavigationBar: _buildBottomNav(),
      body: FondPremiumAnime(
        safeArea: true,
        child: PageResponsive(
          child: IndexedStack(
            index: indexNavigation,
            children: [
              // 0: Accueil
              RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(fluxMesCoursesProvider);
                  ref.invalidate(fluxMesRevenusProvider);
                },
                child: _buildDashboardAccueil(
                    statsRevenus, mesCoursesAsync, documentsValides),
              ),
              // 1: Demandes
              const MarcheDemandes(),
              // 2: Suivi
              const NavigationTransporteur(),
              // 3: Notifications
              const NotificationsPage(),
              // 4: Profil
              const ProfilTransporteur(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDashboardAccueil(Map<String, double> statsRevenus,
      AsyncValue<List<Course>> mesCoursesAsync, bool documentsValides) {
    final transporteurAsync = ref.watch(currentTransporteurProvider);
    final utilisateur = ref.watch(serviceAuthentificationProvider).utilisateur;

    return transporteurAsync.when(
      loading: () => const Center(child: LoaderPremium()),
      error: (err, _) => Center(
          child: Text("Oups ! Chargement impossible : $err",
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)))),
      data: (transporteur) {
        final nomAffichage = transporteur != null
            ? transporteur.prenom
            : (utilisateur?.displayName ?? "Transporteur");
        final photoUrl = transporteur?.photo ?? utilisateur?.photoURL ?? "";

        return SingleChildScrollView(
          padding: EdgeInsets.all(TaillesApp.margePage),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // BANNIERE DE VALIDATION
              if (!documentsValides)
                Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16),
                    border:
                        Border.all(color: Colors.red.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded,
                          color: Colors.red, size: 32),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Compte en attente de validation",
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).colorScheme.onSurface)),
                            const SizedBox(height: 4),
                            Text(
                              "Vos documents sont en cours d'examen par l'administration.",
                              style: TextStyle(
                                  fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

              // HEADER
              Row(
                children: [
                  Container(
                    decoration:
                        BoxDecoration(shape: BoxShape.circle, boxShadow: [
                      BoxShadow(
                        color: CouleursApp.primaire.withValues(alpha: 0.2),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      )
                    ]),
                    child: CircleAvatar(
                      radius: 28,
                      backgroundColor: CouleursApp.secondaire.withValues(alpha: 0.5),
                      backgroundImage:
                          photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
                      child: photoUrl.isEmpty
                          ? const Icon(Iconsax.truck_fast_copy,
                              color: CouleursApp.accent, size: 28)
                          : null,
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _salutationDuJour(),
                          style: GoogleFonts.inter(
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6), fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          nomAffichage,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.5,
                              color: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Theme.of(context).colorScheme.onSurface
                                  : CouleursApp.textePrincipal),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Switch(
                        value: estDisponible,
                        activeThumbColor: Colors.white,
                        activeTrackColor: CouleursApp.succes,
                        inactiveThumbColor: Colors.white,
                        inactiveTrackColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2),
                        onChanged: _chargementDisponibilite
                            ? null
                            : (value) async {
                                setState(() {
                                  estDisponible = value;
                                  _chargementDisponibilite = true;
                                });
                                try {
                                  await ref
                                      .read(transporteurActionsProvider)
                                      .changerDisponibilite(value);
                                } catch (_) {
                                  if (mounted) {
                                    setState(() => estDisponible = !value);
                                  }
                                } finally {
                                  if (mounted) {
                                    setState(() =>
                                        _chargementDisponibilite = false);
                                  }
                                }
                              },
                      ),
                      Text(
                        estDisponible ? 'Disponible' : 'Indisponible',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: estDisponible
                              ? CouleursApp.succes
                              : Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.4),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 30),

              // BANNER REVENUS
              GlassContainer(
                width: double.infinity,
                padding: const EdgeInsets.all(25),
                opaciteFond: 0.15,
                customBorder: Border.all(
                    color: CouleursApp.primaire.withValues(alpha: 0.3)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Revenus du jour",
                      style: GoogleFonts.inter(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                          fontSize: 16,
                          fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "${(statsRevenus['ceJour'] ?? 0).toStringAsFixed(0)} FCFA",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1.0,
                        shadows: [
                          Shadow(
                            color: CouleursApp.primaire.withValues(alpha: 0.5),
                            blurRadius: 20,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 15),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.circle,
                            color: estDisponible
                                ? CouleursApp.succes
                                : CouleursApp.erreur,
                            size: 12,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            estDisponible
                                ? "Disponible pour une course"
                                : "Actuellement indisponible",
                            style: GoogleFonts.inter(
                                color: Theme.of(context).colorScheme.onSurface,
                                fontWeight: FontWeight.w600,
                                fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // ✅ INNOVATION 4.3: CARTE "CONSEIL DU JOUR" - Astuces prédictives
              _buildConseilDuJour(statsRevenus),

              const SizedBox(height: 35),

              // ACTIONS RAPIDES
              Text(
                "Actions rapides",
                style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Theme.of(context).colorScheme.onSurface
                        : CouleursApp.textePrincipal),
              ),
              const SizedBox(height: 15),

              // Grille 2×2 sans GridView : le childAspectRatio fixe (1.4)
              // imposait une hauteur ~105 px, trop faible pour un titre
              // sur 2 lignes (ou une police système agrandie) → overflow.
              // IntrinsicHeight + stretch : la hauteur suit le contenu et
              // les 2 cartes d'une même ligne restent alignées.
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: CarteInformation(
                        compacte: true,
                        titre: "Courses disponibles",
                        icone: Icons.map,
                        auClic: () => setState(() => indexNavigation = 1),
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: CarteInformation(
                        compacte: true,
                        titre: "Portefeuille",
                        icone: Icons.account_balance_wallet,
                        auClic: () =>
                            context.push(RoutesApplication.portefeuille),
                      ),
                    ),
                  ],
                ),
              ),
              // 3 px + marges verticales des cartes (6 + 6) = 15 px,
              // identique à l'espacement horizontal.
              const SizedBox(height: 3),
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: CarteInformation(
                        compacte: true,
                        titre: "Historique",
                        icone: Icons.history,
                        auClic: () => context.push(
                            RoutesApplication.historiqueCoursesTransporteur),
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: CarteInformation(
                        compacte: true,
                        titre: "Documents",
                        icone: Icons.description,
                        auClic: () => context.push("/documents"),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 3),
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: CarteInformation(
                        compacte: true,
                        titre: "Abonnement",
                        icone: Icons.workspace_premium,
                        auClic: () =>
                            context.push(RoutesApplication.abonnement),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 35),

              // DERNIERES COURSES
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Dernières courses",
                      style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.5,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Theme.of(context).colorScheme.onSurface
                              : CouleursApp.textePrincipal)),
                  TextButton(
                      onPressed: () {
                        context.push(
                            RoutesApplication.historiqueCoursesTransporteur);
                      },
                      child: Text("Voir tout",
                          style:
                              GoogleFonts.inter(fontWeight: FontWeight.w600))),
                ],
              ),
              const SizedBox(height: 15),

              mesCoursesAsync.when(
                  loading: () => Column(
                        children: <Widget>[
                          ...List.generate(
                              3,
                              (index) => const GlassContainer(
                                    height: 80,
                                    margin: EdgeInsets.only(bottom: 10),
                                    opaciteFond: 0.05,
                                    child: SizedBox.shrink(),
                                  )
                                      .animate(
                                          onPlay: (controller) =>
                                              controller.repeat())
                                      .shimmer(
                                          color: Theme.of(context).colorScheme.onSurface
                                              .withValues(alpha: 0.08),
                                          duration: 1.5.seconds)),
                        ],
                      ),
                  error: (err, _) => Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.cloud_off_outlined,
                            size: 20,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.6)),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            "Le chargement a échoué. Vérifiez votre connexion, puis réessayez.",
                            style: TextStyle(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withValues(alpha: 0.6)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  data: (courses) {
                    if (courses.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          children: [
                            Icon(Icons.inbox_outlined,
                                size: 40,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withValues(alpha: 0.4)),
                            const SizedBox(height: 12),
                            Text(
                              "Aucune course pour le moment.",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: Theme.of(context).colorScheme.onSurface,
                                  fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Vos prochaines courses apparaîtront ici.",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withValues(alpha: 0.6)),
                            ),
                          ],
                        ),
                      );
                    }

                    return Column(
                      children: <Widget>[
                        ...courses.take(3).map<Widget>((course) {
                          return _creationCarteTrajet(
                              "${course.adresseDepart} → ${course.adresseArrivee}",
                              course.typeMarchandise,
                              "${course.prixEstime.toStringAsFixed(0)} FCFA",
                              Icons.local_shipping,
                              CouleursApp.primaire);
                        }),
                      ],
                    );
                  }),

              const SizedBox(height: 30),
            ],
          ),
        );
      },
    );
  }

  Widget _creationCarteTrajet(String titre, String sousTitre, String prix,
      IconData icone, Color couleurIcone) {
    return Padding(
        padding: const EdgeInsets.only(bottom: 12.0),
        child: GlassContainer(
          padding: const EdgeInsets.all(18),
          opaciteFond: 0.08,
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: couleurIcone.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(icone, color: couleurIcone, size: 26),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(titre,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 6),
                    Text(sousTitre,
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6), fontSize: 13)),
                  ],
                ),
              ),
              Text(prix,
                  style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      color: CouleursApp.primaire,
                      fontSize: 15)),
            ],
          ),
        ));
  }

  // ==========================================
  // ✅ INNOVATION 4.3: CONSEIL DU JOUR
  // Carte de conseil prédictif basée sur les stats du transporteur.
  // Adapte le message selon l'heure et les revenus de la journée.
  // ==========================================
  Widget _buildConseilDuJour(Map<String, double> statsRevenus) {
    final heure = DateTime.now().hour;
    final revenus = statsRevenus['ceJour'] ?? 0;
    final conseil = _determinerConseil(heure, revenus);

    return GlassContainer(
      padding: const EdgeInsets.all(18),
      opaciteFond: 0.06,
      customBorder: Border.all(
          color: conseil.couleur.withValues(alpha: 0.25), width: 1.5),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: conseil.couleur.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(conseil.icone, color: conseil.couleur, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      "Conseil du jour",
                      style: GoogleFonts.inter(
                        color: conseil.couleur,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: conseil.couleur.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text("IA",
                          style: GoogleFonts.inter(
                              color: conseil.couleur,
                              fontSize: 9,
                              fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  conseil.titre,
                  style: GoogleFonts.inter(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                      fontSize: 14),
                ),
                const SizedBox(height: 2),
                Text(
                  conseil.description,
                  style: GoogleFonts.inter(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6), fontSize: 12, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(delay: 400.ms, duration: 300.ms)
        .slideY(begin: 0.1, end: 0);
  }

  _ConseilJour _determinerConseil(int heure, double revenus) {
    if (heure >= 6 && heure < 9) {
      return const _ConseilJour(
          icone: Icons.wb_twilight,
          titre: "C'est l'heure de pointe matinale !",
          description:
              "Les courses vers les bureaux et marchés sont très demandées entre 7h et 9h. Restez disponible !",
          couleur: Colors.orange);
    } else if (heure >= 9 && heure < 12) {
      return const _ConseilJour(
          icone: Icons.inventory_2_outlined,
          titre: "Créneau commercial optimal",
          description:
              "Les courses B2B sont fréquentes le matin. Concentrez-vous sur les zones industrielles.",
          couleur: CouleursApp.primaire);
    } else if (heure >= 12 && heure < 14) {
      return const _ConseilJour(
          icone: Icons.local_cafe_outlined,
          titre: "Pause méritée !",
          description:
              "Moins de demandes sur le créneau déjeuner. Profitez-en pour vous reposer ou refaire le plein.",
          couleur: CouleursApp.accent);
    } else if (heure >= 14 && heure < 18) {
      return const _ConseilJour(
          icone: Icons.local_shipping_outlined,
          titre: "L'après-midi est propice aux longues courses",
          description:
              "Les trajets interurbains et courses commerciales sont fréquents entre 14h-18h.",
          couleur: CouleursApp.primaireNeon);
    } else if (heure >= 18 && heure < 22) {
      return _ConseilJour(
        icone: Icons.nights_stay_outlined,
        titre: revenus > 10000
            ? "Excellente journée !"
            : "Pointe du soir — forte demande",
        description: revenus > 10000
            ? "Vous avez gagné ${revenus.toInt()} FCFA aujourd'hui ! Continuez sur cette lancée."
            : "Les demandes augmentent après 18h. C'est le moment d'augmenter vos revenus.",
        couleur: revenus > 10000 ? CouleursApp.succes : Colors.deepOrange,
      );
    } else {
      return _ConseilJour(
        icone: revenus > 5000 ? Icons.auto_awesome : Icons.bedtime_outlined,
        titre: revenus > 5000
            ? "Belle journée : ${(revenus / 1000).toStringAsFixed(0)}k FCFA !"
            : "Temps calme",
        description: revenus > 5000
            ? "Superbe performance ! Reposez-vous bien pour être au top demain."
            : "Peu de demandes la nuit. Rechargez votre énergie pour une journée chargée.",
        couleur: revenus > 5000 ? Colors.amber : Colors.blueGrey,
      );
    }
  }

  // ==========================================
  // BOTTOM NAVIGATION
  // ==========================================
  Widget _buildBottomNav() {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surface.withValues(alpha: 0.92),
        border: Border(top: BorderSide(color: scheme.outlineVariant)),
        boxShadow: [
          BoxShadow(
              color: scheme.shadow.withValues(alpha: 0.08),
              blurRadius: 30,
              offset: const Offset(0, -10))
        ],
      ),
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: BottomNavigationBar(
            currentIndex: indexNavigation,
            onTap: (index) => setState(() => indexNavigation = index),
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.transparent,
            selectedItemColor: scheme.primary,
            unselectedItemColor: scheme.onSurfaceVariant,
            showUnselectedLabels: true,
            selectedLabelStyle:
                const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            unselectedLabelStyle:
                const TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
            elevation: 0,
            items: const [
              BottomNavigationBarItem(
                  icon: Icon(Iconsax.home_2_copy),
                  activeIcon: Icon(Iconsax.home_2),
                  label: "Accueil"),
              BottomNavigationBarItem(
                  icon: Icon(Iconsax.box_search_copy),
                  activeIcon: Icon(Iconsax.box_search),
                  label: "Marché"),
              BottomNavigationBarItem(
                  icon: Icon(Iconsax.routing_copy),
                  activeIcon: Icon(Iconsax.routing),
                  label: "En Cours"),
              BottomNavigationBarItem(
                  icon: Icon(Iconsax.notification_bing_copy),
                  activeIcon: Icon(Iconsax.notification_bing),
                  label: "Alertes"),
              BottomNavigationBarItem(
                  icon: Icon(Iconsax.user_copy),
                  activeIcon: Icon(Iconsax.user),
                  label: "Profil"),
            ],
          ),
        ),
      ),
    );
  }
}

/// Modèle de données pour la carte "Conseil du jour"
class _ConseilJour {
  final IconData icone;
  final String titre;
  final String description;
  final Color couleur;

  const _ConseilJour({
    required this.icone,
    required this.titre,
    required this.description,
    required this.couleur,
  });
}
