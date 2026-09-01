import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:update_camtrans/coeur/constantes/couleurs.dart';
import 'package:update_camtrans/coeur/etat/transporteur_provider.dart';

class Revenus extends ConsumerWidget {
  const Revenus({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsRevenus = ref.watch(statsRevenusProvider);
    final fluxRevenus = ref.watch(fluxMesRevenusProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: AppBar(
        title: const Text("Revenus & Portefeuille", style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF08111F),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white70),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Carte Solde
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(25),
              decoration: BoxDecoration(
                gradient: CouleursApp.degradePrincipal,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: CouleursApp.primaire.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 10))
                ]
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Revenus totaux générés", style: TextStyle(color: Colors.white70, fontSize: 16)),
                  const SizedBox(height: 10),
                  Text(
                    "${statsRevenus['total']?.toStringAsFixed(0)} FCFA",
                    style: const TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Cette semaine", style: TextStyle(color: Colors.white70, fontSize: 13)),
                          Text("${statsRevenus['cetteSemaine']?.toStringAsFixed(0)} FCFA", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text("Ce mois", style: TextStyle(color: Colors.white70, fontSize: 13)),
                          Text("${statsRevenus['ceMois']?.toStringAsFixed(0)} FCFA", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 30),
            
            // Bouton de retrait
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Fonctionnalité de retrait bientôt disponible !")));
                },
                icon: const Icon(Icons.account_balance_wallet, color: Colors.white),
                label: const Text("Demander un paiement", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black87,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
              ),
            ),

            const SizedBox(height: 35),
            const Text("Historique des paiements", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),

            fluxRevenus.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Text("Erreur: $err"),
              data: (paiements) {
                if (paiements.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(40.0),
                      child: Text("Aucun revenu enregistré pour le moment.", style: TextStyle(color: Colors.white54)),
                    ),
                  );
                }
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: paiements.length,
                  itemBuilder: (context, index) {
                    final paiement = paiements[index];
                    return Card(
                      elevation: 0,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: CircleAvatar(
                          backgroundColor: Colors.green.withValues(alpha: 0.1),
                          child: const Icon(Icons.arrow_downward, color: Colors.green),
                        ),
                        title: const Text("Paiement reçu", style: TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(
                          "${paiement.datePaiement.day}/${paiement.datePaiement.month}/${paiement.datePaiement.year}",
                          style: const TextStyle(color: Colors.white54),
                        ),
                        trailing: Text(
                          "+${paiement.montantNet.toStringAsFixed(0)} FCFA",
                          style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.green, fontSize: 15),
                        ),
                      ),
                    );
                  },
                );
              }
            ),
          ],
        ),
      ),
    );
  }
}