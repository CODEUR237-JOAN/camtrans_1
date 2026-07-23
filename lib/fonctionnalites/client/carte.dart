import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../coeur/constantes/couleurs.dart';
import '../../coeur/etat/carte_provider.dart';
import '../../services/cache_tile_provider.dart';
import '../../services/service_gps.dart';
import 'widgets/couche_transporteurs.dart';

class VueCarte extends ConsumerStatefulWidget {
  const VueCarte({super.key});

  @override
  ConsumerState<VueCarte> createState() => _VueCarteState();
}

class _VueCarteState extends ConsumerState<VueCarte> with TickerProviderStateMixin {
  final MapController _mapController = MapController();

  void _centrerSurMoi(LatLng? position) {
    if (position != null) {
      _animerCarte(position, 16.0);
    }
  }

  void _animerCarte(LatLng destination, double zoomDestination) {
    final latTween = Tween<double>(
      begin: _mapController.camera.center.latitude,
      end: destination.latitude,
    );
    final lngTween = Tween<double>(
      begin: _mapController.camera.center.longitude,
      end: destination.longitude,
    );
    final zoomTween = Tween<double>(
      begin: _mapController.camera.zoom,
      end: zoomDestination,
    );

    final animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    final animation = CurvedAnimation(
      parent: animationController,
      curve: Curves.fastOutSlowIn,
    );

    animationController.addListener(() {
      _mapController.move(
        LatLng(latTween.evaluate(animation), lngTween.evaluate(animation)),
        zoomTween.evaluate(animation),
      );
    });

    animation.addStatusListener((status) {
      if (status == AnimationStatus.completed || status == AnimationStatus.dismissed) {
        animationController.dispose();
      }
    });

    animationController.forward();
  }

  @override
  Widget build(BuildContext context) {
    final etatCarte = ref.watch(carteProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Carte"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          if (etatCarte.horsLigne)
            Container(
              width: double.infinity,
              color: Colors.orange.shade100,
              padding: const EdgeInsets.all(8.0),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.wifi_off, color: Colors.orange),
                  SizedBox(width: 8),
                  Text(
                    "Mode hors ligne actif.",
                    style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          if (etatCarte.erreurGps)
            Container(
              width: double.infinity,
              color: CouleursApp.erreur.withValues(alpha: 0.1),
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                children: [
                  const Icon(Icons.location_off, color: CouleursApp.erreur),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      "Le GPS est désactivé ou l'autorisation a été refusée.",
                      style: TextStyle(color: CouleursApp.erreur),
                    ),
                  ),
                  TextButton(
                    onPressed: () async {
                      final serviceGps = ref.read(serviceGpsProvider);
                      await serviceGps.ouvrirParametresApplication();
                      ref.read(carteProvider.notifier).actualiserPosition();
                    },
                    child: const Text("Paramètres"),
                  ),
                ],
              ),
            ),
          Expanded(
            child: etatCarte.chargement
                ? const Center(child: CircularProgressIndicator())
                : FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: etatCarte.positionActuelle ?? const LatLng(3.8480, 11.5021),
                      initialZoom: 15.0,
                      maxZoom: 19.0,
                      minZoom: 3.0,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.camtrans.update_camtrans',
                        tileProvider: CachedTileProvider(),
                      ),
                      const CoucheTransporteurs(),
                      if (etatCarte.positionActuelle != null)
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: etatCarte.positionActuelle!,
                              width: 60,
                              height: 60,
                              child: const Icon(
                                Icons.person_pin_circle,
                                color: CouleursApp.primaire,
                                size: 50,
                              )
                                  .animate(onPlay: (controller) => controller.repeat())
                                  .scale(
                                    begin: const Offset(0.9, 0.9),
                                    end: const Offset(1.1, 1.1),
                                    duration: 1.seconds,
                                    curve: Curves.easeInOut,
                                  )
                                  .then()
                                  .scale(
                                    begin: const Offset(1.1, 1.1),
                                    end: const Offset(0.9, 0.9),
                                    duration: 1.seconds,
                                    curve: Curves.easeInOut,
                                  ),
                            ),
                          ],
                        ),
                    ],
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ref.read(carteProvider.notifier).actualiserPosition();
          _centrerSurMoi(etatCarte.positionActuelle);
        },
        child: const Icon(Icons.my_location),
      ),
    );
  }
}

