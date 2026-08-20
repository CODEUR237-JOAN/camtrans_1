import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:update_camtrans/coeur/constantes/couleurs.dart';
import 'package:update_camtrans/services/service_firestore.dart';
import 'package:update_camtrans/modeles/paiement.dart';
import 'package:update_camtrans/fonctionnalites/paiement/widgets/ticket_recu.dart';

// Provider pour écouter la liste des paiements de l'utilisateur actuel
final listePaiementsProvider = StreamProvider.autoDispose<List<Paiement>>((ref) {
  final firestore = ref.watch(serviceFirestoreProvider);
  // Simulation: on récupère tous les paiements (à filtrer par clientId en prod)
  return firestore.fluxCollection(collection: 'paiements').map((snapshot) {
    return snapshot.docs.map((doc) => Paiement.fromMap(doc.data())).toList()
      ..sort((a, b) => b.datePaiement.compareTo(a.datePaiement));
  });
});

class Facture extends ConsumerWidget {
  const Facture({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fluxPaiements = ref.watch(listePaiementsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: AppBar(
        title: const Text("Mes Transactions", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black87,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: fluxPaiements.when(
        loading: () => const Center(child: CircularProgressIndicator(color: CouleursApp.primaire)),
        error: (err, stack) => Center(child: Text("Erreur : $err")),
        data: (paiements) {
          if (paiements.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long, size: 80, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  const Text("Aucune transaction trouvée", style: TextStyle(color: Colors.black54, fontSize: 16)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: paiements.length,
            itemBuilder: (context, index) {
              final paiement = paiements[index];
              return _buildTransactionCard(context, paiement, index);
            },
          );
        },
      ),
    );
  }

  Widget _buildTransactionCard(BuildContext context, Paiement paiement, int index) {
    bool isSucces = paiement.statut == "Succès" || paiement.statut == "Confirmé";
    
    IconData getIcon() {
      if (paiement.methodePaiement.toLowerCase().contains("orange")) return Icons.account_balance_wallet;
      if (paiement.methodePaiement.toLowerCase().contains("mtn")) return Icons.phone_android;
      return Icons.credit_card;
    }

    Color getColor() {
      if (paiement.methodePaiement.toLowerCase().contains("orange")) return Colors.orange;
      if (paiement.methodePaiement.toLowerCase().contains("mtn")) return Colors.amber;
      return Colors.blue;
    }

    return GestureDetector(
      onTap: () {
        // Afficher le ticket
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          isScrollControlled: true,
          builder: (ctx) => TicketRecu(
            paiement: paiement,
            onFermer: () => Navigator.pop(ctx),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 5))
          ]
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: getColor().withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(getIcon(), color: getColor()),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(paiement.methodePaiement, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
                  const SizedBox(height: 4),
                  Text("${paiement.datePaiement.day}/${paiement.datePaiement.month}/${paiement.datePaiement.year}", style: const TextStyle(color: Colors.black54, fontSize: 13)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  "${paiement.montant.toInt()} FCFA",
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: isSucces ? Colors.green : Colors.black87),
                ),
                const SizedBox(height: 4),
                Text(
                  paiement.statut,
                  style: TextStyle(color: isSucces ? Colors.green : Colors.orange, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
      ).animate().slideX(begin: 0.2, delay: (index * 100).ms).fadeIn(),
    );
  }
}