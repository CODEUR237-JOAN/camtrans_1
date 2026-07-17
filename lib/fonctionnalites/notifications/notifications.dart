import 'package:flutter/material.dart';

import '../../coeur/constantes/couleurs.dart';
import '../../coeur/constantes/tailles.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() =>
      _NotificationsPageState();
}

class _NotificationsPageState
    extends State<NotificationsPage> {
  String filtre = "Toutes";

  final List<Map<String, dynamic>> notifications = [
    {
      "titre": "Nouvelle course",
      "message":
      "Une nouvelle course est disponible à Douala.",
      "heure": "Il y a 5 min",
      "categorie": "Courses",
      "lue": false,
      "icone": Icons.local_shipping,
      "couleur": Colors.blue,
    },
    {
      "titre": "Paiement reçu",
      "message":
      "Votre paiement de 30 000 FCFA a été effectué.",
      "heure": "Il y a 1 h",
      "categorie": "Paiements",
      "lue": true,
      "icone": Icons.payments,
      "couleur": Colors.green,
    },
    {
      "titre": "Compte validé",
      "message":
      "Votre compte transporteur a été validé.",
      "heure": "Hier",
      "categorie": "Système",
      "lue": false,
      "icone": Icons.verified,
      "couleur": Colors.orange,
    },
    {
      "titre": "Nouveau message",
      "message":
      "Le client vous a envoyé un message.",
      "heure": "Hier",
      "categorie": "Messages",
      "lue": true,
      "icone": Icons.message,
      "couleur": Colors.purple,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CouleursApp.fond,

      appBar: AppBar(
        title: const Text("Notifications"),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.done_all),
            tooltip: "Tout marquer comme lu",
          ),
        ],
      ),

      body: Padding(
        padding: const EdgeInsets.all(
          TaillesApp.margePage,
        ),
        child: Column(
          children: [
            SizedBox(
              height: 45,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _filtre("Toutes"),
                  _filtre("Non lues"),
                  _filtre("Courses"),
                  _filtre("Paiements"),
                  _filtre("Messages"),
                  _filtre("Système"),
                ],
              ),
            ),

            const SizedBox(height: 20),

            Expanded(
              child: ListView.builder(
                itemCount: notifications.length,
                itemBuilder: (context, index) {
                  final notification =
                  notifications[index];

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
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor:
                        (notification[
                        "couleur"]
                        as Color)
                            .withOpacity(.15),
                        child: Icon(
                          notification["icone"],
                          color:
                          notification["couleur"],
                        ),
                      ),

                      title: Text(
                        notification["titre"],
                        style: TextStyle(
                          fontWeight:
                          notification["lue"]
                              ? FontWeight.normal
                              : FontWeight.bold,
                        ),
                      ),

                      subtitle: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment
                            .start,
                        children: [
                          const SizedBox(height: 5),
                          Text(
                              notification["message"]),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Container(
                                padding:
                                const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration:
                                BoxDecoration(
                                  color: (notification[
                                  "couleur"]
                                  as Color)
                                      .withOpacity(
                                      .15),
                                  borderRadius:
                                  BorderRadius
                                      .circular(
                                      20),
                                ),
                                child: Text(
                                  notification[
                                  "categorie"],
                                  style:
                                  TextStyle(
                                    color: notification[
                                    "couleur"],
                                    fontSize: 12,
                                    fontWeight:
                                    FontWeight
                                        .bold,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              Text(
                                notification[
                                "heure"],
                                style:
                                const TextStyle(
                                  fontSize: 12,
                                  color:
                                  Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      trailing:
                      PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value ==
                              "Supprimer") {
                            setState(() {
                              notifications
                                  .removeAt(
                                  index);
                            });
                          } else if (value ==
                              "Marquer comme lu") {
                            setState(() {
                              notification[
                              "lue"] = true;
                            });
                          }
                        },
                        itemBuilder: (context) =>
                        const [
                          PopupMenuItem(
                            value:
                            "Marquer comme lu",
                            child: Text(
                                "Marquer comme lu"),
                          ),
                          PopupMenuItem(
                            value: "Supprimer",
                            child:
                            Text("Supprimer"),
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

  Widget _filtre(String valeur) {
    return Padding(
      padding:
      const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(valeur),
        selected: filtre == valeur,
        onSelected: (_) {
          setState(() {
            filtre = valeur;
          });
        },
      ),
    );
  }
}