import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:update_camtrans/coeur/constantes/couleurs.dart';
import 'package:update_camtrans/coeur/etat/utilisateur_provider.dart';
import 'package:update_camtrans/coeur/routes/routes.dart';
import 'package:update_camtrans/services/service_authentification.dart';

// =====================================================================
// Page : Paramètres
// ConsumerStatefulWidget branché sur Riverpod.
// Préférences persistées dans SharedPreferences.
// Déconnexion réelle via ServiceAuthentification.
// =====================================================================

class Parametres extends ConsumerStatefulWidget {
  const Parametres({super.key});

  @override
  ConsumerState<Parametres> createState() => _ParametresState();
}

class _ParametresState extends ConsumerState<Parametres> {
  bool _notifications = true;
  bool _localisation = true;
  bool _biometrie = false;
  bool _isLoggingOut = false;

  static const _keyNotifications = 'pref_notifications';
  static const _keyLocalisation = 'pref_localisation';
  static const _keyBiometrie = 'pref_biometrie';

  @override
  void initState() {
    super.initState();
    _chargerPreferences();
  }

  // -----------------------------------------------------------------
  // Chargement des préférences depuis SharedPreferences
  // -----------------------------------------------------------------
  Future<void> _chargerPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _notifications = prefs.getBool(_keyNotifications) ?? true;
        _localisation = prefs.getBool(_keyLocalisation) ?? true;
        _biometrie = prefs.getBool(_keyBiometrie) ?? false;
      });
    }
  }

  // -----------------------------------------------------------------
  // Sauvegarde d'une préférence booléenne
  // -----------------------------------------------------------------
  Future<void> _sauvegarderPref(String cle, bool valeur) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(cle, valeur);
  }

  // -----------------------------------------------------------------
  // Déconnexion réelle avec confirmation
  // -----------------------------------------------------------------
  Future<void> _deconnecter() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF10192A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Déconnexion',
          style: GoogleFonts.inter(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        content: Text(
          'Êtes-vous sûr de vouloir vous déconnecter de CamTrans ?',
          style: GoogleFonts.inter(color: Colors.white70, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Annuler',
                style: GoogleFonts.inter(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Déconnecter',
              style: GoogleFonts.inter(
                  color: CouleursApp.erreur, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    setState(() => _isLoggingOut = true);
    try {
      await ref.read(serviceAuthentificationProvider).deconnexion();
      if (mounted) {
        context.go(RoutesApplication.connexion);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Erreur lors de la déconnexion.',
              style: GoogleFonts.inter()),
          backgroundColor: CouleursApp.erreur,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    } finally {
      if (mounted) setState(() => _isLoggingOut = false);
    }
  }

  // -----------------------------------------------------------------
  // Ouverture d'une URL externe (CGU, Politique...)
  // -----------------------------------------------------------------
  Future<void> _ouvrirUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  // -----------------------------------------------------------------
  // BUILD
  // -----------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final clientAsync = ref.watch(currentClientProvider);
    final nomUtilisateur = clientAsync.value != null
        ? '${clientAsync.value!.prenom} ${clientAsync.value!.nom}'
        : '...';

    return Scaffold(
      backgroundColor: const Color(0xFF08111F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF08111F),
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left_2_copy, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Paramètres',
          style: GoogleFonts.inter(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        physics: const BouncingScrollPhysics(),
        children: [
          // --- Profil compact ---
          _buildProfilBandeau(nomUtilisateur, clientAsync.value?.email ?? ''),

          const SizedBox(height: 28),

          // === Section : Préférences ===
          _buildSectionTitre('Préférences'),
          const SizedBox(height: 12),

          _buildSwitch(
            icone: Iconsax.notification_copy,
            titre: 'Notifications push',
            sousTitre: 'Alertes de livraison et mises à jour de statut',
            valeur: _notifications,
            couleur: CouleursApp.primaire,
            onChange: (v) {
              setState(() => _notifications = v);
              _sauvegarderPref(_keyNotifications, v);
            },
          ),

          _buildSwitch(
            icone: Iconsax.location_copy,
            titre: 'Géolocalisation',
            sousTitre: 'Nécessaire pour le suivi GPS en temps réel',
            valeur: _localisation,
            couleur: CouleursApp.accentNeon,
            onChange: (v) {
              setState(() => _localisation = v);
              _sauvegarderPref(_keyLocalisation, v);
            },
          ),

          _buildSwitch(
            icone: Iconsax.finger_scan_copy,
            titre: 'Authentification biométrique',
            sousTitre: 'Empreinte digitale ou Face ID pour vous connecter',
            valeur: _biometrie,
            couleur: CouleursApp.accentViolet,
            onChange: (v) {
              setState(() => _biometrie = v);
              _sauvegarderPref(_keyBiometrie, v);
            },
          ),

          const SizedBox(height: 28),

          // === Section : Compte ===
          _buildSectionTitre('Compte'),
          const SizedBox(height: 12),

          _buildTuile(
            icone: Iconsax.lock_1_copy,
            titre: 'Modifier le mot de passe',
            onTap: () {},
          ),
          _buildTuile(
            icone: Iconsax.shield_tick_copy,
            titre: 'Sécurité',
            onTap: () {},
          ),
          _buildTuile(
            icone: Iconsax.eye_slash_copy,
            titre: 'Confidentialité',
            onTap: () {},
          ),

          const SizedBox(height: 28),

          // === Section : À propos ===
          _buildSectionTitre('À propos'),
          const SizedBox(height: 12),

          _buildTuile(
            icone: Iconsax.document_text_copy,
            titre: 'Conditions d\'utilisation',
            onTap: () => _ouvrirUrl('https://camtrans.cm/cgu'),
          ),
          _buildTuile(
            icone: Iconsax.security_safe_copy,
            titre: 'Politique de confidentialité',
            onTap: () => _ouvrirUrl('https://camtrans.cm/privacy'),
          ),
          _buildTuile(
            icone: Iconsax.message_question_copy,
            titre: 'Centre d\'aide',
            onTap: () => _ouvrirUrl('https://camtrans.cm/aide'),
          ),
          _buildTuile(
            icone: Iconsax.star_copy,
            titre: 'Noter l\'application',
            onTap: () => _ouvrirUrl('market://details?id=cm.camtrans.app'),
          ),

          const SizedBox(height: 16),

          // Badge version
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFF10192A),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: CouleursApp.bordureSombre),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: CouleursApp.succes.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Iconsax.verify_copy,
                      color: CouleursApp.succes, size: 18),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Version de l\'application',
                        style: GoogleFonts.inter(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 14)),
                    Text('1.0.0 — Production',
                        style: GoogleFonts.inter(
                            color: Colors.white54, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ).animate().fadeIn(duration: 400.ms),

          const SizedBox(height: 28),

          // === Bouton Déconnexion — FONCTIONNEL ===
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: _isLoggingOut ? null : _deconnecter,
              style: ElevatedButton.styleFrom(
                backgroundColor: CouleursApp.erreur,
                disabledBackgroundColor:
                    CouleursApp.erreur.withValues(alpha: 0.4),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              icon: _isLoggingOut
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2.5),
                    )
                  : const Icon(Iconsax.logout_copy),
              label: Text(
                _isLoggingOut ? 'Déconnexion...' : 'Se déconnecter',
                style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ).animate().slideY(begin: 0.2, duration: 400.ms),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // -----------------------------------------------------------------
  // Widgets helpers
  // -----------------------------------------------------------------

  Widget _buildProfilBandeau(String nom, String email) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF00C896), Color(0xFF06B6D4)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: Colors.white.withValues(alpha: 0.2),
            child: Text(
              nom.isNotEmpty ? nom[0].toUpperCase() : 'C',
              style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nom,
                  style: GoogleFonts.inter(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  email,
                  style: GoogleFonts.inter(color: Colors.white70, fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1);
  }

  Widget _buildSectionTitre(String titre) {
    return Text(
      titre,
      style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: CouleursApp.primaire,
          letterSpacing: 1.2),
    );
  }

  Widget _buildSwitch({
    required IconData icone,
    required String titre,
    required String sousTitre,
    required bool valeur,
    required Color couleur,
    required ValueChanged<bool> onChange,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF10192A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CouleursApp.bordureSombre),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: couleur.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icone, color: couleur, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titre,
                    style: GoogleFonts.inter(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14)),
                Text(sousTitre,
                    style: GoogleFonts.inter(
                        color: Colors.white54, fontSize: 12, height: 1.4)),
              ],
            ),
          ),
          Switch(
            value: valeur,
            onChanged: onChange,
            activeThumbColor: couleur,
            inactiveTrackColor: Colors.white12,
          ),
        ],
      ),
    );
  }

  Widget _buildTuile({
    required IconData icone,
    required String titre,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF10192A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CouleursApp.bordureSombre),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: CouleursApp.primaire.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icone, color: CouleursApp.primaire, size: 18),
        ),
        title: Text(
          titre,
          style: GoogleFonts.inter(
              color: Colors.white, fontWeight: FontWeight.w500, fontSize: 14),
        ),
        trailing: const Icon(Icons.arrow_forward_ios,
            size: 14, color: Colors.white38),
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
      ),
    );
  }
}
