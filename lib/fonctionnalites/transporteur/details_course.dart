import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../coeur/constantes/couleurs.dart';
import '../../coeur/constantes/tailles.dart';

class DetailsCourse extends StatelessWidget {
  const DetailsCourse({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CouleursApp.fond,
      appBar: AppBar(
        title: const Text("Détails de la course"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(
          TaillesApp.margePage,
        ),
        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            Container(
              height: 220,
              decoration: BoxDecoration(
                borderRadius:
                BorderRadius.circular(20),
              ),
              clipBehavior: Clip.antiAlias,
              child: FlutterMap(
                options: const MapOptions(
                  initialCenter: LatLng(4.0511, 9.7679),
                  initialZoom: 7,
                ),
                children: [
                  TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.joan.update_camtrans',
          ),
                  const MarkerLayer(
                    markers: [
                      Marker(
                        point: LatLng(4.0511, 9.7679),
                        child: Icon(Icons.location_on, color: Colors.red),
                      ),
                      Marker(
                        point: LatLng(3.8480, 11.5021),
                        child: Icon(Icons.flag, color: Colors.green),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            const Text(
              "Informations du client",
              style: TextStyle(
                fontSize: 20,
                fontWeight:
                FontWeight.bold,
              ),
            ),

            const SizedBox(height: 15),

            Card(
              child: ListTile(
                leading: const CircleAvatar(
                  radius: 28,
                  backgroundImage:
                  AssetImage(
                    "assets/images/client.jpg",
                  ),
                ),
                title: const Text(
                  "Jean Dupont",
                ),
                subtitle: const Text(
                  "+237 699 12 34 56",
                ),
                trailing: IconButton(
                  onPressed: () {},
                  icon: const Icon(
                    Icons.phone,
                    color: Colors.green,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 25),

            const Text(
              "Trajet",
              style: TextStyle(
                fontSize: 20,
                fontWeight:
                FontWeight.bold,
              ),
            ),

            const SizedBox(height: 15),

            Card(
              child: Column(
                children: const [
                  ListTile(
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
                  Divider(),
                  ListTile(
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
                ],
              ),
            ),

            const SizedBox(height: 25),

            const Text(
              "Marchandise",
              style: TextStyle(
                fontSize: 20,
                fontWeight:
                FontWeight.bold,
              ),
            ),

            const SizedBox(height: 15),

            Card(
              child: Column(
                children: const [
                  ListTile(
                    leading:
                    Icon(Icons.inventory),
                    title:
                    Text("Type"),
                    subtitle:
                    Text("Mobilier"),
                  ),
                  Divider(),
                  ListTile(
                    leading:
                    Icon(Icons.scale),
                    title:
                    Text("Poids"),
                    subtitle:
                    Text("850 Kg"),
                  ),
                  Divider(),
                  ListTile(
                    leading:
                    Icon(Icons.all_inbox),
                    title:
                    Text("Volume"),
                    subtitle:
                    Text("4.5 m³"),
                  ),
                  Divider(),
                  ListTile(
                    leading:
                    Icon(Icons.route),
                    title:
                    Text("Distance"),
                    subtitle:
                    Text("245 Km"),
                  ),
                  Divider(),
                  ListTile(
                    leading:
                    Icon(Icons.timer),
                    title:
                    Text("Durée estimée"),
                    subtitle:
                    Text("4 h 30"),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            const Text(
              "Photos de la marchandise",
              style: TextStyle(
                fontSize: 20,
                fontWeight:
                FontWeight.bold,
              ),
            ),

            const SizedBox(height: 15),

            SizedBox(
              height: 110,
              child: ListView(
                scrollDirection:
                Axis.horizontal,
                children: List.generate(
                  3,
                      (index) => Container(
                    width: 120,
                    margin:
                    const EdgeInsets.only(
                      right: 15,
                    ),
                    decoration:
                    BoxDecoration(
                      color:
                      Colors.grey.shade200,
                      borderRadius:
                      BorderRadius.circular(
                          15),
                    ),
                    child: const Icon(
                      Icons.image,
                      size: 50,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 25),

            Card(
              color:
              Colors.green.shade50,
              child: const ListTile(
                leading: Icon(
                  Icons.payments,
                  color: Colors.green,
                ),
                title: Text(
                  "Montant proposé",
                ),
                subtitle:
                Text("30 000 FCFA"),
              ),
            ),

            const SizedBox(height: 30),

            Row(
              children: [
                Expanded(
                  child:
                  OutlinedButton.icon(
                    style:
                    OutlinedButton.styleFrom(
                      minimumSize:
                      const Size(
                        double.infinity,
                        55,
                      ),
                    ),
                    onPressed: () {
                      Navigator.pop(
                          context);
                    },
                    icon: const Icon(
                      Icons.close,
                      color: Colors.red,
                    ),
                    label: const Text(
                      "Refuser",
                      style: TextStyle(
                        color: Colors.red,
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 15),

                Expanded(
                  child:
                  ElevatedButton.icon(
                    style:
                    ElevatedButton.styleFrom(
                      backgroundColor:
                      CouleursApp
                          .primaire,
                      foregroundColor:
                      Colors.white,
                      minimumSize:
                      const Size(
                        double.infinity,
                        55,
                      ),
                    ),
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        "/navigation",
                      );
                    },
                    icon: const Icon(
                      Icons.check,
                    ),
                    label: const Text(
                      "Accepter",
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}