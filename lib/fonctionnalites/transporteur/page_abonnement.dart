import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import 'package:update_camtrans/coeur/constantes/couleurs.dart';
import 'package:update_camtrans/coeur/etat/admin_provider.dart';
import 'package:update_camtrans/coeur/etat/transporteur_provider.dart';
import 'package:update_camtrans/modeles/parametres_app.dart';
import 'package:update_camtrans/services/service_authentification.dart';
import 'package:update_camtrans/services/service_paiement.dart';
import 'package:update_camtrans/coeur/widgets/loader_premium.dart';

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
      // ✅ CORRECTION 1.4: Dialog extrait dans un StatefulWidget dédié (_DialogPaiementAbonnement)
      // pour garantir la gestion correcte du dispose() du TextEditingController.
      final result = await showDialog<_ResultatDialogPaiement?>(
        context: context,
        barrierDismissible: false,
        builder: (context) => _DialogPaiementAbonnement(
          montant: prix,
          telephoneInitial: user.telephone,
        ),
      );

      if (result == null || !result.confirme) {
        setState(() => _isProcessing = false);
        return;
      }

      final servicePaiement = ref.read(servicePaiementProvider);
      await servicePaiement.initierPaiementAbonnement(
        transporteurId: user.id,
        nomTransporteur: '${user.prenom} ${user.nom}',
        montant: prix,
        telephonePayeur: result.telephone,
        operateur: result.operateur,
        dureeJours: joursAAjouter,
      );

      HapticFeedback.heavyImpact();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  "Abonnement $type activé ! Bonne route 🚛",
                  style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            backgroundColor: CouleursApp.succes,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Échec du paiement : ${e.toString().replaceAll('Exception: ', '')}"),
            backgroundColor: CouleursApp.erreur,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
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
        title: Text(
          "Abonnement",
          style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF08111F),
        elevation: 0,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: _isProcessing
          ? _buildTraitement()
          : parametresAsync.when(
              loading: () => Center(child: LoaderPremium()),
              error: (err, _) => _buildContenu(const ParametresApp()),
              data: (parametres) => _buildContenu(parametres),
            ),
    );
  }

  /// ✅ HUMANISATION: Écran de traitement animé avec étapes progressives
  Widget _buildTraitement() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: CouleursApp.primaire.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const LoaderPremium(size: 24),
          ).animate(onPlay: (c) => c.repeat())
            .rotate(duration: 2.seconds),
          const SizedBox(height: 24),
          Text(
            "Traitement du paiement...",
            style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 8),
          Text(
            "Patientez, votre abonnement est en cours d'activation 🔐",
            style: GoogleFonts.inter(color: Colors.white54, fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildContenu(ParametresApp parametres) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // En-tête premium
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFB347), Color(0xFFFF8C00)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.orange.withValues(alpha: 0.4),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Icon(Icons.workspace_premium_rounded, size: 48, color: Colors.white),
          ).animate().scale(duration: 400.ms, curve: Curves.elasticOut),

          const SizedBox(height: 20),
          Text(
            "Passez à la vitesse supérieure 🚀",
            style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 150.ms),
          const SizedBox(height: 10),
          Text(
            "Votre accès gratuit est arrivé à terme. Rejoignez la communauté CamTrans et commencez à maximiser vos revenus dès aujourd'hui !",
            style: GoogleFonts.inter(fontSize: 14, color: Colors.white60, height: 1.5),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 250.ms),

          const SizedBox(height: 32),

          // Avantages inclus
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Column(
              children: [
                _buildAvantage(Icons.check_circle_rounded, "Accès illimité aux demandes clients", CouleursApp.succes),
                _buildAvantage(Icons.check_circle_rounded, "Paiements mobiles MTN & Orange Money", CouleursApp.succes),
                _buildAvantage(Icons.check_circle_rounded, "Support prioritaire 24h/24", CouleursApp.succes),
                _buildAvantage(Icons.check_circle_rounded, "Assistant IA pour optimiser vos revenus", CouleursApp.succes),
              ],
            ),
          ).animate().fadeIn(delay: 350.ms),

          // Forfaits
          _buildPlanCard(
            titre: "Journalier",
            duree: "24 Heures",
            prix: parametres.prixAbonnementJour,
            icone: Icons.today_rounded,
            index: 0,
            onTap: () => _souscrire("Journalier", parametres.prixAbonnementJour, 1),
          ),
          const SizedBox(height: 12),
          _buildPlanCard(
            titre: "Mensuel",
            duree: "30 Jours",
            prix: parametres.prixAbonnementMois,
            icone: Icons.calendar_month_rounded,
            recommande: true,
            index: 1,
            onTap: () => _souscrire("Mensuel", parametres.prixAbonnementMois, 30),
          ),
          const SizedBox(height: 12),
          _buildPlanCard(
            titre: "Annuel",
            duree: "365 Jours",
            prix: parametres.prixAbonnementAn,
            icone: Icons.event_rounded,
            index: 2,
            onTap: () => _souscrire("Annuel", parametres.prixAbonnementAn, 365),
          ),

          const SizedBox(height: 32),
          TextButton.icon(
            onPressed: () => ref.read(serviceAuthentificationProvider).deconnexion(),
            icon: const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 16),
            label: Text(
              "Se déconnecter",
              style: GoogleFonts.inter(color: Colors.redAccent, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvantage(IconData icon, String texte, Color couleur) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Icon(icon, color: couleur, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(texte, style: GoogleFonts.inter(color: Colors.white70, fontSize: 13)),
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
    required int index,
    bool recommande = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: recommande
              ? LinearGradient(
                  colors: [
                    CouleursApp.primaire.withValues(alpha: 0.15),
                    CouleursApp.primaire.withValues(alpha: 0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: recommande ? null : Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: recommande ? CouleursApp.primaire : Colors.white.withValues(alpha: 0.1),
            width: recommande ? 2 : 1,
          ),
          boxShadow: recommande
              ? [BoxShadow(color: CouleursApp.primaire.withValues(alpha: 0.15), blurRadius: 20)]
              : null,
        ),
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: recommande ? CouleursApp.primaire : Colors.white.withValues(alpha: 0.08),
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
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (recommande) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [Colors.orange, Colors.deepOrange]),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            "Populaire",
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ]
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Valable $duree",
                    style: GoogleFonts.inter(fontSize: 13, color: Colors.white54),
                  ),
                ],
              ),
            ),
            Text(
              "${prix.toInt()} F",
              style: GoogleFonts.inter(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: recommande ? CouleursApp.primaire : Colors.white70,
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: (400 + index * 100).ms, duration: 300.ms).slideX(begin: 0.05, end: 0);
  }
}

