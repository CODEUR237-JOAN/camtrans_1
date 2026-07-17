import 'package:flutter/material.dart';

import '../../coeur/constantes/couleurs.dart';
import '../../coeur/constantes/tailles.dart';

class GestionClients extends StatefulWidget {
  const GestionClients({super.key});

  @override
  State<GestionClients> createState() => _GestionClientsState();
}

class _GestionClientsState extends State<GestionClients> {
  final TextEditingController rechercheController =
  TextEditingController();

  final List<Map<String, dynamic>> clients = [
    {
      "nom": "Jean Dupont",
      "telephone": "+237 699 12 34 56",
      "ville": "Douala",
      "courses": 45,
      "statut": true,
    },
    {
      "nom": "Marie Ndzi",
      "telephone": "+237 677 45 89 12",
      "ville": "Yaoundé",
      "courses": 28,
      "statut": true,
    },
    {
      "nom": "Paul Mvondo",
      "telephone": "+237 655 44 66 11",
      "ville": "Bafoussam",
      "courses": 12,
      "statut": false,
    },
    {
      "nom": "Patrick Ndzi",
      "telephone": "+237 698 77 12 33",
      "ville": "Kribi",
      "courses": 64,
      "statut": true,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CouleursApp.fond,

      appBar: AppBar(
        title: const Text("Gestion des clients"),
      ),

      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: CouleursApp.primaire,
        onPressed: () {},
        icon: const Icon(Icons.person_add),
        label: const Text("Ajouter"),
      ),

      body: Padding(
        padding: const EdgeInsets.all(
          TaillesApp.margePage,
        ),
        child: Column(
          children: [
            TextField(
              controller: rechercheController,
              decoration: InputDecoration(
                hintText: "Rechercher un client...",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius:
                  BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  child: _statistique(
                    "Clients",
                    "1 254",
                    Icons.people,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _statistique(
                    "Actifs",
                    "1 126",
                    Icons.verified,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _statistique(
                    "Suspendus",
                    "128",
                    Icons.block,
                    Colors.red,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            Expanded(
              child: ListView.builder(
                itemCount: clients.length,
                itemBuilder: (context, index) {
                  final client = clients[index];

                  return Card(
                    margin:
                    const EdgeInsets.only(
                      bottom: 15,
                    ),
                    shape:
                    RoundedRectangleBorder(
                      borderRadius:
                      BorderRadius.circular(
                        18,
                      ),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        radius: 28,
                        backgroundColor:
                        CouleursApp.primaire,
                        child: Text(
                          client["nom"]
                              .substring(0, 1),
                          style:
                          const TextStyle(
                            color: Colors.white,
                            fontWeight:
                            FontWeight.bold,
                          ),
                        ),
                      ),

                      title: Text(
                        client["nom"],
                        style:
                        const TextStyle(
                          fontWeight:
                          FontWeight.bold,
                        ),
                      ),

                      subtitle: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment
                            .start,
                        children: [
                          Text(
                            client["telephone"],
                          ),
                          Text(
                            client["ville"],
                          ),
                          Text(
                            "${client["courses"]} courses",
                          ),
                        ],
                      ),

                      trailing: PopupMenuButton(
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 1,
                            child: Text(
                              "Voir le profil",
                            ),
                          ),
                          const PopupMenuItem(
                            value: 2,
                            child: Text(
                              "Modifier",
                            ),
                          ),
                          const PopupMenuItem(
                            value: 3,
                            child: Text(
                              "Suspendre",
                            ),
                          ),
                          const PopupMenuItem(
                            value: 4,
                            child: Text(
                              "Supprimer",
                            ),
                          ),
                        ],
                      ),
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

  Widget _statistique(
      String titre,
      String valeur,
      IconData icone,
      Color couleur,
      ) {
    return Card(
      child: Padding(
        padding:
        const EdgeInsets.symmetric(
          vertical: 15,
        ),
        child: Column(
          children: [
            Icon(
              icone,
              color: couleur,
              size: 30,
            ),
            const SizedBox(height: 10),
            Text(
              valeur,
              style: const TextStyle(
                fontSize: 18,
                fontWeight:
                FontWeight.bold,
              ),
            ),
            Text(
              titre,
              textAlign: TextAlign.center,
              style:
              const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}