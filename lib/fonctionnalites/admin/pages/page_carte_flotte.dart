import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import 'package:update_camtrans/coeur/etat/admin_provider.dart';
import 'package:update_camtrans/coeur/constantes/couleurs.dart';
import 'package:update_camtrans/modeles/transporteur.dart';
import 'package:flutter_animate/flutter_animate.dart';


class PageCarteFlotte extends ConsumerStatefulWidget {
  const PageCarteFlotte({super.key});

  @override
  ConsumerState<PageCarteFlotte> createState() => _PageCarteFlotteState();
}

class _PageCarteFlotteState extends ConsumerState<PageCarteFlotte> {
  final MapController _mapController = MapController();
  final LatLng _centreParDefaut = const LatLng(3.8480, 11.5021); // Yaoundé par défaut

  @override
  Widget build(BuildContext context) {
    final transporteursAsync = ref.watch(adminTransporteursProvider);
    final isSatellite = ref.watch(isSatelliteViewProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF08111F),
      body: Stack(
        children: [
          // Carte
          transporteursAsync.when(
            loading: () => const Center(child: CircularProgressIndicator(color: CouleursApp.primaire)),
            error: (err, _) => Center(child: Text("Erreur : $err", style: const TextStyle(color: Colors.white))),
            data: (transporteurs) {
              final transporteursEnLigne = transporteurs.where((t) => t.disponible && t.latitude != 0 && t.longitude != 0).toList();
              
              return FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _centreParDefaut,
                  initialZoom: 12.0,
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                  ),
                ),
                children: [
                  TileLayer(
                    urlTemplate: isSatellite ? urlCarteSatellite : urlCarteStandard,
                  ),
                  MarkerLayer(
                    markers: transporteursEnLigne.map((t) {
                      return Marker(
                        point: LatLng(t.latitude, t.longitude),
                        width: 60,
                        height: 60,
                        child: _buildTransporteurMarker(t),
                      );
                    }).toList(),
                  ),
                ],
              );
            },
          ),
          
          // Header / HUD
          Positioned(
            top: 24,
            left: 24,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A).withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Flotte en temps réel",
                    style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  transporteursAsync.when(
                    data: (transporteurs) {
                      final actifs = transporteurs.where((t) => t.disponible).length;
                      return Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                              color: Colors.greenAccent,
                              shape: BoxShape.circle,
                            ),
                          ).animate(onPlay: (controller) => controller.repeat(reverse: true)).fade(duration: 1.seconds),
                          const SizedBox(width: 8),
                          Text("$actifs transporteurs actifs", style: GoogleFonts.inter(color: Colors.white70, fontSize: 14)),
                        ],
                      );
                    },
                    loading: () => const Text("Chargement...", style: TextStyle(color: Colors.white54)),
                    error: (error, stackTrace) => const Text("Erreur", style: TextStyle(color: Colors.redAccent)),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            InkWell(
              onTap: () {
                    ref.read(isSatelliteViewProvider.notifier).state = !isSatellite;
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A).withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: Icon(
                      isSatellite ? Icons.map : Icons.satellite_alt,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Contrôles de zoom
          Positioned(
            bottom: 24,
            right: 24,
            child: Column(
              children: [
                _buildZoomButton(Icons.add, () {
                  _mapController.move(_mapController.camera.center, _mapController.camera.zoom + 1);
                }),
                const SizedBox(height: 12),
                _buildZoomButton(Icons.remove, () {
                  _mapController.move(_mapController.camera.center, _mapController.camera.zoom - 1);
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildZoomButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A).withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Icon(icon, color: Colors.white, size: 24),
      ),
    );
  }

  Widget _buildTransporteurMarker(Transporteur t) {
    return GestureDetector(
      onTap: () {
        _mapController.move(LatLng(t.latitude, t.longitude), 15.0);
        _afficherDetailsTransporteur(t);
      },
      child: SizedBox(
        width: 60,
        height: 60,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: CouleursApp.primaire,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: CouleursApp.primaire.withValues(alpha: 0.5),
                    blurRadius: 10,
                    spreadRadius: 2,
                  )
                ],
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Icon(
                t.typeVehicule == "Moto" ? Icons.motorcycle : Icons.local_shipping,
                color: Colors.white,
                size: 16,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                t.nom.isNotEmpty ? t.nom : (t.prenom.isNotEmpty ? t.prenom : 'Inconnu'),
                style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _afficherDetailsTransporteur(Transporteur t) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Color(0xFF0F172A),
            borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: CouleursApp.primaire.withValues(alpha: 0.2),
                    backgroundImage: t.photo.isNotEmpty ? NetworkImage(t.photo) : null,
                    child: t.photo.isEmpty ? const Icon(Iconsax.user_copy, color: CouleursApp.primaire) : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("${t.prenom} ${t.nom}", style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.white)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.star, color: Colors.amber, size: 16),
                            const SizedBox(width: 4),
                            Text("${t.noteMoyenne} (${t.nombreCourses})", style: GoogleFonts.inter(color: Colors.white70)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text("En ligne", style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _InfoItem(icone: Iconsax.car_copy, titre: "Véhicule", valeur: t.typeVehicule),
                  _InfoItem(icone: Iconsax.card_copy, titre: "Immatriculation", valeur: t.immatriculation),
                  _InfoItem(icone: Icons.money, titre: "Gains", valeur: "${t.revenusTotaux} FCFA"),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  const Icon(Iconsax.location_copy, color: Colors.blueAccent, size: 20),
                  const SizedBox(width: 8),
                  Text("Lieu actuel : ", style: GoogleFonts.inter(color: Colors.white54, fontSize: 13)),
                  Text(
                    "${t.latitude.toStringAsFixed(5)}, ${t.longitude.toStringAsFixed(5)}",
                    style: GoogleFonts.inter(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }
}

class _InfoItem extends StatelessWidget {
  final IconData icone;
  final String titre;
  final String valeur;

  const _InfoItem({required this.icone, required this.titre, required this.valeur});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icone, color: Colors.white54, size: 24),
        const SizedBox(height: 8),
        Text(titre, style: GoogleFonts.inter(color: Colors.white54, fontSize: 12)),
        const SizedBox(height: 4),
        Text(valeur, style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
      ],
    );
  }
}
