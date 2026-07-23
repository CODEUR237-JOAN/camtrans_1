import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../coeur/constantes/couleurs.dart';

/// Abstraction de la carte. Prêt pour migration vers Google Maps si besoin.
class CarteSuiviAbstraite extends StatefulWidget {
  final LatLng depart;
  final LatLng arrivee;
  final LatLng? transporteur;
  final Function(MapController)? onMapCreated;

  const CarteSuiviAbstraite({
    super.key,
    required this.depart,
    required this.arrivee,
    this.transporteur,
    this.onMapCreated,
  });

  @override
  State<CarteSuiviAbstraite> createState() => _CarteSuiviAbstraiteState();
}

class _CarteSuiviAbstraiteState extends State<CarteSuiviAbstraite> {
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    if (widget.onMapCreated != null) {
      widget.onMapCreated!(_mapController);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Si la position du transporteur est inconnue, centrer entre le départ et l'arrivée
    final centre = widget.transporteur ?? 
        LatLng(
          (widget.depart.latitude + widget.arrivee.latitude) / 2,
          (widget.depart.longitude + widget.arrivee.longitude) / 2,
        );

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: centre,
        initialZoom: 14.5,
        maxZoom: 18,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.camtrans.app',
        ),
        // Tracé
        PolylineLayer(
          polylines: [
            Polyline(
              points: [widget.depart, widget.arrivee], // Ligne droite simplifiée
              color: CouleursApp.primaire.withValues(alpha: 0.5),
              strokeWidth: 4,
            ),
          ],
        ),
        // Marqueurs
        MarkerLayer(
          markers: [
            Marker(
              point: widget.depart,
              width: 40,
              height: 40,
              child: const Icon(Icons.location_on, color: Colors.green, size: 40),
            ),
            Marker(
              point: widget.arrivee,
              width: 40,
              height: 40,
              child: const Icon(Icons.location_on, color: Colors.red, size: 40),
            ),
            if (widget.transporteur != null)
              Marker(
                point: widget.transporteur!,
                width: 60,
                height: 60,
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8)],
                  ),
                  child: Center(
                    child: Icon(Icons.local_shipping, color: CouleursApp.primaire, size: 30),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