// ============================================================
// ✅ CORRECTION 1.4: Dialog extrait dans un StatefulWidget dédié
// Garantit que le TextEditingController est correctement disposé
// ============================================================
class _ResultatDialogPaiement {
  final bool confirme;
  final String telephone;
  final String operateur;
  const _ResultatDialogPaiement({
    required this.confirme,
    required this.telephone,
    required this.operateur,
  });
}

class _DialogPaiementAbonnement extends StatefulWidget {
  final double montant;
  final String telephoneInitial;
  const _DialogPaiementAbonnement({
    required this.montant,
    required this.telephoneInitial,
  });

  @override
  State<_DialogPaiementAbonnement> createState() => _DialogPaiementAbonnementState();
}

class _DialogPaiementAbonnementState extends State<_DialogPaiementAbonnement> {
  // ✅ Controller correctement géré avec dispose()
  late final TextEditingController _phoneCtrl;
  String _operateur = "Orange";

  @override
  void initState() {
    super.initState();
    _phoneCtrl = TextEditingController(text: widget.telephoneInitial);
  }

  @override
  void dispose() {
    // ✅ Dispose garanti même si le dialog est fermé brutalement
    _phoneCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF10192A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: CouleursApp.primaire.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Iconsax.wallet_3_copy, color: CouleursApp.primaire, size: 20),
          ),
          const SizedBox(width: 12),
          Text(
            "Paiement via CamPay",
            style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: CouleursApp.accent.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: CouleursApp.accent.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.attach_money, color: CouleursApp.accent),
                const SizedBox(width: 8),
                Text(
                  "Montant : ${widget.montant.toInt()} FCFA",
                  style: GoogleFonts.inter(
                    color: CouleursApp.accent,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            "Numéro Mobile Money",
            style: GoogleFonts.inter(color: Colors.white54, fontSize: 12),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _phoneCtrl,
            keyboardType: TextInputType.phone,
            style: GoogleFonts.inter(color: Colors.white),
            decoration: InputDecoration(
              hintText: "Ex: 6XX XXX XXX",
              hintStyle: const TextStyle(color: Colors.white30),
              prefixIcon: const Icon(Icons.phone_android_rounded, color: Colors.white38, size: 20),
              filled: true,
              fillColor: const Color(0xFF1A2640),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.white12),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.white12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: CouleursApp.primaire),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            "Opérateur",
            style: GoogleFonts.inter(color: Colors.white54, fontSize: 12),
          ),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            initialValue: _operateur,
            dropdownColor: const Color(0xFF10192A),
            style: GoogleFonts.inter(color: Colors.white),
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFF1A2640),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.white12),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.white12),
              ),
            ),
            items: ["Orange", "MTN"]
                .map((op) => DropdownMenuItem(
                      value: op,
                      child: Text(
                        op,
                        style: GoogleFonts.inter(color: Colors.white),
                      ),
                    ))
                .toList(),
            onChanged: (val) {
              if (val != null) setState(() => _operateur = val);
            },
          ),
          const SizedBox(height: 12),
          Text(
            "💡 Un pop-up s'affichera sur ce numéro pour confirmer le paiement.",
            style: GoogleFonts.inter(color: Colors.white38, fontSize: 11),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(
            context,
            const _ResultatDialogPaiement(confirme: false, telephone: '', operateur: ''),
          ),
          child: Text("Annuler", style: GoogleFonts.inter(color: Colors.white54)),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(
            context,
            _ResultatDialogPaiement(
              confirme: true,
              telephone: _phoneCtrl.text,
              operateur: _operateur,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: CouleursApp.primaire,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: Text(
            "Payer",
            style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
