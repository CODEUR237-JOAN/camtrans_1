import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../coeur/constantes/couleurs.dart';
import '../../coeur/widgets/bouton_principal.dart';

class NavigationTransporteur extends StatefulWidget {
  const NavigationTransporteur({super.key});

  @override
  State<NavigationTransporteur> createState() =>
      _NavigationTransporteurState();
}

class _NavigationTransporteurState
    extends State<NavigationTransporteur> {
  final MapController controleurCarte = MapController();

  final LatLng positionInitiale = const LatLng(4.0511, 9.7679);

  final List<Marker> marqueurs = [
    const Marker(
      point: LatLng(4.0511, 9.7679),
      child: Icon(Icons.location_on, color: Colors.red),
    ),
    const Marker(
      point: LatLng(3.8480, 11.5021),
      child: Icon(Icons.flag, color: Colors.green),
    ),
  ];

  double progression = 0.35;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: controleurCarte,
            options: MapOptions(
              initialCenter: positionInitiale,
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
                shape: RoundedRectangleBorder(
                  borderRadius:
                  BorderRadius.circular(18),
                ),
                child: Padding(
                  padding:
                  const EdgeInsets.all(18),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        "Navigation en cours",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight:
                          FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 15),

                      LinearProgressIndicator(
                        value: progression,
                        minHeight: 8,
                        borderRadius:
                        BorderRadius.circular(
                            20),
                      ),

                      const SizedBox(height: 10),

                      Text(
                        "${(progression * 100).toInt()} % du trajet effectué",
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          DraggableScrollableSheet(
            initialChildSize: 0.33,
            minChildSize: 0.25,
            maxChildSize: 0.75,
            builder: (
                context,
                scrollController,
                ) {
              return Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                  BorderRadius.vertical(
                    top: Radius.circular(30),
                  ),
                ),
                child: ListView(
                  controller: scrollController,
                  padding:
                  const EdgeInsets.all(20),
                  children: [
                    Center(
                      child: Container(
                        width: 60,
                        height: 6,
                        decoration:
                        BoxDecoration(
                          color: Colors.grey,
                          borderRadius:
                          BorderRadius.circular(
                              20),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    const ListTile(
                      leading: CircleAvatar(
                        radius: 28,
                        backgroundImage:
                        AssetImage(
                          "assets/images/client.jpg",
                        ),
                      ),
                      title: Text(
                        "Jean Dupont",
                        style: TextStyle(
                          fontWeight:
                          FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        "Client",
                      ),
                    ),

                    const Divider(),

                    const ListTile(
                      leading: Icon(
                        Icons.location_on,
                        color: Colors.red,
                      ),
                      title: Text(
                        "Départ",
                      ),
                      subtitle: Text(
                        "Akwa, Douala",
                      ),
                    ),

                    const ListTile(
                      leading: Icon(
                        Icons.flag,
                        color: Colors.green,
                      ),
                      title: Text(
                        "Destination",
                      ),
                      subtitle: Text(
                        "Centre-ville, Yaoundé",
                      ),
                    ),

                    const ListTile(
                      leading: Icon(
                        Icons.timer,
                      ),
                      title: Text(
                        "Temps restant",
                      ),
                      subtitle: Text(
                        "2 h 45 min",
                      ),
                    ),

                    const ListTile(
                      leading: Icon(
                        Icons.route,
                      ),
                      title: Text(
                        "Distance restante",
                      ),
                      subtitle: Text(
                        "148 Km",
                      ),
                    ),

                    const SizedBox(height: 20),

                    Row(
                      children: [
                        Expanded(
                          child:
                          ElevatedButton.icon(
                            onPressed: () {},
                            icon:
                            const Icon(
                              Icons.phone,
                            ),
                            label:
                            const Text(
                              "Appeler",
                            ),
                          ),
                        ),

                        const SizedBox(width: 15),

                        Expanded(
                          child:
                          ElevatedButton.icon(
                            onPressed: () {},
                            icon:
                            const Icon(
                              Icons.chat,
                            ),
                            label:
                            const Text(
                              "Message",
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    BoutonPrincipal(
                      texte:
                      "Course terminée",
                      icone:
                      Icons.check_circle,
                      auClic: () {
                        ScaffoldMessenger.of(
                            context)
                            .showSnackBar(
                          const SnackBar(
                            content: Text(
                              "Course terminée avec succès.",
                            ),
                          ),
                        );

                        Navigator.pop(context);
                      },
                    ),

                    const SizedBox(height: 15),

                    OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(
                        Icons.warning,
                        color: Colors.orange,
                      ),
                      label: const Text(
                        "Signaler un problème",
                      ),
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
              backgroundColor:
              CouleursApp.primaire,
              child: const Icon(
                Icons.my_location,
              ),
              onPressed: () {
                controleurCarte.move(const LatLng(4.0511, 9.7679), 14);
              },
            ),
          ),
        ],
      ),
    );
  }
}