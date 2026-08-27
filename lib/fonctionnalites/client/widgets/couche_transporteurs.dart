import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import 'package:update_camtrans/coeur/etat/transporteurs_provider.dart';
import 'package:update_camtrans/coeur/etat/carte_provider.dart';
import 'package:update_camtrans/modeles/transporteur.dart';
import 'fiche_transporteur_bottom_sheet.dart';
import 'package:update_camtrans/coeur/constantes/couleurs.dart';

class CoucheTransporteurs extends ConsumerWidget {
  const CoucheTransporteurs({super.key});

  IconData _obtenirIconeVehicule(String type) {
    switch (type.toLowerCase()) {
      case 'moto':
        return Icons.motorcycle;
      case 'voiture':
        return Icons.directions_car;
      case 'camionnette':
        return Icons.airport_shuttle;
      case 'camion léger':
        return Icons.local_shipping;
      case 'camion lourd':
        return Icons.fire_truck;
      default:
        return Icons.directions_car;
    }
  }

  void _afficherDetails(BuildContext context, Transporteur transporteur, LatLng? positionClient) {
    if (positionClient == null) return;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FicheTransporteurBottomSheet(
        transporteur: transporteur,
        positionClient: positionClient,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transporteursAsync = ref.watch(transporteursDisponiblesProvider);
    final etatCarte = ref.watch(carteProvider);

    return transporteursAsync.when(
      data: (transporteurs) {
        final markers = transporteurs.map((transporteur) {
          final position = LatLng(transporteur.latitude, transporteur.longitude);
          
          return Marker(
            point: position,
            width: 50,
            height: 50,
            child: GestureDetector(
              onTap: () => _afficherDetails(context, transporteur, etatCarte.positionActuelle),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                  border: Border.all(color: CouleursApp.primaire, width: 2),
                ),
                child: Icon(
                  _obtenirIconeVehicule(transporteur.typeVehicule),
                  color: CouleursApp.primaire,
                  size: 24,
                ),
              ),
            ).animate().scale(
              end: const Offset(1.0, 1.0),
              duration: 400.ms,
              curve: Curves.easeOutBack,
            ),
          );
        }).toList();

        return MarkerLayer(markers: markers);
      },
      loading: () => const MarkerLayer(markers: []),
      error: (error, stack) {
        debugPrint("Erreur chargement transporteurs: $error");
        return const MarkerLayer(markers: []);
      },
    );
  }
}
