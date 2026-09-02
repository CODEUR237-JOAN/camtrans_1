import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:update_camtrans/coeur/constantes/couleurs.dart';

/// ============================================================
/// WIDGET: QrSuivi
/// ============================================================
/// ✅ INNOVATION 4.1: QR Code de suivi de course partageable.
/// Utilise le package qr_flutter (déjà installé dans pubspec.yaml).
///
/// Le client peut afficher ce QR Code pour permettre au destinataire
/// de scanner et suivre la livraison en temps réel, sans avoir à
/// se connecter à l'application CamTrans.
///
/// Usage:
/// ```dart
/// showModalBottomSheet(
///   context: context,
///   builder: (_) => QrSuivi(codeSuivi: course.codeSuivi),
/// );
/// ```
/// ============================================================
class QrSuivi extends StatelessWidget {
  final String codeSuivi;
  final String? nomClient;

  const QrSuivi({
    super.key,
    required this.codeSuivi,
    this.nomClient,
  });

  /// Génère le lien de suivi public (deeplink ou lien web)
  String get _lienSuivi => 'https://camtrans.cm/suivi/$codeSuivi';

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Poignée
          Container(
            width: 40,
            height: 5,
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(10),
            ),
          ),

          // Titre
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: CouleursApp.primaire.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.qr_code_rounded, color: CouleursApp.primaire, size: 22),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Partager le suivi",
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  Text(
                    "Scannez pour suivre cette livraison",
                    style: GoogleFonts.inter(color: Colors.white54, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 28),

          // QR Code
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: CouleursApp.primaire.withValues(alpha: 0.2),
                  blurRadius: 30,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: QrImageView(
              data: _lienSuivi,
              version: QrVersions.auto,
              size: 200,
              backgroundColor: Colors.white,
              eyeStyle: const QrEyeStyle(
                eyeShape: QrEyeShape.square,
                color: Color(0xFF0F172A),
              ),
              dataModuleStyle: const QrDataModuleStyle(
                dataModuleShape: QrDataModuleShape.square,
                color: Color(0xFF0F172A),
              ),
            ),
          ).animate()
            .scale(begin: const Offset(0.8, 0.8), end: const Offset(1, 1), duration: 400.ms, curve: Curves.elasticOut)
            .fadeIn(duration: 300.ms),

          const SizedBox(height: 20),

          // Code suivi textuel
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.tag_rounded, color: Colors.white54, size: 16),
                const SizedBox(width: 8),
                Text(
                  codeSuivi,
                  style: GoogleFonts.robotoMono(
                    color: Colors.white70,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 3,
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: _lienSuivi));
                    HapticFeedback.selectionClick();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            const Icon(Icons.check, color: Colors.white, size: 16),
                            const SizedBox(width: 8),
                            Text(
                              "Lien copié !",
                              style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        backgroundColor: CouleursApp.succes,
                        behavior: SnackBarBehavior.floating,
                        duration: const Duration(seconds: 2),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: CouleursApp.primaire.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.copy_rounded, color: CouleursApp.primaire, size: 16),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Info
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: CouleursApp.information.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: CouleursApp.information.withValues(alpha: 0.15)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded, color: CouleursApp.information, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "Le destinataire peut scanner ce QR Code pour suivre votre livraison en temps réel, sans télécharger l'app.",
                    style: GoogleFonts.inter(color: Colors.white54, fontSize: 12, height: 1.5),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 300.ms),

          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
