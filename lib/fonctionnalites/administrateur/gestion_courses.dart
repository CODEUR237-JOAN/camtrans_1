import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../coeur/constantes/couleurs.dart';
import '../../coeur/constantes/tailles.dart';

class GestionCourses extends StatefulWidget {
  const GestionCourses({super.key});

  @override
  State<GestionCourses> createState() => _GestionCoursesState();
}

class _GestionCoursesState extends State<GestionCourses> {
  String filtre = "Toutes";

  final List<Map<String, dynamic>> courses = [
    {
      "client": "Jean Dupont",
      "transporteur": "Paul Mvondo",
      "depart": "Douala",
      "arrivee": "Yaoundé",
      "prix": "30 000 FCFA",
      "statut": "Terminée",
      "couleur": Colors.green,
    },
    {
      "client": "Marie Ndzi",
      "transporteur": "Patrick Ndzi",
      "depart": "Kribi",
      "arrivee": "Douala",
      "prix": "18 000 FCFA",
      "statut": "En cours",
      "couleur": Colors.orange,
    },
    {
      "client": "Samuel Momo",
      "transporteur": "Non attribué",
      "depart": "Bafoussam",
      "arrivee": "Douala",
      "prix": "52 000 FCFA",
      "statut": "En attente",
      "couleur": Colors.blue,
    },
    {
      "client": "Brice Ndzi",
      "transporteur": "Jean Mvondo",
      "depart": "Garoua",
      "arrivee": "Ngaoundéré",
      "prix": "120 000 FCFA",
      "statut": "Annulée",
      "couleur": Colors.red,
    },
  ];

  final LatLng positionInitiale = const LatLng(4.0511, 9.7679);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CouleursApp.fond,

      appBar: AppBar(
        title: const Text("Gestion des courses"),
      ),

      body: Padding(
        padding: const EdgeInsets.all(
          TaillesApp.margePage,
        ),
        child: Column(
          children: [
            TextField(
              decoration: InputDecoration(
                hintText: "Rechercher une course...",
                prefixIcon:
                const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius:
                  BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            const SizedBox(height: 15),

            SingleChildScrollView(
              scrollDirection:
              Axis.horizontal,
              child: Row(
                children: [
                  _filtre("Toutes"),
                  _filtre("En attente"),
                  _filtre("En cours"),
                  _filtre("Terminée"),
                  _filtre("Annulée"),
                ],
              ),
            ),

            const SizedBox(height: 20),

            Expanded(
              child: ListView.builder(
                itemCount: courses.length,
                itemBuilder: (context, index) {
                  final course =
                  courses[index];

                  return Card(
                    margin:
                    const EdgeInsets.only(
                      bottom: 15,
                    ),
                    shape:
                    RoundedRectangleBorder(
                      borderRadius:
                      BorderRadius.circular(
                          18),
                    ),
                    child: ExpansionTile(
                      leading: CircleAvatar(
                        backgroundColor:
                        (course["couleur"]
                        as Color)
                            .withValues(alpha: .15),
                        child: Icon(
                          Icons.local_shipping,
                          color:
                          course["couleur"],
                        ),
                      ),

                      title: Text(
                        "${course["depart"]} → ${course["arrivee"]}",
                        style:
                        const TextStyle(
                          fontWeight:
                          FontWeight.bold,
                        ),
                      ),

                      subtitle: Text(
                        course["statut"],
                        style: TextStyle(
                          color:
                          course["couleur"],
                          fontWeight:
                          FontWeight.bold,
                        ),
                      ),

                      children: [
                        ListTile(
                          leading:
                          const Icon(Icons.person),
                          title:
                          const Text("Client"),
                          subtitle:
                          Text(course["client"]),
                        ),

                        ListTile(
                          leading: const Icon(
                              Icons.local_shipping),
                          title: const Text(
                              "Transporteur"),
                          subtitle: Text(
                            course[
                            "transporteur"],
                          ),
                        ),

                        ListTile(
                          leading: const Icon(
                              Icons.payments),
                          title: const Text(
                              "Montant"),
                          subtitle:
                          Text(course["prix"]),
                        ),

                        SizedBox(
                          height: 220,
                          child: ClipRRect(
                            borderRadius:
                            BorderRadius.circular(
                                15),
                            child: FlutterMap(
                              options: MapOptions(
                                initialCenter: positionInitiale,
                                initialZoom: 6,
                              ),
                              children: [
                                TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.joan.update_camtrans',
          ),
                                const MarkerLayer(
                                  markers: [
                                    Marker(point: LatLng(4.0511, 9.7679), child: Icon(Icons.location_on, color: Colors.red)),
                                    Marker(point: LatLng(3.8480, 11.5021), child: Icon(Icons.flag, color: Colors.green)),
                                  ],
                                )
                              ],
                            ),
                          ),
                        ),

                        Padding(
                          padding:
                          const EdgeInsets.all(
                              15),
                          child: Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                              ElevatedButton.icon(
                                onPressed:
                                    () {},
                                icon: const Icon(
                                    Icons
                                        .visibility),
                                label:
                                const Text(
                                  "Détails",
                                ),
                              ),

                              ElevatedButton.icon(
                                onPressed:
                                    () {},
                                icon: const Icon(
                                    Icons.swap_horiz),
                                label:
                                const Text(
                                  "Réaffecter",
                                ),
                              ),

                              ElevatedButton.icon(
                                style:
                                ElevatedButton
                                    .styleFrom(
                                  backgroundColor:
                                  Colors.red,
                                ),
                                onPressed:
                                    () {},
                                icon: const Icon(
                                    Icons.cancel),
                                label:
                                const Text(
                                  "Annuler",
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filtre(String valeur) {
    final actif = filtre == valeur;

    return Padding(
      padding:
      const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(valeur),
        selected: actif,
        onSelected: (_) {
          setState(() {
            filtre = valeur;
          });
        },
      ),
    );
  }
}