import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:update_camtrans/coeur/constantes/couleurs.dart';
import 'package:update_camtrans/services/service_authentification.dart';
import 'package:update_camtrans/services/service_firestore.dart';
import 'package:update_camtrans/modeles/paiement.dart';
import 'package:update_camtrans/modeles/course.dart';
import 'package:update_camtrans/fonctionnalites/paiement/widgets/ticket_recu.dart';

// Provider filtré par l'UID de l'utilisateur connecté
final listePaiementsProvider = StreamProvider.autoDispose<List<Paiement>>((ref) {
  final firestore = ref.watch(serviceFirestoreProvider);
  final auth = ref.watch(serviceAuthentificationProvider);
  final uid = auth.utilisateur?.uid ?? '';

  if (uid.isEmpty) return Stream.value([]);

  // Filtrage Firestore par clientId pour ne voir que ses propres paiements
  return firestore.fluxCollectionCondition(
    collection: 'paiements',
    champ: 'clientId',
    valeur: uid,
  ).map((snapshot) {
    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return Paiement.fromMap(data);
    }).toList()
      ..sort((a, b) => b.datePaiement.compareTo(a.datePaiement));
  });
});

class Facture extends ConsumerWidget {
  final Course? course;
  const Facture({super.key, this.course});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Si une course est passée en param, on affiche ses détails
    if (course != null) {
      return _buildDetailCourse(context, course!);
    }
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

  /// Vue détaillée d'une course spécifique
  Widget _buildDetailCourse(BuildContext context, Course c) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: AppBar(
        title: const Text("Détail de la course", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black87,
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: CouleursApp.degradePrincipal,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: CouleursApp.primaire.withValues(alpha: 0.25), blurRadius: 20)],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Montant de la course", style: TextStyle(color: Colors.white70, fontSize: 14)),
                  const SizedBox(height: 6),
                  Text("${c.prixEstime.toInt()} FCFA",
                      style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 20),
                  Text("Statut : ${c.statut}", style: const TextStyle(color: Colors.white70, fontSize: 13)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _infoTile(Icons.location_on, "Départ", c.adresseDepart),
            _infoTile(Icons.flag, "Destination", c.adresseArrivee),
            _infoTile(Icons.local_shipping, "Véhicule", c.typeVehicule),
            _infoTile(Icons.category, "Type de service", c.categorieService),
            _infoTile(Icons.calendar_today, "Date",
                "${c.dateCreation.day}/${c.dateCreation.month}/${c.dateCreation.year}"),
          ],
        ),
      ),
    );
  }

  Widget _infoTile(IconData icon, String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: CouleursApp.primaire.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(icon, color: CouleursApp.primaire, size: 20),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: Colors.black45, fontSize: 12)),
              Text(value.isNotEmpty ? value : "-",
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)),
            ],
          ),
        ],
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
      ),
    );
  }
}