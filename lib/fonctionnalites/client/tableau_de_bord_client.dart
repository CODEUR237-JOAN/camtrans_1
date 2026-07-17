import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../coeur/etat/course_provider.dart';
import '../../coeur/routes/routes.dart';
import '../../modeles/course.dart';
import '../../services/service_authentification.dart';
import '../../services/service_firestore.dart';

// ==========================================
// PALETTE PREMIUM
// ==========================================
const Color pBlue = Color(0xFF2697FF);
const Color pDarkBlue = Color(0xFF1E3A8A);
const Color pBg = Color(0xFFF4F7FB);
const Color pSurface = Colors.white;
const Color pSuccess = Color(0xFF16A34A);
const Color pWarning = Color(0xFFF59E0B);
const Color pError = Color(0xFFDC2626);
const Color pTextMain = Color(0xFF1E293B);
const Color pTextMuted = Color(0xFF64748B);

class TableauDeBordClient extends ConsumerStatefulWidget {
  const TableauDeBordClient({super.key});

  @override
  ConsumerState<TableauDeBordClient> createState() => _TableauDeBordClientState();
}

class _TableauDeBordClientState extends ConsumerState<TableauDeBordClient> {
  int _bottomNavIndex = 0;
  final MapController _mapController = MapController();

  @override
  Widget build(BuildContext context) {
    final coursesAsync = ref.watch(coursesClientProvider);

    return Scaffold(
      backgroundColor: pBg,
      floatingActionButton: _buildIAAssistantFAB(),
      bottomNavigationBar: _buildBottomNav(),
      body: SafeArea(
        child: RefreshIndicator(
          color: pBlue,
          onRefresh: () async {
            // Recharger le provider
            ref.invalidate(coursesClientProvider);
          },
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(child: _buildHeader()),
              SliverToBoxAdapter(child: _buildSearchBar()),
              SliverToBoxAdapter(child: _buildMainAction(context)),
              SliverToBoxAdapter(child: _buildQuickServices()),
              SliverToBoxAdapter(child: _buildStats()),
              
              // ==========================================
              // GESTION DES ETATS FIRESTORE
              // ==========================================
              coursesAsync.when(
                loading: () => SliverToBoxAdapter(child: _buildLoadingState()),
                error: (err, stack) => SliverToBoxAdapter(child: _buildErrorState(err.toString())),
                data: (courses) {
                  if (courses.isEmpty) {
                    return SliverToBoxAdapter(child: _buildEmptyState());
                  }

                  final enCours = courses.where((c) => c.statut != "Livré" && c.statut != "Annulé").toList();
                  final historique = courses.where((c) => c.statut == "Livré" || c.statut == "Annulé").toList();

                  return SliverList(
                    delegate: SliverChildListDelegate([
                      if (enCours.isNotEmpty) _buildActiveShipment(enCours.first),
                      if (enCours.isNotEmpty) _buildMiniMap(enCours.first),
                      if (historique.isNotEmpty) _buildHistoryList(historique),
                      const SizedBox(height: 100), // Espace pour le FAB
                    ]),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // HEADER PREMIUM
  // ==========================================
  Widget _buildHeader() {
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
                    BoxShadow(color: pBlue.withOpacity(0.2), blurRadius: 15, offset: const Offset(0, 5))
                  ],
                ),
                child: const CircleAvatar(
                  radius: 25,
                  backgroundColor: pBlue,
                  child: Icon(Iconsax.user_copy, color: Colors.white),
                ),
              ).animate().scale(delay: 100.ms),
              const SizedBox(width: 15),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Bonjour, Client",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: pTextMain),
                  ).animate().fadeIn(delay: 200.ms).slideX(),
                  Text(
                    "Prêt à expédier aujourd'hui ?",
                    style: TextStyle(fontSize: 13, color: pTextMuted),
                  ).animate().fadeIn(delay: 300.ms),
                ],
              ),
            ],
          ),
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: pSurface,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)],
                ),
                child: const Icon(Iconsax.notification_bing_copy, color: pTextMain),
              ),
              Positioned(
                top: -5,
                right: -5,
                child: Container(
                  padding: const EdgeInsets.all(5),
                  decoration: const BoxDecoration(color: pError, shape: BoxShape.circle),
                  child: const Text("3", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                ).animate().scale(delay: 400.ms),
              )
            ],
          ).animate().fadeIn(delay: 300.ms)
        ],
      ),
    );
  }

  // ==========================================
  // BARRE DE RECHERCHE GLASSMORPHISM
  // ==========================================
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.8),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: [
            BoxShadow(color: pDarkBlue.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10))
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Où souhaitez-vous expédier ?",
                hintStyle: TextStyle(color: pTextMuted.withOpacity(0.7)),
                prefixIcon: const Icon(Iconsax.location_copy, color: pBlue),
                suffixIcon: Container(
                  margin: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: pDarkBlue,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Iconsax.setting_4_copy, color: Colors.white, size: 18),
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              ),
            ),
          ),
        ),
      ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2),
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
        child: InkWell(
          onTap: () => context.push(RoutesApplication.creerDemande),
          borderRadius: BorderRadius.circular(24),
          child: Ink(
            padding: const EdgeInsets.symmetric(vertical: 25, horizontal: 20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [pBlue, pDarkBlue],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(color: pBlue.withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 10))
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
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        "Réservez un camion en 2 min",
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Iconsax.truck_fast_copy, color: Colors.white, size: 30),
                ).animate(onPlay: (controller) => controller.repeat(reverse: true)).moveY(begin: -2, end: 2, duration: 2.seconds)
              ],
            ),
          ),
        ),
      ).animate().scale(delay: 500.ms, curve: Curves.easeOutBack),
    );
  }

  // ==========================================
  // SERVICES RAPIDES
  // ==========================================
  Widget _buildQuickServices() {
    final services = [
      {"icon": Iconsax.box_time_copy, "title": "Mes Colis", "color": pWarning},
      {"icon": Iconsax.wallet_3_copy, "title": "Paiements", "color": pSuccess},
      {"icon": Iconsax.document_text_copy, "title": "Factures", "color": pBlue},
      {"icon": Iconsax.support_copy, "title": "Support", "color": pError},
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: services.map((s) {
          return Column(
            children: [
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: pSurface,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 5))],
                ),
                child: Icon(s['icon'] as IconData, color: s['color'] as Color, size: 28),
              ).animate().scale(delay: 600.ms),
              const SizedBox(height: 8),
              Text(s['title'] as String, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: pTextMain))
            ],
          );
        }).toList(),
      ),
    );
  }

  // ==========================================
  // STATISTIQUES ANIMÉES
  // ==========================================
  Widget _buildStats() {
    return SizedBox(
      height: 100,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          _buildStatCard("Livraisons", "12", Iconsax.box_tick_copy, pSuccess),
          const SizedBox(width: 15),
          _buildStatCard("Dépenses", "450k", Iconsax.coin_copy, pWarning),
          const SizedBox(width: 15),
          _buildStatCard("En cours", "2", Iconsax.truck_copy, pBlue),
        ],
      ),
    ).animate().fadeIn(delay: 700.ms).slideX(begin: 0.1);
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      width: 140,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: pSurface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: color.withOpacity(0.1), blurRadius: 15, offset: const Offset(0, 5))],
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 22),
              Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
            ],
          ),
          const Spacer(),
          Text(title, style: const TextStyle(fontSize: 13, color: pTextMuted, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  // ==========================================
  // LIVRAISON EN COURS (TIMELINE)
  // ==========================================
  Widget _buildActiveShipment(Course course) {
    bool isTransit = course.statut == "En Transit" || course.statut == "En cours";
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: pSurface,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: pDarkBlue.withOpacity(0.06), blurRadius: 20, offset: const Offset(0, 10))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Expédition Active", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: pTextMain)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: pWarning.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                  child: Text(course.statut, style: const TextStyle(color: pWarning, fontWeight: FontWeight.bold, fontSize: 12)),
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
                    const Text("Départ", style: TextStyle(color: pTextMuted, fontSize: 12)),
                    Text(course.adresseDepart.isNotEmpty ? course.adresseDepart : "Inconnu", style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text("Arrivée", style: TextStyle(color: pTextMuted, fontSize: 12)),
                    Text(course.adresseArrivee.isNotEmpty ? course.adresseArrivee : "Inconnu", style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            )
          ],
        ),
      ).animate().fadeIn(delay: 800.ms).slideY(begin: 0.1),
    );
  }

  Widget _buildTimelineDot(bool active, {bool isCurrent = false}) {
    return Container(
      width: isCurrent ? 20 : 12,
      height: isCurrent ? 20 : 12,
      decoration: BoxDecoration(
        color: active ? pBlue : pBg,
        shape: BoxShape.circle,
        border: isCurrent ? Border.all(color: pBlue.withOpacity(0.3), width: 4) : null,
      ),
      child: active && !isCurrent ? const Icon(Icons.check, size: 8, color: Colors.white) : null,
    );
  }

  Widget _buildTimelineLine(bool active) {
    return Expanded(
      child: Container(height: 3, color: active ? pBlue : pBg),
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
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5))],
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
                    Marker(point: LatLng(4.0511, 9.7679), child: Icon(Icons.local_shipping, color: pBlue, size: 30)),
                    Marker(point: LatLng(3.8480, 11.5021), child: Icon(Icons.location_on, color: pError, size: 30)),
                  ],
                )
              ],
            ),
            Positioned(
              right: 10,
              top: 10,
              child: FloatingActionButton.small(
                heroTag: "btn_map",
                backgroundColor: pSurface,
                onPressed: () => context.push(RoutesApplication.suivi),
                child: const Icon(Iconsax.maximize_circle_copy, color: pDarkBlue),
              ),
            )
          ],
        ),
      ).animate().fadeIn(delay: 900.ms).scale(),
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
              const Text("Historique Récent", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: pTextMain)),
              TextButton(onPressed: () {}, child: const Text("Voir tout", style: TextStyle(color: pBlue))),
            ],
          ),
          ...courses.take(3).map((course) {
            Color statusColor = course.statut == "Livré" ? pSuccess : pError;
            return Container(
              margin: const EdgeInsets.only(bottom: 15),
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: pSurface,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 5))],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: pBg, borderRadius: BorderRadius.circular(15)),
                    child: const Icon(Iconsax.box_copy, color: pTextMuted),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(course.description.isNotEmpty ? course.description : "Marchandise", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        const SizedBox(height: 4),
                        Text("${course.adresseDepart} ➔ ${course.adresseArrivee}", style: const TextStyle(fontSize: 12, color: pTextMuted), overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text("${course.prixEstime} FCFA", style: const TextStyle(fontWeight: FontWeight.bold, color: pTextMain)),
                      const SizedBox(height: 5),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                        child: Text(course.statut, style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold)),
                      )
                    ],
                  )
                ],
              ),
            ).animate().fadeIn(delay: 1000.ms).slideY(begin: 0.1);
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
          decoration: BoxDecoration(color: pSurface, borderRadius: BorderRadius.circular(20)),
        ).animate(onPlay: (controller) => controller.repeat()).shimmer(duration: 1.5.seconds, color: pBg.withOpacity(0.5))),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: pError.withOpacity(0.1),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: pError.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            const Icon(Iconsax.warning_2_copy, color: pError, size: 40),
            const SizedBox(height: 15),
            const Text("Impossible de charger vos données", style: TextStyle(fontWeight: FontWeight.bold, color: pError, fontSize: 16)),
            const SizedBox(height: 10),
            Text(error, style: const TextStyle(color: pError, fontSize: 12), textAlign: TextAlign.center),
            const SizedBox(height: 15),
            ElevatedButton.icon(
              onPressed: () => ref.invalidate(coursesClientProvider),
              icon: const Icon(Icons.refresh),
              label: const Text("Réessayer"),
              style: ElevatedButton.styleFrom(backgroundColor: pError, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
            )
          ],
        ),
      ),
    ).animate().fadeIn().scale();
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: pBg, shape: BoxShape.circle),
            child: const Icon(Iconsax.box_add_copy, size: 50, color: pTextMuted),
          ),
          const SizedBox(height: 20),
          const Text("Aucune expédition en cours", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: pTextMain)),
          const SizedBox(height: 10),
          const Text("Lancez votre première demande de transport dès maintenant.", textAlign: TextAlign.center, style: TextStyle(color: pTextMuted)),
          
          const SizedBox(height: 20),
          
          // Bouton temporaire de génération de données
          TextButton.icon(
            onPressed: () async {
              final auth = ref.read(serviceAuthentificationProvider);
              final firestore = ref.read(serviceFirestoreProvider);
              final userId = auth.utilisateur?.uid;
              if (userId != null) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Génération en cours...", style: TextStyle(color: Colors.white)), backgroundColor: pDarkBlue));
                await firestore.genererCoursesTest(userId);
              }
            },
            icon: const Icon(Icons.bug_report, color: pBlue),
            label: const Text("Générer des données de test", style: TextStyle(color: pBlue)),
          )
        ],
      ),
    ).animate().fadeIn(delay: 500.ms);
  }

  // ==========================================
  // FLOATING ACTION BUTTON (ASSISTANT IA)
  // ==========================================
  Widget _buildIAAssistantFAB() {
    return FloatingActionButton.extended(
      heroTag: "fab_ia",
      onPressed: () {
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          isScrollControlled: true,
          builder: (context) => _buildIABottomSheet(),
        );
      },
      backgroundColor: pDarkBlue,
      icon: const Icon(Iconsax.message_text_copy, color: Colors.white),
      label: const Text("Assistant IA", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
    ).animate().slideY(begin: 2, delay: 1200.ms, curve: Curves.easeOutBack);
  }

  Widget _buildIABottomSheet() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: pSurface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 15),
          Container(width: 50, height: 5, decoration: BoxDecoration(color: pBg, borderRadius: BorderRadius.circular(10))),
          const SizedBox(height: 20),
          const Icon(Iconsax.message_text_copy, size: 50, color: pBlue),
          const SizedBox(height: 15),
          const Text("Assistant IA Gemini", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: pTextMain)),
          const Padding(
            padding: EdgeInsets.all(20),
            child: Text("Bientôt, vous pourrez discuter avec notre IA pour estimer des prix, trouver des camions et suivre vos colis en langage naturel !", textAlign: TextAlign.center, style: TextStyle(color: pTextMuted, fontSize: 16)),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(20),
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 55), backgroundColor: pBlue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
              child: const Text("Fermer", style: TextStyle(color: Colors.white, fontSize: 16)),
            ),
          )
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
        color: pSurface,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, -5))],
      ),
      child: BottomNavigationBar(
        currentIndex: _bottomNavIndex,
        onTap: (index) => setState(() => _bottomNavIndex = index),
        type: BottomNavigationBarType.fixed,
        backgroundColor: pSurface,
        selectedItemColor: pBlue,
        unselectedItemColor: pTextMuted,
        showUnselectedLabels: true,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
        elevation: 0,
        items: const [
          BottomNavigationBarItem(icon: Icon(Iconsax.home_2_copy), activeIcon: Icon(Iconsax.home_2), label: "Accueil"),
          BottomNavigationBarItem(icon: Icon(Iconsax.truck_copy), activeIcon: Icon(Iconsax.truck), label: "Demandes"),
          BottomNavigationBarItem(icon: Icon(Iconsax.location_copy), activeIcon: Icon(Iconsax.location), label: "Suivi"),
          BottomNavigationBarItem(icon: Icon(Iconsax.notification_copy), activeIcon: Icon(Iconsax.notification), label: "Alerte"),
          BottomNavigationBarItem(icon: Icon(Iconsax.user_copy), activeIcon: Icon(Iconsax.user), label: "Profil"),
        ],
      ),
    ).animate().slideY(begin: 1, delay: 1000.ms, curve: Curves.easeOutBack);
  }
}