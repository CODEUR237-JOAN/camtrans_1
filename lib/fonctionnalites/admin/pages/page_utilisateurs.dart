import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../coeur/etat/admin_provider.dart';
import '../../../coeur/widgets/etats_ui.dart';
import '../../../coeur/constantes/couleurs.dart';


class PageUtilisateurs extends ConsumerStatefulWidget {
  const PageUtilisateurs({super.key});

  @override
  ConsumerState<PageUtilisateurs> createState() => _PageUtilisateursState();
}

class _PageUtilisateursState extends ConsumerState<PageUtilisateurs> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text("Gestion des Utilisateurs", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tabController,
          labelColor: CouleursApp.primaire,
          unselectedLabelColor: Colors.grey,
          indicatorColor: CouleursApp.primaire,
          tabs: const [
            Tab(text: "Clients"),
            Tab(text: "Transporteurs"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildListeClients(ref),
          _buildListeTransporteurs(ref),
        ],
      ),
    );
  }

  Widget _buildListeClients(WidgetRef ref) {
    final clientsAsync = ref.watch(adminClientsProvider);

    return clientsAsync.when(
      loading: () => const EtatChargement(),
      error: (err, _) => EtatErreur(
        erreur: err.toString(),
        onRetry: () => ref.refresh(adminClientsProvider),
      ),
      data: (clients) => clients.isEmpty
          ? const Padding(
              padding: EdgeInsets.only(top: 40),
              child: EtatVide(
                titre: "Aucun Client",
                message: "Il n'y a actuellement aucun client inscrit.",
                icone: Icons.people_outline,
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(24),
              itemCount: clients.length,
              itemBuilder: (context, index) {
                final client = clients[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: CouleursApp.primaire.withValues(alpha: 0.2),
                      child: Text(client.nom[0].toUpperCase(), style: const TextStyle(color: CouleursApp.primaire, fontWeight: FontWeight.bold)),
                    ),
                    title: Text("${client.prenom} ${client.nom}", style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(client.email),
                    trailing: const Icon(Icons.more_vert),
                    onTap: () {
                      // TODO: Afficher les détails du client
                    },
                  ),
                );
              },
            ),
    );
  }

  Widget _buildListeTransporteurs(WidgetRef ref) {
    final transporteursAsync = ref.watch(adminTransporteursProvider);

    return transporteursAsync.when(
      loading: () => const EtatChargement(),
      error: (err, _) => EtatErreur(
        erreur: err.toString(),
        onRetry: () => ref.refresh(adminTransporteursProvider),
      ),
      data: (transporteurs) => transporteurs.isEmpty
          ? const Padding(
              padding: EdgeInsets.only(top: 40),
              child: EtatVide(
                titre: "Aucun Transporteur",
                message: "Il n'y a actuellement aucun transporteur inscrit.",
                icone: Icons.local_shipping_outlined,
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(24),
              itemCount: transporteurs.length,
              itemBuilder: (context, index) {
                final transporteur = transporteurs[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.orange.withValues(alpha: 0.2),
                      child: const Icon(Icons.local_shipping, color: Colors.orange),
                    ),
                    title: Text("${transporteur.prenom} ${transporteur.nom}", style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text("Véhicule: ${transporteur.typeVehicule}"),
                    trailing: _buildStatutBadge(transporteur.documentsValides),
                    onTap: () {
                      // TODO: Afficher les détails du transporteur
                    },
                  ),
                );
              },
            ),
    );
  }

  Widget _buildStatutBadge(bool estValide) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: estValide ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        estValide ? "Approuvé" : "En attente",
        style: TextStyle(
          color: estValide ? Colors.green : Colors.red,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}
