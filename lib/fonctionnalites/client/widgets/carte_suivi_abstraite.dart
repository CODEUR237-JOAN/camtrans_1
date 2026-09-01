import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:update_camtrans/coeur/constantes/couleurs.dart';
import 'package:flutter_animate/flutter_animate.dart';


/// Abstraction de la carte. Prêt pour migration vers Google Maps si besoin.
class CarteSuiviAbstraite extends StatefulWidget {
  final LatLng depart;
  final LatLng arrivee;
  final LatLng? transporteur;
  final List<LatLng>? route;
  final Function(MapController)? onMapCreated;
  final bool isRemorque;

  const CarteSuiviAbstraite({
    super.key,
    required this.depart,
    required this.arrivee,
    this.transporteur,
    this.route,
    this.onMapCreated,
    this.isRemorque = false,
  });

  @override
  State<CarteSuiviAbstraite> createState() => _CarteSuiviAbstraiteState();
}

class _CarteSuiviAbstraiteState extends State<CarteSuiviAbstraite> with SingleTickerProviderStateMixin {
  final MapController _mapController = MapController();
  late AnimationController _polyAnimation;

  @override
  void initState() {
    super.initState();
    _polyAnimation = AnimationController(vsync: this, duration: const Duration(seconds: 3))..forward();
    if (widget.onMapCreated != null) {
      widget.onMapCreated!(_mapController);
    }
  }

  @override
  void dispose() {
    _polyAnimation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Si la position du transporteur est inconnue, centrer entre le départ et l'arrivée
    final centre = widget.transporteur ?? 
        LatLng(
          (widget.depart.latitude + widget.arrivee.latitude) / 2,
          (widget.depart.longitude + widget.arrivee.longitude) / 2,
        );

    return Stack(
      children: [
        FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: centre,
        initialZoom: 14.5,
        maxZoom: 18,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          subdomains: const [],
          userAgentPackageName: 'com.joan.update_camtrans',
        ),
        // Tracé
        AnimatedBuilder(
          animation: _polyAnimation,
          builder: (context, child) {
            final points = widget.route != null && widget.route!.isNotEmpty 
                ? widget.route! 
                : [widget.depart, widget.arrivee];
            
            final animatedPoints = points.take((points.length * _polyAnimation.value).ceil()).toList();
            
            return PolylineLayer(
              polylines: [
                Polyline(
                  points: animatedPoints,
                  color: widget.isRemorque ? const Color(0xFF3B82F6) : CouleursApp.primaire.withValues(alpha: 0.8),
                  strokeWidth: 5,
                ),
              ],
            );
          },
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
                  decoration: BoxDecoration(
                    color: widget.isRemorque ? const Color(0xFF0F172A) : Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: widget.isRemorque ? const Color(0xFF3B82F6).withValues(alpha: 0.5) : Colors.black26, blurRadius: 8)],
                  ),
                  child: Center(
                    child: Icon(
                      widget.isRemorque ? Icons.build_circle : Icons.local_shipping, 
                      color: widget.isRemorque ? const Color(0xFF3B82F6) : CouleursApp.primaire, 
                      size: 30
                    ).animate(onPlay: (controller) => controller.repeat()).shimmer(duration: 1500.ms),
                  ),
                ),
              ),
          ],
        ),
      ],
        ),
        // Contrôles de zoom
        Positioned(
          right: 16,
          bottom: 32,
          child: Column(
            children: [
              FloatingActionButton(
                heroTag: 'zoomIn',
                mini: true,
                backgroundColor: CouleursApp.primaire,
                onPressed: () {
                  final zoom = _mapController.camera.zoom + 1;
                  _mapController.move(_mapController.camera.center, zoom);
                },
                child: const Icon(Icons.add, color: Colors.white),
              ),
              const SizedBox(height: 8),
              FloatingActionButton(
                heroTag: 'zoomOut',
                mini: true,
                backgroundColor: CouleursApp.primaire,
                onPressed: () {
                  final zoom = _mapController.camera.zoom - 1;
                  _mapController.move(_mapController.camera.center, zoom);
                },
                child: const Icon(Icons.remove, color: Colors.white),
              ),
            ],
          ),
        ),
      ],
    );
  }
}