import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import 'package:update_camtrans/coeur/constantes/couleurs.dart';
import 'package:update_camtrans/coeur/constantes/statuts.dart';
import 'package:update_camtrans/services/service_authentification.dart';
import 'package:update_camtrans/services/service_firestore.dart';
import 'package:update_camtrans/modeles/paiement.dart';
import 'package:update_camtrans/modeles/course.dart';
import 'package:update_camtrans/fonctionnalites/paiement/widgets/ticket_recu.dart';
import 'package:update_camtrans/coeur/widgets/loader_premium.dart';

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
      backgroundColor: const Color(0xFF08111F),
      appBar: AppBar(
        // ✅ CORRECTION 1.3: foregroundColor blanc (était Colors.black87 invisible sur fond sombre)
        title: Text(
          "Mes Transactions",
          style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF08111F),
        elevation: 0,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: fluxPaiements.when(
        loading: () => Center(child: LoaderPremium()),
        error: (err, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.wifi_off_rounded, size: 60, color: Colors.white38),
              const SizedBox(height: 16),
              Text("Problème de connexion 📡",
                  style: GoogleFonts.inter(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text("Réessayez dans quelques instants",
                  style: GoogleFonts.inter(color: Colors.white38, fontSize: 13)),
            ],
          ),
        ),
        data: (paiements) {
          if (paiements.isEmpty) {
            // ✅ HUMANISATION 3.3: État vide enrichi et chaleureux
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: CouleursApp.primaire.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                        border: Border.all(color: CouleursApp.primaire.withValues(alpha: 0.15), width: 2),
                      ),
                      child: const Icon(Iconsax.receipt_copy, size: 48, color: CouleursApp.primaire),
                    ).animate(onPlay: (c) => c.repeat(reverse: true))
                      .scale(begin: const Offset(1, 1), end: const Offset(1.05, 1.05), duration: 2.seconds),
                    const SizedBox(height: 24),
                    Text(
                      "Votre historique est vierge ✨",
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "Vos transactions apparaîtront ici après votre première course. Lancez-vous ! 🚀",
                      style: GoogleFonts.inter(color: Colors.white54, fontSize: 14, height: 1.5),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
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
      backgroundColor: const Color(0xFF08111F),
      appBar: AppBar(
        // ✅ CORRECTION 1.3: foregroundColor blanc
        title: Text("Détail de la course",
            style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: const Color(0xFF08111F),
        elevation: 0,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
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
        color: const Color(0xFF10192A),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.white.withValues(alpha: 0.07), blurRadius: 8)],
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
              Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
              Text(value.isNotEmpty ? value : "-",
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionCard(BuildContext context, Paiement paiement, int index) {
    // ✅ CORRECTION 1.2: Utilise StatutPaiement.succes au lieu de chaînes littérales
    // (le statut réel en DB est "succes", pas "Succès" ou "Confirmé")
    final bool isSucces = paiement.statut == StatutPaiement.succes;
    
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
          color: const Color(0xFF10192A),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.white.withValues(alpha: 0.07), blurRadius: 10, offset: const Offset(0, 5))
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
                  Text(paiement.methodePaiement, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                  const SizedBox(height: 4),
                  Text("${paiement.datePaiement.day}/${paiement.datePaiement.month}/${paiement.datePaiement.year}", style: const TextStyle(color: Colors.white70, fontSize: 13)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  "${paiement.montant.toInt()} FCFA",
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    // ✅ Couleur correcte : vert si succes, orange sinon (plus de Colors.black87 invisible)
                    color: isSucces ? CouleursApp.succes : CouleursApp.avertissement,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  StatutPaiement.libelle(paiement.statut),
                  style: GoogleFonts.inter(
                    color: isSucces ? CouleursApp.succes : CouleursApp.avertissement,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}