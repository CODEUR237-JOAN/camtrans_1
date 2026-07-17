import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../coeur/constantes/couleurs.dart';
import '../../coeur/constantes/tailles.dart';

class StatistiquesAdministrateur extends StatefulWidget {
  const StatistiquesAdministrateur({super.key});

  @override
  State<StatistiquesAdministrateur> createState() =>
      _StatistiquesAdministrateurState();
}

class _StatistiquesAdministrateurState
    extends State<StatistiquesAdministrateur> {
  String periode = "Mois";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CouleursApp.fond,
      appBar: AppBar(
        title: const Text("Statistiques"),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: "Exporter PDF",
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.table_chart),
            tooltip: "Exporter Excel",
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(
          TaillesApp.margePage,
        ),
        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            const Text(
              "Vue d'ensemble",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 20),

            Row(
              children: [
                _periode("Jour"),
                const SizedBox(width: 10),
                _periode("Semaine"),
                const SizedBox(width: 10),
                _periode("Mois"),
                const SizedBox(width: 10),
                _periode("Année"),
              ],
            ),

            const SizedBox(height: 25),

            Row(
              children: [
                Expanded(
                  child: _carteStatistique(
                    "Revenus",
                    "125 M FCFA",
                    Icons.payments,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: _carteStatistique(
                    "Courses",
                    "3 842",
                    Icons.route,
                    Colors.blue,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 15),

            Row(
              children: [
                Expanded(
                  child: _carteStatistique(
                    "Clients",
                    "1 254",
                    Icons.people,
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: _carteStatistique(
                    "Transporteurs",
                    "468",
                    Icons.local_shipping,
                    Colors.purple,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 30),

            const Text(
              "Évolution des revenus",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 15),

            Container(
              height: 260,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                BorderRadius.circular(20),
              ),
              child: LineChart(
                LineChartData(
                  borderData:
                  FlBorderData(show: false),
                  gridData:
                  FlGridData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      isCurved: true,
                      color:
                      CouleursApp.primaire,
                      barWidth: 4,
                      spots: const [
                        FlSpot(1, 1),
                        FlSpot(2, 2),
                        FlSpot(3, 4),
                        FlSpot(4, 6),
                        FlSpot(5, 7),
                        FlSpot(6, 8),
                        FlSpot(7, 10),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 30),

            const Text(
              "Répartition des courses",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 15),

            SizedBox(
              height: 260,
              child: PieChart(
                PieChartData(
                  sections: [
                    PieChartSectionData(
                      value: 40,
                      title: "Douala",
                      color: Colors.blue,
                    ),
                    PieChartSectionData(
                      value: 25,
                      title: "Yaoundé",
                      color: Colors.orange,
                    ),
                    PieChartSectionData(
                      value: 18,
                      title: "Bafoussam",
                      color: Colors.green,
                    ),
                    PieChartSectionData(
                      value: 17,
                      title: "Autres",
                      color: Colors.red,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 30),

            const Text(
              "Indicateurs",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 15),

            _indicateur(
              "Taux de réussite",
              "98 %",
              Icons.check_circle,
              Colors.green,
            ),

            _indicateur(
              "Courses annulées",
              "2 %",
              Icons.cancel,
              Colors.red,
            ),

            _indicateur(
              "Nouveaux clients",
              "185",
              Icons.person_add,
              Colors.blue,
            ),

            _indicateur(
              "Nouveaux transporteurs",
              "42",
              Icons.local_shipping,
              Colors.orange,
            ),

            _indicateur(
              "Satisfaction client",
              "4.8 / 5",
              Icons.star,
              Colors.amber,
            ),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.download),
                label: const Text(
                  "Exporter les statistiques",
                ),
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _periode(String valeur) {
    return ChoiceChip(
      label: Text(valeur),
      selected: periode == valeur,
      onSelected: (_) {
        setState(() {
          periode = valeur;
        });
      },
    );
  }

  Widget _carteStatistique(
      String titre,
      String valeur,
      IconData icone,
      Color couleur,
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
              color: couleur,
              size: 35,
            ),
            const SizedBox(height: 10),
            Text(
              valeur,
              style: const TextStyle(
                fontSize: 20,
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

  Widget _indicateur(
      String titre,
      String valeur,
      IconData icone,
      Color couleur,
      ) {
    return Card(
      margin: const EdgeInsets.only(
        bottom: 12,
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor:
          couleur.withOpacity(.15),
          child: Icon(
            icone,
            color: couleur,
          ),
        ),
        title: Text(titre),
        trailing: Text(
          valeur,
          style: TextStyle(
            color: couleur,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
    );
  }
}