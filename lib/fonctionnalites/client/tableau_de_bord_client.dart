import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:update_camtrans/coeur/widgets/combi_widget.dart';
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
import 'package:update_camtrans/fonctionnalites/suivi_course/ecran_suivi_course.dart';
import 'package:update_camtrans/fonctionnalites/notifications/notifications.dart';
import 'profil.dart';
import 'package:update_camtrans/coeur/etat/notification_provider.dart';

import 'package:flutter/services.dart';
import 'package:update_camtrans/coeur/etat/demande_expedition_provider.dart';
import 'package:update_camtrans/coeur/constantes/couleurs.dart';
import 'package:update_camtrans/coeur/constantes/statuts.dart';
import 'package:update_camtrans/coeur/widgets/marqueur_premium.dart';
import 'package:update_camtrans/coeur/widgets/page_responsive.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:update_camtrans/coeur/widgets/loader_premium.dart';

class TableauDeBordClient extends ConsumerStatefulWidget {
  const TableauDeBordClient({super.key});

  @override
  ConsumerState<TableauDeBordClient> createState() =>
      _TableauDeBordClientState();
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

    // ✅ Redirection automatique : dès que le transporteur accepte, le client est envoyé vers sa page de suivi
    ref.listen<Course?>(activeCourseClientProvider, (previous, current) {
      if (current == null) return;
      final oldStatut = previous?.statut;
      final newStatut = current.statut;

      // Rediriger si la course vient d'être acceptée (propose → attribue) ou si elle est active
      final devraitRediriger = (oldStatut == StatutCourse.propose ||
              oldStatut == StatutCourse.recherche) &&
          newStatut == StatutCourse.attribue;

      if (devraitRediriger) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.white),
                    SizedBox(width: 10),
                    Expanded(
                        child: Text(
                            "Un transporteur a accepté votre course ! 🎉")),
                  ],
                ),
                backgroundColor: CouleursApp.succes,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                duration: const Duration(seconds: 3),
              ),
            );
            context.push('/suivi/${current.id}');
          }
        });
      }
    });

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          // Blob lumineux haut-gauche (très subtil)
          Positioned(
            top: -120,
            left: -80,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                color: CouleursApp.primaire.withValues(alpha: 0.05),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                      color: CouleursApp.primaire.withValues(alpha: 0.1),
                      blurRadius: 100)
                ],
              ),
            ),
          ),
          // Blob lumineux bas-droite
          Positioned(
            bottom: -60,
            right: -60,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                color: CouleursApp.secondaire.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
            ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(
                begin: const Offset(1, 1),
                end: const Offset(1.3, 1.3),
                duration: 5.seconds),
          ),

          // Contenu principal
          Positioned.fill(
            child: SafeArea(
              bottom: false,
              child: PageResponsive(
                child: IndexedStack(
                  index: _bottomNavIndex,
                  children: [
                    // Onglet 0: Accueil (Tableau de bord dynamique)
                    _buildDashboardAccueil(coursesAsync),

                    // Onglet 1: Commandes (Historique)
                    const Historique(),

                    // Onglet 2: Suivi
                    coursesAsync.when(
                      data: (courses) {
                        final enCours = courses
                            .where((c) => !StatutCourse.estTerminee(c.statut))
                            .toList();
                        if (enCours.isEmpty) {
                          return Container(
                            color: Colors.transparent,
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Iconsax.location_copy,
                                      size: 80, color: CouleursApp.primaire),
                                  const SizedBox(height: 20),
                                  Text("Aucune course en cours à suivre",
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: Theme.of(context).colorScheme.onSurface)),
                                  const SizedBox(height: 10),
                                  ElevatedButton(
                                    onPressed: () =>
                                        setState(() => _bottomNavIndex = 0),
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor: CouleursApp.primaire,
                                        foregroundColor: Colors.white),
                                    child: const Text("Retour à l'accueil"),
                                  )
                                ],
                              ),
                            ),
                          );
                        }
                        return EcranSuiviCourse(
                            courseId: enCours.first.id, isFullScreen: false);
                      },
                      loading: () => const Scaffold(
                          body: Center(child: LoaderPremium(size: 24))),
                      error: (err, stack) =>
                          Scaffold(body: Center(child: Text("Erreur: $err"))),
                    ),

                    // Onglet 3: Notifications
                    const NotificationsPage(),

                    // Onglet 4: Profil
                    const Profil(),
                  ],
                ),
              ),
            ),
          ),

          // Floating Dock Bottom Navigation
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildBottomNav(),
          ),
        ],
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
          SliverToBoxAdapter(child: _buildHeroAction()),
          SliverToBoxAdapter(child: _buildServiceCategories(context)),
          coursesAsync.when(
            loading: () => SliverToBoxAdapter(child: _buildLoadingState()),
            error: (err, stack) =>
                SliverToBoxAdapter(child: _buildErrorState(err.toString())),
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

              double depenses = livrees.fold(0, (sum, c) => sum + c.prixFinal);
              if (depenses == 0) {
                depenses = livrees.fold(0, (sum, c) => sum + c.prixEstime);
              }

              return SliverList(
                delegate: SliverChildListDelegate(<Widget>[
                  if (courses.isEmpty) _buildEmptyState(),
                  if (enCours.isNotEmpty) _buildActiveShipment(enCours.first),
                  if (enCours.isNotEmpty) _buildMiniMap(enCours.first),
                  if (courses
                      .where((c) => StatutCourse.estTerminee(c.statut))
                      .isNotEmpty)
                    _buildHistoryList(courses
                        .where((c) => StatutCourse.estTerminee(c.statut))
                        .toList()),
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
        final String nomAffichage = client != null
            ? client.prenom
            : (utilisateur?.displayName ?? "Client");
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
                        BoxShadow(
                            color: CouleursApp.primaire.withValues(alpha: 0.2),
                            blurRadius: 15,
                            offset: const Offset(0, 5))
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 25,
                      backgroundColor: CouleursApp.primaire,
                      backgroundImage:
                          photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
                      child: photoUrl.isEmpty
                          ? const Icon(Iconsax.user_copy, color: Colors.white)
                          : null,
                    ),
                  ),
                  const SizedBox(width: 15),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "${_salutation()} 👋",
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.6)),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        nomAffichage,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                            color: Theme.of(context).colorScheme.onSurface),
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
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.07),
                                blurRadius: 10)
                          ],
                        ),
                        child: Icon(Iconsax.notification_bing_copy,
                            color: Theme.of(context).colorScheme.onSurface),
                      ),
                      if (badgeCount > 0)
                        Positioned(
                          top: -5,
                          right: -5,
                          child: Container(
                            padding: const EdgeInsets.all(5),
                            decoration: const BoxDecoration(
                                color: Colors.red, shape: BoxShape.circle),
                            child: Text(
                              badgeCount > 9 ? "9+" : badgeCount.toString(),
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold),
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
  // HÉROS D'ACTION — CTA principal (style ride-hailing)
  // ==========================================
  String _salutation() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Bonjour';
    if (h < 18) return 'Bon après-midi';
    return 'Bonsoir';
  }

  Widget _buildHeroAction() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 6),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(26),
          onTap: () {
            HapticFeedback.mediumImpact();
            ref.read(demandeExpeditionProvider.notifier).reinitialiser();
            ref
                .read(demandeExpeditionProvider.notifier)
                .setCategorieService('Autre');
            context.push(RoutesApplication.creerDemande);
          },
          child: Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: CouleursApp.degradePrincipal,
              borderRadius: BorderRadius.circular(26),
              boxShadow: [
                BoxShadow(
                  color: CouleursApp.primaire.withValues(alpha: 0.30),
                  blurRadius: 26,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Iconsax.box_copy,
                          color: Colors.white, size: 18),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Nouvelle expédition',
                      style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Faux champ de recherche (invite à démarrer une demande)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.search,
                          color: Color(0xFF94A3B8), size: 20),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Saisir le point de départ…',
                          style: TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 14,
                              fontWeight: FontWeight.w500),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: const BoxDecoration(
                          color: CouleursApp.primaire,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.arrow_forward_rounded,
                            color: Colors.white, size: 18),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Icône adaptée au type de service d'une course (historique, listes…).
  IconData _iconeService(String categorie) {
    final c = categorie.toLowerCase();
    if (c.contains('remorqu')) return Iconsax.car_copy;
    if (c.contains('ménag') || c.contains('menag')) return Iconsax.home_2_copy;
    if (c.contains('marchand')) return Iconsax.box_copy;
    if (c.contains('autre')) return Iconsax.category_copy;
    return Iconsax.box_copy;
  }

  // Libellé lisible du service (fallback de titre quand pas de description).
  String _libelleService(String categorie) {
    if (categorie.trim().isEmpty) return "Course";
    if (categorie.toLowerCase().contains('remorqu')) return "Remorquage";
    return categorie;
  }

  // ==========================================
  // SELECTION DE SERVICES (ACCUEIL)
  // ==========================================
  Widget _buildServiceCategories(BuildContext context) {
    final categories = [
      {
        "titre": "Déménagement",
        "desc": "Appart. & bureaux",
        "icon": Iconsax.home_2_copy
      },
      {"titre": "Remorque", "desc": "Objets lourds", "icon": Iconsax.car_copy},
      {
        "titre": "Marchandises",
        "desc": "Colis & palettes",
        "icon": Iconsax.box_copy
      },
      {"titre": "Autre", "desc": "Sur mesure", "icon": Iconsax.category_copy},
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                "Nos services",
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.3,
                    color: Theme.of(context).colorScheme.onSurface),
              ),
              const Spacer(),
              Text(
                "Choisissez & estimez",
                style: TextStyle(
                    fontSize: 12.5,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.5)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.05,
            ),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final cat = categories[index];
              return _ServiceCategoryCard(
                titre: cat['titre'] as String,
                desc: cat['desc'] as String,
                icon: cat['icon'] as IconData,
                onTap: () {
                  HapticFeedback.lightImpact();
                  ref.read(demandeExpeditionProvider.notifier).reinitialiser();
                  ref
                      .read(demandeExpeditionProvider.notifier)
                      .setCategorieService(cat['titre'] as String);
                  context.push(RoutesApplication.creerDemande);
                },
              );
            },
          ),
        ],
      ),
    );
  }

  // ==========================================
  // COURSE EN COURS (TIMELINE)
  // ==========================================
  Widget _buildActiveShipment(Course course) {
    bool isTransit = StatutCourse.estActive(course.statut);
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
                color: CouleursApp.primaireFonce.withValues(alpha: 0.06),
                blurRadius: 20,
                offset: const Offset(0, 10))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    "Course Active",
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                      color: CouleursApp.avertissement.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20)),
                  child: Text(StatutCourse.libelle(course.statut),
                      style: const TextStyle(
                          color: CouleursApp.avertissement,
                          fontWeight: FontWeight.bold,
                          fontSize: 12)),
                )
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                _buildTimelineDot(true),
                _buildTimelineLine(true),
                _buildTimelineDot(true, isCurrent: isTransit),
                _buildTimelineLine(false),
                _buildTimelineDot(false),
                _buildTimelineLine(false),
                _buildTimelineDot(false),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Départ",
                          style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7), fontSize: 13)),
                      Text(
                          course.adresseDepart.isNotEmpty
                              ? course.adresseDepart
                              : "Inconnu",
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15)),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text("Arrivée",
                          style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7), fontSize: 13)),
                      Text(
                          course.adresseArrivee.isNotEmpty
                              ? course.adresseArrivee
                              : "Inconnu",
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15)),
                    ],
                  ),
                ),
              ],
            ),
            if (course.statut == StatutCourse.recherche ||
                course.statut == StatutCourse.attribue ||
                course.statut == StatutCourse.enRouteDepart) ...[
              const SizedBox(height: 15),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => _confirmerAnnulation(context, course.id),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: CouleursApp.erreur,
                    side: const BorderSide(color: CouleursApp.erreur),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text("Annuler la course"),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _confirmerAnnulation(BuildContext context, String courseId) {
    debugPrint("OUVERTURE DU DIALOG D'ANNULATION POUR LA COURSE \$courseId");
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Annuler la course"),
        content:
            const Text("Êtes-vous sûr de vouloir annuler cette course ?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Non, garder"),
          ),
          ElevatedButton(
            onPressed: () async {
              debugPrint("CLIC SUR OUI, ANNULER !");
              Navigator.pop(ctx);
              try {
                debugPrint("LANCEMENT DE LA MISE A JOUR FIRESTORE...");
                await ref.read(serviceFirestoreProvider).modifierDocument(
                  collection: 'courses',
                  id: courseId,
                  donnees: {
                    'statut': StatutCourse.annulee,
                  },
                );
                debugPrint("MISE A JOUR REUSSIE !");
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text("La course a été annulée.",
                          style: TextStyle(color: Colors.white)),
                      backgroundColor: CouleursApp.succes));
                }
              } catch (e) {
                debugPrint("ERREUR FIRESTORE LORS DE L'ANNULATION : $e");
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text("Erreur : $e",
                          style: const TextStyle(color: Colors.white)),
                      backgroundColor: CouleursApp.erreur));
                }
              }
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: CouleursApp.erreur,
                foregroundColor: Colors.white),
            child: const Text("Oui, annuler"),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineDot(bool active, {bool isCurrent = false}) {
    double size = isCurrent ? 20 : 12;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: active ? CouleursApp.primaire : Colors.transparent,
        shape: BoxShape.circle,
        border: Border.all(
            color: active
                ? CouleursApp.primaire
                : Colors.grey.withValues(alpha: 0.3),
            width: 2),
      ),
      child: active && !isCurrent
          ? const Icon(Icons.check, size: 8, color: Colors.white)
          : null,
    );
  }

  Widget _buildTimelineLine(bool active) {
    return Expanded(
      child: Container(
          height: 3,
          color: active
              ? CouleursApp.primaire
              : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1)),
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
          boxShadow: [
            BoxShadow(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.07),
                blurRadius: 15,
                offset: const Offset(0, 5))
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter:
                    LatLng(course.latitudeDepart, course.longitudeDepart),
                initialZoom: 12, // Zoom plus proche pour la ville
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.joan.update_camtrans',
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                        point: LatLng(
                            course.latitudeDepart, course.longitudeDepart),
                        child:
                            const MarqueurPremium(type: TypeMarqueur.depart)),
                    Marker(
                        point: LatLng(
                            course.latitudeArrivee, course.longitudeArrivee),
                        child:
                            const MarqueurPremium(type: TypeMarqueur.arrivee)),
                  ],
                )
              ],
            ),
            Positioned(
              right: 10,
              top: 10,
              child: FloatingActionButton.small(
                heroTag: "btn_map",
                backgroundColor: Theme.of(context).colorScheme.surface,
                onPressed: () => setState(() => _bottomNavIndex = 2),
                child: const Icon(Iconsax.maximize_circle_copy,
                    color: CouleursApp.primaireFonce),
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
              Text("Historique Récent",
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface)),
              TextButton(
                  onPressed: () {
                    context.push(RoutesApplication.historique);
                  },
                  child: const Text("Voir tout",
                      style: TextStyle(
                          color: CouleursApp.primaire, fontSize: 14))),
            ],
          ),
          ...courses.take(3).map<Widget>((course) {
            Color statusColor =
                (course.statut == StatutCourse.arriveDestination ||
                        course.statut == StatutCourse.terminee)
                    ? CouleursApp.succes
                    : course.statut == StatutCourse.annulee
                        ? CouleursApp.erreur
                        : CouleursApp.avertissement;
            return Container(
              margin: const EdgeInsets.only(bottom: 15),
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.07),
                      blurRadius: 10,
                      offset: const Offset(0, 5))
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(15)),
                    child: Icon(_iconeService(course.categorieService),
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.7)),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                            course.description.isNotEmpty
                                ? course.description
                                : _libelleService(course.categorieService),
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 4),
                        Text(
                            "${course.adresseDepart} → ${course.adresseArrivee}",
                            style: TextStyle(
                                fontSize: 13, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)),
                            overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text("${course.prixEstime} FCFA",
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onSurface,
                              fontSize: 14)),
                      const SizedBox(height: 5),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8)),
                        child: Text(StatutCourse.libelle(course.statut),
                            style: TextStyle(
                                color: statusColor,
                                fontSize: 12,
                                fontWeight: FontWeight.bold)),
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
        children: List.generate(
            3,
            (index) => Container(
                  height: 100,
                  margin: const EdgeInsets.only(bottom: 15),
                  decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(20)),
                ).animate(onPlay: (controller) => controller.repeat()).shimmer(
                    duration: 1.5.seconds,
                    color: Theme.of(context).scaffoldBackgroundColor
                        .withValues(alpha: 0.5))).cast<Widget>(),
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
            const Icon(Iconsax.warning_2_copy,
                color: CouleursApp.erreur, size: 40),
            const SizedBox(height: 15),
            const Text("Impossible de charger vos données",
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: CouleursApp.erreur,
                    fontSize: 16)),
            const SizedBox(height: 10),
            Text(error,
                style: const TextStyle(color: CouleursApp.erreur, fontSize: 12),
                textAlign: TextAlign.center),
            const SizedBox(height: 15),
            ElevatedButton.icon(
              onPressed: () => ref.invalidate(coursesClientProvider),
              icon: const Icon(Icons.refresh),
              label: const Text("Réessayer"),
              style: ElevatedButton.styleFrom(
                  backgroundColor: CouleursApp.erreur,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15))),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 60),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(25),
            decoration: BoxDecoration(
              color: CouleursApp.primaire.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              border: Border.all(
                color: CouleursApp.primaire.withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            child: const Icon(Iconsax.box_add_copy,
                size: 50, color: CouleursApp.primaire),
          ),
          const SizedBox(height: 24),
          Text("Aucune course active",
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface)),
          const SizedBox(height: 12),
          Text(
              "Passez votre première commande en sélectionnant un service ci-dessus.",
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5), fontSize: 14, height: 1.5)),
        ],
      ),
    );
  }

  // ==========================================
  // ==========================================
  // BOTTOM NAVIGATION
  // ==========================================
  Widget _buildBottomNav() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 24),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(40),
              border: Border.all(
                  color: Theme.of(context).colorScheme.outlineVariant, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: CouleursApp.primaire.withValues(alpha: 0.2),
                  blurRadius: 30,
                  offset: const Offset(0, 15),
                  spreadRadius: 5,
                ),
              ],
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min, // Critical for the "dock" look
                children: [
                  _buildNavItem(
                      0, Iconsax.home_2_copy, Iconsax.home_2, "Accueil"),
                  _buildNavItem(1, Iconsax.truck_copy, Iconsax.truck, "Commandes"),
                  // Bouton IA central — mode compact, intégré dans la navbar
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4),
                    child: BoutonCombi(compact: true),
                  ),
                  _buildNavItem(3, Iconsax.notification_copy,
                      Iconsax.notification, "Alerte"),
                  _buildNavItem(4, Iconsax.user_copy, Iconsax.user, "Profil"),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
      int index, IconData icon, IconData activeIcon, String label) {
    final bool isSelected = _bottomNavIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _bottomNavIndex = index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
        margin:
            const EdgeInsets.symmetric(horizontal: 2), // Reduced from 4 to 2
        padding: EdgeInsets.symmetric(
            horizontal: isSelected ? 16 : 8,
            vertical: 12), // Reduced from 20/12 to 16/8
        decoration: BoxDecoration(
          color: isSelected ? CouleursApp.primaire : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: CouleursApp.primaire.withValues(alpha: 0.4),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  )
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, animation) =>
                  ScaleTransition(scale: animation, child: child),
              child: Icon(
                isSelected ? activeIcon : icon,
                key: ValueKey<bool>(isSelected),
                color: isSelected ? Colors.white : Theme.of(context).colorScheme.onSurfaceVariant,
                size: 24,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 10),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }
}

