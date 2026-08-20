import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import 'package:update_camtrans/coeur/constantes/couleurs.dart';
import 'package:update_camtrans/services/service_paiement.dart';
import 'package:update_camtrans/services/service_notification.dart';
import 'package:update_camtrans/services/service_authentification.dart';

/// Bottom sheet de paiement affiché à la fin de la course.
/// Non-dismissable (barrierDismissible: false).
class BottomSheetPaiement extends ConsumerStatefulWidget {
  final String courseId;
  final double montant;
  final String transporteurId;
  final VoidCallback onPaiementReussi;

  const BottomSheetPaiement({
    super.key,
    required this.courseId,
    required this.montant,
    required this.transporteurId,
    required this.onPaiementReussi,
  });

  @override
  ConsumerState<BottomSheetPaiement> createState() =>
      _BottomSheetPaiementState();
}

class _BottomSheetPaiementState extends ConsumerState<BottomSheetPaiement> {
  String? _modeSelectionne;
  final _phoneCtrl = TextEditingController();
  final _nomCtrl = TextEditingController();
  bool _enChargement = false;
  bool _paiementReussi = false;

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _nomCtrl.dispose();
    super.dispose();
  }

  Future<void> _payer() async {
    if (_modeSelectionne == null) return;
    if (_modeSelectionne != 'especes' && _phoneCtrl.text.isEmpty && _nomCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez remplir les informations requises.')),
      );
      return;
    }

    setState(() => _enChargement = true);
    HapticFeedback.mediumImpact();

    try {
      final servicePaiement = ref.read(servicePaiementProvider);
      final authService = ref.read(serviceAuthentificationProvider);
      final clientId = authService.utilisateur?.uid ?? '';

      switch (_modeSelectionne) {
        case 'orange':
          await servicePaiement.initierPaiementOM(
            courseId: widget.courseId,
            clientId: clientId,
            transporteurId: widget.transporteurId,
            montant: widget.montant,
            telephonePayeur: _phoneCtrl.text,
          );
          break;
        case 'mtn':
          await servicePaiement.initierPaiementMTN(
            courseId: widget.courseId,
            clientId: clientId,
            transporteurId: widget.transporteurId,
            montant: widget.montant,
            telephonePayeur: _phoneCtrl.text,
          );
          break;
        case 'carte':
          await servicePaiement.initierPaiementCarte(
            courseId: widget.courseId,
            clientId: clientId,
            transporteurId: widget.transporteurId,
            montant: widget.montant,
            nomTitulaire: _nomCtrl.text,
          );
          break;
        case 'especes':
          await servicePaiement.initierPaiementEspeces(
            courseId: widget.courseId,
            clientId: clientId,
            transporteurId: widget.transporteurId,
            montant: widget.montant,
          );
          break;
      }

      // Notification au transporteur
      await ServiceNotification.afficherNotification(
        titre: '💰 Paiement reçu !',
        message: '${widget.montant.toStringAsFixed(0)} FCFA ont été réglés.',
        type: 'paiement',
      );

      setState(() {
        _enChargement = false;
        _paiementReussi = true;
      });
      HapticFeedback.heavyImpact();

      // Attendre 2s puis appeler le callback
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) widget.onPaiementReussi();
    } catch (e) {
      setState(() => _enChargement = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Paiement échoué : ${e.toString()}'),
            backgroundColor: CouleursApp.erreur,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Non-dismissable
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF0F172A),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: EdgeInsets.fromLTRB(
            24, 16, 24, MediaQuery.of(context).viewInsets.bottom + 24),
        child: SingleChildScrollView(
          child: _paiementReussi ? _buildSucces() : _buildFormulaire(),
        ),
      ),
    );
  }

  Widget _buildSucces() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 24),
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: CouleursApp.succes.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check_circle_outline,
              color: CouleursApp.succes, size: 48),
        )
            .animate()
            .scale(duration: 400.ms, curve: Curves.elasticOut)
            .fadeIn(),
        const SizedBox(height: 20),
        Text(
          'Paiement confirmé !',
          style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 22),
        ).animate().fadeIn(delay: 200.ms),
        const SizedBox(height: 8),
        Text(
          '${widget.montant.toStringAsFixed(0)} FCFA',
          style: GoogleFonts.poppins(
              color: CouleursApp.succes,
              fontWeight: FontWeight.w800,
              fontSize: 32),
        ).animate().fadeIn(delay: 300.ms),
        const SizedBox(height: 8),
        Text(
          'Merci pour votre confiance.',
          style: GoogleFonts.inter(color: Colors.white54, fontSize: 14),
        ).animate().fadeIn(delay: 400.ms),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildFormulaire() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Poignée
        Center(
          child: Container(
            width: 40,
            height: 5,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(10)),
          ),
        ),

        // Titre
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: CouleursApp.primaire.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Iconsax.wallet_3_copy,
                  color: CouleursApp.primaire, size: 24),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Paiement de la course',
                    style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18)),
                Text('Choisissez votre mode de paiement',
                    style: GoogleFonts.inter(
                        color: Colors.white54, fontSize: 12)),
              ],
            ),
          ],
        ).animate().fadeIn().slideX(begin: -0.1),

        const SizedBox(height: 20),

        // Montant total
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                CouleursApp.primaire.withOpacity(0.2),
                CouleursApp.primaire.withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: CouleursApp.primaire.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              Text('Montant total',
                  style: GoogleFonts.inter(
                      color: Colors.white54, fontSize: 13)),
              const SizedBox(height: 4),
              Text(
                '${widget.montant.toStringAsFixed(0)} FCFA',
                style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 36),
              ),
              Text('Frais de service inclus',
                  style: GoogleFonts.inter(
                      color: Colors.white38, fontSize: 11)),
            ],
          ),
        ).animate().fadeIn(delay: 100.ms),

        const SizedBox(height: 24),

        Text('Mode de paiement',
            style: GoogleFonts.inter(
                color: Colors.white70,
                fontWeight: FontWeight.w600,
                fontSize: 14)),
        const SizedBox(height: 12),

        // Cards modes de paiement
        ..._buildModesGrid(),

        const SizedBox(height: 20),

        // Champ complémentaire selon le mode
        if (_modeSelectionne == 'orange' || _modeSelectionne == 'mtn')
          _buildChampPhone(),
        if (_modeSelectionne == 'carte') _buildChampCarte(),
        if (_modeSelectionne == 'especes') _buildInfoEspeces(),

        const SizedBox(height: 24),

        // Bouton payer
        SizedBox(
          width: double.infinity,
          height: 58,
          child: ElevatedButton(
            onPressed: _modeSelectionne == null || _enChargement ? null : _payer,
            style: ElevatedButton.styleFrom(
              backgroundColor: CouleursApp.primaire,
              disabledBackgroundColor: Colors.white12,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
            child: _enChargement
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2),
                  )
                : Text(
                    _modeSelectionne == null
                        ? 'Choisir un mode de paiement'
                        : 'Payer ${widget.montant.toStringAsFixed(0)} FCFA',
                    style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16),
                  ),
          ),
        ).animate().fadeIn(delay: 300.ms),
      ],
    );
  }

  List<Widget> _buildModesGrid() {
    final modes = [
      {
        'id': 'orange',
        'label': 'Orange Money',
        'icon': '🟠',
        'couleur': const Color(0xFFFF6B00),
      },
      {
        'id': 'mtn',
        'label': 'MTN Mobile Money',
        'icon': '🟡',
        'couleur': const Color(0xFFFFCC00),
      },
      {
        'id': 'carte',
        'label': 'Carte Bancaire',
        'icon': '💳',
        'couleur': const Color(0xFF6366F1),
      },
      {
        'id': 'especes',
        'label': 'Espèces',
        'icon': '💵',
        'couleur': CouleursApp.succes,
      },
    ];

    return [
      GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 2.2,
        children: modes.asMap().entries.map((entry) {
          final index = entry.key;
          final mode = entry.value;
          final id = mode['id'] as String;
          final selected = _modeSelectionne == id;
          final couleur = mode['couleur'] as Color;

          return GestureDetector(
            onTap: () {
              setState(() {
                _modeSelectionne = id;
                _phoneCtrl.clear();
                _nomCtrl.clear();
              });
              HapticFeedback.selectionClick();
            },
            child: AnimatedContainer(
              duration: 200.ms,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: selected
                    ? couleur.withOpacity(0.15)
                    : Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: selected ? couleur : Colors.white12,
                  width: selected ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Text(mode['icon'] as String, style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      mode['label'] as String,
                      style: GoogleFonts.inter(
                        color: selected ? Colors.white : Colors.white60,
                        fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ).animate().fadeIn(delay: Duration(milliseconds: 50 * index));
        }).toList(),
      ),
    ];
  }

  Widget _buildChampPhone() {
    final isOrange = _modeSelectionne == 'orange';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isOrange
              ? 'Numéro Orange Money'
              : 'Numéro MTN Mobile Money',
          style: GoogleFonts.inter(color: Colors.white70, fontSize: 13),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.07),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white12),
          ),
          child: TextField(
            controller: _phoneCtrl,
            keyboardType: TextInputType.phone,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Ex: 6XX XXX XXX',
              hintStyle: const TextStyle(color: Colors.white38),
              prefixIcon: Icon(
                Iconsax.call_copy,
                color: isOrange
                    ? const Color(0xFFFF6B00)
                    : const Color(0xFFFFCC00),
                size: 20,
              ),
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
          ),
        ).animate().fadeIn().slideY(begin: 0.1),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildChampCarte() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Nom du titulaire de la carte',
            style: GoogleFonts.inter(color: Colors.white70, fontSize: 13)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.07),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white12),
          ),
          child: TextField(
            controller: _nomCtrl,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              hintText: 'Ex: Jean DUPONT',
              hintStyle: TextStyle(color: Colors.white38),
              prefixIcon: Icon(Icons.credit_card,
                  color: Color(0xFF6366F1), size: 20),
              border: InputBorder.none,
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
          ),
        ).animate().fadeIn().slideY(begin: 0.1),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildInfoEspeces() {
    return Container(
      padding: const EdgeInsets.all(14),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: CouleursApp.succes.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: CouleursApp.succes.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: CouleursApp.succes, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Remettez exactement ${widget.montant.toStringAsFixed(0)} FCFA en espèces à votre chauffeur.',
              style:
                  GoogleFonts.inter(color: Colors.white70, fontSize: 12),
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.1);
  }
}
