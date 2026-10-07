import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../coeur/etat/textes_app_provider.dart';
import '../../coeur/etat/utilisateur_provider.dart';
import '../../modeles/textes_app.dart';
import 'package:update_camtrans/coeur/etat/suivi_provider.dart';
import 'package:update_camtrans/services/service_gps.dart';
import 'package:update_camtrans/modeles/transporteur.dart';
import 'package:update_camtrans/modeles/course.dart';
import 'package:update_camtrans/services/service_firestore.dart';
import 'package:update_camtrans/coeur/constantes/couleurs.dart';
import 'package:update_camtrans/coeur/widgets/loader_page.dart';
import 'package:update_camtrans/coeur/constantes/statuts.dart';
import 'widgets/timeline_statut.dart';
import 'widgets/carte_suivi_abstraite.dart';
import 'widgets/bottom_sheet_paiement.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'widgets/recherche_radar.dart';

class SuiviTransport extends ConsumerStatefulWidget {
  final String courseId;
  final bool isFullScreen;

  const SuiviTransport(
      {super.key, required this.courseId, this.isFullScreen = true});

  @override
  ConsumerState<SuiviTransport> createState() => _SuiviTransportState();
}

class _SuiviTransportState extends ConsumerState<SuiviTransport> {
  MapController? _mapController;
  bool _enCoursDeRedirection = false;

