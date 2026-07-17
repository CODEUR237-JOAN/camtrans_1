import 'package:flutter/material.dart';

import '../../coeur/constantes/couleurs.dart';
import '../../coeur/constantes/tailles.dart';

class GestionTransporteurs extends StatefulWidget {
  const GestionTransporteurs({super.key});

  @override
  State<GestionTransporteurs> createState() =>
      _GestionTransporteursState();
}

class _GestionTransporteursState
    extends State<GestionTransporteurs> {
  final TextEditingController rechercheController =
  TextEditingController();

  final List<Map<String, dynamic>> transporteurs = [
    {
      "nom": "Jean Mvondo",
      "telephone": "+237 699 12 34 56",
      "vehicule": "Camion 10T",
      "ville": "Douala",
      "note": "4.9",
      "courses": "328",
      "revenus": "12 500 000 FCFA",
      "documents": true,
      "actif": true,
    },
    {
      "nom": "Patrick Ndzi",
      "telephone": "+237 677 45 89 12",
      "vehicule": "Fourgon",
      "ville": "Yaoundé",
      "note": "4.8",
      "courses": "214",
      "revenus": "8 250 000 FCFA",
      "documents": false,
      "actif": true,
    },
    {
      "nom": "Franck Nguema",
      "telephone": "+237 655 11 22 33",
      "vehicule": "Pickup",
      "ville": "Bafoussam",
      "note": "4.5",
      "courses": "142",
      "revenus": "5 100 000 FCFA",
      "documents": true,
      "actif": false,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CouleursApp.fond,
      appBar: AppBar(
        title: const Text(
          "Gestion des transporteurs",
        ),
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
                hintText:
                "Rechercher un transporteur...",
                prefixIcon:
                const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius:
                  BorderRadius.circular(15),
                  borderSide:
                  BorderSide.none,
                ),
              ),
            ),

            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  child: _statistique(
                    "Transporteurs",
                    "468",
                    Icons.local_shipping,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _statistique(
                    "Actifs",
                    "430",
                    Icons.verified,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _statistique(
                    "Suspendus",
                    "38",
                    Icons.block,
                    Colors.red,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            Expanded(
              child: ListView.builder(
                itemCount:
                transporteurs.length,
                itemBuilder:
                    (context, index) {
                  final transporteur =
                  transporteurs[index];

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
                        CouleursApp
                            .primaire,
                        child: Text(
                          transporteur["nom"]
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
                        transporteur["nom"],
                        style:
                        const TextStyle(
                          fontWeight:
                          FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        transporteur[
                        "vehicule"],
                      ),
                      children: [
                        ListTile(
                          leading: const Icon(
                              Icons.phone),
                          title: const Text(
                              "Téléphone"),
                          subtitle: Text(
                            transporteur[
                            "telephone"],
                          ),
                        ),

                        ListTile(
                          leading: const Icon(
                              Icons.location_city),
                          title: const Text(
                              "Ville"),
                          subtitle: Text(
                            transporteur[
                            "ville"],
                          ),
                        ),

                        ListTile(
                          leading: const Icon(
                              Icons.star),
                          title: const Text(
                              "Note"),
                          subtitle: Text(
                            transporteur[
                            "note"],
                          ),
                        ),

                        ListTile(
                          leading: const Icon(
                              Icons.route),
                          title: const Text(
                              "Courses"),
                          subtitle: Text(
                            transporteur[
                            "courses"],
                          ),
                        ),

                        ListTile(
                          leading: const Icon(
                              Icons.payments),
                          title: const Text(
                              "Revenus"),
                          subtitle: Text(
                            transporteur[
                            "revenus"],
                          ),
                        ),

                        ListTile(
                          leading: Icon(
                            transporteur[
                            "documents"]
                                ? Icons
                                .verified
                                : Icons.warning,
                            color: transporteur[
                            "documents"]
                                ? Colors.green
                                : Colors.orange,
                          ),
                          title: const Text(
                            "Documents",
                          ),
                          subtitle: Text(
                            transporteur[
                            "documents"]
                                ? "Tous les documents sont validés"
                                : "Documents en attente",
                          ),
                        ),

                        Padding(
                          padding:
                          const EdgeInsets
                              .all(15),
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
                                  "Voir",
                                ),
                              ),

                              ElevatedButton.icon(
                                onPressed:
                                    () {},
                                icon: const Icon(
                                    Icons
                                        .verified),
                                label:
                                const Text(
                                  "Valider",
                                ),
                              ),

                              ElevatedButton.icon(
                                style:
                                ElevatedButton
                                    .styleFrom(
                                  backgroundColor:
                                  Colors
                                      .orange,
                                ),
                                onPressed:
                                    () {},
                                icon: const Icon(
                                    Icons.pause),
                                label:
                                const Text(
                                  "Suspendre",
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
                                    Icons.delete),
                                label:
                                const Text(
                                  "Supprimer",
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
            const SizedBox(height: 8),
            Text(
              valeur,
              style: const TextStyle(
                fontWeight:
                FontWeight.bold,
                fontSize: 18,
              ),
            ),
            Text(
              titre,
              textAlign:
              TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}