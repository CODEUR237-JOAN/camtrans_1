import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:update_camtrans/coeur/animations/animations_avancees.dart';
import 'package:update_camtrans/coeur/constantes/couleurs.dart';
import 'package:update_camtrans/coeur/constantes/tailles.dart';
import 'package:update_camtrans/coeur/constantes/textes.dart';
import 'package:update_camtrans/coeur/routes/routes.dart';
import 'package:update_camtrans/coeur/utilitaires/validateurs.dart';
import 'package:update_camtrans/coeur/widgets/bouton_principal.dart';
import 'package:update_camtrans/coeur/widgets/champ_texte.dart';
import 'package:update_camtrans/coeur/widgets/effets_visuels.dart';

import 'package:update_camtrans/services/service_authentification.dart';
import 'package:update_camtrans/services/service_firestore.dart';
import 'package:update_camtrans/services/service_notification.dart';
import 'package:update_camtrans/coeur/etat/utilisateur_provider.dart';

// =====================================================================
// Page : Connexion
// 100% opérationnelle :
//  ✅ Email / Mot de passe → Firebase Auth
//  ✅ Connexion Google → Google Sign-In + Firebase credential
//  ✅ Mot de passe oublié → route dédiée
//  ✅ S'inscrire → route choix profil
//  ✅ Messages d'erreur humanisés (codes Firebase traduits)
//  ✅ Indicateur de chargement par action
// =====================================================================

class Connexion extends ConsumerStatefulWidget {
  const Connexion({super.key});

  @override
  ConsumerState<Connexion> createState() => _ConnexionState();
}

class _ConnexionState extends ConsumerState<Connexion> {
  final _cleFormulaire = GlobalKey<FormState>();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _motDePasse = TextEditingController();

  bool _chargementEmail = false;
  bool _chargementGoogle = false;

  // -----------------------------------------------------------------
  // Traduction des codes d'erreur Firebase en messages humains
  // -----------------------------------------------------------------
  String _traduireErreurFirebase(dynamic e) {
    final message = e.toString();
    if (message.contains('user-not-found')) {
      return 'Aucun compte trouvé avec cet e-mail. Vérifiez ou créez un compte.';
    }
    if (message.contains('wrong-password') ||
        message.contains('invalid-credential')) {
      return 'Mot de passe incorrect. Vérifiez vos identifiants.';
    }
    if (message.contains('invalid-email')) {
      return 'Adresse e-mail invalide. Veuillez la corriger.';
    }
    if (message.contains('user-disabled')) {
      return 'Ce compte a été désactivé. Contactez le support CamTrans.';
    }
    if (message.contains('too-many-requests')) {
      return 'Trop de tentatives échouées. Réessayez dans quelques minutes.';
    }
    if (message.contains('network-request-failed')) {
      return 'Pas de connexion Internet. Vérifiez votre réseau.';
    }
    if (message.contains('email-already-in-use')) {
      return 'Un compte existe déjà avec cet e-mail.';
    }
    if (message.contains('sign_in_canceled') || message.contains('canceled')) {
      return 'Connexion annulée.';
    }
    return 'Une erreur inattendue s\'est produite. Réessayez.';
  }

  // -----------------------------------------------------------------
  // Routage post-connexion selon le rôle Firestore
  // -----------------------------------------------------------------
  Future<void> _routerSelonRole(String uid) async {
    final serviceDb = ref.read(serviceFirestoreProvider);
    String? role;

    // 1. Admin
    try {
      final adminDoc =
          await serviceDb.lireDocument(collection: 'admin', id: uid);
      if (adminDoc.exists) role = 'admin';
    } catch (_) {}

    // 2. Transporteur
    if (role == null) {
      try {
        final transpDoc =
            await serviceDb.lireDocument(collection: 'transporteurs', id: uid);
        if (transpDoc.exists) role = 'transporteur';
      } catch (_) {}
    }

    // 3. Client
    if (role == null) {
      try {
        final clientDoc =
            await serviceDb.lireDocument(collection: 'clients', id: uid);
        if (clientDoc.exists) role = 'client';
      } catch (_) {}
    }

    ref.invalidate(userRoleProvider);
    if (!mounted) return;

    if (role == 'admin') {
      context.go(RoutesApplication.admin);
    } else if (role == 'client') {
      await ServiceNotification.enregistrerTokenUtilisateur(uid, 'client');
      if (mounted) context.go(RoutesApplication.tableauBordClient);
    } else if (role == 'transporteur') {
      await ServiceNotification.enregistrerTokenUtilisateur(
          uid, 'transporteur');
      if (mounted) context.go(RoutesApplication.tableauBordTransporteur);
    } else {
      // Nouveau compte Google → créer le profil
      if (mounted) context.go(RoutesApplication.choixProfil);
    }
  }

