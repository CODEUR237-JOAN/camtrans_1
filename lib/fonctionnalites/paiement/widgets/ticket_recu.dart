import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'package:update_camtrans/modeles/paiement.dart';
import 'package:update_camtrans/coeur/constantes/couleurs.dart';

class TicketRecu extends StatelessWidget {
  final Paiement paiement;
  final VoidCallback onFermer;

  const TicketRecu({super.key, required this.paiement, required this.onFermer});

  Future<void> _telechargerPDF(BuildContext context) async {
    final pdf = pw.Document();

    // Charger le logo depuis les assets
    final ByteData logoData = await rootBundle.load('assets/logos/logo.png');
    final Uint8List logoBytes = logoData.buffer.asUint8List();
    final logoImage = pw.MemoryImage(logoBytes);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context ctx) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.SizedBox(height: 20),
              pw.Image(logoImage, width: 120),
              pw.SizedBox(height: 20),
              pw.Text('Reçu de Paiement', style: pw.TextStyle(fontSize: 28, fontWeight: pw.FontWeight.bold, color: const PdfColor(0.08, 0.36, 0.26))),
              pw.SizedBox(height: 10),
              pw.Divider(color: PdfColors.grey300),
              pw.SizedBox(height: 30),
              
              _buildPdfLigneDetails('Montant Payé', '${paiement.montant.toInt()} ${paiement.devise}', isBold: true, isLarge: true),
              pw.SizedBox(height: 20),
              
              _buildPdfLigneDetails('Méthode de paiement', paiement.methodePaiement.toUpperCase()),
              _buildPdfLigneDetails('N° de Transaction', paiement.numeroTransaction),
              _buildPdfLigneDetails('Référence Course', paiement.reference),
              _buildPdfLigneDetails('Date et Heure', "${paiement.datePaiement.day.toString().padLeft(2, '0')}/${paiement.datePaiement.month.toString().padLeft(2, '0')}/${paiement.datePaiement.year} à ${paiement.datePaiement.hour.toString().padLeft(2, '0')}:${paiement.datePaiement.minute.toString().padLeft(2, '0')}"),
              
              pw.SizedBox(height: 40),
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
                ),
                child: pw.BarcodeWidget(
                  data: paiement.numeroTransaction,
                  barcode: pw.Barcode.qrCode(),
                  width: 120,
                  height: 120,
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Text('TransConnect Cameroun - Merci de votre confiance.', style: pw.TextStyle(color: PdfColors.grey600, fontSize: 12)),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Recu_Paiement_${paiement.numeroTransaction}.pdf',
    );
  }

  pw.Widget _buildPdfLigneDetails(String titre, String valeur, {bool isBold = false, bool isLarge = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 8),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(titre, style: pw.TextStyle(color: PdfColors.grey700, fontSize: isLarge ? 16 : 14)),
          pw.Text(valeur, style: pw.TextStyle(fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal, fontSize: isLarge ? 18 : 14)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
            color: CouleursApp.succes.withValues(alpha: 0.3), width: 1.5),
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
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // En-tête vert néon
                Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                  decoration: BoxDecoration(
                    color: CouleursApp.succes.withValues(alpha: 0.1),
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
                        child: const Icon(Icons.check_circle_outline,
                            color: CouleursApp.succes, size: 28),
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

                // Ligne de découpe (Dashed line) moderne
                Row(
                  children: List.generate(30, (index) {
                    return Expanded(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        height: 2,
                        color: index % 2 == 0
                            ? CouleursApp.succes.withValues(alpha: 0.3)
                            : Colors.transparent,
                      ),
                    );
                  }),
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

                      _buildLigneDetails(
                          "Méthode", paiement.methodePaiement.toUpperCase()),
                      const Divider(height: 32, color: Colors.white12),
                      _buildLigneDetails(
                          "N° Transaction", paiement.numeroTransaction),
                      const Divider(height: 32, color: Colors.white12),
                      _buildLigneDetails("Réf. Course", paiement.reference),
                      const Divider(height: 32, color: Colors.white12),
                      _buildLigneDetails("Date",
                          "${paiement.datePaiement.day.toString().padLeft(2, '0')}/${paiement.datePaiement.month.toString().padLeft(2, '0')}/${paiement.datePaiement.year} à ${paiement.datePaiement.hour.toString().padLeft(2, '0')}:${paiement.datePaiement.minute.toString().padLeft(2, '0')}"),

                      const SizedBox(height: 40),

                      // QR Code inversé (Blanc sur transparent)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  blurRadius: 20,
                                  offset: const Offset(0, 5))
                            ]),
                        child: QrImageView(
                          data: paiement.numeroTransaction,
                          version: QrVersions.auto,
                          size: 140.0,
                          dataModuleStyle: const QrDataModuleStyle(
                            dataModuleShape: QrDataModuleShape.square,
                            color: Colors.white,
                          ),
                          eyeStyle: const QrEyeStyle(
                            eyeShape: QrEyeShape.square,
                            color: Color(0xFF08111F),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "Scannez pour valider avec le transporteur",
                        style: GoogleFonts.poppins(
                            color: Colors.white54,
                            fontSize: 11,
                            fontWeight: FontWeight.w500),
                      ),

                      const SizedBox(height: 40),
                      
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: OutlinedButton.icon(
                          onPressed: () => _telechargerPDF(context),
                          icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
                          label: Text(
                            "Télécharger le reçu",
                            style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.white24, width: 1.5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: () {
                            HapticFeedback.mediumImpact();
                            onFermer();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                CouleursApp.succes.withValues(alpha: 0.15),
                            foregroundColor: CouleursApp.succes,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(
                                  color: CouleursApp.succes
                                      .withValues(alpha: 0.3)),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            "Terminer",
                            style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1),
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
      ),
    );
  }

  Widget _buildLigneDetails(String titre, String valeur) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(titre,
            style: GoogleFonts.poppins(color: Colors.white54, fontSize: 14)),
        Text(valeur,
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Colors.white)),
      ],
    );
  }
}
