import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:update_camtrans/coeur/etat/utilisateur_provider.dart';
import 'package:update_camtrans/coeur/constantes/couleurs.dart';
import 'package:go_router/go_router.dart';
import 'package:update_camtrans/coeur/widgets/assistant_vocal_widget.dart';

import 'composants/carte_suivi_interactive.dart';
import 'composants/panneau_details_bottom_sheet.dart';
import 'etat/suivi_course_etat.dart';
import 'etat/suivi_course_provider.dart';

class EcranSuiviCourse extends ConsumerStatefulWidget {
  final String courseId;
  final bool isFullScreen;

  const EcranSuiviCourse({
    Key? key,
    required this.courseId,
    this.isFullScreen = true,
  }) : super(key: key);

  @override
  ConsumerState<EcranSuiviCourse> createState() => _EcranSuiviCourseState();
}

class _EcranSuiviCourseState extends ConsumerState<EcranSuiviCourse> {
  final MapController _mapController = MapController();

  @override
  Widget build(BuildContext context) {
    // Écoute des erreurs pour afficher un SnackBar
    ref.listen<SuiviCourseEtat>(suiviCourseProvider(widget.courseId), (previous, next) {
      if (next.erreur.isNotEmpty && (previous == null || previous.erreur != next.erreur)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 10),
                Expanded(child: Text(next.erreur)),
              ],
            ),
            backgroundColor: CouleursApp.erreur,
            duration: const Duration(seconds: 4),
          ),
        );
      }
      
      // Redirection automatique vers le paiement pour le client
      final role = ref.read(userRoleProvider).valueOrNull;
      final ancienStatut = previous?.course?.statut;
      final nouveauStatut = next.course?.statut;
      
      if (role == 'client' && nouveauStatut == 'arrive_destination' && ancienStatut != 'arrive_destination') {
        final c = next.course!;
        final double montant = c.prixFinal > 0 ? c.prixFinal : c.prixEstime;
        // On utilise un PostFrameCallback pour s'assurer que la frame courante est finie
        WidgetsBinding.instance.addPostFrameCallback((_) {
          GoRouter.of(context).push('/paiement', extra: {
            'courseId': c.id,
            'montant': montant,
            'transporteurId': c.transporteurId,
          });
        });
      }

      // Gestion côté transporteur de la fin de course et confirmation espèces
      if (role == 'transporteur') {
        if (nouveauStatut == 'attente_paiement_especes' && ancienStatut != 'attente_paiement_especes') {
          final c = next.course!;
          final double montant = c.prixFinal > 0 ? c.prixFinal : c.prixEstime;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (ctx) => AlertDialog(
                backgroundColor: CouleursApp.fondSombreSecondaire,
                title: const Text("Paiement en espèces", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                content: Text(
                  "Le client a choisi de régler en espèces.\n\nAvez-vous bien reçu la somme de ${montant.toInt()} FCFA de la part du client ?",
                  style: const TextStyle(color: Colors.white70),
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      // Si non, on pourrait gérer un litige, mais pour l'instant on force à résoudre avec le client
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Veuillez réclamer le paiement au client avant de valider.")),
                      );
                    },
                    child: const Text("Non, pas encore", style: TextStyle(color: Colors.grey)),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: CouleursApp.succes),
                    onPressed: () {
                      Navigator.pop(ctx);
                      // On valide le paiement en espèces
                      ref.read(suiviCourseProvider(widget.courseId).notifier).validerPaiementEspeces();
                    },
                    child: const Text("Oui, j'ai reçu l'argent", style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            );
          });
        }
        
        // Si la course est terminée (soit paiement digital direct, soit confirmation espèces effectuée)
        if (nouveauStatut == 'terminee' && ancienStatut != 'terminee') {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Course terminée avec succès ! Le paiement a été validé."),
                backgroundColor: CouleursApp.succes,
              ),
            );
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop(); // Retour au tableau de bord
            }
          });
        }
      }
    });

    final etatSuivi = ref.watch(suiviCourseProvider(widget.courseId));
    final notifier = ref.read(suiviCourseProvider(widget.courseId).notifier);
    final roleAsync = ref.watch(userRoleProvider);
    final isChauffeur = roleAsync.valueOrNull == 'transporteur';

    if (etatSuivi.isLoading || etatSuivi.course == null) {
      return const Scaffold(
        backgroundColor: CouleursApp.fondSombre,
        body: Center(
          child: CircularProgressIndicator(color: CouleursApp.primaire),
        ),
      );
    }

    return Scaffold(
      backgroundColor: CouleursApp.fondSombre,
      body: Stack(
        children: [
          // 1. La Carte Interactive (Arrière-plan complet)
          CarteSuiviInteractive(
            etat: etatSuivi,
            mapController: _mapController,
          ),

          // 2. Boutons flottants (Bandeau supérieur)
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Bouton Retour (optionnel, pour forcer la sortie)
                  if (widget.isFullScreen)
                    CircleAvatar(
                      backgroundColor: CouleursApp.fondSombreSecondaire.withValues(alpha: 0.8),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    )
                  else
                    const SizedBox.shrink(),
                  
                  // Contrôle vocal (Chauffeur uniquement)
                  if (isChauffeur)
                    CircleAvatar(
                      backgroundColor: CouleursApp.fondSombreSecondaire.withValues(alpha: 0.8),
                      child: IconButton(
                        icon: Icon(
                          etatSuivi.isVoixActive ? Icons.volume_up : Icons.volume_off,
                          color: etatSuivi.isVoixActive ? const Color(0xFF145C43) : Colors.white54,
                        ),
                        onPressed: notifier.basculerVoix,
                      ),
                    ),
                ],
              ),
            ),
          ),
          
          // 3. Assistant Kombi Flottant (Chauffeur uniquement)
          if (isChauffeur)
            Positioned(
              right: 16,
              bottom: 120, // Au-dessus du bottom sheet
              child: const BoutonAssistantVocal(),
            ),

          // 4. Panneau Rétractable avec les détails de la course
          PanneauDetailsBottomSheet(
            etat: etatSuivi,
            isChauffeur: isChauffeur,
            onBoutonAction: () {
              if (etatSuivi.phase == PhaseSuivi.approche) {
                notifier.commencerCourse();
              } else if (etatSuivi.phase == PhaseSuivi.trajet) {
                notifier.terminerCourse();
                // On ne fait pas pop() ici : on attend le paiement du client.
              }
            },
          ),
        ],
      ),
    );
  }
}
