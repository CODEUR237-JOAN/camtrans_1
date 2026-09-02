import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'package:update_camtrans/coeur/constantes/couleurs.dart';
import 'package:update_camtrans/coeur/etat/admin_provider.dart';
import 'package:update_camtrans/coeur/widgets/loader_premium.dart';

class PageAbonnementsAdmin extends ConsumerWidget {
  const PageAbonnementsAdmin({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final abonnementsAsync = ref.watch(adminAbonnementsProvider);

    return Scaffold(
      backgroundColor: CouleursApp.fondSombre,
      appBar: AppBar(
        title: Text(
          'Abonnements Transporteurs',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.white),
        ),
        backgroundColor: CouleursApp.secondaire,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: abonnementsAsync.when(
        loading: () => Center(child: LoaderPremium()),
        error: (err, _) => Center(child: Text("Oups ! Les données sont introuvables : $err 🔧", style: const TextStyle(color: Colors.red))),
        data: (abonnements) {
          // ===== CALCUL DES STATISTIQUES =====
          final now = DateTime.now();
          final debutAujourdhui = DateTime(now.year, now.month, now.day);
          final debutSemaine = now.subtract(Duration(days: now.weekday - 1));
          final debutMois = DateTime(now.year, now.month, 1);
          final debutAnnee = DateTime(now.year, 1, 1);

          double totalJour = 0, totalSemaine = 0, totalMois = 0, totalAnnee = 0;

          for (final a in abonnements) {
            final montant = (a['montant'] as num?)?.toDouble() ?? 0;
            final dateDebut = DateTime.tryParse(a['dateDebut'] ?? '');
            if (dateDebut == null) continue;

            if (!dateDebut.isBefore(debutAujourdhui)) totalJour += montant;
            if (!dateDebut.isBefore(debutSemaine)) totalSemaine += montant;
            if (!dateDebut.isBefore(debutMois)) totalMois += montant;
            if (!dateDebut.isBefore(debutAnnee)) totalAnnee += montant;
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ===== CARTES STATISTIQUES =====
                Text('Revenus des abonnements',
                    style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 16),
                GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: 1.4,
                  children: [
                    _carteStatistique('Aujourd\'hui', totalJour, Icons.today, const Color(0xFF4CAF50)),
                    _carteStatistique('Cette semaine', totalSemaine, Icons.date_range, const Color(0xFF2196F3)),
                    _carteStatistique('Ce mois', totalMois, Icons.calendar_month, const Color(0xFFFF9800)),
                    _carteStatistique('Cette année', totalAnnee, Icons.bar_chart, CouleursApp.primaire),
                  ],
                ),

                const SizedBox(height: 28),

                // ===== LISTE DES PAIEMENTS =====
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Historique (${abonnements.length})',
                        style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                  ],
                ),
                const SizedBox(height: 12),

                if (abonnements.isEmpty)
                  Center(
                    child: Column(
                      children: [
                        const SizedBox(height: 40),
                        Icon(Icons.receipt_long_outlined, size: 70, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        Text('Aucun abonnement pour le moment. Laissons le temps aux transporteurs de nous rejoindre ! 🌱',
                            style: TextStyle(color: Colors.grey.shade500, fontSize: 16)),
                      ],
                    ),
                  )
                else
                  ...abonnements.map((a) => _carteAbonnement(a)).toList(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _carteStatistique(String titre, double montant, IconData icone, Color couleur) {
    final formatter = NumberFormat('#,##0', 'fr_FR');
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CouleursApp.carteSombre,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: couleur.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icone, color: couleur, size: 22),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${formatter.format(montant)} F',
                  style: GoogleFonts.inter(
                      fontSize: 18, fontWeight: FontWeight.w800, color: couleur)),
              Text(titre,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade400, fontWeight: FontWeight.w500)),
            ],
          )
        ],
      ),
    );
  }

  Widget _carteAbonnement(Map<String, dynamic> abonnement) {
    final montant = (abonnement['montant'] as num?)?.toDouble() ?? 0;
    final nom = abonnement['nomTransporteur'] ?? 'Transporteur';
    final duree = abonnement['dureeJours'] ?? 0;
    final operateur = abonnement['operateur'] ?? '';
    final dateDebut = DateTime.tryParse(abonnement['dateDebut'] ?? '');
    final dateFin = DateTime.tryParse(abonnement['dateFin'] ?? '');
    final statut = abonnement['statut'] ?? 'actif';

    final couleurStatut = statut == 'actif' ? Colors.green : Colors.orange;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CouleursApp.carteSombre,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: CouleursApp.primaire.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.workspace_premium, color: CouleursApp.primaire, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(nom,
                    style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white)),
                const SizedBox(height: 2),
                Text('$duree jours • $operateur',
                    style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
                if (dateDebut != null)
                  Text(
                    'Du ${DateFormat('dd/MM/yy').format(dateDebut)} au ${dateFin != null ? DateFormat('dd/MM/yy').format(dateFin) : '?'}',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                  ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${montant.toInt()} F',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 16, color: Colors.green.shade700)),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: couleurStatut.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(statut,
                    style: TextStyle(color: couleurStatut, fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
