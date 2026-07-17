import 'package:flutter/material.dart';

import '../../coeur/constantes/couleurs.dart';
import '../../coeur/constantes/images.dart';
import '../../coeur/constantes/tailles.dart';

class ProfilTransporteur extends StatelessWidget {
  const ProfilTransporteur({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CouleursApp.fond,
      appBar: AppBar(
        title: const Text("Mon profil"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(
          TaillesApp.margePage,
        ),
        child: Column(
          children: [
            CircleAvatar(
              radius: 60,
              backgroundImage: AssetImage(
                ImagesApp.avatar,
              ),
            ),

            const SizedBox(height: 15),

            const Text(
              "Jean Mvondo",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 5),

            const Text(
              "Transporteur Vérifié",
              style: TextStyle(
                color: Colors.grey,
              ),
            ),

            const SizedBox(height: 25),

            Card(
              shape: RoundedRectangleBorder(
                borderRadius:
                BorderRadius.circular(20),
              ),
              child: Column(
                children: const [
                  ListTile(
                    leading: Icon(Icons.phone),
                    title: Text("Téléphone"),
                    subtitle:
                    Text("+237 699 12 34 56"),
                  ),
                  Divider(height: 1),
                  ListTile(
                    leading: Icon(Icons.email),
                    title: Text("E-mail"),
                    subtitle: Text(
                      "transporteur@gmail.com",
                    ),
                  ),
                  Divider(height: 1),
                  ListTile(
                    leading: Icon(Icons.location_city),
                    title: Text("Ville"),
                    subtitle: Text("Douala"),
                  ),
                  Divider(height: 1),
                  ListTile(
                    leading: Icon(Icons.home),
                    title: Text("Adresse"),
                    subtitle:
                    Text("Bonamoussadi"),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Informations du véhicule",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 15),

            Card(
              shape: RoundedRectangleBorder(
                borderRadius:
                BorderRadius.circular(20),
              ),
              child: Column(
                children: const [
                  ListTile(
                    leading: Icon(Icons.local_shipping),
                    title: Text("Camion"),
                    subtitle:
                    Text("Mitsubishi Fuso"),
                  ),
                  Divider(height: 1),
                  ListTile(
                    leading: Icon(Icons.confirmation_number),
                    title:
                    Text("Immatriculation"),
                    subtitle:
                    Text("CE-245-DL"),
                  ),
                  Divider(height: 1),
                  ListTile(
                    leading: Icon(Icons.scale),
                    title: Text("Capacité"),
                    subtitle: Text("10 Tonnes"),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            Row(
              children: [
                Expanded(
                  child: _statistique(
                    "Courses",
                    "328",
                    Icons.local_shipping,
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: _statistique(
                    "Note",
                    "4.9 ★",
                    Icons.star,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 15),

            Row(
              children: [
                Expanded(
                  child: _statistique(
                    "Documents",
                    "5/5",
                    Icons.verified,
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: _statistique(
                    "Expérience",
                    "4 ans",
                    Icons.workspace_premium,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 30),

            Card(
              child: ListTile(
                leading: const Icon(
                  Icons.edit,
                  color: CouleursApp.primaire,
                ),
                title:
                const Text("Modifier le profil"),
                trailing: const Icon(
                  Icons.arrow_forward_ios,
                  size: 18,
                ),
                onTap: () {},
              ),
            ),

            Card(
              child: ListTile(
                leading: const Icon(
                  Icons.settings,
                  color: CouleursApp.primaire,
                ),
                title:
                const Text("Paramètres"),
                trailing: const Icon(
                  Icons.arrow_forward_ios,
                  size: 18,
                ),
                onTap: () {},
              ),
            ),

            Card(
              child: ListTile(
                leading: const Icon(
                  Icons.lock,
                  color: CouleursApp.primaire,
                ),
                title: const Text(
                    "Modifier le mot de passe"),
                trailing: const Icon(
                  Icons.arrow_forward_ios,
                  size: 18,
                ),
                onTap: () {},
              ),
            ),

            Card(
              child: ListTile(
                leading: const Icon(
                  Icons.help,
                  color: CouleursApp.primaire,
                ),
                title: const Text("Aide"),
                trailing: const Icon(
                  Icons.arrow_forward_ios,
                  size: 18,
                ),
                onTap: () {},
              ),
            ),

            const SizedBox(height: 25),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  minimumSize:
                  const Size(double.infinity, 55),
                  shape: RoundedRectangleBorder(
                    borderRadius:
                    BorderRadius.circular(15),
                  ),
                ),
                onPressed: () {
                  Navigator.pushReplacementNamed(
                    context,
                    "/connexion",
                  );
                },
                icon: const Icon(Icons.logout),
                label: const Text(
                  "Déconnexion",
                ),
              ),
            ),

            const SizedBox(height: 40),
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
              color: CouleursApp.primaire,
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
}