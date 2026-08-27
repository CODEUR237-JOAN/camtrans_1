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
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:update_camtrans/coeur/constantes/statuts.dart';
import 'package:update_camtrans/coeur/etat/transporteur_provider.dart';
import 'package:update_camtrans/coeur/routes/routes.dart';
import 'package:update_camtrans/coeur/etat/gps_provider.dart';
import 'package:update_camtrans/services/service_authentification.dart';
import 'package:update_camtrans/modeles/course.dart';

import 'navigation.dart';
import 'package:update_camtrans/fonctionnalites/notifications/notifications.dart';
import 'profil.dart';
import 'package:update_camtrans/coeur/widgets/page_responsive.dart';

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
    // Charger la disponibilité depuis Firestore au démarrage
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final transporteurAsync = ref.read(currentTransporteurProvider);
      transporteurAsync.whenData((t) {
        if (t != null && mounted) {
          setState(() => estDisponible = t.disponible);
        }
      });
      
      // Démarrer le tracker GPS
      ref.read(gpsTrackerProvider).startTracking();
    });
  }

  @override
  Widget build(BuildContext context) {
    final statsRevenus = ref.watch(statsRevenusProvider);
    final mesCoursesAsync = ref.watch(fluxMesCoursesProvider);
    final transporteurAsync = ref.watch(currentTransporteurProvider);
    final documentsValides = transporteurAsync.valueOrNull?.documentsValides ?? false;

    return Scaffold(
      backgroundColor: CouleursApp.fond,
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

    return transporteurAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text("Erreur: $err")),
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
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: Colors.red.shade700, size: 32),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Compte en attente de validation", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red.shade900)),
                            const SizedBox(height: 4),
                            Text(
                              "Vos documents sont en cours d'examen par l'administration. Vous ne pouvez pas encore accepter de courses.",
                              style: TextStyle(fontSize: 12, color: Colors.red.shade700),
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
                          style: GoogleFonts.inter(color: CouleursApp.texteSecondaire, fontSize: 14),
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
                    inactiveTrackColor: Colors.grey.shade300,
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
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(25),
                decoration: BoxDecoration(
                  gradient: CouleursApp.degradePrincipal,
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: CouleursApp.primaire.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    )
                  ]
                ),
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
                      style: GoogleFonts.inter(color: Colors.white, fontSize: 34, fontWeight: FontWeight.w800, letterSpacing: -1.0),
                    ),
                    const SizedBox(height: 15),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.circle,
                            color: estDisponible ? Colors.greenAccent : Colors.redAccent,
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
                    ).animate(onPlay: (controller) => controller.repeat()).shimmer(color: Colors.grey.shade200, duration: 1.5.seconds)),
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
                    ...List.generate(3, (index) => Container(
                      height: 80, margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                    ).animate(onPlay: (controller) => controller.repeat()).shimmer(color: Colors.grey.shade200, duration: 1.5.seconds)),
                  ],
                ),
                error: (err, _) => Text("Erreur: $err"),
                data: (courses) {
                  if (courses.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(20.0),
                      child: Text("Aucune course assignée.", style: TextStyle(color: Colors.grey)),
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
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 5),
          )
        ]
      ),
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
                Text(sousTitre, style: const TextStyle(color: CouleursApp.texteSecondaire, fontSize: 13)),
              ],
            ),
          ),
          Text(prix, style: const TextStyle(fontWeight: FontWeight.w900, color: CouleursApp.primaire, fontSize: 15)),
        ],
      ),
    );
  }

  // ==========================================
  // BOTTOM NAVIGATION
  // ==========================================
  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.8),
        boxShadow: [BoxShadow(color: CouleursApp.ombre, blurRadius: 30, offset: const Offset(0, -10))],
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

