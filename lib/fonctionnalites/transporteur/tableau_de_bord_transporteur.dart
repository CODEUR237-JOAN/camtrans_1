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
import 'package:update_camtrans/coeur/constantes/statuts.dart';
import '../../coeur/etat/transporteur_provider.dart';
import '../../coeur/etat/textes_app_provider.dart';
import 'package:update_camtrans/coeur/routes/routes.dart';
import 'package:update_camtrans/coeur/etat/gps_provider.dart';
import 'package:update_camtrans/services/service_authentification.dart';
import 'package:update_camtrans/modeles/course.dart';

import 'package:update_camtrans/fonctionnalites/transporteur/marche_demandes.dart';
import 'package:update_camtrans/fonctionnalites/transporteur/navigation.dart';
import 'package:update_camtrans/fonctionnalites/notifications/notifications.dart';
import 'package:update_camtrans/coeur/widgets/assistant_vocal_widget.dart';
import 'package:update_camtrans/services/service_notification.dart';
import 'profil.dart';
import 'package:update_camtrans/coeur/widgets/page_responsive.dart';
import 'package:update_camtrans/fonctionnalites/transporteur/widgets/popup_proposition_course.dart';
import 'page_abonnement.dart';
import 'package:update_camtrans/coeur/widgets/loader_premium.dart';

class TableauDeBordTransporteur extends ConsumerStatefulWidget {
  const TableauDeBordTransporteur({super.key});

  @override
  ConsumerState<TableauDeBordTransporteur> createState() => _TableauDeBordTransporteurState();
}

