import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:update_camtrans/coeur/constantes/couleurs.dart';
import 'package:update_camtrans/coeur/etat/admin_provider.dart';
import 'package:update_camtrans/coeur/etat/transporteur_provider.dart';
import 'package:update_camtrans/modeles/parametres_app.dart';
import 'package:update_camtrans/services/service_authentification.dart';
import 'package:update_camtrans/services/service_paiement.dart';

class PageAbonnement extends ConsumerStatefulWidget {
  const PageAbonnement({super.key});

  @override
  ConsumerState<PageAbonnement> createState() => _PageAbonnementState();
}

class _PageAbonnementState extends ConsumerState<PageAbonnement> {
  bool _isProcessing = false;

  Future<void> _souscrire(String type, double prix, int joursAAjouter) async {
    final user = ref.read(currentTransporteurProvider).valueOrNull;
    if (user == null) return;

    setState(() => _isProcessing = true);

    try {
      final phoneCtrl = TextEditingController(text: user.telephone);
      String operateur = "Orange";

      final confirme = await showDialog<bool>(
        context: context,
        builder: (context) {
          return StatefulBuilder(
            builder: (context, setStateDialog) {
              return AlertDialog(
                backgroundColor: const Color(0xFF08111F),
                title: Text("Paiement via CamPay", style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text("Vous allez payer ${prix.toInt()} F. Un pop-up s'affichera sur ce numéro pour valider.", style: const TextStyle(color: Colors.white70)),
                    const SizedBox(height: 16),
                    TextField(
                      controller: phoneCtrl,
                      keyboardType: TextInputType.phone,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: "Numéro Mobile Money",
                        labelStyle: const TextStyle(color: Colors.white54),
                        filled: true,
                        fillColor: const Color(0xFF1A2640),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: operateur,
                      dropdownColor: const Color(0xFF10192A),
                      style: const TextStyle(color: Colors.white),
                      items: ["Orange", "MTN"].map((op) => DropdownMenuItem(value: op, child: Text(op))).toList(),
                      onChanged: (val) {
                        if (val != null) setStateDialog(() => operateur = val);
                      },
                      decoration: InputDecoration(
                        labelText: "Opérateur",
                        labelStyle: const TextStyle(color: Colors.white54),
                        filled: true,
                        fillColor: const Color(0xFF1A2640),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],
                ),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Annuler")),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(backgroundColor: CouleursApp.primaire),
                    child: const Text("Payer"),
                  ),
                ],
              );
            }
          );
        },
      );

      if (confirme != true) {
        setState(() => _isProcessing = false);
        return;
      }

      // Appeler CamPay avec toutes les infos
      final servicePaiement = ref.read(servicePaiementProvider);
      await servicePaiement.initierPaiementAbonnement(
        transporteurId: user.id,
        nomTransporteur: '${user.prenom} ${user.nom}',
        montant: prix,
        telephonePayeur: phoneCtrl.text,
        operateur: operateur,
        dureeJours: joursAAjouter,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Abonnement $type activé avec succès !")));
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Échec du paiement : $e")));
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final parametresAsync = ref.watch(adminParametresProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF08111F),
      appBar: AppBar(
        title: const Text("Abonnement", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF08111F),
        elevation: 0,
        automaticallyImplyLeading: false, // On force le choix
      ),
      body: _isProcessing
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: CouleursApp.primaire),
                  SizedBox(height: 16),
                  Text("Traitement du paiement en cours...", style: TextStyle(color: Colors.white)),
                ],
              ),
            )
          : parametresAsync.when(
              loading: () => const Center(child: CircularProgressIndicator(color: CouleursApp.primaire)),
              error: (err, _) => _buildContenu(const ParametresApp()),
              data: (parametres) => _buildContenu(parametres),
            ),
    );
  }

  Widget _buildContenu(ParametresApp parametres) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(Icons.workspace_premium_rounded, size: 80, color: Colors.orangeAccent),
          const SizedBox(height: 16),
          Text(
            "Passez à la vitesse supérieure 🚀",
            style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            "Votre accès gratuit est arrivé à terme. Rejoignez la communauté CamTrans et commencez à maximiser vos revenus dès aujourd'hui !",
            style: GoogleFonts.inter(fontSize: 14, color: Colors.white70),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          // Liste des forfaits
          _buildPlanCard(
            titre: "Journalier",
            duree: "24 Heures",
            prix: parametres.prixAbonnementJour,
            icone: Icons.today,
            onTap: () => _souscrire("Journalier", parametres.prixAbonnementJour, 1),
          ),
          const SizedBox(height: 16),
          _buildPlanCard(
            titre: "Mensuel",
            duree: "30 Jours",
            prix: parametres.prixAbonnementMois,
            icone: Icons.calendar_month,
            recommande: true,
            onTap: () => _souscrire("Mensuel", parametres.prixAbonnementMois, 30),
          ),
          const SizedBox(height: 16),
          _buildPlanCard(
            titre: "Annuel",
            duree: "365 Jours",
            prix: parametres.prixAbonnementAn,
            icone: Icons.event,
            onTap: () => _souscrire("Annuel", parametres.prixAbonnementAn, 365),
          ),
          
          const SizedBox(height: 24),
          TextButton(
            onPressed: () => ref.read(serviceAuthentificationProvider).deconnexion(),
            child: const Text("Se déconnecter", style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanCard({
    required String titre,
    required String duree,
    required double prix,
    required IconData icone,
    required VoidCallback onTap,
    bool recommande = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: recommande ? CouleursApp.primaire.withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: recommande ? CouleursApp.primaire : Colors.white.withValues(alpha: 0.1),
            width: recommande ? 2 : 1,
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: recommande ? CouleursApp.primaire : Colors.white.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icone, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          titre, 
                          style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (recommande) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(color: Colors.orange, borderRadius: BorderRadius.circular(10)),
                          child: const Text("Populaire", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
                        ),
                      ]
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text("Valable $duree", style: GoogleFonts.inter(fontSize: 13, color: Colors.white70)),
                ],
              ),
            ),
            Text(
              "${prix.toInt()} F",
              style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold, color: CouleursApp.primaire),
            ),
          ],
        ),
      ),
    );
  }
}
