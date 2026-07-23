import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../modeles/transporteur.dart';
import '../../../services/service_gps.dart';

class FicheTransporteurBottomSheet extends ConsumerWidget {
  final Transporteur transporteur;
  final LatLng positionClient;

  const FicheTransporteurBottomSheet({
    super.key,
    required this.transporteur,
    required this.positionClient,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final serviceGps = ref.watch(serviceGpsProvider);
    final distance = serviceGps.calculerDistance(
      latitudeDepart: positionClient.latitude,
      longitudeDepart: positionClient.longitude,
      latitudeArrivee: transporteur.latitude,
      longitudeArrivee: transporteur.longitude,
    );

    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.0)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundImage: transporteur.photo.isNotEmpty
                    ? NetworkImage(transporteur.photo)
                    : null,
                child: transporteur.photo.isEmpty
                    ? const Icon(Icons.person, size: 30)
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "${transporteur.prenom} ${transporteur.nom}",
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 18),
                        const SizedBox(width: 4),
                        Text(
                          transporteur.noteMoyenne > 0 
                            ? transporteur.noteMoyenne.toStringAsFixed(1) 
                            : "Nouveau",
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(width: 16),
                        const Icon(Icons.directions_car, color: Colors.grey, size: 18),
                        const SizedBox(width: 4),
                        Text(
                          transporteur.typeVehicule.isNotEmpty ? transporteur.typeVehicule : "Véhicule non défini",
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Distance",
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "${distance.toStringAsFixed(1)} km",
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Statut",
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        "Disponible",
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.green),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                // Action pour choisir ce transporteur
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Vous avez sélectionné ${transporteur.prenom}")),
                );
              },
              child: const Text("Sélectionner ce transporteur"),
            ),
          ),
        ],
      ),
    );
  }
}
