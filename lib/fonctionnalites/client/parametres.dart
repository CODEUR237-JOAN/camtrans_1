import 'package:flutter/material.dart';

import 'package:update_camtrans/coeur/constantes/couleurs.dart';
import 'package:update_camtrans/coeur/constantes/tailles.dart';

class Parametres extends StatefulWidget {
  const Parametres({super.key});

  @override
  State<Parametres> createState() => _ParametresState();
}

class _ParametresState extends State<Parametres> {
  bool notifications = true;
  bool localisation = true;
  bool modeSombre = false;
  bool biometrie = false;

  String langue = "Français";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CouleursApp.fond,
      appBar: AppBar(
        title: const Text("Paramètres"),
      ),
      body: ListView(
        padding: EdgeInsets.all(
          TaillesApp.margePage,
        ),
        children: [
          const Text(
            "Préférences",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 15),

          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            child: SwitchListTile(
              value: modeSombre,
              secondary: const Icon(
                Icons.dark_mode,
                color: CouleursApp.primaire,
              ),
              title: const Text("Mode sombre"),
              subtitle: const Text(
                "Activer le thème sombre",
              ),
              onChanged: (value) {
                setState(() {
                  modeSombre = value;
                });
              },
            ),
          ),

          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            child: SwitchListTile(
              value: notifications,
              secondary: const Icon(
                Icons.notifications,
                color: CouleursApp.primaire,
              ),
              title: const Text("Notifications"),
              subtitle: const Text(
                "Recevoir les notifications",
              ),
              onChanged: (value) {
                setState(() {
                  notifications = value;
                });
              },
            ),
          ),

          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            child: SwitchListTile(
              value: localisation,
              secondary: const Icon(
                Icons.location_on,
                color: CouleursApp.primaire,
              ),
              title: const Text("Localisation"),
              subtitle: const Text(
                "Partager votre position",
              ),
              onChanged: (value) {
                setState(() {
                  localisation = value;
                });
              },
            ),
          ),

          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            child: SwitchListTile(
              value: biometrie,
              secondary: const Icon(
                Icons.fingerprint,
                color: CouleursApp.primaire,
              ),
              title: const Text(
                "Authentification biométrique",
              ),
              subtitle: const Text(
                "Empreinte digitale ou Face ID",
              ),
              onChanged: (value) {
                setState(() {
                  biometrie = value;
                });
              },
            ),
          ),

          const SizedBox(height: 25),

          const Text(
            "Langue",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 15),

          Card(
            child: ListTile(
              leading: const Icon(
                Icons.language,
                color: CouleursApp.primaire,
              ),
              title: const Text("Langue"),
              subtitle: Text(langue),
              trailing: DropdownButton<String>(
                value: langue,
                underline: const SizedBox(),
                items: const [
                  DropdownMenuItem(
                    value: "Français",
                    child: Text("Français"),
                  ),
                  DropdownMenuItem(
                    value: "English",
                    child: Text("English"),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    langue = value!;
                  });
                },
              ),
            ),
          ),

          const SizedBox(height: 25),

          const Text(
            "Compte",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 15),

          _element(
            Icons.lock,
            "Modifier le mot de passe",
                () {},
          ),

          _element(
            Icons.security,
            "Sécurité",
                () {},
          ),

          _element(
            Icons.privacy_tip,
            "Confidentialité",
                () {},
          ),

          _element(
            Icons.description,
            "Conditions d'utilisation",
                () {},
          ),

          _element(
            Icons.policy,
            "Politique de confidentialité",
                () {},
          ),

          _element(
            Icons.help_center,
            "Centre d'aide",
                () {},
          ),

          _element(
            Icons.star_rate,
            "Noter l'application",
                () {},
          ),

          _element(
            Icons.share,
            "Partager l'application",
                () {},
          ),

          _element(
            Icons.info,
            "À propos",
                () {},
          ),

          const SizedBox(height: 30),

          Card(
            color: Colors.grey.shade100,
            child: const ListTile(
              leading: Icon(
                Icons.verified,
                color: Colors.green,
              ),
              title: Text("Version"),
              subtitle: Text("1.0.0"),
            ),
          ),

          const SizedBox(height: 25),

          ElevatedButton.icon(
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
            onPressed: () {},
            icon: const Icon(Icons.logout),
            label: const Text("Déconnexion"),
          ),

          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _element(
      IconData icone,
      String titre,
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
        title: Text(titre),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 18,
        ),
        onTap: action,
      ),
    );
  }
}