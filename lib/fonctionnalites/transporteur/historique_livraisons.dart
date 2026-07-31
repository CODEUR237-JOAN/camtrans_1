import 'package:flutter/material.dart';

import '../../coeur/constantes/couleurs.dart';
import '../../coeur/constantes/tailles.dart';

class HistoriqueLivraisons extends StatelessWidget {
  const HistoriqueLivraisons({super.key});

  final List<Map<String, dynamic>> livraisons = const [
    {
      "depart": "Douala",
      "arrivee": "Yaoundé",
      "date": "05 Juillet 2026",
      "prix": "30 000 FCFA",
      "statut": "Terminée"
    },
    {
      "depart": "Bafoussam",
      "arrivee": "Douala",
      "date": "03 Juillet 2026",
      "prix": "55 000 FCFA",
      "statut": "Terminée"
    },
    {
      "depart": "Kribi",
      "arrivee": "Douala",
      "date": "01 Juillet 2026",
      "prix": "18 000 FCFA",
      "statut": "Terminée"
    },
    {
      "depart": "Garoua",
      "arrivee": "Ngaoundéré",
      "date": "27 Juin 2026",
      "prix": "120 000 FCFA",
      "statut": "Terminée"
    },
    {
      "depart": "Bertoua",
      "arrivee": "Douala",
      "date": "24 Juin 2026",
      "prix": "68 000 FCFA",
      "statut": "Terminée"
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CouleursApp.fond,
      appBar: AppBar(
        title: const Text("Historique des livraisons"),
      ),
      body: Padding(
        padding: EdgeInsets.all(
          TaillesApp.margePage,
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: CouleursApp.degradePrincipal,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.history,
                    color: Colors.white,
                    size: 45,
                  ),
                  SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Historique",
                          style: TextStyle(
                            color: Colors.white70,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          "Toutes vos livraisons réalisées sont enregistrées ici.",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),

            const SizedBox(height: 25),

            Expanded(
              child: ListView.builder(
                itemCount: livraisons.length,
                itemBuilder: (context, index) {
                  final livraison = livraisons[index];

                  return Card(
                    elevation: 3,
                    margin: const EdgeInsets.only(
                      bottom: 15,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                      BorderRadius.circular(18),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        radius: 28,
                        backgroundColor:
                        Colors.green.shade100,
                        child: const Icon(
                          Icons.local_shipping,
                          color: Colors.green,
                        ),
                      ),
                      title: Text(
                        "${livraison["depart"]} → ${livraison["arrivee"]}",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 6),
                          Text(livraison["date"]),
                          Text(
                            livraison["statut"],
                            style: const TextStyle(
                              color: Colors.green,
                              fontWeight:
                              FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      trailing: Column(
                        mainAxisAlignment:
                        MainAxisAlignment.center,
                        children: [
                          Text(
                            livraison["prix"],
                            style: const TextStyle(
                              color: Colors.green,
                              fontWeight:
                              FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                          )
                        ],
                      ),
                      onTap: () {},
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
}