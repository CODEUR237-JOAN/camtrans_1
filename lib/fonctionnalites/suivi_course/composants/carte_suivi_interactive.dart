import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:update_camtrans/coeur/constantes/couleurs.dart';

import 'package:update_camtrans/fonctionnalites/suivi_course/etat/suivi_course_etat.dart';

// =====================================================================
// CARTE DE SUIVI INTERACTIVE (flutter_map / OpenStreetMap)
//
// Rendu « Yango » gratuit :
//   - Polyligne premium (couleur primaire + bordure lisse).
//   - Marqueur du véhicule ANIMÉ (glissement fluide entre deux points
//     GPS via AnimationController + Tween) et ORIENTÉ (rotation selon
//     le cap calculé entre l'ancienne et la nouvelle position).
//   - Auto-cadrage de la caméra (LatLngBounds + padding) pour garder le
//     véhicule ET la cible visibles.
// =====================================================================
class CarteSuiviInteractive extends StatefulWidget {
  final SuiviCourseEtat etat;
  final MapController mapController;

  const CarteSuiviInteractive({
    super.key,
    required this.etat,
    required this.mapController,
  });

  @override
  State<CarteSuiviInteractive> createState() => _CarteSuiviInteractiveState();
}

class _CarteSuiviInteractiveState extends State<CarteSuiviInteractive>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controleur;

  // Position de départ et d'arrivée de l'animation courante du véhicule.
  LatLng? _depart;
  LatLng? _arrivee;
  // Cap (radians) du véhicule, pour orienter l'icône dans le sens du trajet.
  double _cap = 0.0;

  @override
  void initState() {
    super.initState();
    _controleur = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _arrivee = widget.etat.positionChauffeur;
    _depart = widget.etat.positionChauffeur;
    _controleur.value = 1.0;
    WidgetsBinding.instance.addPostFrameCallback((_) => _cadrer());
  }

  @override
  void didUpdateWidget(covariant CarteSuiviInteractive oldWidget) {
    super.didUpdateWidget(oldWidget);
    final nouvelle = widget.etat.positionChauffeur;
    if (nouvelle == null) return;

    // Nouvelle position GPS différente → on anime le glissement.
    if (_arrivee == null) {
      _depart = nouvelle;
      _arrivee = nouvelle;
      _controleur.value = 1.0;
    } else if (nouvelle.latitude != _arrivee!.latitude ||
        nouvelle.longitude != _arrivee!.longitude) {
      _depart = _positionAnimee(); // on repart de la position affichée
      _cap = _calculerCap(_depart!, nouvelle);
      _arrivee = nouvelle;
      _controleur
        ..reset()
        ..forward();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _cadrer());
  }

  @override
  void dispose() {
    _controleur.dispose();
    super.dispose();
  }

  // Position interpolée entre _depart et _arrivee selon l'avancement.
  LatLng _positionAnimee() {
    final a = _depart;
    final b = _arrivee;
    if (a == null || b == null) {
      return widget.etat.positionChauffeur ??
          widget.etat.positionClient ??
          const LatLng(0, 0);
    }
    final t = _controleur.value;
    return LatLng(
      a.latitude + (b.latitude - a.latitude) * t,
      a.longitude + (b.longitude - a.longitude) * t,
    );
  }

  // Cap (bearing) en radians entre deux points — 0 = Nord.
  double _calculerCap(LatLng de, LatLng vers) {
    final lat1 = de.latitude * math.pi / 180;
    final lat2 = vers.latitude * math.pi / 180;
    final dLon = (vers.longitude - de.longitude) * math.pi / 180;
    final y = math.sin(dLon) * math.cos(lat2);
    final x = math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLon);
    return math.atan2(y, x);
  }

  LatLng? get _cible => widget.etat.phase == PhaseSuivi.approche
      ? widget.etat.positionClient
      : widget.etat.positionDestination;

  // Recadre la caméra pour montrer le véhicule ET la cible, avec marge.
  void _cadrer() {
    if (!mounted) return;
    final vehicule = _arrivee ?? widget.etat.positionChauffeur;
    final cible = _cible;
    if (vehicule == null) return;
    try {
      if (cible != null) {
        widget.mapController.fitCamera(
          CameraFit.bounds(
            bounds: LatLngBounds.fromPoints([vehicule, cible]),
            padding: const EdgeInsets.all(100),
            maxZoom: 16.5,
          ),
        );
      }
    } catch (_) {
      // La carte n'est pas encore prête : on ignore silencieusement.
    }
  }

  @override
  Widget build(BuildContext context) {
    final centre = widget.etat.positionChauffeur ?? widget.etat.positionClient;
    if (centre == null) {
      return const Center(
        child: CircularProgressIndicator(color: CouleursApp.primaire),
      );
    }

    final cible = _cible;

    return FlutterMap(
      mapController: widget.mapController,
      options: MapOptions(
        initialCenter: centre,
        initialZoom: 16.0,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.camtrans.app',
        ),

        // Polyligne premium : couleur primaire + bordure lisse.
        if (widget.etat.pointsItineraire.isNotEmpty)
          PolylineLayer(
            polylines: [
              Polyline(
                points: widget.etat.pointsItineraire,
                color: CouleursApp.primaire,
                strokeWidth: 6.0,
                borderStrokeWidth: 2.0,
                borderColor: Colors.white,
              ),
            ],
          ),

        // Marqueurs : cible (fixe) + véhicule (animé).
        MarkerLayer(
          markers: [
            if (cible != null)
              Marker(
                point: cible,
                width: 50,
                height: 50,
                child: _marqueurCible(),
              ),
          ],
        ),

        // Le véhicule est dans sa propre couche animée.
        AnimatedBuilder(
          animation: _controleur,
          builder: (context, _) {
            final pos = _positionAnimee();
            return MarkerLayer(
              markers: [
                Marker(
                  point: pos,
                  width: 54,
                  height: 54,
                  child: _marqueurVehicule(),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _marqueurVehicule() {
    return Container(
      decoration: BoxDecoration(
        color: CouleursApp.primaire,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Transform.rotate(
        angle: _cap, // oriente le "nez" dans le sens du mouvement
        child: const Icon(Icons.navigation, color: Colors.white, size: 26),
      ),
    );
  }

  Widget _marqueurCible() {
    return Container(
      decoration: BoxDecoration(
        color: CouleursApp.secondaire, // ocre/orange charte
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Icon(
        widget.etat.phase == PhaseSuivi.approche ? Icons.person : Icons.flag,
        color: Colors.white,
        size: 24,
      ),
    );
  }
}