class _TableauDeBordTransporteurState extends ConsumerState<TableauDeBordTransporteur> {
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
        titre: '⚠️ Abonnement expiré',
        message: 'Votre abonnement est terminé. Renouvelez-le pour continuer à recevoir des courses.',
        type: 'alerte',
      );
    } else if (joursRestants <= 3) {
      // Expire bientôt
      ServiceNotification.afficherNotification(
        titre: '🕔 Abonnement bientôt expiré',
        message: 'Votre abonnement expire dans $joursRestants jour(s). Pensez à le renouveler.',
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

    // ✅ PHASE 4: DISPATCH AUTOMATIQUE - Écoute des propositions de courses
    ref.listen<AsyncValue<Course?>>(fluxCourseProposeeProvider, (previous, next) {
      if (next.hasValue && next.value != null) {
        final courseProposee = next.value!;
        // Éviter d'afficher plusieurs fois la même proposition
        if (previous?.value?.id != courseProposee.id) {
          // Déclencher une alerte sonore/système
          ServiceNotification.afficherNotification(
            titre: '🚨 NOUVELLE COURSE !',
            message: 'Une nouvelle demande vous a été affectée. Acceptez vite !',
            type: 'succes',
          );

          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (ctx) => PopupPropositionCourse(course: courseProposee),
          );
        }
      }
    });

    // Redirection si l'abonnement est expiré
    if (transporteur != null && !transporteur.abonnementValide) {
      return const PageAbonnement();
    }

    return Scaffold(
      backgroundColor: const Color(0xFF08111F),
      floatingActionButton: const BoutonAssistantVocal(),
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
              child: _buildDashboardAccueil(statsRevenus, mesCoursesAsync, documentsValides),
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

  Widget _buildDashboardAccueil(Map<String, double> statsRevenus, AsyncValue<List<Course>> mesCoursesAsync, bool documentsValides) {
    final transporteurAsync = ref.watch(currentTransporteurProvider);
    final utilisateur = ref.watch(serviceAuthentificationProvider).utilisateur;
    final textes = ref.watch(textesAppProvider);

    return transporteurAsync.when(
      loading: () => Center(child: LoaderPremium()),
      error: (err, _) => Center(child: Text("Oups ! Chargement impossible : $err", style: const TextStyle(color: Colors.white70))),
      data: (transporteur) {
        final nomAffichage = transporteur != null ? transporteur.prenom : (utilisateur?.displayName ?? "Transporteur");
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
                    border: Border.all(color: Colors.red.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 32),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Compte en attente de validation", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                            const SizedBox(height: 4),
                            const Text(
                              "Vos documents sont en cours d'examen par l'administration.",
                              style: TextStyle(fontSize: 12, color: Colors.white70),
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
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: CouleursApp.primaire.withValues(alpha: 0.2),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        )
                      ]
                    ),
                    child: CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.orange.withValues(alpha: 0.1),
                      backgroundImage: photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
                      child: photoUrl.isEmpty ? const Icon(Iconsax.truck_fast_copy, color: Colors.orange, size: 28) : null,
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Bienvenue,",
                          style: GoogleFonts.inter(color: Colors.white60, fontSize: 14),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          nomAffichage,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w700, letterSpacing: -0.5, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : CouleursApp.textePrincipal),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: estDisponible,
                    activeThumbColor: Colors.white,
                    activeTrackColor: Colors.green,
                    inactiveThumbColor: Colors.white,
                    inactiveTrackColor: Colors.white.withValues(alpha: 0.2),
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
                                setState(() => _chargementDisponibilite = false);
                              }
                            }
                          },
                  ),
                ],
              ),
              const SizedBox(height: 30),

              // BANNER REVENUS
              GlassContainer(
                width: double.infinity,
                padding: const EdgeInsets.all(25),
                opaciteFond: 0.15,
                customBorder: Border.all(color: CouleursApp.primaire.withValues(alpha: 0.3)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Revenus du jour",
                      style: GoogleFonts.inter(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "${(statsRevenus['ceJour'] ?? 0).toStringAsFixed(0)} FCFA",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        color: Colors.white, 
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
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.circle,
                            color: estDisponible ? CouleursApp.succes : CouleursApp.erreur,
                            size: 12,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            estDisponible ? "En ligne et disponible" : "Hors ligne",
                            style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 35),

              // STATISTIQUES
              Text(
                "Statistiques",
                style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700, letterSpacing: -0.5, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : CouleursApp.textePrincipal),
              ),
              const SizedBox(height: 15),

              mesCoursesAsync.when(
                loading: () => Column(
                  children: <Widget>[
                    ...List.generate(2, (index) => Container(
                      height: 100, margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                    ).animate(onPlay: (controller) => controller.repeat()).shimmer(color: Colors.white.withValues(alpha: 0.08), duration: 1.5.seconds)),
                  ],
                ),
                error: (err, _) => const SizedBox.shrink(),
                data: (courses) {
                  int livrees = courses.where((c) => c.statut == StatutCourse.arriveDestination || c.statut == StatutCourse.terminee).length;
                  int enAttente = courses.where((c) => StatutCourse.estActive(c.statut)).length;
                  
                  return Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: CarteInformation(titre: "Courses", valeur: "${courses.length}", icone: Icons.local_shipping),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: CarteInformation(titre: "Livrées", valeur: "$livrees", icone: Icons.check_circle, couleurIcone: Colors.green, couleurValeur: Colors.green),
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),
                      Row(
                        children: [
                          Expanded(
                            child: CarteInformation(titre: "En cours", valeur: "$enAttente", icone: Icons.schedule, couleurIcone: Colors.orange, couleurValeur: Colors.orange),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: CarteInformation(titre: "Note", valeur: "4.9 ", icone: Icons.star, couleurIcone: Colors.amber, couleurValeur: Colors.amber),
                          ),
                        ],
                      ),
                    ],
                  );
                }
              ),

              const SizedBox(height: 24),

              // ✅ INNOVATION 4.3: CARTE "CONSEIL DU JOUR" - Astuces prédictives
              _buildConseilDuJour(statsRevenus),

              const SizedBox(height: 35),

              // ACTIONS RAPIDES
              Text(
                "Actions rapides",
                style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700, letterSpacing: -0.5, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : CouleursApp.textePrincipal),
              ),
              const SizedBox(height: 15),

              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 15,
                mainAxisSpacing: 15,
                childAspectRatio: 1.4,
                children: [
                  CarteInformation(
                    titre: "Courses\ndisponibles",
                    icone: Icons.map,
                    auClic: () => setState(() => indexNavigation = 1),
                  ).animate(onPlay: (controller) => controller.repeat(reverse: true)).moveY(begin: -2, end: 2, duration: 2.seconds).scale(delay: 900.ms, curve: Curves.easeOutBack),
                  CarteInformation(
                    titre: "Revenus",
                    icone: Icons.account_balance_wallet,
                    auClic: () => context.push("/revenus"),
                  ).animate(onPlay: (controller) => controller.repeat(reverse: true)).moveY(begin: 2, end: -2, duration: 2.seconds).scale(delay: 1000.ms, curve: Curves.easeOutBack),
                  CarteInformation(
                    titre: "Portefeuille",
                    icone: Icons.wallet,
                    auClic: () => context.push("/portefeuille"),
                  ).animate(onPlay: (controller) => controller.repeat(reverse: true)).moveY(begin: -2, end: 2, duration: 2.seconds).scale(delay: 1100.ms, curve: Curves.easeOutBack),
                  CarteInformation(
                    titre: "Documents",
                    icone: Icons.description,
                    auClic: () => context.push("/documents"),
                  ).animate(onPlay: (controller) => controller.repeat(reverse: true)).moveY(begin: 2, end: -2, duration: 2.seconds).scale(delay: 1200.ms, curve: Curves.easeOutBack),
                ],
              ),

              const SizedBox(height: 35),

              // DERNIERES COURSES
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Dernières courses", style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700, letterSpacing: -0.5, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : CouleursApp.textePrincipal)),
                  TextButton(
                      onPressed: () {
                        context.push(RoutesApplication.historiqueLivraisonsTransporteur);
                      },
                      child: Text("Voir tout", style: GoogleFonts.inter(fontWeight: FontWeight.w600))),
                ],
              ),
              const SizedBox(height: 15),

              mesCoursesAsync.when(
                loading: () => Column(
                  children: <Widget>[
                    ...List.generate(3, (index) => GlassContainer(
                      height: 80, margin: const EdgeInsets.only(bottom: 10),
                      opaciteFond: 0.05,
                      child: const SizedBox.shrink(),
                    ).animate(onPlay: (controller) => controller.repeat()).shimmer(color: Colors.white.withValues(alpha: 0.08), duration: 1.5.seconds)),
                  ],
                ),
                error: (err, _) => Text("Hmm, petit souci de chargement : $err 🔧"),
                data: (courses) {
                  if (courses.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(20.0),
                      child: Text("Aucune course assignée.", style: TextStyle(color: Colors.white54)),
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
                          Colors.blue
                        );
                      }),
                    ],
                  );
                }
              ),

              const SizedBox(height: 30),
            ],
          ),
        );
      },
    );
  }

  Widget _creationCarteTrajet(String titre, String sousTitre, String prix, IconData icone, Color couleurIcone) {
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
                Text(titre, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 6),
                Text(sousTitre, style: const TextStyle(color: Colors.white60, fontSize: 13)),
              ],
            ),
          ),
          Text(prix, style: const TextStyle(fontWeight: FontWeight.w900, color: CouleursApp.primaire, fontSize: 15)),
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
      customBorder: Border.all(color: conseil.couleur.withValues(alpha: 0.25), width: 1.5),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: conseil.couleur.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Text(conseil.emoji, style: const TextStyle(fontSize: 22)),
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
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: conseil.couleur.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text("IA", style: GoogleFonts.inter(color: conseil.couleur, fontSize: 9, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  conseil.titre,
                  style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 2),
                Text(
                  conseil.description,
                  style: GoogleFonts.inter(color: Colors.white60, fontSize: 12, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 400.ms, duration: 300.ms).slideY(begin: 0.1, end: 0);
  }

  _ConseilJour _determinerConseil(int heure, double revenus) {
    if (heure >= 6 && heure < 9) {
      return _ConseilJour(emoji: "🌅", titre: "C'est l'heure de pointe matinale !", description: "Les courses vers les bureaux et marchés sont très demandées entre 7h et 9h. Restez disponible !", couleur: Colors.orange);
    } else if (heure >= 9 && heure < 12) {
      return _ConseilJour(emoji: "📦", titre: "Créneau commercial optimal", description: "Les livraisons B2B sont fréquentes le matin. Concentrez-vous sur les zones industrielles.", couleur: CouleursApp.primaire);
    } else if (heure >= 12 && heure < 14) {
      return _ConseilJour(emoji: "☕", titre: "Pause méritée !", description: "Moins de demandes sur le créneau déjeuner. Profitez-en pour vous reposer ou refaire le plein.", couleur: CouleursApp.accent);
    } else if (heure >= 14 && heure < 18) {
      return _ConseilJour(emoji: "🚛", titre: "L'après-midi est propice aux longues courses", description: "Les trajets interurbains et livraisons commerciales sont fréquents entre 14h-18h.", couleur: CouleursApp.primaireNeon);
    } else if (heure >= 18 && heure < 22) {
      return _ConseilJour(
        emoji: "🌆",
        titre: revenus > 10000 ? "Excellente journée ! 🔥" : "Pointe du soir — forte demande",
        description: revenus > 10000 ? "Vous avez gagné ${revenus.toInt()} FCFA aujourd'hui ! Continuez sur cette lancée." : "Les demandes augmentent après 18h. C'est le moment d'augmenter vos revenus.",
        couleur: revenus > 10000 ? CouleursApp.succes : Colors.deepOrange,
      );
    } else {
      return _ConseilJour(
        emoji: revenus > 5000 ? "🌟" : "💤",
        titre: revenus > 5000 ? "Belle journée : ${(revenus / 1000).toStringAsFixed(0)}k FCFA !" : "Temps calme",
        description: revenus > 5000 ? "Superbe performance ! Reposez-vous bien pour être au top demain." : "Peu de demandes la nuit. Rechargez votre énergie pour une journée chargée.",
        couleur: revenus > 5000 ? Colors.amber : Colors.blueGrey,
      );
    }
  }

  // ==========================================
  // BOTTOM NAVIGATION
  // ==========================================
  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.8),
        boxShadow: [BoxShadow(color: Colors.white.withValues(alpha: 0.07), blurRadius: 30, offset: const Offset(0, -10))],
      ),
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: BottomNavigationBar(
            currentIndex: indexNavigation,
            onTap: (index) => setState(() => indexNavigation = index),
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.transparent,
            selectedItemColor: CouleursApp.primaire,
            unselectedItemColor: CouleursApp.texteSecondaire,
            showUnselectedLabels: true,
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
            elevation: 0,
            items: const [
              BottomNavigationBarItem(icon: Icon(Iconsax.home_2_copy), activeIcon: Icon(Iconsax.home_2), label: "Accueil"),
              BottomNavigationBarItem(icon: Icon(Iconsax.box_search_copy), activeIcon: Icon(Iconsax.box_search), label: "Marché"),
              BottomNavigationBarItem(icon: Icon(Iconsax.routing_copy), activeIcon: Icon(Iconsax.routing), label: "En Cours"),
              BottomNavigationBarItem(icon: Icon(Iconsax.notification_bing_copy), activeIcon: Icon(Iconsax.notification_bing), label: "Alertes"),
              BottomNavigationBarItem(icon: Icon(Iconsax.user_copy), activeIcon: Icon(Iconsax.user), label: "Profil"),
            ],
          ),
        ),
      ),
    );
  }
}

/// Modèle de données pour la carte "Conseil du jour"
class _ConseilJour {
  final String emoji;
  final String titre;
  final String description;
  final Color couleur;

  const _ConseilJour({
    required this.emoji,
    required this.titre,
    required this.description,
    required this.couleur,
  });
}