class _ServiceCategoryCard extends StatefulWidget {
  final String titre;
  final String desc;
  final IconData icon;
  final VoidCallback onTap;

  const _ServiceCategoryCard({
    required this.titre,
    required this.desc,
    required this.icon,
    required this.onTap,
  });

  @override
  State<_ServiceCategoryCard> createState() => _ServiceCategoryCardState();
}

class _ServiceCategoryCardState extends State<_ServiceCategoryCard> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final scale = _isPressed ? 0.95 : (_isHovered ? 1.02 : 1.0);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) {
          setState(() => _isPressed = false);
          widget.onTap();
        },
        onTapCancel: () => setState(() => _isPressed = false),
        child: AnimatedScale(
          scale: scale,
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _isHovered
                  ? CouleursApp.primaire.withValues(alpha: 0.1)
                  : Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: _isHovered
                    ? CouleursApp.primaire.withValues(alpha: 0.3)
                    : Colors.transparent,
                width: 1.5,
              ),
              boxShadow: [
                if (_isHovered)
                  BoxShadow(
                      color: CouleursApp.primaire.withValues(alpha: 0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10))
                else
                  BoxShadow(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.07),
                      blurRadius: 10,
                      offset: const Offset(0, 4)),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _isHovered
                        ? CouleursApp.primaire.withValues(alpha: 0.15)
                        : CouleursApp.primaire.withValues(alpha: 0.05),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    widget.icon,
                    color: _isHovered
                        ? CouleursApp.primaireFonce
                        : CouleursApp.primaire,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  widget.titre,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: _isHovered ? CouleursApp.primaire : Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.desc,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
