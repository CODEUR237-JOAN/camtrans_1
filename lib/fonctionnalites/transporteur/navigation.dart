import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:update_camtrans/coeur/constantes/couleurs.dart';
import 'package:update_camtrans/coeur/etat/transporteur_provider.dart';
import 'package:update_camtrans/services/service_gps.dart';

class NavigationTransporteur extends ConsumerStatefulWidget {
  const NavigationTransporteur({super.key});

  @override
  ConsumerState<NavigationTransporteur> createState() => _NavigationTransporteurState();
}

class _NavigationTransporteurState extends ConsumerState<NavigationTransporteur> {
  final MapController controleurCarte = MapController();
  double progression = 0.35;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(serviceGpsProvider).verifierPermissions().then((autorise) {
        if (!autorise && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Le GPS est requis pour guider votre trajet."),
              backgroundColor: Colors.orange,
            ),
          );
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final activeCourse = ref.watch(activeCourseProvider);

    if (activeCourse == null) {
      return Scaffold(
        backgroundColor: CouleursApp.fond,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.map_outlined, size: 80, color: Colors.grey),
              const SizedBox(height: 20),
              const Text("Aucune course active", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 10),
              const Text("Acceptez une course sur le marché pour commencer.", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      );
    }

    // Coordonnées réelles ou mockées si non définies
    final LatLng depart = LatLng(activeCourse.latitudeDepart != 0 ? activeCourse.latitudeDepart : 4.0511, activeCourse.longitudeDepart != 0 ? activeCourse.longitudeDepart : 9.7679);
    final LatLng arrivee = LatLng(activeCourse.latitudeArrivee != 0 ? activeCourse.latitudeArrivee : 3.8480, activeCourse.longitudeArrivee != 0 ? activeCourse.longitudeArrivee : 11.5021);

    final List<Marker> marqueurs = [
      Marker(point: depart, child: const Icon(Icons.location_on, color: Colors.red, size: 30)),
      Marker(point: arrivee, child: const Icon(Icons.flag, color: Colors.green, size: 30)),
    ];

    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: controleurCarte,
            options: MapOptions(
              initialCenter: depart,
              initialZoom: 11,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.joan.update_camtrans',
              ),
              MarkerLayer(markers: marqueurs),
            ],
          ),

          SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: Card(
                margin: const EdgeInsets.all(15),
                elevation: 5,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        "Course en cours",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      LinearProgressIndicator(
                        value: progression,
                        minHeight: 8,
                        borderRadius: BorderRadius.circular(20),
                        backgroundColor: Colors.grey.shade200,
                        color: CouleursApp.primaire,
                      ),
                      const SizedBox(height: 10),
                      Text("${(progression * 100).toInt()} % du trajet effectué", style: const TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
            ),
          ),

          DraggableScrollableSheet(
            initialChildSize: 0.33,
            minChildSize: 0.25,
            maxChildSize: 0.85,
            builder: (context, scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 20)],
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                ),
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(24),
                  children: [
                    Center(child: Container(width: 50, height: 5, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)))),
                    const SizedBox(height: 20),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const CircleAvatar(radius: 28, backgroundColor: Colors.grey, child: Icon(Icons.person, color: Colors.white)),
                      title: Text(activeCourse.nomClient, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      subtitle: const Text("Client"),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            onPressed: () => _appelerClient(activeCourse.telephoneClient),
                            icon: const Icon(Icons.phone, color: Colors.green),
                            style: IconButton.styleFrom(backgroundColor: Colors.green.withValues(alpha: 0.1)),
                          ),
                          IconButton(
                            onPressed: () {
                               ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Le chat avec le client sera bientôt disponible.")));
                            },
                            icon: const Icon(Icons.chat, color: Colors.blue),
                            style: IconButton.styleFrom(backgroundColor: Colors.blue.withValues(alpha: 0.1)),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 30),
                    _buildStepInfo(Icons.location_on, "Départ", activeCourse.adresseDepart, Colors.red),
                    const SizedBox(height: 16),
                    _buildStepInfo(Icons.flag, "Destination", activeCourse.adresseArrivee, Colors.green),
                    const SizedBox(height: 16),
                    _buildStepInfo(Icons.inventory_2, "Marchandise", activeCourse.description, Colors.orange),
                    const SizedBox(height: 30),


                    const SizedBox(height: 15),
                    OutlinedButton.icon(
                      onPressed: () {
                         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Retard signalé au client et à l'administration.")));
                      },
                      icon: const Icon(Icons.warning_amber_rounded, color: Colors.orange),
                      label: const Text("Signaler un retard", style: TextStyle(color: Colors.orange)),
                      style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.orange), padding: const EdgeInsets.symmetric(vertical: 12)),
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              );
            },
          ),

          Positioned(
            bottom: 330,
            right: 20,
            child: FloatingActionButton(
              backgroundColor: Colors.white,
              onPressed: () => controleurCarte.move(depart, 14),
              child: const Icon(Icons.my_location, color: CouleursApp.primaire),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepInfo(IconData icone, String titre, String valeur, Color couleur) {
    return Row(
      children: [
        Icon(icone, color: couleur, size: 24),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(titre, style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
              Text(valeur, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ],
    );
  }

  void _appelerClient(String tel) {
    if (tel.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Numéro de téléphone non renseigné")));
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Appel de $tel en cours...")));
  }

}
