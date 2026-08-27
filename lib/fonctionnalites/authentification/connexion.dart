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

class Connexion extends ConsumerStatefulWidget {
  const Connexion({super.key});

  @override
  ConsumerState<Connexion> createState() => _ConnexionState();
}

class _ConnexionState extends ConsumerState<Connexion> {
  final _cleFormulaire = GlobalKey<FormState>();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _motDePasse = TextEditingController();
  bool _chargement = false;

  void _connexion() async {
    if (!_cleFormulaire.currentState!.validate()) return;

    setState(() => _chargement = true);

    try {
      final serviceAuth = ref.read(serviceAuthentificationProvider);
      final serviceDb = ref.read(serviceFirestoreProvider);

      final userCred = await serviceAuth.connexion(
        email: _email.text,
        motDePasse: _motDePasse.text,
      );

      if (!mounted) return;

      if (userCred.user != null) {
        final uid = userCred.user!.uid;
        final email = userCred.user!.email;

          String? role;
          if (email == 'admintrans@gmail.com') {
            role = 'admin';
          } else {
            // Vérification admin
            try {
              final adminDoc = await serviceDb.lireDocument(collection: 'admin', id: uid);
              if (adminDoc.exists) role = 'admin';
            } catch (_) {}

            // Vérification transporteur EN PREMIER (priorité sur client)
            if (role == null) {
              try {
                final transpDoc = await serviceDb.lireDocument(collection: 'transporteurs', id: uid);
                if (transpDoc.exists) {
                  role = 'transporteur';
                  debugPrint(' Rôle détecté: transporteur (uid=$uid)');
                }
              } catch (e) {
                debugPrint('️ Erreur lecture transporteurs: $e');
              }
            }

            // Vérification client
            if (role == null) {
              try {
                final clientDoc = await serviceDb.lireDocument(collection: 'clients', id: uid);
                if (clientDoc.exists) {
                  role = 'client';
                  debugPrint(' Rôle détecté: client (uid=$uid)');
                }
              } catch (e) {
                debugPrint('️ Erreur lecture clients: $e');
              }
            }

            // Fallback: lire le champ "role" dans le doc Firestore directement
            if (role == null) {
              for (final col in ['transporteurs', 'clients']) {
                try {
                  final doc = await serviceDb.lireDocument(collection: col, id: uid);
                  if (doc.exists) {
                    final data = doc.data();
                    final roleField = data?['role'] as String?;
                    if (roleField != null && roleField.isNotEmpty) {
                      role = roleField;
                      debugPrint(' Rôle via champ role: $role (uid=$uid)');
                      break;
                    }
                  }
                } catch (_) {}
              }
            }
          }

          ref.invalidate(userRoleProvider);

          if (!mounted) return;

          debugPrint(' Redirection → rôle=$role');

          if (role == 'admin') {
            context.go(RoutesApplication.admin);
          } else if (role == 'client') {
            await ServiceNotification.enregistrerTokenUtilisateur(uid, 'client');
            if (mounted) context.go(RoutesApplication.tableauBordClient);
          } else if (role == 'transporteur') {
            await ServiceNotification.enregistrerTokenUtilisateur(uid, 'transporteur');
            if (mounted) context.go(RoutesApplication.tableauBordTransporteur);
          } else {
            debugPrint('️ Rôle introuvable pour uid=$uid, redirection vers choixProfil');
            context.go(RoutesApplication.choixProfil);
          }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Oups, la connexion a échoué : ${e.toString()}"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _chargement = false);
    }
  }

  @override
  void dispose() {
    _email.dispose();
    _motDePasse.dispose();
    super.dispose();
  }

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
                              color: CouleursApp.primaire.withValues(alpha: 0.2),
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

                    // Titre
                    AnimationSlideFade(
                      delay: const Duration(milliseconds: 200),
                      child: Text(
                        TextesApp.bienvenue,
                        style: TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w900,
                          color: isDark ? Colors.white : CouleursApp.textePrincipal,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    AnimationSlideFade(
                      delay: const Duration(milliseconds: 300),
                      child: Text(
                        "Connectez-vous pour continuer",
                        style: TextStyle(
                          color: isDark ? const Color(0xFFCBD5E1) : CouleursApp.texteSecondaire,
                          fontSize: 17,
                        ),
                      ),
                    ),

                    const SizedBox(height: 40),

                    // Formulaire Glassmorphism
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

                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () => context.push(RoutesApplication.motDePasseOublie),
                                child: Text(
                                  TextesApp.motDePasseOublie,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: CouleursApp.primaire,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 8),

                            BoutonPrincipal(
                              texte: TextesApp.connexion,
                              icone: Icons.login,
                              chargement: _chargement,
                              auClic: _connexion,
                              gradient: CouleursApp.degradePrincipal,
                              glow: true,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 28),

                    // Pas de compte ?
                    AnimationSlideFade(
                      delay: const Duration(milliseconds: 600),
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            "Vous n'avez pas de compte ?",
                            style: TextStyle(
                              color: isDark ? const Color(0xFFCBD5E1) : CouleursApp.texteSecondaire,
                              fontSize: 15,
                            ),
                          ),
                          TextButton(
                            onPressed: () => context.push(RoutesApplication.choixProfil),
                            child: const Text(
                              "S'inscrire",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Séparateur
                    AnimationSlideFade(
                      delay: const Duration(milliseconds: 700),
                      child: Row(
                        children: [
                          Expanded(
                            child: Divider(
                              color: isDark ? Colors.white12 : Colors.grey.shade300,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            child: Text(
                              "Ou avec",
                              style: TextStyle(
                                color: isDark ? const Color(0xFF94A3B8) : Colors.grey.shade500,
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Divider(
                              color: isDark ? Colors.white12 : Colors.grey.shade300,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Boutons sociaux
                    AnimationSlideFade(
                      delay: const Duration(milliseconds: 800),
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 16,
                        runSpacing: 16,
                        children: [
                          _boutonSocial(Icons.g_mobiledata, const Color(0xFFEA4335)),
                          _boutonSocial(Icons.facebook, const Color(0xFF1877F2)),
                          _boutonSocial(Icons.apple, isDark ? Colors.white : Colors.black),
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

  Widget _boutonSocial(IconData icone, Color couleur) {
    return AnimatedShadowCard(
      onTap: () {},
      padding: const EdgeInsets.all(14),
      borderRadius: 20,
      child: Icon(icone, color: couleur, size: 28),
    );
  }
}
