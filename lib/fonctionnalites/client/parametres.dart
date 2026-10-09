import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:update_camtrans/coeur/constantes/couleurs.dart';
import 'package:update_camtrans/fonctionnalites/client/ecran_contenu_info.dart';
import 'package:update_camtrans/services/service_biometrie.dart';
import 'package:update_camtrans/services/service_notification.dart';
import 'package:update_camtrans/coeur/etat/utilisateur_provider.dart';
import 'package:update_camtrans/coeur/routes/routes.dart';
import 'package:update_camtrans/coeur/widgets/selecteur_theme.dart';
import 'package:update_camtrans/coeur/etat/locale_provider.dart';
import 'package:update_camtrans/services/service_authentification.dart';
import 'package:update_camtrans/l10n/app_localizations.dart';

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
  // Effets RÉELS des préférences (notifications, GPS, biométrie)
  // -----------------------------------------------------------------
  String? get _uid =>
      ref.read(serviceAuthentificationProvider).utilisateur?.uid;

  /// Active/désactive réellement les notifications push (permission + token FCM).
  Future<void> _changerNotifications(bool v) async {
    setState(() => _notifications = v);
    await _sauvegarderPref(_keyNotifications, v);
    final uid = _uid;
    if (uid == null) return;

    if (v) {
      final ok = await ServiceNotification.activerNotifications(uid, 'client');
      if (!mounted) return;
      if (!ok) {
        setState(() => _notifications = false);
        await _sauvegarderPref(_keyNotifications, false);
        _toast('Autorisez les notifications dans les réglages du téléphone.',
            erreur: true);
      } else {
        _toast('Notifications activées.');
      }
    } else {
      await ServiceNotification.desactiverNotifications(uid, 'client');
      if (mounted) _toast('Notifications désactivées.');
    }
  }

  /// Demande/gère réellement la permission de géolocalisation.
  Future<void> _changerLocalisation(bool v) async {
    if (v) {
      final statut = await Permission.locationWhenInUse.request();
      if (!mounted) return;
      if (statut.isGranted || statut.isLimited) {
        setState(() => _localisation = true);
        await _sauvegarderPref(_keyLocalisation, true);
        _toast('Géolocalisation activée.');
      } else {
        setState(() => _localisation = false);
        await _sauvegarderPref(_keyLocalisation, false);
        _toast('Permission de localisation refusée.', erreur: true);
        if (statut.isPermanentlyDenied) await openAppSettings();
      }
    } else {
      setState(() => _localisation = false);
      await _sauvegarderPref(_keyLocalisation, false);
      if (mounted) {
        _toast(
            'Pour couper totalement le GPS, désactivez-le dans les réglages du téléphone.');
      }
    }
  }

  /// Active/désactive réellement le déverrouillage biométrique (local_auth).
  /// À l'activation, une vraie invite biométrique confirme l'identité.
  /// Une fois actif, la biométrie est demandée à l'ouverture de l'app (splash).
  Future<void> _changerBiometrie(bool v) async {
    if (v) {
      final service = ServiceBiometrie();
      if (!await service.disponible()) {
        if (mounted) {
          setState(() => _biometrie = false);
          _toast('Aucune biométrie configurée sur cet appareil.', erreur: true);
        }
        return;
      }
      final ok = await service.authentifier(
          'Confirmez votre identité pour activer le déverrouillage biométrique');
      if (!mounted) return;
      if (ok) {
        setState(() => _biometrie = true);
        await _sauvegarderPref(_keyBiometrie, true);
        _toast('Déverrouillage biométrique activé.');
      } else {
        setState(() => _biometrie = false);
        await _sauvegarderPref(_keyBiometrie, false);
        _toast('Activation annulée.', erreur: true);
      }
    } else {
      setState(() => _biometrie = false);
      await _sauvegarderPref(_keyBiometrie, false);
      if (mounted) _toast('Déverrouillage biométrique désactivé.');
    }
  }

  void _toast(String message, {bool erreur = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message,
          style: GoogleFonts.inter(
              color: Theme.of(context).colorScheme.onSurface)),
      backgroundColor: erreur ? CouleursApp.erreur : CouleursApp.succes,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  // -----------------------------------------------------------------
  // Déconnexion réelle avec confirmation
  // -----------------------------------------------------------------
  Future<void> _deconnecter() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Déconnexion',
          style: GoogleFonts.inter(
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.bold,
              fontSize: 18),
        ),
        content: Text(
          'Êtes-vous sûr de vouloir vous déconnecter de CamTrans ?',
          style: GoogleFonts.inter(
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.7),
              height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context)!.cancel,
                style: GoogleFonts.inter(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.5))),
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
    } else if (mounted) {
      _toast('Impossible d\'ouvrir ce lien.', erreur: true);
    }
  }

  /// Ouvre un contenu informatif EN LOCAL (CGU, Confidentialité, Aide).
  void _ouvrirContenu(String titre, String contenu) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            EcranContenuInfo(titre: titre, contenuMarkdown: contenu),
      ),
    );
  }

  /// Ouvre la fiche Play Store de l'app (fallback web si le Store natif absent).
  Future<void> _noterApplication() async {
    const package = 'com.joan.update_camtrans';
    final natif = Uri.parse('market://details?id=$package');
    final web =
        Uri.parse('https://play.google.com/store/apps/details?id=$package');
    if (await canLaunchUrl(natif)) {
      await launchUrl(natif, mode: LaunchMode.externalApplication);
    } else {
      await launchUrl(web, mode: LaunchMode.externalApplication);
    }
  }

  // -----------------------------------------------------------------
  // Feuille « Sécurité » : options de protection du compte
  // -----------------------------------------------------------------
  void _ouvrirSecurite() {
    _afficherFeuille(
      icone: Iconsax.shield_tick_copy,
      titre: 'Sécurité',
      sousTitre: 'Protégez l\'accès à votre compte CamTrans.',
      enfants: [
        _ligneFeuilleAction(
          icone: Iconsax.lock_1_copy,
          titre: 'Modifier le mot de passe',
          sousTitre: 'Changez votre mot de passe régulièrement.',
          onTap: () {
            Navigator.pop(context);
            context.push(RoutesApplication.changerMotDePasse);
          },
        ),
        _ligneFeuilleSwitch(
          icone: Iconsax.finger_scan_copy,
          titre: 'Déverrouillage biométrique',
          sousTitre: 'Empreinte ou Face ID à l\'ouverture de l\'app.',
          valeur: _biometrie,
          onChange: _changerBiometrie,
        ),
        _ligneFeuilleInfo(
          icone: Iconsax.shield_tick_copy,
          texte:
              'Vos données de connexion sont gérées de façon sécurisée par Firebase Authentication. '
              'CamTrans ne stocke jamais votre mot de passe en clair.',
        ),
      ],
    );
  }

  // -----------------------------------------------------------------
  // Feuille « Confidentialité » : usage des données personnelles
  // -----------------------------------------------------------------
  void _ouvrirConfidentialite() {
    _afficherFeuille(
      icone: Iconsax.eye_slash_copy,
      titre: 'Confidentialité',
      sousTitre: 'Vous gardez le contrôle de vos données.',
      enfants: [
        _ligneFeuilleInfo(
          icone: Iconsax.location_copy,
          texte:
              'Votre position n\'est utilisée que pendant une course active, '
              'pour le suivi en temps réel. Vous pouvez la désactiver dans les préférences.',
        ),
        _ligneFeuilleInfo(
          icone: Iconsax.document_copy,
          texte:
              'Vos informations (nom, téléphone) ne sont partagées qu\'avec le '
              'transporteur de votre course, le temps de la prestation.',
        ),
        _ligneFeuilleAction(
          icone: Iconsax.security_safe_copy,
          titre: 'Lire la politique complète',
          sousTitre: 'Détail de la collecte et de vos droits.',
          onTap: () {
            Navigator.pop(context);
            _ouvrirUrl('https://camtrans.cm/privacy');
          },
        ),
        _ligneFeuilleAction(
          icone: Iconsax.trash_copy,
          titre: 'Demander la suppression de mon compte',
          sousTitre: 'Contactez le support pour effacer vos données.',
          couleur: CouleursApp.erreur,
          onTap: () {
            Navigator.pop(context);
            _ouvrirUrl(
                'mailto:support@camtrans.cm?subject=Suppression de mon compte');
          },
        ),
      ],
    );
  }

  // Affiche une bottom sheet stylée, cohérente avec le thème sombre.
  void _afficherFeuille({
    required IconData icone,
    required String titre,
    required String sousTitre,
    required List<Widget> enfants,
  }) {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 12,
          bottom: 20 + MediaQuery.of(context).padding.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: CouleursApp.primaire.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icone, color: CouleursApp.primaire, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(titre,
                          style: GoogleFonts.inter(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontWeight: FontWeight.bold,
                              fontSize: 18)),
                      Text(sousTitre,
                          style: GoogleFonts.inter(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.5),
                              fontSize: 13,
                              height: 1.4)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ...enfants,
          ],
        ),
      ),
    );
  }

  Widget _ligneFeuilleAction({
    required IconData icone,
    required String titre,
    required String sousTitre,
    required VoidCallback onTap,
    Color? couleur,
  }) {
    final c = couleur ?? CouleursApp.primaire;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CouleursApp.bordureSombre),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: c.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icone, color: c, size: 18),
        ),
        title: Text(titre,
            style: GoogleFonts.inter(
                color: couleur ?? Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w600,
                fontSize: 14)),
        subtitle: Text(sousTitre,
            style: GoogleFonts.inter(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.5),
                fontSize: 12,
                height: 1.4)),
        trailing: Icon(Icons.arrow_forward_ios,
            size: 13,
            color:
                Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4)),
        onTap: onTap,
      ),
    );
  }

  Widget _ligneFeuilleSwitch({
    required IconData icone,
    required String titre,
    required String sousTitre,
    required bool valeur,
    required ValueChanged<bool> onChange,
  }) {
    return StatefulBuilder(
      builder: (context, setSheetState) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: CouleursApp.bordureSombre),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: CouleursApp.accentViolet.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icone, color: CouleursApp.accentViolet, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(titre,
                      style: GoogleFonts.inter(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.w600,
                          fontSize: 14)),
                  Text(sousTitre,
                      style: GoogleFonts.inter(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.5),
                          fontSize: 12,
                          height: 1.4)),
                ],
              ),
            ),
            Switch(
              value: valeur,
              activeThumbColor: CouleursApp.accentViolet,
              inactiveTrackColor: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.1),
              onChanged: (v) {
                setSheetState(() {});
                onChange(v);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _ligneFeuilleInfo({required IconData icone, required String texte}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: CouleursApp.primaire.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CouleursApp.primaire.withValues(alpha: 0.15)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icone, color: CouleursApp.primaire, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Text(texte,
                style: GoogleFonts.inter(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.7),
                    fontSize: 12.5,
                    height: 1.5)),
          ),
        ],
      ),
    );
  }

  // -----------------------------------------------------------------
  // BUILD
  // -----------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final clientAsync = ref.watch(currentClientProvider);
    final nomUtilisateur = clientAsync.value != null
        ? '${clientAsync.value!.prenom} ${clientAsync.value!.nom}'
        : '...';

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Iconsax.arrow_left_2_copy,
              color: Theme.of(context).colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          l10n.settings,
          style: GoogleFonts.inter(
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.bold,
              fontSize: 18),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        physics: const BouncingScrollPhysics(),
        children: [
          // --- Profil compact ---
          _buildProfilBandeau(nomUtilisateur, clientAsync.value?.email ?? '', clientAsync.value?.photo ?? ''),

          const SizedBox(height: 28),

          // === Section : Préférences ===
          _buildSectionTitre('Préférences'),
          const SizedBox(height: 12),

          _buildSwitch(
            icone: Iconsax.notification_copy,
            titre: 'Notifications push',
            sousTitre: 'Alertes de course et mises à jour de statut',
            valeur: _notifications,
            couleur: CouleursApp.primaire,
            onChange: _changerNotifications,
          ),

          _buildSwitch(
            icone: Iconsax.location_copy,
            titre: 'Géolocalisation',
            sousTitre: 'Nécessaire pour le suivi GPS en temps réel',
            valeur: _localisation,
            couleur: CouleursApp.accentNeon,
            onChange: _changerLocalisation,
          ),

          _buildSwitch(
            icone: Iconsax.finger_scan_copy,
            titre: 'Authentification biométrique',
            sousTitre: 'Empreinte digitale ou Face ID pour vous connecter',
            valeur: _biometrie,
            couleur: CouleursApp.accentViolet,
            onChange: _changerBiometrie,
          ),

          const SizedBox(height: 28),

          // === Section : Apparence & Langue ===
          _buildSectionTitre('Interface'),
          const SizedBox(height: 12),
          const SelecteurTheme(),
          const SizedBox(height: 12),
          _buildSelecteurLangue(),

          const SizedBox(height: 28),

          // === Section : Compte ===
          _buildSectionTitre('Compte'),
          const SizedBox(height: 12),

          _buildTuile(
            icone: Iconsax.lock_1_copy,
            titre: 'Modifier le mot de passe',
            onTap: () => context.push(RoutesApplication.changerMotDePasse),
          ),
          _buildTuile(
            icone: Iconsax.shield_tick_copy,
            titre: 'Sécurité',
            onTap: _ouvrirSecurite,
          ),
          _buildTuile(
            icone: Iconsax.eye_slash_copy,
            titre: 'Confidentialité',
            onTap: _ouvrirConfidentialite,
          ),

          const SizedBox(height: 28),

          // === Section : À propos ===
          _buildSectionTitre('À propos'),
          const SizedBox(height: 12),

          _buildTuile(
            icone: Iconsax.document_text_copy,
            titre: 'Conditions d\'utilisation',
            onTap: () => _ouvrirContenu(
                'Conditions d\'utilisation', ContenusLegaux.conditions),
          ),
          _buildTuile(
            icone: Iconsax.security_safe_copy,
            titre: 'Politique de confidentialité',
            onTap: () => _ouvrirContenu(
                'Politique de confidentialité', ContenusLegaux.confidentialite),
          ),
          _buildTuile(
            icone: Iconsax.message_question_copy,
            titre: 'Centre d\'aide',
            onTap: () => _ouvrirContenu('Centre d\'aide', ContenusLegaux.aide),
          ),
          _buildTuile(
            icone: Iconsax.star_copy,
            titre: 'Noter l\'application',
            onTap: _noterApplication,
          ),

          const SizedBox(height: 16),

          // Badge version
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
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
                            color: Theme.of(context).colorScheme.onSurface,
                            fontWeight: FontWeight.w600,
                            fontSize: 14)),
                    Text('1.0.0 — Production',
                        style: GoogleFonts.inter(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.5),
                            fontSize: 12)),
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
                foregroundColor: Theme.of(context).colorScheme.onSurface,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              icon: _isLoggingOut
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          color: Theme.of(context).colorScheme.onSurface,
                          strokeWidth: 2.5),
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

  Widget _buildSelecteurLangue() {
    final locale = ref.watch(localeProvider);
    final isFr = locale.languageCode == 'fr';
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CouleursApp.bordureSombre),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: CouleursApp.primaire.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.language,
                    color: CouleursApp.primaire, size: 18),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.language,
                      style: GoogleFonts.inter(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.w600,
                          fontSize: 14)),
                  Text(isFr ? "Français" : "English",
                      style: GoogleFonts.inter(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.5),
                          fontSize: 12)),
                ],
              ),
            ],
          ),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'fr', label: Text('FR')),
              ButtonSegment(value: 'en', label: Text('EN')),
            ],
            selected: {locale.languageCode},
            onSelectionChanged: (Set<String> newSelection) {
              ref
                  .read(localeProvider.notifier)
                  .setLocale(Locale(newSelection.first));
            },
            style: SegmentedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.surface,
              selectedForegroundColor: Theme.of(context).colorScheme.onSurface,
              selectedBackgroundColor: CouleursApp.primaire,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfilBandeau(String nom, String email, String photoUrl) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF007ACC), Color(0xFF33AFFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor:
                Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2),
            backgroundImage: photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
            child: photoUrl.isEmpty
                ? Text(
                    nom.isNotEmpty ? nom[0].toUpperCase() : 'C',
                    style: GoogleFonts.inter(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface),
                  )
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nom,
                  style: GoogleFonts.inter(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                      fontSize: 16),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  email,
                  style: GoogleFonts.inter(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.7),
                      fontSize: 13),
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
        color: Theme.of(context).colorScheme.surface,
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
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                        fontSize: 14)),
                Text(sousTitre,
                    style: GoogleFonts.inter(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.5),
                        fontSize: 12,
                        height: 1.4)),
              ],
            ),
          ),
          Switch(
            value: valeur,
            onChanged: onChange,
            activeThumbColor: couleur,
            inactiveTrackColor:
                Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
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
        color: Theme.of(context).colorScheme.surface,
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
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.w500,
              fontSize: 14),
        ),
        trailing: Icon(Icons.arrow_forward_ios,
            size: 14,
            color:
                Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4)),
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
      ),
    );
  }
}
