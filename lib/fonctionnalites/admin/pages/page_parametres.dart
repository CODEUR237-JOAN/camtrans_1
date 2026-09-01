import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:update_camtrans/coeur/constantes/couleurs.dart';
import 'package:update_camtrans/coeur/etat/admin_provider.dart';
import 'package:update_camtrans/modeles/parametres_app.dart';

class PageParametres extends ConsumerStatefulWidget {
  const PageParametres({super.key});

  @override
  ConsumerState<PageParametres> createState() => _PageParametresState();
}

class _PageParametresState extends ConsumerState<PageParametres> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _commissionCtrl;
  late TextEditingController _prixMotoCtrl;
  late TextEditingController _prixCamionCtrl;
  late TextEditingController _prixFourgonCtrl;

  late TextEditingController _prixJourCtrl;
  late TextEditingController _prixMoisCtrl;
  late TextEditingController _prixAnCtrl;

  bool _approbationAuto = false;
  bool _paiementEspece = true;
  bool _isSaving = false;

  ParametresApp? _parametresInitiaux;

  @override
  void initState() {
    super.initState();
    _commissionCtrl = TextEditingController();
    _prixMotoCtrl = TextEditingController();
    _prixCamionCtrl = TextEditingController();
    _prixFourgonCtrl = TextEditingController();
    _prixJourCtrl = TextEditingController();
    _prixMoisCtrl = TextEditingController();
    _prixAnCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _commissionCtrl.dispose();
    _prixMotoCtrl.dispose();
    _prixCamionCtrl.dispose();
    _prixFourgonCtrl.dispose();
    _prixJourCtrl.dispose();
    _prixMoisCtrl.dispose();
    _prixAnCtrl.dispose();
    super.dispose();
  }

  void _initialiserChamps(ParametresApp params) {
    if (_parametresInitiaux == null) {
      _parametresInitiaux = params;
      _commissionCtrl.text = params.commissionPlateforme.toString();
      _prixMotoCtrl.text = params.prixKmMoto.toString();
      _prixCamionCtrl.text = params.prixKmCamion.toString();
      _prixFourgonCtrl.text = params.prixKmFourgon.toString();
      _prixJourCtrl.text = params.prixAbonnementJour.toString();
      _prixMoisCtrl.text = params.prixAbonnementMois.toString();
      _prixAnCtrl.text = params.prixAbonnementAn.toString();
      _approbationAuto = params.approbationAutomatique;
      _paiementEspece = params.paiementEspeceActif;
    }
  }

  Future<void> _sauvegarder() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final updateParams = ref.read(adminUpdateParametresProvider);
      final nouveauxParams = ParametresApp(
        commissionPlateforme: double.tryParse(_commissionCtrl.text) ?? 10.0,
        prixKmMoto: double.tryParse(_prixMotoCtrl.text) ?? 200.0,
        prixKmCamion: double.tryParse(_prixCamionCtrl.text) ?? 1000.0,
        prixKmFourgon: double.tryParse(_prixFourgonCtrl.text) ?? 700.0,
        approbationAutomatique: _approbationAuto,
        paiementEspeceActif: _paiementEspece,
        prixAbonnementJour: double.tryParse(_prixJourCtrl.text) ?? 1000.0,
        prixAbonnementMois: double.tryParse(_prixMoisCtrl.text) ?? 25000.0,
        prixAbonnementAn: double.tryParse(_prixAnCtrl.text) ?? 250000.0,
      );

      await updateParams(nouveauxParams);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Parfait ! Les paramètres ont été mis à jour avec succès. ✨"), backgroundColor: CouleursApp.succes));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Oups ! Échec de la sauvegarde : $e 🔧")));
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final parametresAsync = ref.watch(adminParametresProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: parametresAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: CouleursApp.primaire)),
        error: (err, stack) => Center(child: Text("Impossible de charger les paramètres : $err 🔧", style: const TextStyle(color: Colors.redAccent))),
        data: (parametres) {
          // On initialise une seule fois (pour ne pas écraser la saisie en cours de route si un update arrive)
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_parametresInitiaux == null) {
              setState(() {
                _initialiserChamps(parametres);
              });
            }
          });

          return SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Paramètres Généraux", style: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 8),
                  Text("Gérez les règles financières et métiers de CamTrans", style: GoogleFonts.inter(color: Colors.white54)),
                  const SizedBox(height: 40),

                  // Section Financière
                  _buildSectionTitre("Paramètres Financiers", Iconsax.wallet_3_copy),
                  const SizedBox(height: 16),
                  _buildCarte(
                    child: Column(
                      children: [
                        _buildChampSaisie(
                          controller: _commissionCtrl,
                          label: "Commission de la plateforme (%)",
                          icon: Icons.percent,
                          hint: "Ex: 10.0",
                        ),
                        const SizedBox(height: 16),
                        _buildChampSaisie(
                          controller: _prixMotoCtrl,
                          label: "Prix de base par Km (Moto)",
                          icon: Icons.two_wheeler,
                          hint: "Ex: 200",
                          suffix: "FCFA",
                        ),
                        const SizedBox(height: 16),
                        _buildChampSaisie(
                          controller: _prixCamionCtrl,
                          label: "Prix de base par Km (Camion)",
                          icon: Icons.local_shipping,
                          hint: "Ex: 1000",
                          suffix: "FCFA",
                        ),
                        const SizedBox(height: 16),
                        _buildChampSaisie(
                          controller: _prixFourgonCtrl,
                          label: "Prix de base par Km (Fourgon)",
                          icon: Icons.airport_shuttle,
                          hint: "Ex: 700",
                          suffix: "FCFA",
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Section Modération & Paiement
                  _buildSectionTitre("Modération et Paiement", Iconsax.security_safe_copy),
                  const SizedBox(height: 16),
                  _buildCarte(
                    child: Column(
                      children: [
                        _buildSwitchRow(
                          titre: "Approbation automatique des transporteurs",
                          description: "Si activé, les transporteurs peuvent recevoir des courses immédiatement après leur inscription.",
                          valeur: _approbationAuto,
                          onChanged: (val) => setState(() => _approbationAuto = val),
                        ),
                        const Divider(color: Colors.white10, height: 32),
                        _buildSwitchRow(
                          titre: "Activer les paiements en espèces",
                          description: "Permet aux clients de payer leur course directement au chauffeur en espèces.",
                          valeur: _paiementEspece,
                          onChanged: (val) => setState(() => _paiementEspece = val),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Section Abonnements
                  _buildSectionTitre("Abonnements Transporteurs", Iconsax.card_copy),
                  const SizedBox(height: 16),
                  _buildCarte(
                    child: Column(
                      children: [
                        _buildChampSaisie(
                          controller: _prixJourCtrl,
                          label: "Abonnement Journalier",
                          icon: Icons.calendar_today,
                          hint: "Ex: 1000",
                          suffix: "FCFA",
                        ),
                        const SizedBox(height: 16),
                        _buildChampSaisie(
                          controller: _prixMoisCtrl,
                          label: "Abonnement Mensuel",
                          icon: Icons.calendar_month,
                          hint: "Ex: 25000",
                          suffix: "FCFA",
                        ),
                        const SizedBox(height: 16),
                        _buildChampSaisie(
                          controller: _prixAnCtrl,
                          label: "Abonnement Annuel",
                          icon: Icons.event,
                          hint: "Ex: 250000",
                          suffix: "FCFA",
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Bouton de sauvegarde
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _sauvegarder,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: CouleursApp.primaire,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: _isSaving
                          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : Text("Enregistrer les modifications", style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionTitre(String titre, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: CouleursApp.primaire.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: CouleursApp.primaire, size: 20),
        ),
        const SizedBox(width: 12),
        Text(titre, style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
      ],
    );
  }

  Widget _buildCarte({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: child,
    );
  }

  Widget _buildChampSaisie({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    String? suffix,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.inter(color: Colors.white70, fontSize: 14)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: const TextStyle(color: Colors.white),
          validator: (val) {
            if (val == null || val.isEmpty) return "Ce champ est requis";
            if (double.tryParse(val) == null) return "Valeur numérique invalide";
            return null;
          },
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
            prefixIcon: Icon(icon, color: Colors.white54),
            suffixText: suffix,
            suffixStyle: const TextStyle(color: Colors.white54),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.03),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: CouleursApp.primaire),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.redAccent),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSwitchRow({
    required String titre,
    required String description,
    required bool valeur,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(titre, style: GoogleFonts.inter(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(description, style: GoogleFonts.inter(color: Colors.white54, fontSize: 13)),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Switch(
          value: valeur,
          onChanged: onChanged,
          activeColor: CouleursApp.primaire,
        ),
      ],
    );
  }
}
