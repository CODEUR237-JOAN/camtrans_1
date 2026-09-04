import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import 'package:update_camtrans/coeur/constantes/couleurs.dart';
import 'package:update_camtrans/coeur/etat/transporteur_provider.dart';
import 'package:update_camtrans/modeles/course.dart';
import 'package:update_camtrans/coeur/widgets/loader_premium.dart';
import 'package:go_router/go_router.dart';

class PopupPropositionCourse extends ConsumerStatefulWidget {
  final Course course;

  const PopupPropositionCourse({super.key, required this.course});

  @override
  ConsumerState<PopupPropositionCourse> createState() => _PopupPropositionCourseState();
}

class _PopupPropositionCourseState extends ConsumerState<PopupPropositionCourse> {
  Timer? _timer;
  int _secondesRestantes = 30;
  bool _enCoursTraitement = false;

  @override
  void initState() {
    super.initState();
    _calculerTempsRestant();
    _demarrerMinuteur();
    HapticFeedback.heavyImpact(); // Attirer l'attention
  }

  void _calculerTempsRestant() {
    if (widget.course.expirationProposition != null) {
      final diff = widget.course.expirationProposition!.difference(DateTime.now()).inSeconds;
      _secondesRestantes = diff > 0 ? diff : 0;
    }
  }

  void _demarrerMinuteur() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_secondesRestantes > 0) {
          _secondesRestantes--;
        } else {
          timer.cancel();
          if (!_enCoursTraitement) {
             _refuserCourse(expiration: true);
          }
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _accepterCourse() async {
    if (_enCoursTraitement) return;
    setState(() => _enCoursTraitement = true);
    _timer?.cancel();

    try {
      await ref.read(transporteurActionsProvider).accepterPropositionCourse(widget.course.id);
      HapticFeedback.heavyImpact();
      if (mounted) {
        Navigator.pop(context); // Fermer le popup
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Course acceptée ! 🎉", style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
            backgroundColor: CouleursApp.succes,
          )
        );
        // Rediriger le transporteur vers SA page de suivi spécifique
        context.push('/suivi-transporteur/${widget.course.id}');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _enCoursTraitement = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur: ${e.toString().replaceAll('Exception: ', '')}"), backgroundColor: CouleursApp.erreur)
        );
      }
    }
  }

  Future<void> _refuserCourse({bool expiration = false}) async {
    if (_enCoursTraitement) return;
    setState(() => _enCoursTraitement = true);
    _timer?.cancel();

    try {
      await ref.read(transporteurActionsProvider).refuserPropositionCourse(widget.course.id);
      if (mounted) {
        Navigator.pop(context); // Fermer le popup
        if (!expiration) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Course refusée.", style: GoogleFonts.inter(color: Colors.white)),
              backgroundColor: Colors.grey.shade800,
            )
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _enCoursTraitement = false);
        Navigator.pop(context); // Force close
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Écouter le flux de la proposition. Si elle disparaît (annulée, expirée ou transférée), on ferme le popup.
    ref.listen<AsyncValue<Course?>>(fluxCourseProposeeProvider, (previous, next) {
      if (next.hasValue && next.value == null) {
        if (mounted && !_enCoursTraitement) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Temps écoulé ou course non disponible."),
              backgroundColor: Colors.grey,
            ),
          );
        }
      }
    });

    // Calcul de la progression du cercle
    final double progression = _secondesRestantes / 30.0;

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
            border: Border.all(color: CouleursApp.primaire.withValues(alpha: 0.3)),
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
              // Indicateur de temps (Cercle avec compte à rebours)
              SizedBox(
                height: 100,
                width: 100,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CircularProgressIndicator(
                      value: progression,
                      strokeWidth: 8,
                      backgroundColor: Colors.white10,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _secondesRestantes > 10 ? CouleursApp.primaire : CouleursApp.erreur
                      ),
                    ),
                    Center(
                      child: Text(
                        "$_secondesRestantes",
                        style: GoogleFonts.inter(
                          color: _secondesRestantes > 10 ? Colors.white : CouleursApp.erreur,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ).animate().scale(delay: 200.ms, duration: 400.ms, curve: Curves.elasticOut),

              const SizedBox(height: 24),

              Text(
                "NOUVELLE COURSE !",
                style: GoogleFonts.inter(
                  color: CouleursApp.primaire,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  letterSpacing: 2,
                ),
              ).animate(onPlay: (c) => c.repeat(reverse: true)).fade(begin: 0.5, end: 1.0, duration: 800.ms),

              const SizedBox(height: 16),

              // Détails de la course
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Iconsax.routing_2_copy, color: Colors.white54, size: 16),
                            const SizedBox(width: 8),
                            Text("${widget.course.distanceKm.toStringAsFixed(1)} km", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        Row(
                          children: [
                            const Icon(Icons.attach_money, color: CouleursApp.succes, size: 16),
                            const SizedBox(width: 4),
                            Text("${widget.course.prixEstime.toInt()} FCFA", style: const TextStyle(color: CouleursApp.succes, fontWeight: FontWeight.w900, fontSize: 16)),
                          ],
                        ),
                      ],
                    ),
                    const Divider(color: Colors.white10, height: 24),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.location_on, color: CouleursApp.accent, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(widget.course.adresseDepart, style: const TextStyle(color: Colors.white70, fontSize: 13), maxLines: 2, overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),
              
              // Badge de Tarification Standardisée
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: CouleursApp.succes.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: CouleursApp.succes.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.verified, color: CouleursApp.succes, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Tarif Standardisé CamTrans",
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: CouleursApp.succes),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "Calculé équitablement. Le prix est fixe et non négociable.",
                            style: TextStyle(color: Colors.white70, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Boutons d'action
              if (_enCoursTraitement)
                Center(child: LoaderPremium())
              else
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _refuserCourse(),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white70,
                          side: const BorderSide(color: Colors.white24),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text("Refuser", style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _accepterCourse(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: CouleursApp.primaire,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 10,
                          shadowColor: CouleursApp.primaire.withValues(alpha: 0.5),
                        ),
                        child: Text("ACCEPTER", style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
