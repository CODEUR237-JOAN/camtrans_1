import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../coeur/etat/admin_provider.dart';
import '../../../coeur/constantes/couleurs.dart';
import '../../../modeles/transporteur.dart';
import '../../../coeur/widgets/etats_ui.dart';
import '../../../services/service_firestore.dart';

class PageModeration extends ConsumerWidget {
  const PageModeration({super.key});

  static Future<void> modifierStatut(BuildContext context, WidgetRef ref, Transporteur transporteur, bool approuve) async {
    try {
      final firestore = ref.read(serviceFirestoreProvider);
      await firestore.modifierDocument(
        collection: 'transporteurs',
        id: transporteur.id,
        donnees: {'documentsValides': approuve},
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(approuve ? "Dossier de ${transporteur.prenom} approuvé" : "Dossier de ${transporteur.prenom} rejeté"),
            backgroundColor: approuve ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

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

class _DossierCard extends ConsumerWidget {
  final Transporteur transporteur;
  
  const _DossierCard({required this.transporteur});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
          
          _buildDocLigne(context, Icons.badge, "Photo de profil", transporteur.photo.isNotEmpty, transporteur.photo),
          _buildDocLigne(context, Icons.drive_eta, "Permis de conduire", transporteur.photoPermis.isNotEmpty, transporteur.photoPermis),
          _buildDocLigne(context, Icons.description, "Carte grise", transporteur.photoCarteGrise.isNotEmpty, transporteur.photoCarteGrise),
          
          const Spacer(),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => PageModeration.modifierStatut(context, ref, transporteur, false),
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
                  onPressed: () => PageModeration.modifierStatut(context, ref, transporteur, true),
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

  Widget _buildDocLigne(BuildContext context, IconData icone, String label, bool recu, String imageUrl) {
    return InkWell(
      onTap: recu && imageUrl.isNotEmpty ? () => _afficherImageEnGrand(context, label, imageUrl) : null,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
        child: Row(
          children: [
            Icon(icone, size: 20, color: Colors.grey.shade600),
            const SizedBox(width: 8),
            Expanded(child: Text(label, style: TextStyle(fontSize: 14, decoration: recu && imageUrl.isNotEmpty ? TextDecoration.underline : TextDecoration.none, color: recu && imageUrl.isNotEmpty ? CouleursApp.primaire : Colors.black87))),
            Icon(
              recu ? Icons.check_circle : Icons.pending,
              color: recu ? Colors.green : Colors.orange,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  void _afficherImageEnGrand(BuildContext context, String titre, String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              title: Text(titre, style: const TextStyle(fontSize: 16)),
              automaticallyImplyLeading: false,
              actions: [
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ],
            ),
            InteractiveViewer(
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const SizedBox(
                    height: 300,
                    child: Center(child: CircularProgressIndicator()),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return const SizedBox(
                    height: 200,
                    child: Center(child: Text("Erreur de chargement de l'image")),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
