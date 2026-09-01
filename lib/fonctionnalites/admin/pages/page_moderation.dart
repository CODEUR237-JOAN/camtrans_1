import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import 'package:update_camtrans/coeur/etat/admin_provider.dart';
import 'package:update_camtrans/coeur/constantes/couleurs.dart';
import 'package:update_camtrans/modeles/transporteur.dart';
import 'package:update_camtrans/coeur/widgets/etats_ui.dart';
import 'package:update_camtrans/services/service_firestore.dart';
import 'package:flutter_animate/flutter_animate.dart';


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
            backgroundColor: approuve ? CouleursApp.succes : CouleursApp.erreur,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur: $e"), backgroundColor: CouleursApp.erreur, behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transporteursAsync = ref.watch(adminTransporteursProvider);

    return Scaffold(
      backgroundColor: Colors.transparent, // Sera géré par le parent
      body: Stack(
        children: [
          Container(color: Colors.white),
          Positioned(
            bottom: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                color: CouleursApp.avertissement.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
            ).animate(onPlay: (controller) => controller.repeat(reverse: true)).scale(duration: 5.seconds, begin: const Offset(1,1), end: const Offset(1.3,1.3)),
          ),
          
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              Expanded(
                child: transporteursAsync.when(
                  loading: () => const EtatChargement(message: "Chargement des dossiers..."),
                  error: (err, _) => EtatErreur(erreur: err.toString(), onRetry: () => ref.refresh(adminTransporteursProvider)),
                  data: (transporteurs) {
                    final enAttente = transporteurs.where((t) => !t.documentsValides).toList();

                    if (enAttente.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(color: CouleursApp.succes.withValues(alpha: 0.1), shape: BoxShape.circle),
                              child: const Icon(Iconsax.verify_copy, size: 64, color: CouleursApp.succes),
                            ),
                            const SizedBox(height: 24),
                            Text("À jour !", style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                            const SizedBox(height: 8),
                            Text("Aucun dossier en attente de modération.", style: GoogleFonts.inter(color: Colors.white54)),
                          ],
                        ),
                      );
                    }

                    return LayoutBuilder(
                      builder: (context, constraints) {
                        int crossAxisCount = constraints.maxWidth > 1000 ? 3 : constraints.maxWidth > 600 ? 2 : 1;
                        
                        return GridView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: crossAxisCount,
                            crossAxisSpacing: 24,
                            mainAxisSpacing: 24,
                            childAspectRatio: 0.75, // Ajusté pour le nouveau design
                          ),
                          itemCount: enAttente.length,
                          itemBuilder: (context, index) {
                            return _DossierCard(transporteur: enAttente[index])
                                .animate().slideY(begin: 0.1);
                          },
                        );
                      }
                    );
                  },
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
            "Modération des Documents",
            style: GoogleFonts.inter(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: -1),
          ),
          const SizedBox(height: 8),
          Text(
            "Vérifiez les nouveaux transporteurs avant leur activation.",
            style: GoogleFonts.inter(fontSize: 16, color: Colors.white54),
          ),
        ],
      ),
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
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 60, height: 60,
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Iconsax.personalcard_copy, color: Colors.orange, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("${transporteur.prenom} ${transporteur.nom}", style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white), maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Text(transporteur.telephone, style: GoogleFonts.inter(color: Colors.white54, fontSize: 13)),
                  ],
                ),
              )
            ],
          ),
          const SizedBox(height: 24),
          Divider(color: Colors.white.withValues(alpha: 0.1), height: 1),
          const SizedBox(height: 24),
          Text("Documents soumis :", style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 12),
          
          _buildDocLigne(context, Iconsax.image_copy, "Photo de profil", transporteur.photo.isNotEmpty, transporteur.photo),
          _buildDocLigne(context, Iconsax.personalcard_copy, "Permis de conduire", transporteur.photoPermis.isNotEmpty, transporteur.photoPermis),
          _buildDocLigne(context, Iconsax.document_copy, "Carte grise", transporteur.photoCarteGrise.isNotEmpty, transporteur.photoCarteGrise),
          
          const Spacer(),
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  icon: Iconsax.close_circle_copy,
                  label: "Rejeter",
                  color: CouleursApp.erreur,
                  onTap: () => PageModeration.modifierStatut(context, ref, transporteur, false),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  icon: Iconsax.tick_circle_copy,
                  label: "Approuver",
                  color: CouleursApp.succes,
                  onTap: () => PageModeration.modifierStatut(context, ref, transporteur, true),
                  isPrimary: true,
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildActionButton({required IconData icon, required String label, required Color color, required VoidCallback onTap, bool isPrimary = false}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isPrimary ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: isPrimary ? Colors.white : color),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                color: isPrimary ? Colors.white : color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
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
            Icon(icone, size: 20, color: Colors.white54),
            const SizedBox(width: 12),
            Expanded(child: Text(label, style: GoogleFonts.inter(fontSize: 14, decoration: recu && imageUrl.isNotEmpty ? TextDecoration.underline : TextDecoration.none, color: recu && imageUrl.isNotEmpty ? Colors.white : Colors.white54))),
            Icon(
              recu ? Iconsax.tick_circle_copy : Iconsax.clock_copy,
              color: recu ? CouleursApp.succes : CouleursApp.avertissement,
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
        backgroundColor: const Color(0xFF1E293B), // Dark Premium
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(titre, style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                  IconButton(
                    icon: const Icon(Iconsax.close_circle_copy, color: Colors.white54),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Divider(color: Colors.white.withValues(alpha: 0.1), height: 1),
            InteractiveViewer(
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const SizedBox(
                    height: 300,
                    child: Center(child: CircularProgressIndicator(color: CouleursApp.primaire)),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return SizedBox(
                    height: 200,
                    child: Center(child: Text("Erreur de chargement de l'image", style: GoogleFonts.inter(color: Colors.white54))),
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
