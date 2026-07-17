import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../coeur/constantes/couleurs.dart';
import '../../coeur/constantes/tailles.dart';
import '../../coeur/widgets/bouton_principal.dart';

class Facture extends StatelessWidget {
  const Facture({super.key});

  @override
  Widget build(BuildContext context) {
    const double montantTransport = 30000;
    const double fraisService = 2000;
    const double total = montantTransport + fraisService;

    return Scaffold(
      backgroundColor: CouleursApp.fond,
      appBar: AppBar(
        title: const Text("Détails de la Facture", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: CouleursApp.fond,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(TaillesApp.margePage),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(25),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, 10))
                ]
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: CouleursApp.primaire.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.receipt_long, size: 50, color: CouleursApp.primaire),
                  ).animate().scale(delay: 100.ms, curve: Curves.easeOutBack),
                  
                  const SizedBox(height: 20),
                  
                  const Text("FACTURE", style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 2))
                      .animate().fadeIn(delay: 200.ms),
                  const SizedBox(height: 8),
                  const Text("N° FAC-2026-000145", style: TextStyle(color: CouleursApp.texteSecondaire, fontWeight: FontWeight.w500))
                      .animate().fadeIn(delay: 300.ms),
                  
                  const SizedBox(height: 30),
                  const Divider(),
                  const SizedBox(height: 15),
                  
                  _ligne("Client", "Jean Dupont").animate().fadeIn(delay: 400.ms).slideX(begin: -0.1),
                  _ligne("Transporteur", "Jean Mvondo").animate().fadeIn(delay: 450.ms).slideX(begin: -0.1),
                  _ligne("Départ", "Douala").animate().fadeIn(delay: 500.ms).slideX(begin: -0.1),
                  _ligne("Destination", "Yaoundé").animate().fadeIn(delay: 550.ms).slideX(begin: -0.1),
                  _ligne("Date", "07 Juillet 2026").animate().fadeIn(delay: 600.ms).slideX(begin: -0.1),
                  _ligne("Statut", "Livré", couleurValeur: Colors.green).animate().fadeIn(delay: 650.ms).slideX(begin: -0.1),
                  
                  const SizedBox(height: 15),
                  const Divider(),
                  const SizedBox(height: 15),
                  
                  _ligneMontant("Transport", montantTransport).animate().fadeIn(delay: 700.ms).slideX(begin: -0.1),
                  _ligneMontant("Frais de service", fraisService).animate().fadeIn(delay: 750.ms).slideX(begin: -0.1),
                  
                  const SizedBox(height: 15),
                  const Divider(),
                  const SizedBox(height: 15),
                  
                  _ligneMontant("TOTAL", total, gras: true).animate().fadeIn(delay: 800.ms).scale(begin: const Offset(0.9, 0.9)),
                  
                  const SizedBox(height: 40),
                  
                  Container(
                    width: 140,
                    height: 140,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300, width: 2),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: const Icon(Icons.qr_code_2, size: 100, color: Colors.black87),
                  ).animate().fadeIn(delay: 900.ms),
                  const SizedBox(height: 12),
                  const Text("Scannez pour vérifier", style: TextStyle(color: CouleursApp.texteSecondaire, fontSize: 13))
                      .animate().fadeIn(delay: 1000.ms),
                ],
              ),
            ),
            
            const SizedBox(height: 35),
            
            BoutonPrincipal(
              texte: "Télécharger en PDF",
              icone: Icons.picture_as_pdf,
              auClic: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Le téléchargement PDF sera disponible après l'intégration du backend.")),
                );
              },
            ).animate().fadeIn(delay: 1100.ms).slideY(begin: 0.2),
            
            const SizedBox(height: 15),
            
            OutlinedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Le partage sera disponible prochainement.")),
                );
              },
              icon: const Icon(Icons.share, color: CouleursApp.primaire),
              label: const Text("Partager la facture", style: TextStyle(color: CouleursApp.primaire, fontWeight: FontWeight.bold)),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 55),
                side: const BorderSide(color: CouleursApp.primaire, width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              ),
            ).animate().fadeIn(delay: 1200.ms).slideY(begin: 0.2),
            
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  static Widget _ligne(String titre, String valeur, {Color? couleurValeur}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(titre, style: const TextStyle(color: CouleursApp.texteSecondaire, fontSize: 15)),
          ),
          Text(
            valeur,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: couleurValeur ?? CouleursApp.textePrincipal),
          ),
        ],
      ),
    );
  }

  static Widget _ligneMontant(String titre, double montant, {bool gras = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              titre,
              style: TextStyle(
                fontWeight: gras ? FontWeight.bold : FontWeight.w500,
                color: gras ? CouleursApp.textePrincipal : CouleursApp.texteSecondaire,
                fontSize: gras ? 18 : 15,
              ),
            ),
          ),
          Text(
            "${montant.toStringAsFixed(0)} FCFA",
            style: TextStyle(
              fontWeight: gras ? FontWeight.w900 : FontWeight.w600,
              fontSize: gras ? 22 : 16,
              color: gras ? Colors.green : CouleursApp.textePrincipal,
            ),
          ),
        ],
      ),
    );
  }
}