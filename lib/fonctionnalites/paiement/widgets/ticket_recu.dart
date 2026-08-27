import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:update_camtrans/modeles/paiement.dart';
import 'package:update_camtrans/coeur/constantes/couleurs.dart';

class TicketRecu extends StatelessWidget {
  final Paiement paiement;
  final VoidCallback onFermer;

  const TicketRecu({super.key, required this.paiement, required this.onFermer});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: CouleursApp.succes.withValues(alpha: 0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: CouleursApp.succes.withValues(alpha: 0.15),
            blurRadius: 40,
            offset: const Offset(0, 10),
            spreadRadius: 5,
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // En-tête vert néon
              Container(
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                decoration: BoxDecoration(
                  color: CouleursApp.succes.withValues(alpha: 0.1),
                  border: Border(bottom: BorderSide(color: CouleursApp.succes.withValues(alpha: 0.2))),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: CouleursApp.succes.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check_circle_outline, color: CouleursApp.succes, size: 28),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      "Paiement Réussi",
                      style: GoogleFonts.poppins(
                        color: CouleursApp.succes,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              
              Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  children: [
                    Text(
                      "${paiement.montant.toInt()} ${paiement.devise}",
                      style: GoogleFonts.poppins(
                        fontSize: 42,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: -1,
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    _buildLigneDetails("Méthode", paiement.methodePaiement.toUpperCase()),
                    const Divider(height: 32, color: Colors.white12),
                    _buildLigneDetails("N° Transaction", paiement.numeroTransaction),
                    const Divider(height: 32, color: Colors.white12),
                    _buildLigneDetails("Réf. Course", paiement.reference),
                    const Divider(height: 32, color: Colors.white12),
                    _buildLigneDetails("Date", "${paiement.datePaiement.day.toString().padLeft(2, '0')}/${paiement.datePaiement.month.toString().padLeft(2, '0')}/${paiement.datePaiement.year} à ${paiement.datePaiement.hour.toString().padLeft(2, '0')}:${paiement.datePaiement.minute.toString().padLeft(2, '0')}"),
                    
                    const SizedBox(height: 40),
                    
                    // QR Code inversé (Blanc sur transparent)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: QrImageView(
                        data: paiement.numeroTransaction,
                        version: QrVersions.auto,
                        size: 140.0,
                        dataModuleStyle: const QrDataModuleStyle(
                          dataModuleShape: QrDataModuleShape.square,
                          color: Color(0xFF08111F),
                        ),
                        eyeStyle: const QrEyeStyle(
                          eyeShape: QrEyeShape.square,
                          color: Color(0xFF08111F),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "Scannez pour valider avec le transporteur",
                      style: GoogleFonts.poppins(color: Colors.white54, fontSize: 10),
                    ),
                    
                    const SizedBox(height: 40),
                    
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () {
                          HapticFeedback.mediumImpact();
                          onFermer();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: 0.1),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          "Continuer",
                          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    )
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLigneDetails(String titre, String valeur) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(titre, style: GoogleFonts.poppins(color: Colors.white54, fontSize: 14)),
        Text(valeur, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white)),
      ],
    );
  }
}
