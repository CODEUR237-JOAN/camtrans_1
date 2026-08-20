import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:update_camtrans/coeur/etat/suivi_provider.dart';
import 'package:update_camtrans/services/service_gps.dart';
import 'package:update_camtrans/modeles/transporteur.dart';
import 'package:update_camtrans/services/service_firestore.dart';
import 'package:update_camtrans/coeur/constantes/couleurs.dart';
import 'package:update_camtrans/coeur/constantes/statuts.dart';
import 'widgets/timeline_statut.dart';
import 'widgets/carte_suivi_abstraite.dart';
import 'widgets/bottom_sheet_paiement.dart';

class SuiviTransport extends ConsumerStatefulWidget {
  final String courseId;

  const SuiviTransport({super.key, required this.courseId});

  @override
  ConsumerState<SuiviTransport> createState() => _SuiviTransportState();
}

class _SuiviTransportState extends ConsumerState<SuiviTransport> {
  MapController? _mapController;

  @override
  void initState() {
    super.initState();
    // Vérifier les permissions GPS au chargement
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(serviceGpsProvider).verifierPermissions().then((autorise) {
        if (!autorise && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Le GPS est nécessaire pour le suivi en temps réel."),
              backgroundColor: Colors.orange,
            ),
          );
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    // Si widget.courseId est vide pour le mockup, on utilise une valeur par défaut, sinon on écoute la vraie base.
    // L'idéal est de router avec un paramètre d'ID.
    final String courseId = widget.courseId.isNotEmpty ? widget.courseId : "course_demo_id";
    final etatSuivi = ref.watch(suiviProvider(courseId));

    if (etatSuivi.chargement) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator(color: CouleursApp.primaire)),
      );
    }

    if (etatSuivi.erreur != null || etatSuivi.course == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(child: Text("Impossible de charger le suivi : ${etatSuivi.erreur}")),
      );
    }

    final course = etatSuivi.course!;
    final transporteur = etatSuivi.transporteur;

    final LatLng depart = LatLng(course.latitudeDepart, course.longitudeDepart);
    final LatLng arrivee = LatLng(course.latitudeArrivee, course.longitudeArrivee);
    
    LatLng posTransporteur = depart;
    if (etatSuivi.positionTransporteurSimule != null) {
      posTransporteur = etatSuivi.positionTransporteurSimule!;
    } else if (transporteur != null && transporteur.latitude != 0 && transporteur.longitude != 0) {
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
              course.codeSuivi, 
              course.statut, 
              transporteur, 
              etatSuivi.quartierTransporteur,
              etatSuivi.distanceRestante, 
              etatSuivi.tempsRestantSeconds
            ),
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
        decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 4))]),
        child: const Icon(Icons.arrow_back, color: Colors.black87),
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
        decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 4))]),
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
              Text("$distKm km", style: const TextStyle(fontWeight: FontWeight.bold, color: CouleursApp.primaire)),
            ],
          ),
          Container(width: 1, height: 24, color: CouleursApp.primaire.withValues(alpha: 0.3)),
          Row(
            children: [
              const Icon(Icons.timer, color: CouleursApp.succes, size: 20),
              const SizedBox(width: 8),
              Text("$min min", style: const TextStyle(fontWeight: FontWeight.bold, color: CouleursApp.succes)),
            ],
          ),
        ],
      ),
    ).animate().fadeIn();
  }

  Widget _buildTransporteurInfo(BuildContext context, Transporteur transporteur, String? quartier) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, 10))]),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24, 
            backgroundColor: CouleursApp.primaire.withValues(alpha: 0.1), 
            backgroundImage: transporteur.photo.isNotEmpty ? NetworkImage(transporteur.photo) : null,
            child: transporteur.photo.isEmpty ? const Icon(Icons.person, color: CouleursApp.primaire) : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("${transporteur.prenom} ${transporteur.nom}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87), overflow: TextOverflow.ellipsis),
                Row(
                  children: [
                    const Icon(Iconsax.location_copy, size: 12, color: CouleursApp.primaire),
                    const SizedBox(width: 4),
                    Expanded(child: Text(quartier ?? "Localisation en cours...", style: const TextStyle(color: CouleursApp.primaire, fontSize: 12, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis)),
                  ],
                ),
                Text(transporteur.typeVehicule.isEmpty ? "Véhicule utilitaire" : transporteur.typeVehicule, style: const TextStyle(color: Colors.black54, fontSize: 11)),
              ],
            ),
          ),
          Row(
            children: [
              GestureDetector(
                onTap: () {
                  context.push("/chat", extra: {"transporteur": transporteur});
                },
                child: Container(
                  padding: const EdgeInsets.all(10),
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(color: CouleursApp.secondaire.withValues(alpha: 0.1), shape: BoxShape.circle),
                  child: const Icon(Iconsax.message_copy, color: CouleursApp.secondaire, size: 20),
                ),
              ),
              GestureDetector(
                onTap: () async {
                  final Uri telUrl = Uri(scheme: 'tel', path: transporteur.telephone);
                  if (await canLaunchUrl(telUrl)) {
                    await launchUrl(telUrl);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: CouleursApp.primaire.withValues(alpha: 0.1), shape: BoxShape.circle),
                  child: const Icon(Iconsax.call_copy, color: CouleursApp.primaire, size: 20),
                ),
              ),
            ],
          )
        ],
      ),
    ).animate().slideY(begin: -0.2).fadeIn();
  }

  Widget _buildBottomSheet(BuildContext context, String codeSuivi, String statut, Transporteur? transporteur, String? quartier, double distanceMetres, double tempsSecondes) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.65,
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: const BorderRadius.vertical(top: Radius.circular(32)), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 20, offset: const Offset(0, -5))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Poignée du bottom sheet
          Center(
            child: Container(
              width: 40, height: 5,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)),
            ),
          ),
          
          // Entête Course
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Course", style: TextStyle(color: Colors.black54, fontSize: 13)),
                  Text(codeSuivi, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: CouleursApp.primaire.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
                child: const Text("En direct", style: TextStyle(color: CouleursApp.primaire, fontWeight: FontWeight.bold, fontSize: 12)),
              ).animate(onPlay: (controller) => controller.repeat(reverse: true)).fade(begin: 0.5, end: 1.0, duration: 1.seconds),
            ],
          ),
          const Divider(height: 32),

          // Infos Chauffeur
          if (transporteur != null) ...[
            _buildTransporteurInfo(context, transporteur, quartier),
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
              child: TimelineStatut(statutActuel: statut),
            ),
          ),

          // Bouton "Terminer la course" ou "Je suis arrivé"
          if (statut == StatutCourse.arriveDestination || (statut == StatutCourse.enTransit && distanceMetres < 200)) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () => _confirmerFinCourse(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: statut == StatutCourse.arriveDestination ? CouleursApp.primaire : CouleursApp.succes,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: Text(
                  statut == StatutCourse.arriveDestination ? "Confirmer la livraison" : "Valider l'arrivée", 
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)
                ),
              ).animate().scale(delay: 200.ms),
            ),
          ],
        ],
      ),
    ).animate().slideY(begin: 0.2).fadeIn();
  }

  void _confirmerFinCourse(BuildContext context) {
    final course = ref
        .read(suiviProvider(
            widget.courseId.isNotEmpty ? widget.courseId : 'course_demo_id'))
        .course;

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
}