  // -----------------------------------------------------------------
  // Connexion Email / Mot de passe
  // -----------------------------------------------------------------
  Future<void> _connexionEmail() async {
    if (!_cleFormulaire.currentState!.validate()) return;
    setState(() => _chargementEmail = true);
    try {
      final serviceAuth = ref.read(serviceAuthentificationProvider);
      final userCred = await serviceAuth.connexion(
        email: _email.text.trim(),
        motDePasse: _motDePasse.text,
      );
      if (!mounted) return;
      if (userCred.user != null) {
        await _routerSelonRole(userCred.user!.uid);
      }
    } catch (e) {
      if (!mounted) return;
      _afficherErreur(_traduireErreurFirebase(e));
    } finally {
      if (mounted) setState(() => _chargementEmail = false);
    }
  }

  // -----------------------------------------------------------------
  // Connexion Google
  // -----------------------------------------------------------------
  Future<void> _connexionGoogle() async {
    setState(() => _chargementGoogle = true);
    try {
      final serviceAuth = ref.read(serviceAuthentificationProvider);
      final userCred = await serviceAuth.connexionGoogle();
      if (!mounted) return;
      if (userCred?.user != null) {
        await _routerSelonRole(userCred!.user!.uid);
      }
      // Si null → l'utilisateur a annulé (pas d'erreur à afficher)
    } catch (e) {
      if (!mounted) return;
      final msg = _traduireErreurFirebase(e);
      if (!msg.contains('annulée')) _afficherErreur(msg);
    } finally {
      if (mounted) setState(() => _chargementGoogle = false);
    }
  }

