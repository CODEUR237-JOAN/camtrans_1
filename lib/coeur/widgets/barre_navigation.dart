import 'package:flutter/material.dart';

import '../constantes/couleurs.dart';

class BarreNavigation extends StatelessWidget {
  final int indexSelectionne;
  final ValueChanged<int> lorsDuChangement;

  const BarreNavigation({
    super.key,
    required this.indexSelectionne,
    required this.lorsDuChangement,
  });

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: indexSelectionne,
      onDestinationSelected: lorsDuChangement,
      height: 75,
      backgroundColor: Colors.white,
      indicatorColor: CouleursApp.primaireClair,

      labelBehavior:
      NavigationDestinationLabelBehavior.alwaysShow,

      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: "Accueil",
          tooltip: "Aller à l'écran d'accueil",
        ),

        NavigationDestination(
          icon: Icon(Icons.local_shipping_outlined),
          selectedIcon: Icon(Icons.local_shipping),
          label: "Demandes",
          tooltip: "Voir vos demandes d'expédition",
        ),

        NavigationDestination(
          icon: Icon(Icons.location_on_outlined),
          selectedIcon: Icon(Icons.location_on),
          label: "Suivi",
          tooltip: "Suivre vos marchandises en temps réel",
        ),

        NavigationDestination(
          icon: Icon(Icons.notifications_outlined),
          selectedIcon: Icon(Icons.notifications),
          label: "Notifications",
          tooltip: "Voir vos notifications",
        ),

        NavigationDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person),
          label: "Profil",
          tooltip: "Ouvrir votre profil utilisateur",
        ),
      ],
    );
  }
}