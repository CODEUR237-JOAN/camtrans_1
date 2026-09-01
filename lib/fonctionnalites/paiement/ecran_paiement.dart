import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:update_camtrans/coeur/etat/paiement_provider.dart';
import 'package:update_camtrans/coeur/constantes/couleurs.dart';
import 'package:update_camtrans/services/service_authentification.dart';
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
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _telephoneController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _validerPaiement() {
    if (_methodeSelectionnee != "especes" && _telephoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Veuillez entrer une information valide."),
          backgroundColor: CouleursApp.erreur,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    
    // Fermer le clavier
    FocusScope.of(context).unfocus();

    final provider = ref.read(paiementProvider.notifier);
    final authService = ref.read(serviceAuthentificationProvider);
    final clientId = authService.utilisateur?.uid ?? "client_anonyme";

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
    } else if (_methodeSelectionnee == "carte") {
      provider.payerParCarte(
        courseId: widget.courseId,
        clientId: clientId,
        transporteurId: widget.transporteurId,
        montant: widget.montant,
        nomTitulaire: _telephoneController.text,
      );
    } else if (_methodeSelectionnee == "especes") {
      provider.payerEnEspeces(
        courseId: widget.courseId,
        clientId: clientId,
        transporteurId: widget.transporteurId,
        montant: widget.montant,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final etatPaiement = ref.watch(paiementProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: const Color(0xFF08111F),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16.0, top: 8.0, bottom: 8.0),
          child: _GlassButton(
            icon: Iconsax.arrow_left_2_copy,
            onTap: () {
              ref.read(paiementProvider.notifier).reinitialiser();
              context.pop();
            },
          ),
        ),
        title: Text("Paiement Sécurisé", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // Background Gradient Sombre
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF08111F), Color(0xFF111827)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          // Blob lumineux en fond pour le header
          Positioned(
            top: -100,
            left: -50,
            right: -50,
            child: Container(
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: CouleursApp.primaire.withValues(alpha: 0.1),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
                child: const SizedBox(),
              ),
            ),
          ),

          SafeArea(
            bottom: false,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Montant
                        Center(
                          child: Column(
                            children: [
                              Text("Montant de la course", style: GoogleFonts.poppins(color: Colors.white54, fontSize: 14)),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.montant.toInt().toString(),
                                    style: GoogleFonts.poppins(fontSize: 48, fontWeight: FontWeight.w900, color: Colors.white, height: 1),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    "FCFA",
                                    style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: CouleursApp.primaire, height: 1.5),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 40),

                        Text("Méthode de paiement", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
                        const SizedBox(height: 16),

                        // Liste des méthodes de paiement
                        Column(
                          children: [
                            _buildMethodeCard("om", "Orange Money", "Paiement Mobile", "assets/om.png", Iconsax.mobile_copy, const Color(0xFFFF7900)),
                            const SizedBox(height: 12),
                            _buildMethodeCard("mtn", "MTN Mobile Money", "Paiement Mobile", "assets/mtn.png", Iconsax.mobile_copy, const Color(0xFFFFCC00)),
                            const SizedBox(height: 12),
                            _buildMethodeCard("carte", "Carte Bancaire", "Visa, Mastercard", "", Iconsax.card_copy, const Color(0xFF3B82F6)),
                            const SizedBox(height: 12),
                            _buildMethodeCard("especes", "Espèces", "Paiement direct au chauffeur", "", Iconsax.money_3_copy, CouleursApp.succes),
                          ],
                        ),

                        const SizedBox(height: 40),

                        // Formulaire (masqué si espèces)
                        AnimatedSize(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                          child: Container(
                            key: ValueKey(_methodeSelectionnee),
                            child: _methodeSelectionnee == "especes" 
                            ? Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: CouleursApp.succes.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: CouleursApp.succes.withValues(alpha: 0.2)),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Iconsax.info_circle_copy, color: CouleursApp.succes, size: 24),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        "Vous réglerez le montant directement au chauffeur lors de la prestation.",
                                        style: GoogleFonts.poppins(color: CouleursApp.succes, fontSize: 13),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _methodeSelectionnee == "carte" ? "Nom sur la carte" : "Numéro de téléphone",
                                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.white70),
                                ),
                                const SizedBox(height: 12),
                                _buildFloatingTextField(
                                  controller: _telephoneController,
                                  focusNode: _focusNode,
                                  hint: _methodeSelectionnee == "carte" ? "Ex: Jean Dupont" : "Ex: 6XXXXXXXX",
                                  icon: _methodeSelectionnee == "carte" ? Iconsax.user_copy : Iconsax.call_copy,
                                  keyboardType: _methodeSelectionnee == "carte" ? TextInputType.name : TextInputType.phone,
                                ),
                                const SizedBox(height: 12),

                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 100), // Espace pour le bouton
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Bouton flottant de validation
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A).withValues(alpha: 0.9),
                border: const Border(top: BorderSide(color: Colors.white12)),
              ),
              child: SafeArea(
                top: false,
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: etatPaiement.enCours ? null : _validerPaiement,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: CouleursApp.succes,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: etatPaiement.enCours
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Iconsax.lock_copy, size: 20),
                              const SizedBox(width: 8),
                              Text("Payer ${widget.montant.toInt()} FCFA", style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
                            ],
                          ),
                  ),
                ),
              ),
            ),
          ),

          // Message d'erreur flottant (Glass effect)
          if (etatPaiement.erreur != null && etatPaiement.succes == null)
            Positioned(
              top: MediaQuery.of(context).padding.top + kToolbarHeight + 20,
              left: 20,
              right: 20,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: CouleursApp.erreur.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: CouleursApp.erreur),
                    ),
                    child: Row(
                      children: [
                        const Icon(Iconsax.warning_2_copy, color: CouleursApp.erreur),
                        const SizedBox(width: 12),
                        Expanded(child: Text(etatPaiement.erreur!, style: GoogleFonts.poppins(color: Colors.white))),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white54, size: 18),
                          onPressed: () => ref.read(paiementProvider.notifier).reinitialiser(), // Permet de fermer l'erreur
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        )
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // Surcouche de reçu si succès (plein écran)
          if (etatPaiement.succes != null)
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  color: Colors.white.withValues(alpha: 0.8),
                  child: SafeArea(
                    child: Center(
                      child: TicketRecu(
                        paiement: etatPaiement.succes!,
                        onFermer: () {
                          ref.read(paiementProvider.notifier).reinitialiser();
                          context.go('/evaluation/${widget.courseId}'); // Redirection vers l'écran d'évaluation avec ID
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMethodeCard(String cle, String titre, String sousTitre, String logoPath, IconData defaultIcon, Color brandColor) {
    final estSelectionne = _methodeSelectionnee == cle;
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() {
          _methodeSelectionnee = cle;
          _telephoneController.clear();
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutQuart,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: estSelectionne ? brandColor.withValues(alpha: 0.1) : const Color(0xFF1E293B).withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: estSelectionne ? brandColor : Colors.white.withValues(alpha: 0.05),
            width: estSelectionne ? 2 : 1,
          ),
          boxShadow: estSelectionne
              ? [BoxShadow(color: brandColor.withValues(alpha: 0.2), blurRadius: 20, offset: const Offset(0, 8))]
              : [],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: estSelectionne ? brandColor.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(defaultIcon, color: estSelectionne ? brandColor : Colors.white54, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(titre, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                  Text(sousTitre, style: GoogleFonts.poppins(fontSize: 12, color: Colors.white54)),
                ],
              ),
            ),
            if (estSelectionne)
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(color: brandColor, shape: BoxShape.circle),
                child: const Icon(Icons.check, color: Colors.white, size: 16),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingTextField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String hint,
    required IconData icon,
    required TextInputType keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: keyboardType,
      style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.poppins(color: const Color(0xFF64748B), fontWeight: FontWeight.w400),
        prefixIcon: Icon(icon, color: const Color(0xFF94A3B8), size: 20),
        filled: true,
        fillColor: const Color(0xFF0F172A).withValues(alpha: 0.7),
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 1.5)),
      ),
    );
  }
}

class _GlassButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _GlassButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}
