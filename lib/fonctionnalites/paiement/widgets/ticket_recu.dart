import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../modeles/paiement.dart';
import '../../../coeur/constantes/couleurs.dart';

class TicketRecu extends StatelessWidget {
  final Paiement paiement;
  final VoidCallback onFermer;

  const TicketRecu({super.key, required this.paiement, required this.onFermer});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // En-tête vert
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Colors.green,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 32),
                const SizedBox(width: 12),
                const Text(
                  "Paiement Réussi",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                Text(
                  "${paiement.montant.toInt()} ${paiement.devise}",
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 24),
                _buildLigneDetails("Moyen de paiement", paiement.methodePaiement),
                const Divider(height: 32),
                _buildLigneDetails("Numéro de Transaction", paiement.numeroTransaction),
                const Divider(height: 32),
                _buildLigneDetails("Référence Course", paiement.reference),
                const Divider(height: 32),
                _buildLigneDetails("Date", "${paiement.datePaiement.day}/${paiement.datePaiement.month}/${paiement.datePaiement.year} ${paiement.datePaiement.hour}:${paiement.datePaiement.minute}"),
                
                const SizedBox(height: 32),
                // QR Code
                QrImageView(
                  data: paiement.numeroTransaction,
                  version: QrVersions.auto,
                  size: 120.0,
                  dataModuleStyle: const QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.square,
                    color: Colors.black87,
                  ),
                  eyeStyle: const QrEyeStyle(
                    eyeShape: QrEyeShape.square,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Scannez pour vérifier",
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
                
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: onFermer,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: CouleursApp.primaire,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      "Terminer",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                )
              ],
            ),
          )
        ],
      ),
    ).animate().slideY(begin: -1.0, end: 0, curve: Curves.easeOutBack, duration: 800.ms).fadeIn();
  }

  Widget _buildLigneDetails(String titre, String valeur) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(titre, style: const TextStyle(color: Colors.black54, fontSize: 14)),
        Text(valeur, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)),
      ],
    );
  }
}
