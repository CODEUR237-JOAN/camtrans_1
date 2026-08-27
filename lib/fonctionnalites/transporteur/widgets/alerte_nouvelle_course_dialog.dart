import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:update_camtrans/coeur/etat/transporteur_provider.dart';

import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import 'package:update_camtrans/coeur/constantes/couleurs.dart';
import 'package:update_camtrans/modeles/course.dart';

class AlerteNouvelleCourseDialog extends ConsumerStatefulWidget {
  final Course course;

  const AlerteNouvelleCourseDialog({super.key, required this.course});

  @override
  ConsumerState<AlerteNouvelleCourseDialog> createState() => _AlerteNouvelleCourseDialogState();
}

class _AlerteNouvelleCourseDialogState extends ConsumerState<AlerteNouvelleCourseDialog> {
  @override
  void initState() {
    super.initState();
    // Jouer une sonnerie d'alarme par défaut
    FlutterRingtonePlayer().playAlarm();
  }

  @override
  void dispose() {
    FlutterRingtonePlayer().stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark 
              ? Colors.grey[900] 
              : Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: CouleursApp.primaire.withValues(alpha: 0.3),
              blurRadius: 30,
              spreadRadius: 10,
            )
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon animée
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: CouleursApp.primaire.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.notifications_active,
                color: CouleursApp.primaire,
                size: 60,
              ),
            )
            .animate(onPlay: (controller) => controller.repeat(reverse: true))
            .scale(begin: const Offset(1, 1), end: const Offset(1.2, 1.2), duration: 500.ms),
            
            const SizedBox(height: 24),
            
            // Titre
            Text(
              "NOUVELLE COURSE !",
              style: GoogleFonts.inter(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: CouleursApp.primaire,
              ),
              textAlign: TextAlign.center,
            )
            .animate(onPlay: (controller) => controller.repeat(reverse: true))
            .fadeIn(duration: 500.ms),
            
            const SizedBox(height: 16),
            
            // Description
            Text(
              "Une nouvelle course vous a été attribuée automatiquement. Vous devez vous rendre au point de départ.",
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Theme.of(context).brightness == Brightness.dark 
                    ? Colors.white70 
                    : Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 20),
            
            // Details
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: Colors.green, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.course.adresseDepart,
                          style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.flag, color: Colors.red, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.course.adresseArrivee,
                          style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 30),
            
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 55,
                    child: OutlinedButton(
                      onPressed: () async {
                        FlutterRingtonePlayer().stop();
                        try {
                          await ref.read(transporteurActionsProvider).refuserCourse(widget.course.id);
                        } catch (e) {
                          debugPrint("Erreur refus course: $e");
                        }
                        if (context.mounted) {
                          Navigator.of(context).pop();
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.grey.shade400, width: 2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        "REFUSER",
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 55,
                    child: ElevatedButton(
                      onPressed: () async {
                        FlutterRingtonePlayer().stop();
                        try {
                          await ref.read(transporteurActionsProvider).accepterCourse(widget.course.id);
                        } catch (e) {
                          debugPrint("Erreur acceptation course: $e");
                        }
                        if (context.mounted) {
                          Navigator.of(context).pop();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: CouleursApp.primaire,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 5,
                      ),
                      child: Text(
                        "ACCEPTER",
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