  void _afficherErreur(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
                child: Text(message, style: const TextStyle(fontSize: 13))),
          ],
        ),
        backgroundColor: CouleursApp.erreur,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  void dispose() {
    _email.dispose();
    _motDePasse.dispose();
    super.dispose();
  }

  // -----------------------------------------------------------------
  // BUILD
  // -----------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: FondPremiumAnime(
        safeArea: true,
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: TaillesApp.margePage),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Form(
                key: _cleFormulaire,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 20),

                    // Logo avec glow
                    AnimationScaleBounce(
                      delay: const Duration(milliseconds: 100),
                      child: Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          gradient: CouleursApp.degradePrincipal,
                          shape: BoxShape.circle,
                          boxShadow: [
                            CouleursApp.ombreNeon(blurRadius: 25),
                            BoxShadow(
                              color:
                                  CouleursApp.primaire.withValues(alpha: 0.2),
                              blurRadius: 40,
                              spreadRadius: 4,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.local_shipping,
                          size: 56,
                          color: Colors.white,
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    AnimationSlideFade(
                      delay: const Duration(milliseconds: 200),
                      child: Text(
                        TextesApp.bienvenue,
                        style: TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w900,
                          color: isDark
                              ? Colors.white
                              : CouleursApp.textePrincipal,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    AnimationSlideFade(
                      delay: const Duration(milliseconds: 300),
                      child: Text(
                        'Connectez-vous pour continuer',
                        style: TextStyle(
                          color: isDark
                              ? const Color(0xFFCBD5E1)
                              : CouleursApp.texteSecondaire,
                          fontSize: 17,
                        ),
                      ),
                    ),

                    const SizedBox(height: 40),

                    // ─── Formulaire Glassmorphism ───
                    AnimationSlideFade(
                      delay: const Duration(milliseconds: 400),
                      child: GlassCard(
                        padding: const EdgeInsets.all(28),
                        blur: 25,
                        child: Column(
                          children: [
                            ChampTexte(
                              controleur: _email,
                              libelle: TextesApp.adresseEmail,
                              icone: Icons.email_outlined,
                              typeClavier: TextInputType.emailAddress,
                              validateur: Validateurs.email,
                              glassmorphism: true,
                            ),

                            const SizedBox(height: 20),

                            ChampTexte(
                              controleur: _motDePasse,
                              libelle: TextesApp.motDePasse,
                              icone: Icons.lock_outline,
                              estMotDePasse: true,
                              validateur: Validateurs.motDePasse,
                              glassmorphism: true,
                            ),

                            const SizedBox(height: 12),

                            // ✅ Mot de passe oublié → route dédiée
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () => context
                                    .push(RoutesApplication.motDePasseOublie),
                                child: Text(
                                  TextesApp.motDePasseOublie,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: CouleursApp.primaire,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 8),

                            // ✅ Bouton connexion email
                            BoutonPrincipal(
                              texte: TextesApp.connexion,
                              icone: Icons.login,
                              chargement: _chargementEmail,
                              auClic: _connexionEmail,
                              gradient: CouleursApp.degradePrincipal,
                              glow: true,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 28),

                    // ─── Pas de compte ───
                    AnimationSlideFade(
                      delay: const Duration(milliseconds: 600),
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            'Vous n\'avez pas de compte ?',
                            style: TextStyle(
                              color: isDark
                                  ? const Color(0xFFCBD5E1)
                                  : CouleursApp.texteSecondaire,
                              fontSize: 15,
                            ),
                          ),
                          // ✅ S'inscrire → choix du profil
                          TextButton(
                            onPressed: () =>
                                context.push(RoutesApplication.choixProfil),
                            child: const Text(
                              'S\'inscrire',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ─── Séparateur ───
                    AnimationSlideFade(
                      delay: const Duration(milliseconds: 700),
                      child: Row(
                        children: [
                          Expanded(
                            child: Divider(
                              color: isDark
                                  ? Colors.white12
                                  : Colors.grey.shade300,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            child: Text(
                              'Ou continuer avec',
                              style: TextStyle(
                                color: isDark
                                    ? const Color(0xFF94A3B8)
                                    : Colors.grey.shade500,
                                fontWeight: FontWeight.w500,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Divider(
                              color: isDark
                                  ? Colors.white12
                                  : Colors.grey.shade300,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ─── Bouton Google (opérationnel) ───
                    AnimationSlideFade(
                      delay: const Duration(milliseconds: 800),
                      child: _chargementGoogle
                          ? const SizedBox(
                              height: 56,
                              child: Center(
                                child: CircularProgressIndicator(
                                    color: CouleursApp.primaire),
                              ),
                            )
                          : SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: OutlinedButton.icon(
                                onPressed: _connexionGoogle,
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(
                                    color: isDark
                                        ? Colors.white24
                                        : Colors.grey.shade300,
                                    width: 1.5,
                                  ),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16)),
                                  backgroundColor: isDark
                                      ? Colors.white.withValues(alpha: 0.04)
                                      : Colors.white,
                                ),
                                icon: const _GoogleLogo(),
                                label: Text(
                                  'Continuer avec Google',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                    color:
                                        isDark ? Colors.white : Colors.black87,
                                  ),
                                ),
                              ),
                            ),
                    ),

                    const SizedBox(height: 12),

                    // ─── Liens Facebook / Apple → inscription ───
                    AnimationSlideFade(
                      delay: const Duration(milliseconds: 900),
                      child: Row(
                        children: [
                          Expanded(
                            child: _boutonSocialSecondaire(
                              label: 'Facebook',
                              couleur: const Color(0xFF1877F2),
                              icone: Icons.facebook,
                              onTap: () {
                                // Facebook → redirige vers l'inscription
                                context.push(RoutesApplication.choixProfil);
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _boutonSocialSecondaire(
                              label: 'Apple',
                              couleur: isDark ? Colors.white : Colors.black,
                              icone: Icons.apple,
                              onTap: () {
                                // Apple → redirige vers l'inscription
                                context.push(RoutesApplication.choixProfil);
                              },
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _boutonSocialSecondaire({
    required String label,
    required Color couleur,
    required IconData icone,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return OutlinedButton.icon(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        side: BorderSide(
          color: isDark ? Colors.white12 : Colors.grey.shade300,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        backgroundColor:
            isDark ? Colors.white.withValues(alpha: 0.03) : Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
      icon: Icon(icone, color: couleur, size: 20),
      label: Text(
        label,
        style: TextStyle(
          color: isDark ? Colors.white70 : Colors.black87,
          fontWeight: FontWeight.w500,
          fontSize: 13,
        ),
      ),
    );
  }
}

// ─── Logo Google SVG inline (propre, sans dépendance externe) ───
class _GoogleLogo extends StatelessWidget {
  const _GoogleLogo();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 22,
      height: 22,
      child: CustomPaint(painter: _GoogleLogoPainter()),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    const colors = [
      Color(0xFF4285F4), // Bleu
      Color(0xFF34A853), // Vert
      Color(0xFFFBBC05), // Jaune
      Color(0xFFEA4335), // Rouge
    ];

    // Dessin simplifié du logo Google via arcs
    final paint = Paint()..style = PaintingStyle.fill;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Segment bleu (droite)
    paint.color = colors[0];
    canvas.drawArc(rect, -0.35, 1.75, true, paint);

    // Segment rouge (haut-gauche)
    paint.color = colors[3];
    canvas.drawArc(rect, -2.1, 1.05, true, paint);

    // Segment jaune (bas-gauche)
    paint.color = colors[2];
    canvas.drawArc(rect, 2.45, 0.7, true, paint);

    // Segment vert (bas)
    paint.color = colors[1];
    canvas.drawArc(rect, 3.15, 0.75, true, paint);

    // Cercle blanc central
    paint.color = Colors.white;
    canvas.drawCircle(center, radius * 0.62, paint);

    // Barre bleue horizontale (le "G")
    paint.color = colors[0];
    canvas.drawRect(
      Rect.fromCenter(
          center: Offset(center.dx + radius * 0.15, center.dy),
          width: radius * 0.85,
          height: radius * 0.32),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
