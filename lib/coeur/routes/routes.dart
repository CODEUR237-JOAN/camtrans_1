import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:update_camtrans/coeur/animations/transitions_page.dart';
import 'package:update_camtrans/coeur/constantes/couleurs.dart';
import 'package:update_camtrans/coeur/widgets/effets_visuels.dart';

import 'package:update_camtrans/fonctionnalites/authentification/choix_profil.dart';
import 'package:update_camtrans/fonctionnalites/authentification/connexion.dart';
import 'package:update_camtrans/fonctionnalites/authentification/inscription_client.dart';
import 'package:update_camtrans/fonctionnalites/authentification/inscription_transporteur.dart';
import 'package:update_camtrans/fonctionnalites/authentification/mot_de_passe_oublie.dart';
import 'package:update_camtrans/fonctionnalites/authentification/verification_email.dart';
import 'package:update_camtrans/fonctionnalites/client/carte.dart';
import 'package:update_camtrans/fonctionnalites/client/creer_demande.dart';
import 'package:update_camtrans/fonctionnalites/client/facture.dart';
import 'package:update_camtrans/fonctionnalites/client/historique.dart';
import 'package:update_camtrans/fonctionnalites/client/suivi_transport.dart';
import 'package:update_camtrans/fonctionnalites/client/tableau_de_bord_client.dart';
import 'package:update_camtrans/fonctionnalites/demarrage/ecran_splash.dart';
import 'package:update_camtrans/fonctionnalites/demarrage/onboarding.dart';
import 'package:update_camtrans/fonctionnalites/transporteur/tableau_de_bord_transporteur.dart';
import 'package:update_camtrans/fonctionnalites/ia/ecran_assistant_ia.dart';
import 'package:update_camtrans/fonctionnalites/paiement/ecran_paiement.dart';
import 'package:update_camtrans/fonctionnalites/admin/tableau_de_bord_admin.dart';
import 'package:update_camtrans/fonctionnalites/client/adresses_favorites.dart';
import 'package:update_camtrans/fonctionnalites/client/ecran_chat.dart';
import 'package:update_camtrans/fonctionnalites/client/ecran_evaluation.dart';
import 'package:update_camtrans/fonctionnalites/profil/modifier_profil.dart';
import 'package:update_camtrans/fonctionnalites/profil/changer_mot_de_passe.dart';
import 'package:update_camtrans/fonctionnalites/transporteur/historique_livraisons.dart';
import 'package:update_camtrans/fonctionnalites/transporteur/revenus.dart';
import 'package:update_camtrans/fonctionnalites/transporteur/portefeuille.dart';
import 'package:update_camtrans/fonctionnalites/transporteur/documents.dart';
import 'package:update_camtrans/modeles/transporteur.dart';
import 'package:update_camtrans/modeles/course.dart';
import 'package:update_camtrans/fonctionnalites/transporteur/page_abonnement.dart';

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
  static const String modifierProfil = "/modifier-profil";
  static const String changerMotDePasse = "/changer-mot-de-passe";
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
  static const String evaluation = "/evaluation/:courseId";
  static const String admin = "/admin";
  static const String adressesFavorites = "/adresses-favorites";
  static const String chat = "/chat";
  static const String historiqueLivraisonsTransporteur = "/historique-livraisons-transporteur";
  static const String revenus = "/revenus";
  static const String portefeuille = "/portefeuille";
  static const String documents = "/documents";
  static const String facture = "/facture";
  static const String abonnement = "/abonnement";

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
        path: modifierProfil,
        pageBuilder: (context, state) => _page(const ModifierProfil(), state.pageKey),
      ),
      GoRoute(
        path: changerMotDePasse,
        pageBuilder: (context, state) => _page(const ChangerMotDePasse(), state.pageKey),
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
      // Route de suivi avec l'ID réel de la course 
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
        path: "/evaluation/:courseId",
        pageBuilder: (context, state) => _page(
          EcranEvaluation(courseId: state.pathParameters['courseId'] ?? ""),
          state.pageKey,
        ),
      ),
      GoRoute(
        path: paiement,
        pageBuilder: (context, state) {
          final args = state.extra as Map<String, dynamic>?;
          // Si les arguments sont absents, on ne peut pas afficher l'écran de paiement
          if (args == null || args['courseId'] == null) {
            return _page(
              Scaffold(
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 60, color: Colors.red),
                      const SizedBox(height: 16),
                      const Text("Impossible d'accéder au paiement", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      const Text("Veuillez relancer depuis votre course.", textAlign: TextAlign.center),
                    ],
                  ),
                ),
              ),
              state.pageKey,
            );
          }
          return _page(
            EcranPaiement(
              courseId: args['courseId'] as String,
              montant: (args['montant'] as num?)?.toDouble() ?? 0.0,
              transporteurId: args['transporteurId'] as String? ?? '',
            ),
            state.pageKey,
          );
        },
      ),
      GoRoute(
        path: adressesFavorites,
        pageBuilder: (context, state) => _page(const AdressesFavoritesPage(), state.pageKey),
      ),
      GoRoute(
        path: chat,
        pageBuilder: (context, state) {
          final args = state.extra as Map<String, dynamic>? ?? {};
          final transporteur = args['transporteur'] as Transporteur;
          return _page(EcranChat(transporteur: transporteur), state.pageKey);
        },
      ),
      GoRoute(
        path: historiqueLivraisonsTransporteur,
        pageBuilder: (context, state) => _page(const HistoriqueLivraisons(), state.pageKey),
      ),
      GoRoute(
        path: admin,
        pageBuilder: (context, state) => _page(const TableauDeBordAdmin(), state.pageKey),
      ),
      GoRoute(
        path: revenus,
        pageBuilder: (context, state) => _page(const Revenus(), state.pageKey),
      ),
      GoRoute(
        path: portefeuille,
        pageBuilder: (context, state) => _page(const Portefeuille(), state.pageKey),
      ),
      GoRoute(
        path: documents,
        pageBuilder: (context, state) => _page(const Documents(), state.pageKey),
      ),
      GoRoute(
        path: facture,
        pageBuilder: (context, state) {
          final course = state.extra as Course?;
          return _page(
            Facture(course: course),
            state.pageKey,
          );
        },
      ),
      GoRoute(
        path: abonnement,
        pageBuilder: (context, state) => _page(const PageAbonnement(), state.pageKey),
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
