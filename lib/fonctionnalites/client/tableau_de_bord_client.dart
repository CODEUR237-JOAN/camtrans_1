import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import 'package:update_camtrans/coeur/etat/course_provider.dart';
import 'package:update_camtrans/coeur/etat/utilisateur_provider.dart';
import 'package:update_camtrans/services/service_gps.dart';
import 'package:update_camtrans/coeur/routes/routes.dart';
import 'package:update_camtrans/modeles/course.dart';
import 'package:update_camtrans/services/service_authentification.dart';
import 'package:update_camtrans/services/service_firestore.dart';

import 'historique.dart';
import 'suivi_transport.dart';
import 'package:update_camtrans/fonctionnalites/notifications/notifications.dart';
import 'profil.dart';
import 'package:update_camtrans/coeur/etat/notification_provider.dart';

import 'package:update_camtrans/coeur/constantes/couleurs.dart';
import 'package:update_camtrans/coeur/constantes/statuts.dart';
import 'package:update_camtrans/coeur/widgets/page_responsive.dart';
import 'package:flutter_animate/flutter_animate.dart';


class TableauDeBordClient extends ConsumerStatefulWidget {
  const TableauDeBordClient({super.key});

  @override
  ConsumerState<TableauDeBordClient> createState() => _TableauDeBordClientState();
}

