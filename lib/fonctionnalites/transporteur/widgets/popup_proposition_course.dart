import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import 'package:update_camtrans/coeur/constantes/couleurs.dart';
import 'package:update_camtrans/modeles/course.dart';
import 'package:go_router/go_router.dart';

class PopupPropositionCourse extends ConsumerStatefulWidget {
  final Course course;

  const PopupPropositionCourse({super.key, required this.course});

  @override
  ConsumerState<PopupPropositionCourse> createState() =>
      _PopupPropositionCourseState();
}

class _PopupPropositionCourseState
    extends ConsumerState<PopupPropositionCourse> {
  @override
  void initState() {
    super.initState();
    HapticFeedback.heavyImpact(); // Attirer l'attention
  }

  Future<void> _accepterCourse() async {
    HapticFeedback.heavyImpact();
    if (mounted) {
      Navigator.pop(context); // Fermer le popup
      // Rediriger le transporteur vers SA page de suivi spécifique
      context.push('/suivi/${widget.course.id}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Empêche de fermer avec le bouton retour sans refuser
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(24),
            border:
                Border.all(color: CouleursApp.primaire.withValues(alpha: 0.3)),
            boxShadow: [
              BoxShadow(
                color: CouleursApp.primaire.withValues(alpha: 0.2),
                blurRadius: 40,
                spreadRadius: -10,
              )
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              const Icon(Icons.route_rounded,
                      color: CouleursApp.primaire, size: 48)
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .scale(
                      begin: const Offset(1, 1),
                      end: const Offset(1.2, 1.2),
                      duration: 800.ms),
              const SizedBox(height: 24),
              Text(
                "NOUVELLE COURSE ATTRIBUÉE",
                style: GoogleFonts.inter(
                  color: CouleursApp.primaire,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  letterSpacing: 2,
                ),
              )
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .fade(begin: 0.5, end: 1.0, duration: 800.ms),

              const SizedBox(height: 16),

              // Détails de la course
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Iconsax.routing_2_copy,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withValues(alpha: 0.54),
                                size: 16),
                            const SizedBox(width: 8),
                            Text(
                                "${widget.course.distanceKm.toStringAsFixed(1)} km",
                                style: TextStyle(
                                    color:
                                        Theme.of(context).colorScheme.onSurface,
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                        Row(
                          children: [
                            const Icon(Icons.attach_money,
                                color: CouleursApp.succes, size: 16),
                            const SizedBox(width: 4),
                            Text("${widget.course.prixEstime.toInt()} FCFA",
                                style: const TextStyle(
                                    color: CouleursApp.succes,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 16)),
                          ],
                        ),
                      ],
                    ),
                    Divider(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.1),
                        height: 24),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.location_on,
                            color: CouleursApp.accent, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(widget.course.adresseDepart,
                              style: TextStyle(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withValues(alpha: 0.7),
                                  fontSize: 13),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Badge de Tarification Standardisée
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: CouleursApp.succes.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: CouleursApp.succes.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.verified,
                        color: CouleursApp.succes, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Tarif Standardisé CamTrans",
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: CouleursApp.succes),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "Calculé équitablement. Le prix est fixe et non négociable.",
                            style: TextStyle(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withValues(alpha: 0.7),
                                fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Bouton d'action unique (Subit l'attribution)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _accepterCourse(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: CouleursApp.primaire,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 10,
                    shadowColor: CouleursApp.primaire.withValues(alpha: 0.5),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.navigation_rounded),
                      const SizedBox(width: 8),
                      Text("PRENDRE LA ROUTE",
                          style: GoogleFonts.inter(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
