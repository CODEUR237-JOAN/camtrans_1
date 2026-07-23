import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../coeur/constantes/couleurs.dart';
import '../../../coeur/etat/admin_provider.dart';
import '../../../coeur/routes/routes.dart';

class SidebarAdmin extends ConsumerWidget {
  const SidebarAdmin({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final indexSelectionne = ref.watch(adminMenuIndexProvider);
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width > 900;

    if (!isDesktop) {
      return const SizedBox.shrink(); // Géré par un Drawer sur mobile
    }

    return Container(
      width: 250,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(5, 0),
          )
        ],
      ),
      child: Column(
        children: [
          const SizedBox(height: 20),
          // Logo Admin
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: CouleursApp.primaire.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.admin_panel_settings, color: CouleursApp.primaire),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    "CamTrans\nConsole",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),

          // Menu Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _SectionTitle(titre: "GÉNÉRAL"),
                _MenuItem(
                  titre: "Vue d'ensemble",
                  icone: Icons.dashboard_outlined,
                  index: 0,
                  currentIndex: indexSelectionne,
                  onTap: () => ref.read(adminMenuIndexProvider.notifier).state = 0,
                ),
                const SizedBox(height: 20),
                
                _SectionTitle(titre: "UTILISATEURS"),
                _MenuItem(
                  titre: "Tous les utilisateurs",
                  icone: Icons.people_outline,
                  index: 1,
                  currentIndex: indexSelectionne,
                  onTap: () => ref.read(adminMenuIndexProvider.notifier).state = 1,
                ),
                const SizedBox(height: 20),
                
                _SectionTitle(titre: "MODÉRATION"),
                _MenuItem(
                  titre: "Documents en attente",
                  icone: Icons.verified_user_outlined,
                  index: 2,
                  currentIndex: indexSelectionne,
                  onTap: () => ref.read(adminMenuIndexProvider.notifier).state = 2,
                ),
                
                // Add more items like signalements, paiements here in the future
              ],
            ),
          ),

          // Footer (Déconnexion)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ListTile(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              leading: const Icon(Icons.logout, color: Colors.redAccent),
              title: const Text("Quitter l'Admin", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
              onTap: () {
                context.go(RoutesApplication.connexion);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String titre;
  const _SectionTitle({required this.titre});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, bottom: 8),
      child: Text(
        titre,
        style: const TextStyle(
          color: Colors.grey,
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final String titre;
  final IconData icone;
  final int index;
  final int currentIndex;
  final VoidCallback onTap;

  const _MenuItem({
    required this.titre,
    required this.icone,
    required this.index,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = index == currentIndex;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 5),
      decoration: BoxDecoration(
        color: isSelected ? CouleursApp.primaire.withValues(alpha: 0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        leading: Icon(
          icone,
          color: isSelected ? CouleursApp.primaire : Colors.black54,
        ),
        title: Text(
          titre,
          style: TextStyle(
            color: isSelected ? CouleursApp.primaire : Colors.black87,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
        onTap: onTap,
      ),
    );
  }
}
