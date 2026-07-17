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
        ),

        NavigationDestination(
          icon: Icon(Icons.local_shipping_outlined),
          selectedIcon: Icon(Icons.local_shipping),
          label: "Demandes",
        ),

        NavigationDestination(
          icon: Icon(Icons.location_on_outlined),
          selectedIcon: Icon(Icons.location_on),
          label: "Suivi",
        ),

        NavigationDestination(
          icon: Icon(Icons.notifications_outlined),
          selectedIcon: Icon(Icons.notifications),
          label: "Notifications",
        ),

        NavigationDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person),
          label: "Profil",
        ),
      ],
    );
  }
}