import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:update_camtrans/coeur/constantes/couleurs.dart';
import 'package:update_camtrans/coeur/widgets/loader_premium.dart';
import 'package:google_fonts/google_fonts.dart';

class IndicateurChargement extends StatelessWidget {
  final String? message;
  final double taille;
  final Color? couleur;
  final bool afficherCarte;

  const IndicateurChargement({
    super.key,
    this.message,
    this.taille = 45,
    this.couleur,
    this.afficherCarte = true,
  });

  @override
  Widget build(BuildContext context) {
    final Widget contenu = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        LoaderPremium(size: taille, color: couleur),
        if (message != null) ...[
          const SizedBox(height: 24),
          Text(
            message!,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.white70,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );

    if (!afficherCarte) {
      return Center(child: contenu);
    }

    return Center(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
            decoration: BoxDecoration(
              color: const Color(0xFF10192A).withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: contenu,
          ),
        ),
      ),
    );
  }
}