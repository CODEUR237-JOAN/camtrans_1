import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:update_camtrans/coeur/constantes/couleurs.dart';

import '../etat/suivi_course_etat.dart';

class CarteSuiviInteractive extends StatelessWidget {
  final SuiviCourseEtat etat;
  final MapController mapController;

  const CarteSuiviInteractive({
    Key? key,
    required this.etat,
    required this.mapController,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (etat.positionChauffeur == null) {
      return const Center(
        child: CircularProgressIndicator(color: CouleursApp.primaire),
      );
    }

    final cible = etat.phase == PhaseSuivi.approche
        ? etat.positionClient
        : etat.positionDestination;

    return FlutterMap(
      mapController: mapController,
      options: MapOptions(
        initialCenter: etat.positionChauffeur!,
        initialZoom: 16.0,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.camtrans.app',
        ),
        if (etat.pointsItineraire.isNotEmpty)
          PolylineLayer(
            polylines: [
              Polyline(
                points: etat.pointsItineraire,
                color: const Color(0xFF145C43), // Vert charte
                strokeWidth: 5.0,
              ),
            ],
          ),
        MarkerLayer(
          markers: [
            // Marqueur Chauffeur
            Marker(
              point: etat.positionChauffeur!,
              width: 50,
              height: 50,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF145C43), // Vert transporteur
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
                child: const Icon(
                  Icons.local_shipping,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
            // Marqueur Cible (Client ou Destination)
            if (cible != null)
              Marker(
                point: cible,
                width: 50,
                height: 50,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFC1652F), // Ocre charte
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
                    etat.phase == PhaseSuivi.approche ? Icons.person : Icons.flag,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
