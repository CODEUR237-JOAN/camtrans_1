import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:update_camtrans/coeur/constantes/couleurs.dart';
import 'package:update_camtrans/services/service_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:update_camtrans/coeur/widgets/loader_premium.dart';

class EcranEvaluation extends ConsumerStatefulWidget {
  final String courseId;
  const EcranEvaluation({super.key, required this.courseId});

  @override
  ConsumerState<EcranEvaluation> createState() => _EcranEvaluationState();
}

class _EcranEvaluationState extends ConsumerState<EcranEvaluation> {
  int _note = 0;
  final TextEditingController _commentaireController = TextEditingController();
  bool _chargement = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: CouleursApp.primaire),
          onPressed: () => context.go('/'),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: CouleursApp.succes.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_outline,
                    color: CouleursApp.succes, size: 80),
              ),

              const SizedBox(height: 24),
              Text(
                "Mission accomplie",
                style: GoogleFonts.inter(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 28,
                    fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 8),
              Text(
                "Votre avis nous aide à maintenir notre niveau d'excellence. Comment évaluez-vous le service de votre transporteur ?",
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54), fontSize: 16),
              ),

              const SizedBox(height: 40),

              // Étoiles
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _note = index + 1;
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Icon(
                        index < _note ? Icons.star : Icons.star_border,
                        color: index < _note
                            ? CouleursApp.avertissement
                            : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.24),
                        size: 40,
                      )
                          .animate(target: index < _note ? 1 : 0)
                          .scale(end: const Offset(1.2, 1.2))
                          .tint(color: CouleursApp.avertissement),
                    ),
                  );
                }),
              ),

              const SizedBox(height: 40),

              // Champ Commentaire
              if (_note > 0)
                TextField(
                  controller: _commentaireController,
                  maxLines: 3,
                  style: GoogleFonts.inter(color: Theme.of(context).colorScheme.onSurface),
                  decoration: InputDecoration(
                    hintText: "Laissez un commentaire (optionnel)",
                    hintStyle: GoogleFonts.inter(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38)),
                    filled: true,
                    fillColor: const Color(0xFF1A2640).withValues(alpha: 0.05),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),

              const Spacer(),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: (_note > 0 && !_chargement)
                      ? () async {
                          setState(() => _chargement = true);
                          try {
                            final firestore =
                                ref.read(serviceFirestoreProvider);
                            final db = FirebaseFirestore.instance;

                            // 1. Note enregistrée sur la course (trace).
                            await firestore.modifierDocument(
                              collection: 'courses',
                              id: widget.courseId,
                              donnees: {
                                'noteClient': _note.toDouble(),
                                'commentaireClient':
                                    _commentaireController.text.trim(),
                              },
                            );

                            // 2. Évaluation dédiée → permet de calculer la
                            //    note moyenne du transporteur (lisible par
                            //    tous), sans Cloud Function.
                            try {
                              final courseDoc = await db
                                  .collection('courses')
                                  .doc(widget.courseId)
                                  .get();
                              final transpId = (courseDoc.data()?[
                                          'transporteurId'] ??
                                      '')
                                  .toString();
                              final clientId =
                                  (courseDoc.data()?['clientId'] ?? '')
                                      .toString();
                              if (transpId.isNotEmpty) {
                                await db.collection('evaluations').add({
                                  'transporteurId': transpId,
                                  'clientId': clientId,
                                  'courseId': widget.courseId,
                                  'note': _note,
                                  'commentaire':
                                      _commentaireController.text.trim(),
                                  'date': FieldValue.serverTimestamp(),
                                });
                              }
                            } catch (_) {}

                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text("Merci pour votre retour !"),
                                  backgroundColor: CouleursApp.succes),
                            );
                            context.go('/');
                          } catch (e) {
                            if (context.mounted) {
                              setState(() => _chargement = false);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text("Erreur : $e"),
                                    backgroundColor: CouleursApp.erreur),
                              );
                            }
                          }
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: CouleursApp.primaire,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _chargement
                      ? const LoaderPremium(size: 24)
                      : Text("Envoyer mon avis",
                          style: GoogleFonts.inter(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
