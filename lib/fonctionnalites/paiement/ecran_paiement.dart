import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../coeur/etat/paiement_provider.dart';
import '../../coeur/constantes/couleurs.dart';
import 'widgets/ticket_recu.dart';

class EcranPaiement extends ConsumerStatefulWidget {
  final String courseId;
  final double montant;
  final String transporteurId;

  const EcranPaiement({
    super.key,
    required this.courseId,
    required this.montant,
    required this.transporteurId,
  });

  @override
  ConsumerState<EcranPaiement> createState() => _EcranPaiementState();
}

class _EcranPaiementState extends ConsumerState<EcranPaiement> {
  String _methodeSelectionnee = "om"; // om, mtn, carte
  final TextEditingController _telephoneController = TextEditingController();

  @override
  void dispose() {
    _telephoneController.dispose();
    super.dispose();
  }

  void _validerPaiement() {
    if (_telephoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Veuillez entrer un numéro de téléphone ou un nom valide.")),
      );
      return;
    }

    final provider = ref.read(paiementProvider.notifier);
    // On simule que l'ID du client est récupéré depuis un provider global d'authentification
    // Pour l'instant, on met une valeur factice.
    const clientId = "client_actuel_123";

    if (_methodeSelectionnee == "om") {
      provider.payerParOM(
        courseId: widget.courseId,
        clientId: clientId,
        transporteurId: widget.transporteurId,
        montant: widget.montant,
        telephone: _telephoneController.text,
      );
    } else if (_methodeSelectionnee == "mtn") {
      provider.payerParMTN(
        courseId: widget.courseId,
        clientId: clientId,
        transporteurId: widget.transporteurId,
        montant: widget.montant,
        telephone: _telephoneController.text,
      );
    } else {
      provider.payerParCarte(
        courseId: widget.courseId,
        clientId: clientId,
        transporteurId: widget.transporteurId,
        montant: widget.montant,
        nomTitulaire: _telephoneController.text,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final etatPaiement = ref.watch(paiementProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: AppBar(
        title: const Text("Paiement Sécurisé", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black87,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            ref.read(paiementProvider.notifier).reinitialiser();
            context.pop();
          },
      ),
      ),
      body: Stack(
        children: [
          // Formulaire principal
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Montant
                  Center(
                    child: Column(
                      children: [
                        const Text("Montant à régler", style: TextStyle(color: Colors.black54, fontSize: 16)),
                        const SizedBox(height: 8),
                        Text(
                          "${widget.montant.toInt()} FCFA",
                          style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w900, color: CouleursApp.primaire),
                        ).animate().scale(delay: 200.ms, duration: 400.ms, curve: Curves.easeOutBack),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),

                  const Text("Moyen de paiement", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87)),
                  const SizedBox(height: 16),

                  // Grille des méthodes
                  Row(
                    children: [
                      Expanded(child: _buildMethodeCard("om", "Orange Money", Icons.account_balance_wallet, Colors.orange)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildMethodeCard("mtn", "MTN MoMo", Icons.account_balance_wallet, Colors.amber)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildMethodeCard("carte", "Carte", Icons.credit_card, Colors.blue)),
                    ],
                  ),

                  const SizedBox(height: 40),

                  // Champ de saisie dynamique
                  Text(
                    _methodeSelectionnee == "carte" ? "Nom du titulaire" : "Numéro de téléphone",
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _telephoneController,
                    keyboardType: _methodeSelectionnee == "carte" ? TextInputType.name : TextInputType.phone,
                    decoration: InputDecoration(
                      hintText: _methodeSelectionnee == "carte" ? "Ex: Jean Dupont" : "Ex: 6XXXXXXXX",
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      prefixIcon: Icon(_methodeSelectionnee == "carte" ? Icons.person : Icons.phone, color: CouleursApp.primaire),
                    ),
                  ),

                  const SizedBox(height: 16),
                  const Text("Note : Tapez '000000000' pour simuler un échec.", style: TextStyle(color: Colors.grey, fontSize: 12)),

                  const SizedBox(height: 50),

                  // Bouton de validation
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: etatPaiement.enCours ? null : _validerPaiement,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: CouleursApp.primaire,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 5,
                      ),
                      child: etatPaiement.enCours
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text("Valider le paiement", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Surcouche de reçu si succès
          if (etatPaiement.succes != null)
            Container(
              color: Colors.black54, // Fond sombre
              child: Center(
                child: TicketRecu(
                  paiement: etatPaiement.succes!,
                  onFermer: () {
                    ref.read(paiementProvider.notifier).reinitialiser();
                    context.pop(); // Retourner à l'écran précédent
                  },
                ),
              ),
            ),

          // Message d'erreur flottant
          if (etatPaiement.erreur != null && etatPaiement.succes == null)
            Positioned(
              top: 20,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red),
                    const SizedBox(width: 12),
                    Expanded(child: Text(etatPaiement.erreur!, style: const TextStyle(color: Colors.red))),
                  ],
                ),
              ).animate().fadeIn().slideY(begin: -0.2),
            ),
        ],
      ),
    );
  }

  Widget _buildMethodeCard(String cle, String label, IconData icon, Color couleurIcone) {
    final estSelectionne = _methodeSelectionnee == cle;
    return GestureDetector(
      onTap: () {
        setState(() {
          _methodeSelectionnee = cle;
          _telephoneController.clear();
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: estSelectionne ? CouleursApp.primaire.withValues(alpha: 0.1) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: estSelectionne ? CouleursApp.primaire : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            if (!estSelectionne)
              BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: estSelectionne ? CouleursApp.primaire : couleurIcone, size: 32),
            const SizedBox(height: 12),
            Text(
              label,
              style: TextStyle(
                fontWeight: estSelectionne ? FontWeight.bold : FontWeight.normal,
                color: estSelectionne ? CouleursApp.primaire : Colors.black87,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
