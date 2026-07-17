import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../coeur/constantes/couleurs.dart';
import '../../coeur/constantes/tailles.dart';

class TableauDeBordAdministrateur extends StatelessWidget {
  const TableauDeBordAdministrateur({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CouleursApp.fond,

      appBar: AppBar(
        title: const Text("Tableau de bord"),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.person),
          ),
        ],
      ),

      drawer: Drawer(
        child: ListView(
          children: [
            const UserAccountsDrawerHeader(
              accountName: Text("Administrateur"),
              accountEmail: Text("admin@transport.cm"),
              currentAccountPicture: CircleAvatar(
                child: Icon(
                  Icons.admin_panel_settings,
                  size: 40,
                ),
              ),
            ),

            _menu(Icons.dashboard, "Tableau de bord"),
            _menu(Icons.people, "Clients"),
            _menu(Icons.local_shipping, "Transporteurs"),
            _menu(Icons.route, "Courses"),
            _menu(Icons.bar_chart, "Statistiques"),
            _menu(Icons.settings, "Paramètres"),

            const Divider(),

            _menu(Icons.logout, "Déconnexion"),
          ],
        ),
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
              width: double.infinity,
              padding: const EdgeInsets.all(25),
              decoration: BoxDecoration(
                gradient:
                CouleursApp.degradePrincipal,
                borderRadius:
                BorderRadius.circular(20),
              ),
              child: const Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  Text(
                    "Bienvenue Administrateur",
                    style: TextStyle(
                      color: Colors.white70,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Plateforme de gestion du transport",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight:
                      FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            const Text(
              "Statistiques",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 15),

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
                const SizedBox(width: 15),
                Expanded(
                  child: _statistique(
                    "Transporteurs",
                    "468",
                    Icons.local_shipping,
                    Colors.green,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 15),

            Row(
              children: [
                Expanded(
                  child: _statistique(
                    "Courses",
                    "3 842",
                    Icons.route,
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: _statistique(
                    "Revenus",
                    "125 M FCFA",
                    Icons.payments,
                    Colors.red,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 30),

            const Text(
              "Évolution des activités",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 15),

            Container(
              height: 250,
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
                        FlSpot(1, 2),
                        FlSpot(2, 4),
                        FlSpot(3, 5),
                        FlSpot(4, 6),
                        FlSpot(5, 8),
                        FlSpot(6, 7),
                        FlSpot(7, 10),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 30),

            const Text(
              "Dernières inscriptions",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 15),

            _utilisateur(
              "Jean Dupont",
              "Client",
            ),

            _utilisateur(
              "Paul Ndzié",
              "Transporteur",
            ),

            _utilisateur(
              "Marie Ndzi",
              "Client",
            ),

            const SizedBox(height: 30),

            const Text(
              "Dernières courses",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 15),

            _course(
              "Douala → Yaoundé",
              "Terminée",
            ),

            _course(
              "Kribi → Douala",
              "En cours",
            ),

            _course(
              "Garoua → Ngaoundéré",
              "En attente",
            ),

            const SizedBox(height: 30),

            const Text(
              "Accès rapide",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 15),

            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics:
              const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 15,
              mainAxisSpacing: 15,
              children: [
                _action(
                  Icons.people,
                  "Clients",
                ),
                _action(
                  Icons.local_shipping,
                  "Transporteurs",
                ),
                _action(
                  Icons.route,
                  "Courses",
                ),
                _action(
                  Icons.bar_chart,
                  "Statistiques",
                ),
              ],
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  static Widget _statistique(
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
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
            ),
            const SizedBox(height: 5),
            Text(titre),
          ],
        ),
      ),
    );
  }

  static Widget _utilisateur(
      String nom,
      String type,
      ) {
    return Card(
      child: ListTile(
        leading: const CircleAvatar(
          child: Icon(Icons.person),
        ),
        title: Text(nom),
        subtitle: Text(type),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 16,
        ),
      ),
    );
  }

  static Widget _course(
      String trajet,
      String statut,
      ) {
    return Card(
      child: ListTile(
        leading: const CircleAvatar(
          child: Icon(Icons.local_shipping),
        ),
        title: Text(trajet),
        subtitle: Text(statut),
      ),
    );
  }

  static Widget _action(
      IconData icone,
      String titre,
      ) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius:
        BorderRadius.circular(20),
      ),
      child: InkWell(
        borderRadius:
        BorderRadius.circular(20),
        onTap: () {},
        child: Column(
          mainAxisAlignment:
          MainAxisAlignment.center,
          children: [
            Icon(
              icone,
              size: 45,
              color: CouleursApp.primaire,
            ),
            const SizedBox(height: 15),
            Text(
              titre,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _menu(
      IconData icone,
      String titre,
      ) {
    return ListTile(
      leading: Icon(icone),
      title: Text(titre),
      onTap: () {},
    );
  }
}