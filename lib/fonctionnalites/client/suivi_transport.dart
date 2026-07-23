import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';

import '../../coeur/etat/suivi_provider.dart';
import '../../coeur/constantes/couleurs.dart';
import 'widgets/timeline_statut.dart';
import 'widgets/carte_suivi_abstraite.dart';

class SuiviTransport extends ConsumerStatefulWidget {
  final String courseId;

  const SuiviTransport({super.key, required this.courseId});

  @override
  ConsumerState<SuiviTransport> createState() => _SuiviTransportState();
}

class _SuiviTransportState extends ConsumerState<SuiviTransport> {
  MapController? _mapController;

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
    
    LatLng? posTransporteur;
    if (transporteur != null && transporteur.latitude != 0 && transporteur.longitude != 0) {
      posTransporteur = LatLng(transporteur.latitude, transporteur.longitude);
    } else {
      // Mockup de la position si le transporteur n'a pas mis à jour ses coordonnées
      posTransporteur = depart;
    }

    return Scaffold(
      body: Stack(
        children: [
          // 1. CARTE (Abstraction)
          CarteSuiviAbstraite(
            depart: depart,
            arrivee: arrivee,
            transporteur: posTransporteur,
            onMapCreated: (ctrl) => _mapController = ctrl,
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

          // 4. PANNEAU TRANSPORTEUR (Haut)
          if (transporteur != null)
            Positioned(
              top: MediaQuery.of(context).padding.top + 70,
              left: 20,
              right: 20,
              child: _buildTransporteurInfo(transporteur.nom, transporteur.typeVehicule),
            ),

          // 5. BOTTOM SHEET TIMELINE
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildBottomSheet(course.codeSuivi, course.statut),
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

  Widget _buildTransporteurInfo(String nom, String vehicule) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, 10))]),
      child: Row(
        children: [
          const CircleAvatar(radius: 24, backgroundColor: Colors.grey, backgroundImage: AssetImage("assets/images/transporteur.jpg")),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(nom, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
                Text(vehicule.isEmpty ? "Véhicule utilitaire" : vehicule, style: const TextStyle(color: Colors.black54, fontSize: 14)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: CouleursApp.primaire.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: const Icon(Icons.phone, color: CouleursApp.primaire, size: 20),
          )
        ],
      ),
    ).animate().slideY(begin: -0.2).fadeIn();
  }

  Widget _buildBottomSheet(String codeSuivi, String statut) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.40,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: const BorderRadius.vertical(top: Radius.circular(32)), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 20, offset: const Offset(0, -5))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
          const SizedBox(height: 24),
          Expanded(child: SingleChildScrollView(child: TimelineStatut(statutActuel: statut))),
        ],
      ),
    ).animate().slideY(begin: 0.2).fadeIn();
  }
}