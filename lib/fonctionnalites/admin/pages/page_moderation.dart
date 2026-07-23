import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../coeur/etat/admin_provider.dart';
import '../../../coeur/constantes/couleurs.dart';
import '../../../modeles/transporteur.dart';
import '../../../coeur/widgets/etats_ui.dart';

class PageModeration extends ConsumerWidget {
  const PageModeration({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transporteursAsync = ref.watch(adminTransporteursProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      body: transporteursAsync.when(
        loading: () => const EtatChargement(message: "Chargement des dossiers..."),
        error: (err, _) => EtatErreur(
          erreur: err.toString(),
          onRetry: () => ref.refresh(adminTransporteursProvider),
        ),
        data: (transporteurs) {
          final enAttente = transporteurs.where((t) => !t.documentsValides).toList();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Modération des Documents",
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                const SizedBox(height: 8),
                Text(
                  "${enAttente.length} dossiers en attente d'approbation",
                  style: const TextStyle(color: Colors.grey, fontSize: 16),
                ),
                const SizedBox(height: 32),

                if (enAttente.isEmpty)
                  _buildEmptyState()
                else
                  _buildGridDossiers(enAttente),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return const EtatVide(
      titre: "Tout est à jour !",
      message: "Aucun document en attente de validation.",
      icone: Icons.check_circle_outline,
    );
  }

  Widget _buildGridDossiers(List<Transporteur> enAttente) {
    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = constraints.maxWidth > 1000 ? 3 : constraints.maxWidth > 600 ? 2 : 1;
        
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.85, // Ajusté pour le contenu
          ),
          itemCount: enAttente.length,
          itemBuilder: (context, index) {
            return _DossierCard(transporteur: enAttente[index]);
          },
        );
      }
    );
  }
}

class _DossierCard extends StatelessWidget {
  final Transporteur transporteur;
  
  const _DossierCard({required this.transporteur});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: CouleursApp.primaire.withValues(alpha: 0.2),
                radius: 25,
                child: const Icon(Icons.person, color: CouleursApp.primaire),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("${transporteur.prenom} ${transporteur.nom}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text(transporteur.telephone, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                  ],
                ),
              )
            ],
          ),
          const Divider(height: 32),
          const Text("Documents soumis :", style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          
          _buildDocLigne(Icons.badge, "Pièce d'identité", true),
          _buildDocLigne(Icons.drive_eta, "Permis de conduire", true),
          _buildDocLigne(Icons.description, "Carte grise", transporteur.typeVehicule != 'moto'),
          
          const Spacer(),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Dossier rejeté")));
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text("Rejeter"),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Dossier approuvé avec succès")));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text("Approuver"),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildDocLigne(IconData icone, String label, bool recu) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(icone, size: 20, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 14))),
          Icon(
            recu ? Icons.check_circle : Icons.pending,
            color: recu ? Colors.green : Colors.orange,
            size: 20,
          ),
        ],
      ),
    );
  }
}
