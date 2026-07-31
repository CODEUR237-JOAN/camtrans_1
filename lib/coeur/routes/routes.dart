import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../animations/transitions_page.dart';
import '../constantes/couleurs.dart';
import '../widgets/effets_visuels.dart';

import '../../fonctionnalites/authentification/choix_profil.dart';
import '../../fonctionnalites/authentification/connexion.dart';
import '../../fonctionnalites/authentification/inscription_client.dart';
import '../../fonctionnalites/authentification/inscription_transporteur.dart';
import '../../fonctionnalites/authentification/mot_de_passe_oublie.dart';
import '../../fonctionnalites/authentification/verification_email.dart';
import '../../fonctionnalites/client/carte.dart';
import '../../fonctionnalites/client/creer_demande.dart';
import '../../fonctionnalites/client/facture.dart';
import '../../fonctionnalites/client/historique.dart';
import '../../fonctionnalites/client/suivi_transport.dart';
import '../../fonctionnalites/client/tableau_de_bord_client.dart';
import '../../fonctionnalites/demarrage/ecran_splash.dart';
import '../../fonctionnalites/demarrage/onboarding.dart';
import '../../fonctionnalites/transporteur/tableau_de_bord_transporteur.dart';
import '../../fonctionnalites/ia/ecran_assistant_ia.dart';
import '../../fonctionnalites/paiement/ecran_paiement.dart';
import '../../fonctionnalites/admin/tableau_de_bord_admin.dart';

class RoutesApplication {
  RoutesApplication._();

  // ===========================
  // Noms des routes
  // ===========================

  static const String splash = "/";
  static const String onboarding = "/onboarding";
  static const String connexion = "/connexion";
  static const String choixProfil = "/choix-profil";
  static const String inscriptionClient = "/inscription-client";
  static const String inscriptionTransporteur = "/inscription-transporteur";
  static const String motDePasseOublie = "/mot-de-passe-oublie";
  static const String verificationEmail = "/verification-email";
  static const String tableauBordClient = "/tableau-bord-client";
  static const String creerDemande = "/creer-demande";
  static const String carte = "/carte";
  static const String suivi = "/suivi";
  static const String suiviAvecId = "/suivi/:courseId"; // Route paramétrée
  static const String historique = "/historique";
  static const String factures = "/factures";
  static const String tableauBordTransporteur = "/tableau-bord-transporteur";
  static const String assistantIA = "/assistant-ia";
  static const String paiement = "/paiement";
  static const String admin = "/admin";

  // ===========================
  // Routeur GoRouter
  // ===========================

  static CustomTransitionPage _page(Widget child, LocalKey? key) {
    return SharedAxisTransition(
      key: key,
      type: SharedAxisTransitionType.scaled,
      child: child,
    );
  }

  static final GoRouter routeur = GoRouter(
    initialLocation: splash,
    routes: [
      GoRoute(
        path: splash,
        pageBuilder: (context, state) => _page(const EcranSplash(), state.pageKey),
      ),
      GoRoute(
        path: onboarding,
        pageBuilder: (context, state) => _page(const Onboarding(), state.pageKey),
      ),
      GoRoute(
        path: connexion,
        pageBuilder: (context, state) => _page(const Connexion(), state.pageKey),
      ),
      GoRoute(
        path: choixProfil,
        pageBuilder: (context, state) => _page(const ChoixProfil(), state.pageKey),
      ),
      GoRoute(
        path: inscriptionClient,
        pageBuilder: (context, state) => _page(const InscriptionClient(), state.pageKey),
      ),
      GoRoute(
        path: inscriptionTransporteur,
        pageBuilder: (context, state) => _page(const InscriptionTransporteur(), state.pageKey),
      ),
      GoRoute(
        path: motDePasseOublie,
        pageBuilder: (context, state) => _page(const MotDePasseOublie(), state.pageKey),
      ),
      GoRoute(
        path: verificationEmail,
        pageBuilder: (context, state) => _page(const VerificationEmail(), state.pageKey),
      ),
      GoRoute(
        path: tableauBordClient,
        pageBuilder: (context, state) => _page(const TableauDeBordClient(), state.pageKey),
      ),
      GoRoute(
        path: tableauBordTransporteur,
        pageBuilder: (context, state) => _page(const TableauDeBordTransporteur(), state.pageKey),
      ),
      GoRoute(
        path: creerDemande,
        pageBuilder: (context, state) => _page(const CreerDemande(), state.pageKey),
      ),
      GoRoute(
        path: carte,
        pageBuilder: (context, state) => _page(const VueCarte(), state.pageKey),
      ),
      // Route de suivi sans ID (mode démo)
      GoRoute(
        path: suivi,
        pageBuilder: (context, state) => _page(
          const SuiviTransport(courseId: ""),
          state.pageKey,
        ),
      ),
      // Route de suivi avec l'ID réel de la course ✅
      GoRoute(
        path: suiviAvecId,
        pageBuilder: (context, state) => _page(
          SuiviTransport(courseId: state.pathParameters['courseId'] ?? ""),
          state.pageKey,
        ),
      ),
      GoRoute(
        path: historique,
        pageBuilder: (context, state) => _page(const Historique(), state.pageKey),
      ),
      GoRoute(
        path: factures,
        pageBuilder: (context, state) => _page(const Facture(), state.pageKey),
      ),
      GoRoute(
        path: assistantIA,
        pageBuilder: (context, state) => _page(const EcranAssistantIA(), state.pageKey),
      ),
      GoRoute(
        path: paiement,
        pageBuilder: (context, state) {
          final args = state.extra as Map<String, dynamic>? ?? {};
          return _page(
            EcranPaiement(
              courseId: args['courseId'] ?? 'demo_course_123',
              montant: (args['montant'] as num?)?.toDouble() ?? 15000.0,
              transporteurId: args['transporteurId'] ?? 'transp_456',
            ),
            state.pageKey,
          );
        },
      ),
      GoRoute(
        path: admin,
        pageBuilder: (context, state) => _page(const TableauDeBordAdmin(), state.pageKey),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: FondPremiumAnime(
        safeArea: true,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: CouleursApp.degradeErreur,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: CouleursApp.erreur.withValues(alpha: 0.24),
                        blurRadius: 24,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.route_outlined, color: Colors.white, size: 42),
                ),
                const SizedBox(height: 24),
                const Text(
                  "Page introuvable",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Text(
                  "Cette destination n'existe pas encore.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: CouleursApp.texteSecondaire.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