  @override
  void initState() {
    super.initState();
    // Vérifier les permissions GPS au chargement
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(serviceGpsProvider).verifierPermissions().then((autorise) {
        if (!autorise && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content:
                  Text("Le GPS est nécessaire pour le suivi en temps réel."),
              backgroundColor: CouleursApp.avertissement,
            ),
          );
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    // Si aucun courseId fourni, afficher un état vide propre
    final textes = ref.watch(textesAppProvider).value ?? const TextesApp();
    if (widget.courseId.isEmpty) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          title: Text('Suivi', style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          elevation: 0,
          iconTheme: IconThemeData(color: Theme.of(context).colorScheme.onSurface),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.local_shipping_outlined,
                  size: 80, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54)),
              const SizedBox(height: 20),
              Text(
                  textes.get('vide_course_client',
                      "Aucune course active à suivre. Où allons-nous aujourd'hui ?"),
                  style: TextStyle(fontSize: 16, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)),
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      );
    }
    final String courseId = widget.courseId;
    final etatSuivi = ref.watch(suiviProvider(courseId));
    final roleAsync = ref.watch(userRoleProvider);
    final estClient = roleAsync.valueOrNull == 'client';

    //  Paiement automatique : dès que la course passe à 'terminee', ouvrir le volet de paiement (client uniquement)
    ref.listen<EtatSuivi>(suiviProvider(courseId), (previous, next) {
      if (!estClient) return;
      final ancienStatut = previous?.course?.statut;
      final nouveauStatut = next.course?.statut;
      if (ancienStatut != StatutCourse.terminee &&
          nouveauStatut == StatutCourse.terminee) {
        if (next.course?.paiementEffectue == false) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _confirmerFinCourse(context);
          });
        }
      }
    });

    if (etatSuivi.chargement) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: const LoaderPage(message: 'Chargement du suivi…'),
      );
    }

    if (etatSuivi.erreur != null || etatSuivi.course == null) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          elevation: 0,
          iconTheme: IconThemeData(color: Theme.of(context).colorScheme.onSurface),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Iconsax.radar_2_copy, size: 80, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2)),
                const SizedBox(height: 24),
                Text(
                  'Oups, nous avons perdu le signal',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'La connexion est momentanément interrompue. Nous tentons de rétablir le suivi de votre course...',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                const CircularProgressIndicator(color: CouleursApp.primaire),
              ],
            ),
          ),
        ),
      );
    }

    final course = etatSuivi.course!;

    //  PILIER 1 & 2: Moteur d'Auto-Dispatch côté Client
    if (estClient && course.statut == StatutCourse.recherche) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _executerAutoDispatch(course);
      });
    }

    //  PILIER 3: Timeout Global de 5 minutes
    if (estClient && (course.statut == StatutCourse.recherche || course.statut == StatutCourse.enAttente)) {
      if (DateTime.now().difference(course.dateCreation).inMinutes >= 5) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _afficherTimeoutGlobal(course);
        });
      }
    }

    // Affichage du Radar continu tant qu'aucun transporteur n'a accepté
    if (course.statut == StatutCourse.recherche ||
        course.statut == StatutCourse.propose) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Stack(
          children: [
            const RechercheRadar(), // Votre widget de Radar existant
            Positioned(
              top: MediaQuery.of(context).padding.top + 10,
              left: 20,
              child: _buildBackButton(context),
            ),
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(CouleursApp.primaire),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "Recherche du transporteur idéal en cours...",
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 18,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Notre algorithme sélectionne le meilleur véhicule à proximité.",
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7), fontSize: 14),
                  ),
                  const SizedBox(height: 20),
                  TextButton(
                    onPressed: () => _confirmerAnnulation(context),
                    style: TextButton.styleFrom(
                        foregroundColor: CouleursApp.erreur),
                    child: const Text("Annuler la course"),
                  )
                ],
              ),
            )
          ],
        ),
      );
    }

    final transporteur = etatSuivi.transporteur;

    final LatLng depart = LatLng(course.latitudeDepart, course.longitudeDepart);
    final LatLng arrivee =
        LatLng(course.latitudeArrivee, course.longitudeArrivee);

    LatLng posTransporteur = depart;
    if (transporteur != null &&
        transporteur.latitude != 0 &&
        transporteur.longitude != 0) {
      posTransporteur = LatLng(transporteur.latitude, transporteur.longitude);
    }

    return Scaffold(
      body: Stack(
        children: [
          // 1. CARTE (Abstraction)
          CarteSuiviAbstraite(
            depart: depart,
            arrivee: arrivee,
            transporteur: posTransporteur,
            route: etatSuivi.infoTrajet?.points,
            onMapCreated: (ctrl) => _mapController = ctrl,
            isRemorque: course.categorieService == 'Remorque',
          ),

          // 2. BOUTON RETOUR
          if (widget.isFullScreen)
            Positioned(
              top: MediaQuery.of(context).padding.top + 10,
              left: 20,
              child: _buildBackButton(context),
            ),

          // 3. BOUTON RECENTRER
          Positioned(
            right: 20,
            bottom: MediaQuery.of(context).size.height * 0.45,
            child: _buildLocationButton(posTransporteur),
          ),

          // 4. BOTTOM SHEET TIMELINE & INFOS
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildBottomSheet(
                context,
                course,
                transporteur,
                etatSuivi.quartierTransporteur,
                etatSuivi.distanceRestante,
                etatSuivi.tempsRestantSeconds),
          ),
        ],
      ),
    );
  }

  Widget _buildBackButton(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/');
        }
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.07),
                  blurRadius: 10,
                  offset: const Offset(0, 4))
            ]),
        child: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.onSurface),
      ),
    );
  }

  Widget _buildLocationButton(LatLng posTransporteur) {
    return GestureDetector(
      onTap: () {
        if (_mapController != null) {
          _mapController!.move(posTransporteur, 14.5);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.07),
                  blurRadius: 10,
                  offset: const Offset(0, 4))
            ]),
        child: const Icon(Iconsax.location_copy, color: CouleursApp.primaire),
      ),
    );
  }

  Widget _buildInfosTrajet(double distanceMetres, double tempsSecondes) {
    final distKm = (distanceMetres / 1000).toStringAsFixed(1);
    final min = (tempsSecondes / 60).ceil();

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: CouleursApp.primaire.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CouleursApp.primaire.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Row(
            children: [
              const Icon(Icons.route, color: CouleursApp.primaire, size: 20),
              const SizedBox(width: 8),
              Text("$distKm km",
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: CouleursApp.primaire)),
            ],
          ),
          Container(
              width: 1,
              height: 24,
              color: CouleursApp.primaire.withValues(alpha: 0.3)),
          Row(
            children: [
              const Icon(Icons.timer, color: CouleursApp.succes, size: 20),
              const SizedBox(width: 8),
              Text("$min min",
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, color: CouleursApp.succes)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTransporteurInfo(
      BuildContext context, Transporteur transporteur, String? quartier, String courseId) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.07),
                blurRadius: 20,
                offset: const Offset(0, 10))
          ]),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: CouleursApp.primaire.withValues(alpha: 0.1),
            backgroundImage: transporteur.photo.isNotEmpty
                ? NetworkImage(transporteur.photo)
                : null,
            child: transporteur.photo.isEmpty
                ? const Icon(Icons.person, color: CouleursApp.primaire)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("${transporteur.prenom} ${transporteur.nom}",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Theme.of(context).colorScheme.onSurface),
                    overflow: TextOverflow.ellipsis),
                Row(
                  children: [
                    const Icon(Iconsax.location_copy,
                        size: 12, color: CouleursApp.primaire),
                    const SizedBox(width: 4),
                    Expanded(
                        child: Text(quartier ?? "Localisation en cours...",
                            style: const TextStyle(
                                color: CouleursApp.primaire,
                                fontSize: 12,
                                fontWeight: FontWeight.w600),
                            overflow: TextOverflow.ellipsis)),
                  ],
                ),
                Text(
                    transporteur.typeVehicule.isEmpty
                        ? "Véhicule utilitaire"
                        : transporteur.typeVehicule,
                    style:
                        TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7), fontSize: 11)),
              ],
            ),
          ),
          Row(
            children: [
              GestureDetector(
                onTap: () {
                  context.push("/chat", extra: {"courseId": courseId});
                },
                child: Container(
                  padding: const EdgeInsets.all(10),
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                      color: CouleursApp.secondaire.withValues(alpha: 0.1),
                      shape: BoxShape.circle),
                  child: const Icon(Iconsax.message_copy,
                      color: CouleursApp.secondaire, size: 20),
                ),
              ),
              GestureDetector(
                onTap: () async {
                  final telClean = transporteur.telephone.replaceAll(' ', '');
                  final Uri telUrl = Uri.parse('tel:$telClean');
                  try {
                    if (await canLaunchUrl(telUrl)) {
                      await launchUrl(telUrl);
                    } else {
                      await launchUrl(telUrl, mode: LaunchMode.externalApplication);
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Impossible de lancer l'appel pour $telClean")),
                      );
                    }
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                      color: CouleursApp.primaire.withValues(alpha: 0.1),
                      shape: BoxShape.circle),
                  child: const Icon(Iconsax.call_copy,
                      color: CouleursApp.primaire, size: 20),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildBottomSheet(
      BuildContext context,
      Course course,
      Transporteur? transporteur,
      String? quartier,
      double distanceMetres,
      double tempsSecondes) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.70,
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.onSurface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          boxShadow: [
            BoxShadow(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.07),
                blurRadius: 20,
                offset: const Offset(0, -5))
          ]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Poignée du bottom sheet
          Center(
            child: Container(
              width: 40,
              height: 5,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(10)),
            ),
          ),

          // Entête Course
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Course",
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54), fontSize: 13)),
                  Text(course.codeSuivi,
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Theme.of(context).colorScheme.onSurface)),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                    color: CouleursApp.primaire.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20)),
                child: const Text("En direct",
                    style: TextStyle(
                        color: CouleursApp.primaire,
                        fontWeight: FontWeight.bold,
                        fontSize: 12)),
              )
                  .animate(
                      onPlay: (controller) => controller.repeat(reverse: true))
                  .fade(begin: 0.5, end: 1.0, duration: 1.seconds),
            ],
          ),
          const SizedBox(height: 12),

          // Adresses de la course
          Row(
            children: [
              const Icon(Icons.location_on, color: CouleursApp.erreur, size: 20),
              const SizedBox(width: 8),
              Expanded(
                  child: Text(course.adresseDepart,
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.87),
                          fontSize: 13,
                          fontWeight: FontWeight.w500))),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 9.0, top: 2, bottom: 2),
            child: Container(width: 2, height: 12, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.12)),
          ),
          Row(
            children: [
              const Icon(Icons.flag, color: CouleursApp.succes, size: 20),
              const SizedBox(width: 8),
              Expanded(
                  child: Text(course.adresseArrivee,
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.87),
                          fontSize: 13,
                          fontWeight: FontWeight.w500))),
            ],
          ),

          const Divider(height: 24),

          // Infos Chauffeur
          if (transporteur != null) ...[
            _buildTransporteurInfo(context, transporteur, quartier, course.id),
            const SizedBox(height: 16),
          ],

          // ETA & Distance
          if (distanceMetres > 0) ...[
            _buildInfosTrajet(distanceMetres, tempsSecondes),
            const SizedBox(height: 24),
          ],

          // Timeline (Scrollable)
          Expanded(
            child: SingleChildScrollView(
              child: TimelineStatut(statutActuel: course.statut),
            ),
          ),

          // Bouton "Terminer la course" ou "Je suis arrivé"
          if (course.statut == StatutCourse.arriveDestination ||
              (course.statut == StatutCourse.enTransit &&
                  distanceMetres < 200)) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () => _confirmerFinCourse(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      course.statut == StatutCourse.arriveDestination
                          ? CouleursApp.primaire
                          : CouleursApp.succes,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: Text(
                    course.statut == StatutCourse.arriveDestination
                        ? "Confirmer la course"
                        : "Valider l'arrivée",
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],

          // Bouton d'annulation
          if (course.statut == StatutCourse.recherche ||
              course.statut == StatutCourse.attribue ||
              course.statut == StatutCourse.enRouteDepart) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => _confirmerAnnulation(context),
                style:
                    TextButton.styleFrom(foregroundColor: CouleursApp.erreur),
                child: const Text("Annuler la course"),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _confirmerAnnulation(BuildContext context) {
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
              Navigator.pop(ctx);
              final courseId = widget.courseId;
              try {
                await ref.read(serviceFirestoreProvider).modifierDocument(
                  collection: 'courses',
                  id: courseId,
                  donnees: {
                    'statut': StatutCourse.annulee,
                  },
                );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text("Course annulée.", style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
                      backgroundColor: CouleursApp.succes));
                  context.go('/');
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text("Erreur lors de l'annulation : \$e", style: TextStyle(color: Colors.white)),
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

  void _confirmerFinCourse(BuildContext context) {
    final course = ref.read(suiviProvider(widget.courseId)).course;

    if (course == null) return;

    // Si déjà payé → aller directement à l'évaluation
    if (course.paiementEffectue) {
      context.go('/evaluation/${course.id}');
      return;
    }

    final double montant =
        course.prixFinal > 0 ? course.prixFinal : course.prixEstime;

    // Afficher le bottom sheet de paiement (non-dismissable)
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => BottomSheetPaiement(
        courseId: course.id,
        montant: montant > 0 ? montant : 5000,
        transporteurId: course.transporteurId,
        onPaiementReussi: () {
          Navigator.pop(ctx);
          if (context.mounted) {
            context.go('/evaluation/${course.id}');
          }
        },
      ),
    );
  }

  bool _rechercheEnCours = false;

  Future<void> _executerAutoDispatch(Course course) async {
    if (_rechercheEnCours || course.statut != StatutCourse.recherche) return;
    _rechercheEnCours = true;

    try {
      final docRef = FirebaseFirestore.instance.collection('courses').doc(course.id);
      final courseSnapshot = await docRef.get();
      if (!courseSnapshot.exists) return;

      final data = courseSnapshot.data()!;
      if (data['statut'] != StatutCourse.recherche) return;

      final List<dynamic> declinesDyn = data['transporteursDeclines'] ?? [];
      final Set<String> declines = declinesDyn.map((e) => e.toString()).toSet();

      // 1. Récupérer les transporteurs en ligne
      final transporteursSnap = await FirebaseFirestore.instance
          .collection('transporteurs')
          .where('disponible', isEqualTo: true)
          .where('documentsValides', isEqualTo: true)
          .get();

      final serviceGps = ref.read(serviceGpsProvider);
      final List<Map<String, dynamic>> candidats = [];

      // 2. Filtrer
      for (var doc in transporteursSnap.docs) {
        if (declines.contains(doc.id)) continue;
        final t = doc.data();
        if (t['estEnLigne'] != true) continue;
        if (course.typeVehicule.isNotEmpty && t['typeVehicule'] != course.typeVehicule) continue;

        final double tLat = t['latitude'] ?? 0.0;
        final double tLng = t['longitude'] ?? 0.0;

        double dist = 999.0;
        if (tLat != 0.0) {
          dist = serviceGps.calculerDistance(
            latitudeDepart: course.latitudeDepart,
            longitudeDepart: course.longitudeDepart,
            latitudeArrivee: tLat,
            longitudeArrivee: tLng,
          );
        }

        candidats.add({
          'id': doc.id,
          'distance': dist,
          'nom': t['prenom'],
          'telephone': t['telephone'],
          'doc': t,
        });
      }

      if (candidats.isEmpty) {
        // Personne trouvé. Le timeout global finira par annuler la course.
        return;
      }

      // 3. Trier par distance
      candidats.sort((a, b) => (a['distance'] as double).compareTo(b['distance'] as double));

      // 4. Exécuter l'attribution transactionnelle stricte (Pilier 2)
      for (final candidat in candidats) {
        final transporteurId = candidat['id'] as String;
        final transporteurRef = FirebaseFirestore.instance.collection('transporteurs').doc(transporteurId);

        try {
          await FirebaseFirestore.instance.runTransaction((transaction) async {
            // Lecture
            final tSnap = await transaction.get(transporteurRef);
            final cSnap = await transaction.get(docRef);

            if (!tSnap.exists || !cSnap.exists) throw Exception("Doc manquant");
            final cData = cSnap.data()!;
            if (cData['statut'] != StatutCourse.recherche) throw Exception("Course plus dispo");

            final tData = tSnap.data()!;
            if (tData['disponible'] != true || tData['estEnLigne'] != true) {
              throw Exception("Transporteur occupé");
            }

            // Écriture : verrouiller le chauffeur et attribuer la course
            transaction.update(transporteurRef, {'disponible': false});
            transaction.update(docRef, {
              'statut': StatutCourse.attribue,
              'transporteurId': transporteurId,
              'nomTransporteur': "${tData['prenom']} ${tData['nom']}",
              'telephoneTransporteur': tData['telephone'] ?? "",
            });
          });
          
          // Match réussi ! L'UI se mettra à jour automatiquement
          break;
        } catch (e) {
          // Transaction échouée (chauffeur a pris une autre course à cette milliseconde)
          debugPrint("Collision Auto-Dispatch : candidat \$transporteurId déjà pris.");
          continue;
        }
      }
    } catch (e) {
      debugPrint("Erreur Auto-Dispatch : \$e");
    } finally {
      // Pause de 5 secondes avant la prochaine tentative (Cascade)
      await Future.delayed(const Duration(seconds: 5));
      _rechercheEnCours = false;
    }
  }

  void _afficherTimeoutGlobal(Course course) {
    if (_enCoursDeRedirection) return;
    _enCoursDeRedirection = true;

    // Met à jour la course en expiré côté client (pour ne plus afficher le radar)
    FirebaseFirestore.instance.collection('courses').doc(course.id).update({
      'statut': StatutCourse.annulee,
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.info_outline_rounded, color: CouleursApp.erreur, size: 28),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                "Aucun véhicule disponible",
                style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface),
              ),
            ),
          ],
        ),
        content: Text(
          "Malheureusement, aucun transporteur n'a pu accepter votre course dans le temps imparti. Vous pouvez relancer votre recherche.",
          style: GoogleFonts.inter(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.go('/');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: CouleursApp.primaire,
            ),
            child: Text("Compris", style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

}
