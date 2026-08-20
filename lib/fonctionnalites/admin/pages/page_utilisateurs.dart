import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:update_camtrans/coeur/etat/admin_provider.dart';
import 'package:update_camtrans/modeles/transporteur.dart';
import 'package:update_camtrans/coeur/widgets/etats_ui.dart';
import 'package:update_camtrans/services/service_firestore.dart';
import 'package:update_camtrans/coeur/constantes/couleurs.dart';

class PageUtilisateurs extends ConsumerStatefulWidget {
  const PageUtilisateurs({super.key});

  @override
  ConsumerState<PageUtilisateurs> createState() => _PageUtilisateursState();
}

class _PageUtilisateursState extends ConsumerState<PageUtilisateurs> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = "";

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
      backgroundColor: Colors.transparent, // Sera géré par le Row parent ou on met le #08111F
      body: Stack(
        children: [
          // Background commun
          Container(color: const Color(0xFF08111F)),
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                color: CouleursApp.primaire.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
            ).animate(onPlay: (controller) => controller.repeat(reverse: true)).scale(duration: 4.seconds, begin: const Offset(1,1), end: const Offset(1.2,1.2)),
          ),
          
          Column(
            children: [
              _buildHeader(),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildListeClients(ref),
                    _buildListeTransporteurs(ref),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.only(left: 32, right: 32, top: 32, bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Gestion des Utilisateurs",
            style: GoogleFonts.inter(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: -1),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  child: TextField(
                    style: GoogleFonts.inter(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: "Rechercher par nom ou email...",
                      hintStyle: GoogleFonts.inter(color: Colors.white54),
                      prefixIcon: const Icon(Iconsax.search_normal_copy, color: Colors.white54, size: 20),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                    onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
                  ),
                ),
              ),
              const SizedBox(width: 24),
              Container(
                height: 50,
                width: 300,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                ),
                child: TabBar(
                  controller: _tabController,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white54,
                  labelStyle: GoogleFonts.inter(fontWeight: FontWeight.bold),
                  indicator: BoxDecoration(
                    color: CouleursApp.primaire.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  tabs: const [
                    Tab(text: "Clients"),
                    Tab(text: "Transporteurs"),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildListeClients(WidgetRef ref) {
    final clientsAsync = ref.watch(adminClientsProvider);

    return clientsAsync.when(
      loading: () => const EtatChargement(),
      error: (err, _) => EtatErreur(erreur: err.toString(), onRetry: () => ref.refresh(adminClientsProvider)),
      data: (tousClients) {
        final clients = tousClients.where((c) {
          final nomComplet = "${c.prenom} ${c.nom}".toLowerCase();
          return nomComplet.contains(_searchQuery) || c.email.toLowerCase().contains(_searchQuery);
        }).toList();

        if (clients.isEmpty) {
          return Center(child: Text("Aucun client trouvé.", style: GoogleFonts.inter(color: Colors.white54)));
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          itemCount: clients.length,
          itemBuilder: (context, index) {
            final client = clients[index];
            final initiale = (client.nom.isNotEmpty ? client.nom[0] : (client.prenom.isNotEmpty ? client.prenom[0] : '?')).toUpperCase();
            return _GlassListItem(
              titre: "${client.prenom} ${client.nom}".trim().isNotEmpty ? "${client.prenom} ${client.nom}".trim() : client.email,
              sousTitre: client.email,
              initiale: initiale,
              couleurInitiale: CouleursApp.primaire,
              estActif: client.actif,
              onToggleActif: () => _basculerStatutClient(context, ref, client),
              onTap: () => _afficherDetailsClient(context, client),
            ).animate().fadeIn(delay: Duration(milliseconds: 50 * index)).slideX();
          },
        );
      },
    );
  }

  Widget _buildListeTransporteurs(WidgetRef ref) {
    final transporteursAsync = ref.watch(adminTransporteursProvider);

    return transporteursAsync.when(
      loading: () => const EtatChargement(),
      error: (err, _) => EtatErreur(erreur: err.toString(), onRetry: () => ref.refresh(adminTransporteursProvider)),
      data: (tousTransporteurs) {
        final transporteurs = tousTransporteurs.where((t) {
          final nomComplet = "${t.prenom} ${t.nom}".toLowerCase();
          return nomComplet.contains(_searchQuery) || t.email.toLowerCase().contains(_searchQuery);
        }).toList();

        if (transporteurs.isEmpty) {
          return Center(child: Text("Aucun transporteur trouvé.", style: GoogleFonts.inter(color: Colors.white54)));
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          itemCount: transporteurs.length,
          itemBuilder: (context, index) {
            final transporteur = transporteurs[index];
            return _GlassListItem(
              titre: "${transporteur.prenom} ${transporteur.nom}",
              sousTitre: "Véhicule: ${transporteur.typeVehicule}",
              icone: Iconsax.truck_fast_copy,
              couleurInitiale: Colors.orange,
              estActif: transporteur.actif,
              documentsValides: transporteur.documentsValides,
              onToggleActif: () => _basculerStatutTransporteur(context, ref, transporteur),
              onTap: () => _afficherDetailsTransporteur(context, transporteur),
            ).animate().fadeIn(delay: Duration(milliseconds: 50 * index)).slideX();
          },
        );
      },
    );
  }

  Future<void> _basculerStatutClient(BuildContext context, WidgetRef ref, dynamic client) async {
    await ref.read(serviceFirestoreProvider).modifierDocument(collection: 'clients', id: client.id, donnees: {'actif': !client.actif});
  }

  Future<void> _basculerStatutTransporteur(BuildContext context, WidgetRef ref, Transporteur transporteur) async {
    await ref.read(serviceFirestoreProvider).modifierDocument(collection: 'transporteurs', id: transporteur.id, donnees: {'actif': !transporteur.actif});
  }

  void _afficherDetailsClient(BuildContext context, dynamic client) {
    // Reste identique pour le moment
  }

  void _afficherDetailsTransporteur(BuildContext context, Transporteur transporteur) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF111827),
        title: Text("Validation Transporteur", style: GoogleFonts.inter(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Nom: ${transporteur.prenom} ${transporteur.nom}", style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 8),
            Text("Email: ${transporteur.email}", style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 8),
            Text("Véhicule: ${transporteur.typeVehicule}", style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 8),
            Text("Immatriculation: ${transporteur.immatriculation}", style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 16),
            const Text("Action requise :", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Fermer", style: TextStyle(color: Colors.grey)),
          ),
          if (!transporteur.documentsValides)
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: CouleursApp.succes),
              onPressed: () async {
                await ref.read(serviceFirestoreProvider).modifierDocument(
                  collection: 'transporteurs',
                  id: transporteur.id,
                  donnees: {'documentsValides': true},
                );
                if (context.mounted) Navigator.pop(ctx);
              },
              child: const Text("Approuver les documents", style: TextStyle(color: Colors.white)),
            )
          else
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: CouleursApp.erreur),
              onPressed: () async {
                await ref.read(serviceFirestoreProvider).modifierDocument(
                  collection: 'transporteurs',
                  id: transporteur.id,
                  donnees: {'documentsValides': false},
                );
                if (context.mounted) Navigator.pop(ctx);
              },
              child: const Text("Révoquer l'approbation", style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
    );
  }
}

class _GlassListItem extends StatelessWidget {
  final String titre;
  final String sousTitre;
  final String? initiale;
  final IconData? icone;
  final Color couleurInitiale;
  final bool estActif;
  final bool? documentsValides;
  final VoidCallback onToggleActif;
  final VoidCallback onTap;

  const _GlassListItem({
    required this.titre,
    required this.sousTitre,
    this.initiale,
    this.icone,
    required this.couleurInitiale,
    required this.estActif,
    this.documentsValides,
    required this.onToggleActif,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  width: 50, height: 50,
                  decoration: BoxDecoration(
                    color: couleurInitiale.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: icone != null
                      ? Icon(icone, color: couleurInitiale)
                      : Text(initiale ?? "", style: GoogleFonts.inter(color: couleurInitiale, fontWeight: FontWeight.bold, fontSize: 18)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(titre, style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 4),
                      Text(sousTitre, style: GoogleFonts.inter(color: Colors.white54, fontSize: 14)),
                    ],
                  ),
                ),
                if (documentsValides != null)
                  Container(
                    margin: const EdgeInsets.only(right: 16),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: documentsValides! ? CouleursApp.succes.withValues(alpha: 0.1) : CouleursApp.erreur.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(documentsValides! ? "Approuvé" : "En attente", style: GoogleFonts.inter(color: documentsValides! ? CouleursApp.succes : CouleursApp.erreur, fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                IconButton(
                  icon: Icon(estActif ? Iconsax.unlock_copy : Iconsax.lock_copy, color: estActif ? Colors.white54 : CouleursApp.erreur),
                  onPressed: onToggleActif,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
