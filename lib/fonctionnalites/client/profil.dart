import 'package:flutter/material.dart';

import '../../coeur/constantes/couleurs.dart';
import '../../coeur/constantes/images.dart';
import '../../coeur/constantes/tailles.dart';

class Profil extends StatelessWidget {
  const Profil({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CouleursApp.fond,
      appBar: AppBar(
        title: const Text("Mon Profil"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(
          TaillesApp.margePage,
        ),
        child: Column(
          children: [
            const SizedBox(height: 20),

            CircleAvatar(
              radius: 60,
              backgroundColor: CouleursApp.primaireClair,
              backgroundImage: AssetImage(
                ImagesApp.avatar,
              ),
            ),

            const SizedBox(height: 15),

            const Text(
              "Jean Dupont",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 5),

            const Text(
              "Client Premium",
              style: TextStyle(
                color: CouleursApp.texteSecondaire,
              ),
            ),

            const SizedBox(height: 30),

            _carteInformation(
              Icons.phone,
              "Téléphone",
              "+237 699 12 34 56",
            ),

            _carteInformation(
              Icons.email,
              "Adresse e-mail",
              "jeandupont@gmail.com",
            ),

            _carteInformation(
              Icons.location_city,
              "Ville",
              "Douala",
            ),

            _carteInformation(
              Icons.home,
              "Adresse",
              "Akwa, Douala",
            ),

            const SizedBox(height: 25),

            _bouton(
              context,
              Icons.edit,
              "Modifier le profil",
                  () {
                Navigator.pushNamed(
                  context,
                  "/modifier-profil",
                );
              },
            ),

            _bouton(
              context,
              Icons.lock_reset,
              "Changer le mot de passe",
                  () {},
            ),

            _bouton(
              context,
              Icons.account_balance_wallet,
              "Moyens de paiement",
                  () {},
            ),

            _bouton(
              context,
              Icons.settings,
              "Paramètres",
                  () {
                Navigator.pushNamed(
                  context,
                  "/parametres",
                );
              },
            ),

            _bouton(
              context,
              Icons.help,
              "Centre d'assistance",
                  () {},
            ),

            _bouton(
              context,
              Icons.info,
              "À propos de l'application",
                  () {},
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

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  static Widget _carteInformation(
      IconData icone,
      String titre,
      String valeur,
      ) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor:
          CouleursApp.primaireClair,
          child: Icon(
            icone,
            color: CouleursApp.primaire,
          ),
        ),
        title: Text(titre),
        subtitle: Text(valeur),
      ),
    );
  }

  static Widget _bouton(
      BuildContext context,
      IconData icone,
      String texte,
      VoidCallback action,
      ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: ListTile(
        leading: Icon(
          icone,
          color: CouleursApp.primaire,
        ),
        title: Text(texte),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 18,
        ),
        onTap: action,
      ),
    );
  }
}