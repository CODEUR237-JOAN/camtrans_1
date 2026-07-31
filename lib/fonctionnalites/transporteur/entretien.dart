import 'package:flutter/material.dart';

import '../../coeur/constantes/couleurs.dart';
import '../../coeur/constantes/tailles.dart';

class Entretien extends StatefulWidget {
  const Entretien({super.key});

  @override
  State<Entretien> createState() => _EntretienState();
}

class _EntretienState extends State<Entretien> {
  final List<Map<String, dynamic>> entretiens = [
    {
      "titre": "Vidange moteur",
      "date": "15 Juin 2026",
      "prochain": "15 Septembre 2026",
      "icone": Icons.oil_barrel,
      "couleur": Colors.orange,
    },
    {
      "titre": "Changement des pneus",
      "date": "03 Avril 2026",
      "prochain": "03 Avril 2027",
      "icone": Icons.tire_repair,
      "couleur": Colors.blue,
    },
    {
      "titre": "Visite technique",
      "date": "10 Janvier 2026",
      "prochain": "10 Janvier 2027",
      "icone": Icons.car_repair,
      "couleur": Colors.green,
    },
    {
      "titre": "Freinage",
      "date": "20 Mai 2026",
      "prochain": "20 Novembre 2026",
      "icone": Icons.settings,
      "couleur": Colors.red,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CouleursApp.fond,
      appBar: AppBar(
        title: const Text("Entretien du véhicule"),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: CouleursApp.primaire,
        icon: const Icon(Icons.add),
        label: const Text("Ajouter"),
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                "Cette fonctionnalité sera disponible après l'intégration du backend.",
              ),
            ),
          );
        },
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(
          TaillesApp.margePage,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: CouleursApp.degradePrincipal,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  Text(
                    "Carnet d'entretien",
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    "Gardez votre véhicule en parfait état pour offrir un service de qualité.",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            Row(
              children: [
                Expanded(
                  child: _statistique(
                    "Entretiens",
                    "12",
                    Icons.build,
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: _statistique(
                    "À venir",
                    "2",
                    Icons.schedule,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 30),

            const Text(
              "Historique",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 15),

            ...entretiens.map<Widget>(
                  (entretien) => Card(
                margin:
                const EdgeInsets.only(bottom: 15),
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius:
                  BorderRadius.circular(18),
                ),
                child: ListTile(
                  contentPadding:
                  const EdgeInsets.all(15),
                  leading: CircleAvatar(
                    radius: 28,
                    backgroundColor:
                    (entretien["couleur"] as Color)
                        .withValues(alpha: .15),
                    child: Icon(
                      entretien["icone"],
                      color: entretien["couleur"],
                    ),
                  ),
                  title: Text(
                    entretien["titre"],
                    style: const TextStyle(
                      fontWeight:
                      FontWeight.bold,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      Text(
                        "Dernier entretien : ${entretien["date"]}",
                      ),
                      Text(
                        "Prochain : ${entretien["prochain"]}",
                      ),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.edit),
                    color: CouleursApp.primaire,
                    onPressed: () {},
                  ),
                ),
              ),
            ),

            const SizedBox(height: 25),

            Card(
              color: Colors.orange.shade50,
              shape: RoundedRectangleBorder(
                borderRadius:
                BorderRadius.circular(18),
              ),
              child: const ListTile(
                leading: Icon(
                  Icons.notifications_active,
                  color: Colors.orange,
                ),
                title: Text(
                  "Prochain rappel",
                ),
                subtitle: Text(
                  "Vidange moteur prévue le 15 Septembre 2026.",
                ),
              ),
            ),

            const SizedBox(height: 25),

            Card(
              color: Colors.green.shade50,
              shape: RoundedRectangleBorder(
                borderRadius:
                BorderRadius.circular(18),
              ),
              child: const ListTile(
                leading: Icon(
                  Icons.verified,
                  color: Colors.green,
                ),
                title: Text(
                  "État du véhicule",
                ),
                subtitle: Text(
                  "Votre véhicule est conforme et prêt à effectuer des courses.",
                ),
              ),
            ),

            const SizedBox(height: 90),
          ],
        ),
      ),
    );
  }

  Widget _statistique(
      String titre,
      String valeur,
      IconData icone,
      ) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius:
        BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            Icon(
              icone,
              size: 35,
              color: CouleursApp.primaire,
            ),
            const SizedBox(height: 10),
            Text(
              valeur,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 5),
            Text(titre),
          ],
        ),
      ),
    );
  }
}