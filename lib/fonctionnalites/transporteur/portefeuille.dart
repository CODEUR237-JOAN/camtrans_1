import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:update_camtrans/coeur/constantes/couleurs.dart';
import 'package:update_camtrans/coeur/constantes/tailles.dart';
import 'package:update_camtrans/coeur/widgets/bouton_principal.dart';
import 'package:update_camtrans/coeur/etat/transporteur_provider.dart';

class Portefeuille extends ConsumerWidget {
  const Portefeuille({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsRevenus = ref.watch(statsRevenusProvider);
    final fluxRevenus = ref.watch(fluxMesRevenusProvider);

    return Scaffold(
      backgroundColor: CouleursApp.fond,
      appBar: AppBar(
        title: const Text("Mon portefeuille"),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(TaillesApp.margePage),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(25),
              decoration: BoxDecoration(
                gradient: CouleursApp.degradePrincipal,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Solde disponible",
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "${statsRevenus['total']?.toStringAsFixed(0)} FCFA",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            Row(
              children: [
                Expanded(
                  child: _statistique(
                    "Cette semaine",
                    "${statsRevenus['cetteSemaine']?.toStringAsFixed(0)} FCFA",
                    Icons.date_range,
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: _statistique(
                    "Ce mois",
                    "${statsRevenus['ceMois']?.toStringAsFixed(0)} FCFA",
                    Icons.calendar_month,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 30),

            const Text(
              "Retrait",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 15),

            BoutonPrincipal(
              texte: "Retirer via Orange Money",
              icone: Icons.account_balance_wallet,
              auClic: () {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Service de retrait non disponible en environnement de test.")));
              },
            ),

            const SizedBox(height: 15),

            BoutonPrincipal(
              texte: "Retirer via MTN Mobile Money",
              icone: Icons.phone_android,
              auClic: () {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Service de retrait non disponible en environnement de test.")));
              },
            ),

            const SizedBox(height: 15),

            BoutonPrincipal(
              texte: "Virement bancaire",
              icone: Icons.account_balance,
              auClic: () {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Service de retrait non disponible en environnement de test.")));
              },
            ),

            const SizedBox(height: 30),

            const Text(
              "Historique des transactions",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 15),

            fluxRevenus.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Text("Erreur: $err"),
              data: (paiements) {
                if (paiements.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(20.0),
                    child: Center(child: Text("Aucune transaction.", style: TextStyle(color: Colors.grey))),
                  );
                }
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: paiements.length,
                  itemBuilder: (context, index) {
                    final paiement = paiements[index];
                    return _transaction(
                      "Paiement course",
                      "Via ${paiement.methodePaiement}",
                      "+${paiement.montantNet.toStringAsFixed(0)} FCFA",
                      Colors.green,
                      Icons.arrow_downward,
                    );
                  },
                );
              }
            ),

            const SizedBox(height: 25),
          ],
        ),
      ),
    );
  }

  Widget _statistique(String titre, String valeur, IconData icone) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            Icon(icone, color: CouleursApp.primaire, size: 35),
            const SizedBox(height: 12),
            Text(valeur, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 6),
            Text(titre, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _transaction(String titre, String sousTitre, String montant, Color couleur, IconData icone) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: couleur.withValues(alpha: .15),
          child: Icon(icone, color: couleur),
        ),
        title: Text(titre),
        subtitle: Text(sousTitre),
        trailing: Text(
          montant,
          style: TextStyle(color: couleur, fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
    );
  }
}