class _TableauDeBordClientState extends ConsumerState<TableauDeBordClient> {
  int _bottomNavIndex = 0;
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    // Demander les permissions GPS dès l'accueil pour une expérience fluide
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(serviceGpsProvider).verifierPermissions();
    });
  }

  @override
  Widget build(BuildContext context) {
    final coursesAsync = ref.watch(coursesClientProvider);

    return Scaffold(
      backgroundColor: CouleursApp.fond,
      floatingActionButton: _bottomNavIndex == 0 ? _buildIAAssistantFAB() : null,
      bottomNavigationBar: _buildBottomNav(),
      body: SafeArea(
        child: PageResponsive(
          child: IndexedStack(
            index: _bottomNavIndex,
          children: [
            // Onglet 0: Accueil (Tableau de bord dynamique)
            _buildDashboardAccueil(coursesAsync),
            
            // Onglet 1: Demandes (Historique)
            const Historique(),
            
            // Onglet 2: Suivi
            coursesAsync.when(
              data: (courses) {
                final enCours = courses.where((c) => !StatutCourse.estTerminee(c.statut)).toList();
                if (enCours.isEmpty) {
                  return Container(
                    color: Colors.white,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Iconsax.location_copy, size: 80, color: Colors.grey),
                          const SizedBox(height: 20),
                          const Text("Aucune course en cours à suivre", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 10),
                          ElevatedButton(
                            onPressed: () => setState(() => _bottomNavIndex = 0),
                            style: ElevatedButton.styleFrom(backgroundColor: CouleursApp.primaire, foregroundColor: Colors.white),
                            child: const Text("Retour à l'accueil"),
                          )
                        ],
                      ),
                    ),
                  );
                }
                return SuiviTransport(courseId: enCours.first.id, isFullScreen: false);
              },
              loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
              error: (err, stack) => Scaffold(body: Center(child: Text("Erreur: $err"))),
            ),
            
            // Onglet 3: Notifications
            const NotificationsPage(),
            
            // Onglet 4: Profil
            const Profil(),
          ],
        ),
        ),
      ),
    );
  }

  // Contenu du Tableau de Bord Principal
  Widget _buildDashboardAccueil(AsyncValue<List<Course>> coursesAsync) {
    return RefreshIndicator(
      color: CouleursApp.primaire,
      onRefresh: () async {
        ref.invalidate(coursesClientProvider);
      },
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(child: _buildHeader()),
          SliverToBoxAdapter(child: _buildSearchBar()),
          SliverToBoxAdapter(child: _buildMainAction(context)),
          SliverToBoxAdapter(child: _buildQuickServices()),
          
          coursesAsync.when(
            loading: () => SliverToBoxAdapter(child: _buildLoadingState()),
            error: (err, stack) => SliverToBoxAdapter(child: _buildErrorState(err.toString())),
            data: (courses) {
              final enCours = courses.where((c) => !StatutCourse.estTerminee(c.statut)).toList();
              final livrees = courses.where((c) => c.statut == StatutCourse.arriveDestination || c.statut == StatutCourse.terminee).toList();
              
              double depenses = livrees.fold(0, (sum, c) => sum + c.prixFinal);
              if (depenses == 0) {
                 depenses = livrees.fold(0, (sum, c) => sum + c.prixEstime);
              }

              return SliverList(
                delegate: SliverChildListDelegate(<Widget>[
                  _buildStats(livraisons: livrees.length, depenses: depenses, enCours: enCours.length),
                  if (courses.isEmpty) _buildEmptyState(),
                  if (enCours.isNotEmpty) _buildActiveShipment(enCours.first),
                  if (enCours.isNotEmpty) _buildMiniMap(enCours.first),
                  if (courses.isNotEmpty) _buildHistoryList(courses.where((c) => StatutCourse.estTerminee(c.statut)).toList()),
                  const SizedBox(height: 100),
                ]),
              );
            },
          ),
        ],
      ),
    );
  }

  // ==========================================
  // HEADER PREMIUM
  // ==========================================
  Widget _buildHeader() {
    final clientAsync = ref.watch(currentClientProvider);
    final utilisateur = ref.watch(serviceAuthentificationProvider).utilisateur;

    return clientAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (err, stack) => const SizedBox.shrink(),
      data: (client) {
        final String nomAffichage = client != null ? client.prenom : (utilisateur?.displayName ?? "Client");
        final String photoUrl = client?.photo ?? utilisateur?.photoURL ?? "";

        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: CouleursApp.primaire.withValues(alpha: 0.2), blurRadius: 15, offset: const Offset(0, 5))
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 25,
                      backgroundColor: CouleursApp.primaire,
                      backgroundImage: photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
                      child: photoUrl.isEmpty ? const Icon(Iconsax.user_copy, color: Colors.white) : null,
                    ),
                  ),
                  const SizedBox(width: 15),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Bienvenue, $nomAffichage",
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: CouleursApp.textePrincipal),
                      ),
                      const Text(
                        "Prêt à expédier aujourd'hui ?",
                        style: TextStyle(fontSize: 14, color: CouleursApp.texteSecondaire),
                      ),
                    ],
                  ),
                ],
              ),
              Builder(builder: (context) {
                final badgeCount = ref.watch(badgeNotificationsProvider);
                return GestureDetector(
                  onTap: () => setState(() => _bottomNavIndex = 3),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: CouleursApp.surface,
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10)],
                        ),
                        child: const Icon(Iconsax.notification_bing_copy, color: CouleursApp.textePrincipal),
                      ),
                      if (badgeCount > 0)
                        Positioned(
                          top: -5,
                          right: -5,
                          child: Container(
                            padding: const EdgeInsets.all(5),
                            decoration: const BoxDecoration(color: CouleursApp.erreur, shape: BoxShape.circle),
                            child: Text(
                              badgeCount > 9 ? "9+" : "$badgeCount",
                              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                        )
                    ],
                  ),
                );
              })
            ],
          ),
        );
      },
    );
  }

  // ==========================================
  // BARRE DE RECHERCHE GLASSMORPHISM
  // ==========================================
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      child: GestureDetector(
        onTap: () => context.push(RoutesApplication.creerDemande),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(color: CouleursApp.primaireFonce.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, 10))
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: AbsorbPointer(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: "Où souhaitez-vous expédier ?",
                    hintStyle: TextStyle(color: CouleursApp.texteSecondaire.withValues(alpha: 0.8), fontSize: 15),
                    prefixIcon: const Icon(Iconsax.location_copy, color: CouleursApp.primaire),
                    suffixIcon: Container(
                      margin: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: CouleursApp.primaireFonce,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Iconsax.arrow_right_3_copy, color: Colors.white, size: 18),
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================
  // ACTION PRINCIPALE
  // ==========================================
  Widget _buildMainAction(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Material(
        color: Colors.transparent,
        child: Semantics(
          button: true,
          label: "Créer une nouvelle expédition",
          hint: "Double tapez pour réserver un camion",
          child: InkWell(
          onTap: () => context.push(RoutesApplication.creerDemande),
          borderRadius: BorderRadius.circular(24),
          child: Ink(
            padding: const EdgeInsets.symmetric(vertical: 25, horizontal: 20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [CouleursApp.primaire, CouleursApp.primaireFonce],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(color: CouleursApp.primaire.withValues(alpha: 0.4), blurRadius: 20, offset: const Offset(0, 10))
              ]
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Nouvelle Expédition",
                      style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        "Réservez un camion en 2 min",
                        style: TextStyle(color: Colors.white, fontSize: 13),
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Iconsax.truck_fast_copy, color: Colors.white, size: 30),
                ).animate(onPlay: (controller) => controller.repeat(reverse: true)).moveY(begin: -2, end: 2, duration: 2.seconds)
              ],
            ),
          ),
          ), // Fermeture InkWell
        ), // Fermeture Semantics
      ),
    );
  }

  // ==========================================
  // SERVICES RAPIDES
  // ==========================================
  Widget _buildQuickServices() {
    final services = [
      {"icon": Iconsax.box_time_copy, "title": "Mes Colis", "color": CouleursApp.avertissement, "action": () => setState(() => _bottomNavIndex = 1)},
      {"icon": Iconsax.wallet_3_copy, "title": "Paiements", "color": CouleursApp.succes, "action": () => context.push(RoutesApplication.factures)},
      {"icon": Iconsax.document_text_copy, "title": "Factures", "color": CouleursApp.primaire, "action": () => context.push(RoutesApplication.factures)},
      {"icon": Iconsax.support_copy, "title": "Support", "color": CouleursApp.erreur, "action": () => context.push(RoutesApplication.assistantIA)},
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: services.map((s) {
          return GestureDetector(
            onTap: s['action'] as VoidCallback,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: CouleursApp.surface,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 5))],
                  ),
                  child: Icon(s['icon'] as IconData, color: s['color'] as Color, size: 28),
                ).animate(onPlay: (controller) => controller.repeat(reverse: true)).moveY(begin: 0, end: -3, duration: 1.5.seconds).scale(delay: 600.ms),
                const SizedBox(height: 8),
                Text(s['title'] as String, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: CouleursApp.textePrincipal))
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ==========================================
  // STATISTIQUES ANIMÉES
  // ==========================================
  Widget _buildStats({required int livraisons, required double depenses, required int enCours}) {
    // Format des dépenses (k si > 1000)
    String depensesText = depenses >= 1000 ? "${(depenses / 1000).toStringAsFixed(1)}k" : depenses.toStringAsFixed(0);

    return SizedBox(
      height: 100,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          _buildStatCard("Livraisons", livraisons.toString(), Iconsax.box_tick_copy, CouleursApp.succes),
          const SizedBox(width: 15),
          _buildStatCard("Dépenses", depensesText, Iconsax.coin_copy, CouleursApp.avertissement),
          const SizedBox(width: 15),
          _buildStatCard("En cours", enCours.toString(), Iconsax.truck_copy, CouleursApp.primaire),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      width: 155,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: CouleursApp.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.1), blurRadius: 15, offset: const Offset(0, 5))],
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
              Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
            ],
          ),
          const Spacer(),
          Text(title, style: const TextStyle(fontSize: 14, color: CouleursApp.texteSecondaire, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  // ==========================================
  // LIVRAISON EN COURS (TIMELINE)
  // ==========================================
  Widget _buildActiveShipment(Course course) {
    bool isTransit = StatutCourse.estActive(course.statut);
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: CouleursApp.surface,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: CouleursApp.primaireFonce.withValues(alpha: 0.06), blurRadius: 20, offset: const Offset(0, 10))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Expanded(
                  child: Text("Expédition Active", 
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: CouleursApp.textePrincipal),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(color: CouleursApp.avertissement.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
                  child: Text(course.statut, style: const TextStyle(color: CouleursApp.avertissement, fontWeight: FontWeight.bold, fontSize: 12)),
                )
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                _buildTimelineDot(true), _buildTimelineLine(true),
                _buildTimelineDot(true, isCurrent: isTransit), _buildTimelineLine(false),
                _buildTimelineDot(false), _buildTimelineLine(false),
                _buildTimelineDot(false),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Départ", style: TextStyle(color: CouleursApp.texteSecondaire, fontSize: 13)),
                    Text(course.adresseDepart.isNotEmpty ? course.adresseDepart : "Inconnu", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text("Arrivée", style: TextStyle(color: CouleursApp.texteSecondaire, fontSize: 13)),
                    Text(course.adresseArrivee.isNotEmpty ? course.adresseArrivee : "Inconnu", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  ],
                ),
              ],
            ),
            if (course.statut == StatutCourse.recherche || course.statut == StatutCourse.attribue || course.statut == StatutCourse.enRouteDepart) ...[
              const SizedBox(height: 15),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => _confirmerAnnulation(context, course.id),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: CouleursApp.erreur, 
                    side: const BorderSide(color: CouleursApp.erreur),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text("Annuler l'expédition"),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _confirmerAnnulation(BuildContext context, String courseId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Annuler l'expédition"),
        content: const Text("Êtes-vous sûr de vouloir annuler cette expédition ?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Non, garder"),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(serviceFirestoreProvider).modifierDocument(
                collection: 'courses',
                id: courseId,
                donnees: {'statut': StatutCourse.annulee},
              );
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("L'expédition a été annulée.", style: TextStyle(color: Colors.white)), backgroundColor: CouleursApp.erreur));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: CouleursApp.erreur, foregroundColor: Colors.white),
            child: const Text("Oui, annuler"),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineDot(bool active, {bool isCurrent = false}) {
    return Container(
      width: isCurrent ? 20 : 12,
      height: isCurrent ? 20 : 12,
      decoration: BoxDecoration(
        color: active ? CouleursApp.primaire : CouleursApp.fond,
        shape: BoxShape.circle,
        border: isCurrent ? Border.all(color: CouleursApp.primaire.withValues(alpha: 0.3), width: 4) : null,
      ),
      child: active && !isCurrent ? const Icon(Icons.check, size: 8, color: Colors.white) : null,
    );
  }

  Widget _buildTimelineLine(bool active) {
    return Expanded(
      child: Container(height: 3, color: active ? CouleursApp.primaire : CouleursApp.fond),
    );
  }

  // ==========================================
  // CARTE (OPENSTREETMAP) MINIATURE
  // ==========================================
  Widget _buildMiniMap(Course course) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        height: 150,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 15, offset: const Offset(0, 5))],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            FlutterMap(
              mapController: _mapController,
              options: const MapOptions(
                initialCenter: LatLng(4.0511, 9.7679), // Douala center mock
                initialZoom: 6,
              ),
              children: [
                TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.joan.update_camtrans',
          ),
                const MarkerLayer(
                  markers: [
                    Marker(point: LatLng(4.0511, 9.7679), child: Icon(Icons.local_shipping, color: CouleursApp.primaire, size: 30)),
                    Marker(point: LatLng(3.8480, 11.5021), child: Icon(Icons.location_on, color: CouleursApp.erreur, size: 30)),
                  ],
                )
              ],
            ),
            Positioned(
              right: 10,
              top: 10,
              child: FloatingActionButton.small(
                heroTag: "btn_map",
                backgroundColor: CouleursApp.surface,
                onPressed: () => setState(() => _bottomNavIndex = 2),
                child: const Icon(Iconsax.maximize_circle_copy, color: CouleursApp.primaireFonce),
              ),
            )
          ],
        ),
      ),
    );
  }

  // ==========================================
  // HISTORIQUE
  // ==========================================
  Widget _buildHistoryList(List<Course> courses) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Historique Récent", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: CouleursApp.textePrincipal)),
              TextButton(
                  onPressed: () {
                    context.push(RoutesApplication.historique);
                  },
                  child: const Text("Voir tout", style: TextStyle(color: CouleursApp.primaire, fontSize: 14))),
            ],
          ),
          ...courses.take(3).map<Widget>((course) {
            Color statusColor = (course.statut == StatutCourse.arriveDestination || course.statut == StatutCourse.terminee)
                ? CouleursApp.succes
                : course.statut == StatutCourse.annulee
                    ? CouleursApp.erreur
                    : CouleursApp.avertissement;
            return Container(
              margin: const EdgeInsets.only(bottom: 15),
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: CouleursApp.surface,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 5))],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: CouleursApp.fond, borderRadius: BorderRadius.circular(15)),
                    child: const Icon(Iconsax.box_copy, color: CouleursApp.texteSecondaire),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(course.description.isNotEmpty ? course.description : "Marchandise", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 4),
                        Text("${course.adresseDepart}  ${course.adresseArrivee}", style: const TextStyle(fontSize: 13, color: CouleursApp.texteSecondaire), overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text("${course.prixEstime} FCFA", style: const TextStyle(fontWeight: FontWeight.bold, color: CouleursApp.textePrincipal, fontSize: 14)),
                      const SizedBox(height: 5),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                        child: Text(StatutCourse.libelle(course.statut), style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold)),
                      )
                    ],
                  )
                ],
              ),
            );
          })
        ],
      ),
    );
  }

  // ==========================================
  // ETATS (ERROR, LOADING, EMPTY)
  // ==========================================
  Widget _buildLoadingState() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: List.generate(3, (index) => Container(
          height: 100,
          margin: const EdgeInsets.only(bottom: 15),
          decoration: BoxDecoration(color: CouleursApp.surface, borderRadius: BorderRadius.circular(20)),
        ).animate(onPlay: (controller) => controller.repeat()).shimmer(duration: 1.5.seconds, color: CouleursApp.fond.withValues(alpha: 0.5))).cast<Widget>(),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: CouleursApp.erreur.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: CouleursApp.erreur.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            const Icon(Iconsax.warning_2_copy, color: CouleursApp.erreur, size: 40),
            const SizedBox(height: 15),
            const Text("Impossible de charger vos données", style: TextStyle(fontWeight: FontWeight.bold, color: CouleursApp.erreur, fontSize: 16)),
            const SizedBox(height: 10),
            Text(error, style: const TextStyle(color: CouleursApp.erreur, fontSize: 12), textAlign: TextAlign.center),
            const SizedBox(height: 15),
            ElevatedButton.icon(
              onPressed: () => ref.invalidate(coursesClientProvider),
              icon: const Icon(Icons.refresh),
              label: const Text("Réessayer"),
              style: ElevatedButton.styleFrom(backgroundColor: CouleursApp.erreur, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: CouleursApp.fond, shape: BoxShape.circle),
            child: const Icon(Iconsax.box_add_copy, size: 50, color: CouleursApp.texteSecondaire),
          ),
          const SizedBox(height: 20),
          const Text("Aucune expédition en cours", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: CouleursApp.textePrincipal)),
          const SizedBox(height: 10),
          const Text("Lancez votre première demande de transport dès maintenant.", textAlign: TextAlign.center, style: TextStyle(color: CouleursApp.texteSecondaire)),
          
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ==========================================
  // FLOATING ACTION BUTTON (ASSISTANT IA)
  // ==========================================
  Widget _buildIAAssistantFAB() {
    return FloatingActionButton.extended(
      heroTag: "fab_ia",
      onPressed: () {
        context.push(RoutesApplication.assistantIA);
      },
      backgroundColor: CouleursApp.primaireFonce,
      tooltip: "Discuter avec l'assistant",
      icon: const Icon(Iconsax.message_text_copy, color: Colors.white),
      label: const Text("Assistant", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
            currentIndex: _bottomNavIndex,
            onTap: (index) => setState(() => _bottomNavIndex = index),
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.transparent,
            selectedItemColor: CouleursApp.primaire,
            unselectedItemColor: CouleursApp.texteSecondaire,
            showUnselectedLabels: true,
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
            elevation: 0,
            items: const [
              BottomNavigationBarItem(icon: Icon(Iconsax.home_2_copy), activeIcon: Icon(Iconsax.home_2), label: "Accueil", tooltip: "Retourner à l'accueil"),
              BottomNavigationBarItem(icon: Icon(Iconsax.truck_copy), activeIcon: Icon(Iconsax.truck), label: "Demandes", tooltip: "Gérer vos expéditions"),
              BottomNavigationBarItem(icon: Icon(Iconsax.location_copy), activeIcon: Icon(Iconsax.location), label: "Suivi", tooltip: "Suivre vos colis sur la carte"),
              BottomNavigationBarItem(icon: Icon(Iconsax.notification_copy), activeIcon: Icon(Iconsax.notification), label: "Alerte", tooltip: "Voir les notifications"),
              BottomNavigationBarItem(icon: Icon(Iconsax.user_copy), activeIcon: Icon(Iconsax.user), label: "Profil", tooltip: "Paramètres du profil"),
            ],
          ),
        ),
      ),
    );
  }
}
