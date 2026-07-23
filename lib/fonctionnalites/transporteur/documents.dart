import 'package:flutter/material.dart';

import '../../coeur/constantes/couleurs.dart';
import '../../coeur/constantes/tailles.dart';

class Documents extends StatefulWidget {
  const Documents({super.key});

  @override
  State<Documents> createState() => _DocumentsState();
}

class _DocumentsState extends State<Documents> {
  final List<Map<String, dynamic>> documents = [
    {
      "nom": "Carte Nationale d'Identité",
      "icone": Icons.badge,
      "statut": "Validé",
      "couleur": Colors.green,
    },
    {
      "nom": "Permis de conduire",
      "icone": Icons.drive_eta,
      "statut": "Validé",
      "couleur": Colors.green,
    },
    {
      "nom": "Carte grise",
      "icone": Icons.directions_car,
      "statut": "En attente",
      "couleur": Colors.orange,
    },
    {
      "nom": "Assurance",
      "icone": Icons.health_and_safety,
      "statut": "À importer",
      "couleur": Colors.red,
    },
    {
      "nom": "Visite technique",
      "icone": Icons.fact_check,
      "statut": "À importer",
      "couleur": Colors.red,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CouleursApp.fond,
      appBar: AppBar(
        title: const Text("Mes documents"),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: CouleursApp.primaire,
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                "L'importation sera disponible après l'intégration du backend.",
              ),
            ),
          );
        },
        icon: const Icon(Icons.upload_file),
        label: const Text("Importer"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Documents du transporteur",
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    "Complétez tous vos documents afin de recevoir davantage de courses.",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            const Text(
              "Liste des documents",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 15),

            ...documents.map<Widget>(
                  (document) => Card(
                elevation: 3,
                margin: const EdgeInsets.only(bottom: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(15),
                  leading: CircleAvatar(
                    radius: 28,
                    backgroundColor: (document["couleur"] as Color)
                        .withValues(alpha: .15),
                    child: Icon(
                      document["icone"],
                      color: document["couleur"],
                    ),
                  ),
                  title: Text(
                    document["nom"],
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: (document["couleur"] as Color)
                                .withValues(alpha: .15),
                            borderRadius:
                            BorderRadius.circular(20),
                          ),
                          child: Text(
                            document["statut"],
                            style: TextStyle(
                              color: document["couleur"],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.upload),
                    color: CouleursApp.primaire,
                    onPressed: () {
                      ScaffoldMessenger.of(context)
                          .showSnackBar(
                        SnackBar(
                          content: Text(
                            "Importer : ${document["nom"]}",
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),

            const SizedBox(height: 25),

            Card(
              color: Colors.blue.shade50,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              child: const ListTile(
                leading: Icon(
                  Icons.info,
                  color: Colors.blue,
                ),
                title: Text(
                  "Conseil",
                ),
                subtitle: Text(
                  "Des documents validés permettent d'accéder à davantage de courses et renforcent la confiance des clients.",
                ),
              ),
            ),

            const SizedBox(height: 90),
          ],
        ),
      ),
    );
  }
}