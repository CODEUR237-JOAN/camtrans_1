import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../coeur/etat/admin_provider.dart';
import '../../../modeles/transporteur.dart';
import '../../../coeur/widgets/etats_ui.dart';
import '../../../services/service_firestore.dart';
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

  String _searchQuery = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text("Gestion des Utilisateurs", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(110),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: "Rechercher par nom ou email...",
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  ),
                  onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
                ),
              ),
              TabBar(
                controller: _tabController,
                labelColor: CouleursApp.primaire,
                unselectedLabelColor: Colors.grey,
                indicatorColor: CouleursApp.primaire,
                tabs: const [
                  Tab(text: "Clients"),
                  Tab(text: "Transporteurs"),
                ],
              ),
            ],
          ),
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
      data: (tousClients) {
        final clients = tousClients.where((c) {
          final nomComplet = "${c.prenom} ${c.nom}".toLowerCase();
          return nomComplet.contains(_searchQuery) || c.email.toLowerCase().contains(_searchQuery);
        }).toList();

        return clients.isEmpty
            ? const Padding(
                padding: EdgeInsets.only(top: 40),
                child: EtatVide(
                  titre: "Aucun Client",
                  message: "Aucun client ne correspond à votre recherche.",
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
                      trailing: IconButton(
                        icon: Icon(client.actif ? Icons.lock_open : Icons.lock, color: client.actif ? Colors.grey : Colors.red),
                        onPressed: () => _basculerStatutClient(context, ref, client),
                      ),
                      onTap: () => _afficherDetailsClient(context, client),
                    ),
                  );
                },
              );
      },
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
      data: (tousTransporteurs) {
        final transporteurs = tousTransporteurs.where((t) {
          final nomComplet = "${t.prenom} ${t.nom}".toLowerCase();
          return nomComplet.contains(_searchQuery) || t.email.toLowerCase().contains(_searchQuery);
        }).toList();

        return transporteurs.isEmpty
            ? const Padding(
                padding: EdgeInsets.only(top: 40),
                child: EtatVide(
                  titre: "Aucun Transporteur",
                  message: "Aucun transporteur ne correspond à votre recherche.",
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
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildStatutBadge(transporteur.documentsValides),
                          IconButton(
                            icon: Icon(transporteur.actif ? Icons.lock_open : Icons.lock, color: transporteur.actif ? Colors.grey : Colors.red),
                            onPressed: () => _basculerStatutActif(context, ref, transporteur),
                          ),
                        ],
                      ),
                      onTap: () => _afficherDetailsTransporteur(context, transporteur),
                    ),
                  );
                },
              );
      },
    );
  }

  Future<void> _basculerStatutActif(BuildContext context, WidgetRef ref, Transporteur transporteur) async {
    try {
      final firestore = ref.read(serviceFirestoreProvider);
      await firestore.modifierDocument(
        collection: 'transporteurs',
        id: transporteur.id,
        donnees: {'actif': !transporteur.actif},
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(transporteur.actif ? "Compte de ${transporteur.prenom} bloqué" : "Compte de ${transporteur.prenom} débloqué"),
            backgroundColor: transporteur.actif ? Colors.red : Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erreur: $e"), backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _basculerStatutClient(BuildContext context, WidgetRef ref, dynamic client) async {
    try {
      final firestore = ref.read(serviceFirestoreProvider);
      await firestore.modifierDocument(
        collection: 'clients',
        id: client.id,
        donnees: {'actif': !client.actif},
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(client.actif ? "Compte de ${client.prenom} bloqué" : "Compte de ${client.prenom} débloqué"),
            backgroundColor: client.actif ? Colors.red : Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erreur: $e"), backgroundColor: Colors.red));
      }
    }
  }

  void _afficherDetailsClient(BuildContext context, dynamic client) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("${client.prenom} ${client.nom}", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text("Email: ${client.email}"),
            Text("Téléphone: ${client.telephone}"),
            const SizedBox(height: 10),
            Text("Rôle: Client"),
            Text("Date d'inscription: ${client.dateCreation?.toLocal().toString().split('.')[0] ?? 'Inconnue'}"),
            const SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Fermer"),
              ),
            )
          ],
        ),
      ),
    );
  }

  void _afficherDetailsTransporteur(BuildContext context, Transporteur transporteur) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("${transporteur.prenom} ${transporteur.nom}", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text("Email: ${transporteur.email}"),
            Text("Téléphone: ${transporteur.telephone}"),
            const SizedBox(height: 10),
            Text("Véhicule: ${transporteur.marqueVehicule} ${transporteur.modeleVehicule}"),
            Text("Immatriculation: ${transporteur.immatriculation}"),
            const SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Fermer"),
              ),
            )
          ],
        ),
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
