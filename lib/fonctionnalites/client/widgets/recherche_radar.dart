import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:update_camtrans/coeur/constantes/couleurs.dart';
import 'package:flutter_animate/flutter_animate.dart';


class RechercheRadar extends StatelessWidget {
  const RechercheRadar({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Fond sombre premium
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animation Radar Sonar
            Stack(
              alignment: Alignment.center,
              children: [
                // Cercles concentriques animés
                ...List.generate(3, (index) {
                  return Container(
                    width: 100.0 + (index * 80),
                    height: 100.0 + (index * 80),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: CouleursApp.primaire.withValues(alpha: 0.3), width: 2),
                    ),
                  )
                      .animate(onPlay: (controller) => controller.repeat())
                      .scale(duration: const Duration(seconds: 2), begin: const Offset(0.5, 0.5), end: const Offset(1.5, 1.5))
                      .fade(duration: const Duration(seconds: 2), begin: 0.8, end: 0.0);
                }),
                
                // Point central
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: CouleursApp.primaire,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: CouleursApp.primaire.withValues(alpha: 0.5),
                        blurRadius: 20,
                        spreadRadius: 5,
                      )
                    ],
                  ),
                  child: const Icon(Icons.search, color: Colors.white, size: 30),
                )
                    .animate(onPlay: (controller) => controller.repeat(reverse: true))
                    .scale(duration: const Duration(milliseconds: 800), begin: const Offset(0.9, 0.9), end: const Offset(1.1, 1.1)),
              ],
            ),
            const SizedBox(height: 60),
            
            // Texte
            Text(
              "Recherche du meilleur transporteur...",
              style: GoogleFonts.poppins(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ).animate(onPlay: (controller) => controller.repeat(reverse: true)).fade(duration: const Duration(seconds: 1), begin: 0.5, end: 1.0),
            
            const SizedBox(height: 12),
            Text(
              "Service d'Urgence 24h/24\nDélai d'intervention estimé : 30 minutes",
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
