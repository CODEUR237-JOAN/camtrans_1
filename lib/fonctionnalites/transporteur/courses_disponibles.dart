import 'package:flutter/material.dart';

import '../../coeur/constantes/couleurs.dart';
import '../../coeur/constantes/tailles.dart';

class CoursesDisponibles extends StatefulWidget {
  const CoursesDisponibles({super.key});

  @override
  State<CoursesDisponibles> createState() =>
      _CoursesDisponiblesState();
}

class _CoursesDisponiblesState
    extends State<CoursesDisponibles> {
  final TextEditingController recherche =
  TextEditingController();

  final List<Map<String, dynamic>> courses = [
    {
      "depart": "Douala",
      "arrivee": "Yaoundé",
      "marchandise": "Mobilier",
      "poids": "850 Kg",
      "distance": "245 Km",
      "prix": "30 000 FCFA",
      "date": "Aujourd'hui",
    },
    {
      "depart": "Bafoussam",
      "arrivee": "Douala",
      "marchandise": "Cacao",
      "poids": "2 Tonnes",
      "distance": "305 Km",
      "prix": "55 000 FCFA",
      "date": "Aujourd'hui",
    },
    {
      "depart": "Kribi",
      "arrivee": "Douala",
      "marchandise": "Poissons",
      "poids": "500 Kg",
      "distance": "170 Km",
      "prix": "18 000 FCFA",
      "date": "Demain",
    },
    {
      "depart": "Garoua",
      "arrivee": "Ngaoundéré",
      "marchandise": "Matériel industriel",
      "poids": "8 Tonnes",
      "distance": "290 Km",
      "prix": "120 000 FCFA",
      "date": "Demain",
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CouleursApp.fond,
      appBar: AppBar(
        title: const Text(
          "Courses disponibles",
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(
              TaillesApp.margePage,
            ),
            child: TextField(
              controller: recherche,
              decoration: InputDecoration(
                hintText:
                "Rechercher une course...",
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
          ),

          SizedBox(
            height: 50,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding:
              const EdgeInsets.symmetric(
                horizontal:
                TaillesApp.margePage,
              ),
              children: [
                _filtre("Toutes"),
                _filtre("Aujourd'hui"),
                _filtre("Proche"),
                _filtre("Longue distance"),
                _filtre("Urgent"),
              ],
            ),
          ),

          const SizedBox(height: 15),

          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(
                TaillesApp.margePage,
              ),
              itemCount: courses.length,
              itemBuilder: (context, index) {
                final course = courses[index];

                return Card(
                  elevation: 4,
                  margin:
                  const EdgeInsets.only(
                    bottom: 18,
                  ),
                  shape:
                  RoundedRectangleBorder(
                    borderRadius:
                    BorderRadius.circular(
                        18),
                  ),
                  child: Padding(
                    padding:
                    const EdgeInsets.all(
                        18),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 28,
                              backgroundColor:
                              CouleursApp
                                  .primaireClair,
                              child: const Icon(
                                Icons
                                    .local_shipping,
                                color:
                                CouleursApp
                                    .primaire,
                              ),
                            ),

                            const SizedBox(
                                width: 15),

                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                CrossAxisAlignment
                                    .start,
                                children: [
                                  Text(
                                    "${course["depart"]} ➜ ${course["arrivee"]}",
                                    style:
                                    const TextStyle(
                                      fontSize:
                                      18,
                                      fontWeight:
                                      FontWeight
                                          .bold,
                                    ),
                                  ),

                                  const SizedBox(
                                      height: 5),

                                  Text(
                                    course[
                                    "marchandise"],
                                  ),
                                ],
                              ),
                            ),

                            Text(
                              course["prix"],
                              style:
                              const TextStyle(
                                color:
                                Colors.green,
                                fontWeight:
                                FontWeight
                                    .bold,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(
                            height: 18),

                        Row(
                          children: [
                            const Icon(
                              Icons.scale,
                              size: 18,
                              color:
                              Colors.grey,
                            ),
                            const SizedBox(
                                width: 5),
                            Text(
                              course["poids"],
                            ),
                            const Spacer(),
                            const Icon(
                              Icons.route,
                              size: 18,
                              color:
                              Colors.grey,
                            ),
                            const SizedBox(
                                width: 5),
                            Text(
                              course[
                              "distance"],
                            ),
                          ],
                        ),

                        const SizedBox(
                            height: 10),

                        Row(
                          children: [
                            const Icon(
                              Icons.calendar_today,
                              size: 18,
                              color:
                              Colors.grey,
                            ),
                            const SizedBox(
                                width: 5),
                            Text(
                              course["date"],
                            ),
                          ],
                        ),

                        const SizedBox(
                            height: 20),

                        Row(
                          children: [
                            Expanded(
                              child:
                              OutlinedButton.icon(
                                onPressed:
                                    () {
                                  Navigator
                                      .pushNamed(
                                    context,
                                    "/details-course",
                                  );
                                },
                                icon:
                                const Icon(
                                  Icons
                                      .visibility,
                                ),
                                label:
                                const Text(
                                  "Détails",
                                ),
                              ),
                            ),

                            const SizedBox(
                                width: 15),

                            Expanded(
                              child:
                              ElevatedButton.icon(
                                style:
                                ElevatedButton.styleFrom(
                                  backgroundColor:
                                  CouleursApp
                                      .primaire,
                                  foregroundColor:
                                  Colors
                                      .white,
                                ),
                                onPressed:
                                    () {
                                  ScaffoldMessenger.of(
                                      context)
                                      .showSnackBar(
                                    const SnackBar(
                                      content:
                                      Text(
                                        "Course acceptée avec succès.",
                                      ),
                                    ),
                                  );
                                },
                                icon:
                                const Icon(
                                  Icons.check,
                                ),
                                label:
                                const Text(
                                  "Accepter",
                                ),
                              ),
                            ),
                          ],
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
    );
  }

  Widget _filtre(String texte) {
    return Padding(
      padding:
      const EdgeInsets.only(right: 10),
      child: FilterChip(
        label: Text(texte),
        selected: false,
        onSelected: (_) {},
      ),
    );
  }
}