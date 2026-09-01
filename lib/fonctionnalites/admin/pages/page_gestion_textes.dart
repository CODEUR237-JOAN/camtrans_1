import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../coeur/constantes/couleurs.dart';
import '../../../coeur/etat/textes_app_provider.dart';
import '../../../modeles/textes_app.dart';

class PageGestionTextes extends ConsumerStatefulWidget {
  const PageGestionTextes({super.key});

  @override
  ConsumerState<PageGestionTextes> createState() => _PageGestionTextesState();
}

class _PageGestionTextesState extends ConsumerState<PageGestionTextes> {
  final Map<String, TextEditingController> _controllers = {};
  bool _enCours = false;
  bool _initialise = false;

  // Descriptions affichées dans l'UI pour chaque clé
  final Map<String, String> _descriptions = {
    // === Documents Légaux ===
    'conditions_transporteur': "📋 Conditions d'utilisation (transporteurs)",
    'conditions_client': "📋 Conditions d'utilisation (clients)",

    // Succès
    'succes_parametres': "Succès : Mise à jour des paramètres",
    'succes_purge_historique': "Succès : Nettoyage de l'historique (Admin)",
    'succes_annulation_course': "Succès : Annulation de course",

    // Erreurs
    'err_demarrage': "Erreur : Problème au démarrage",
    'err_chargement_historique': "Erreur : Chargement de l'historique",
    'err_chargement_stats': "Erreur : Chargement des statistiques",
    'err_reseau': "Erreur : Problème réseau générique",
    'err_inscription': "Erreur : Échec de l'inscription",
    'err_profil': "Erreur : Mise à jour du profil",
    'err_sauvegarde_parametres': "Erreur : Sauvegarde des paramètres admin",

    // Vides
    'vide_course_client': "Vide : Aucune course en cours (Client)",
    'vide_historique_client': "Vide : Historique vide (Client)",
    'vide_historique_transp': "Vide : Historique vide (Transporteur)",
    'vide_demandes_transp': "Vide : Aucune demande au marché (Transporteur)",
    'vide_abonnements_admin': "Vide : Aucun abonnement (Admin)",
  };

  // Valeurs par défaut pour chaque clé — visibles et modifiables directement par l'Admin
  static const Map<String, String> _defaults = {
    'conditions_transporteur':
        "Bienvenue sur Camtrans !\n\n"
        "1. Engagements du Transporteur\n"
        "Vous vous engagez à maintenir votre véhicule en bon état et à respecter les délais de livraison.\n\n"
        "2. Gammes et Tarification\n"
        "La gamme 'Confort' requiert une validation stricte par l'administrateur. "
        "Tout signalement client peut entraîner une rétrogradation vers la gamme 'Éco'.\n\n"
        "3. Confidentialité\n"
        "Vos documents et données personnelles sont stockés de manière sécurisée "
        "et ne seront partagés qu'avec l'administration pour validation.",

    'conditions_client':
        "Bienvenue sur la plateforme CamTrans.\n\n"
        "1. Utilisation du service\n"
        "En utilisant notre plateforme, vous vous engagez à respecter les lois en vigueur "
        "et à ne pas utiliser nos services à des fins illégales.\n\n"
        "2. Données personnelles et Confidentialité\n"
        "Nous collectons et traitons vos données personnelles (nom, téléphone, adresse, "
        "position géographique) uniquement pour assurer la prestation de transport. "
        "Vos données ne sont pas vendues à des tiers.\n\n"
        "3. Paiements et Facturation\n"
        "Les tarifs affichés sont des estimations. Le montant final peut varier en fonction "
        "des conditions réelles du trajet.\n\n"
        "4. Responsabilité\n"
        "CamTrans agit en tant qu'intermédiaire entre le client et le transporteur. "
        "Nous ne saurions être tenus responsables des retards ou des dommages causés pendant le transport.",

    'succes_parametres': "Paramètres mis à jour avec succès.",
    'succes_purge_historique': "Historique nettoyé avec succès.",
    'succes_annulation_course': "Course annulée avec succès.",

    'err_demarrage': "Une erreur est survenue au démarrage. Veuillez relancer l'application.",
    'err_chargement_historique': "Impossible de charger l'historique. Vérifiez votre connexion.",
    'err_chargement_stats': "Impossible de charger les statistiques.",
    'err_reseau': "Problème de connexion réseau. Veuillez réessayer.",
    'err_inscription': "L'inscription a échoué. Veuillez réessayer.",
    'err_profil': "La mise à jour du profil a échoué.",
    'err_sauvegarde_parametres': "Erreur lors de la sauvegarde des paramètres.",

    'vide_course_client': "Aucune course en cours. Créez une nouvelle demande !",
    'vide_historique_client': "Votre historique de courses est vide.",
    'vide_historique_transp': "Vous n'avez pas encore effectué de course.",
    'vide_demandes_transp': "Aucune demande disponible pour le moment.",
    'vide_abonnements_admin': "Aucun abonnement actif.",
  };

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  /// Initialise les contrôleurs UNE SEULE FOIS avec les données Firestore
  /// (ou la valeur par défaut si aucune donnée n'existe encore en BDD).
  void _initialiserControleurs(TextesApp textes) {
    if (_initialise) return;
    _initialise = true;
    for (final cle in _descriptions.keys) {
      final valeurFirestore = textes.textes[cle]?.toString();
      final valeurDefaut = _defaults[cle] ?? '';
      _controllers[cle] = TextEditingController(
        text: (valeurFirestore != null && valeurFirestore.isNotEmpty)
            ? valeurFirestore
            : valeurDefaut,
      );
    }
  }

  void _sauvegarder(TextesApp textesActuels) async {
    setState(() => _enCours = true);
    try {
      final nouveauxTextes = Map<String, dynamic>.from(textesActuels.toMap());

      _controllers.forEach((cle, controller) {
        // On sauvegarde toujours le contenu du champ (même s'il est identique au défaut)
        // Un champ vide signifie "retourner au défaut codé en dur"
        if (controller.text.trim().isNotEmpty) {
          nouveauxTextes[cle] = controller.text.trim();
        } else {
          nouveauxTextes.remove(cle);
        }
      });

      final updateProvider = ref.read(updateTextesAppProvider);
      await updateProvider(TextesApp(textes: nouveauxTextes));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Textes mis à jour avec succès ! ✨"),
            backgroundColor: CouleursApp.succes,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Erreur lors de la sauvegarde : $e 🔧"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _enCours = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textesAsync = ref.watch(textesAppProvider);

    return Scaffold(
      backgroundColor: CouleursApp.fondSombre,
      appBar: AppBar(
        title: Text(
          "Gestion des Textes",
          style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: CouleursApp.secondaire,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: textesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: CouleursApp.primaire)),
        error: (err, _) => Center(
          child: Text("Erreur de chargement : $err", style: const TextStyle(color: Colors.red)),
        ),
        data: (textes) {
          _initialiserControleurs(textes);

          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Modifiez les textes affichés dans l'application. Les champs sont pré-remplis avec les valeurs par défaut.",
                  style: GoogleFonts.inter(color: Colors.white70, fontSize: 15),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: CouleursApp.primaire.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: CouleursApp.primaire.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: CouleursApp.primaire, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "💡 Videz un champ et sauvegardez pour revenir à la valeur par défaut codée en dur.",
                          style: GoogleFonts.inter(color: CouleursApp.primaire, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: ListView.separated(
                    itemCount: _descriptions.length,
                    separatorBuilder: (context, index) => const Divider(color: Colors.white12),
                    itemBuilder: (context, index) {
                      final cle = _descriptions.keys.elementAt(index);
                      final description = _descriptions[cle]!;
                      final controller = _controllers[cle];

                      if (controller == null) return const SizedBox.shrink();

                      // Hauteur adaptée : les conditions utilisent un grand champ
                      final estConditions = cle.startsWith('conditions_');

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    description,
                                    style: GoogleFonts.inter(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                // Bouton "Réinitialiser" pour remettre la valeur par défaut
                                if (_defaults.containsKey(cle))
                                  TextButton.icon(
                                    onPressed: () {
                                      setState(() {
                                        controller.text = _defaults[cle]!;
                                      });
                                    },
                                    icon: const Icon(Icons.refresh, size: 14, color: Colors.white38),
                                    label: Text(
                                      "Réinitialiser",
                                      style: GoogleFonts.inter(color: Colors.white38, fontSize: 11),
                                    ),
                                    style: TextButton.styleFrom(padding: EdgeInsets.zero),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Clé : $cle",
                              style: GoogleFonts.inter(color: Colors.white38, fontSize: 11),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: controller,
                              style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.5),
                              maxLines: estConditions ? 10 : 3,
                              minLines: estConditions ? 6 : 1,
                              decoration: InputDecoration(
                                hintText: "Entrez le texte ici...",
                                hintStyle: const TextStyle(color: Colors.white24),
                                filled: true,
                                fillColor: Colors.white.withValues(alpha: 0.05),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(color: CouleursApp.primaire, width: 1.5),
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: _enCours ? null : () => _sauvegarder(textes),
                    icon: _enCours
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Icon(Icons.save_rounded, color: Colors.white),
                    label: Text(
                      _enCours ? "Sauvegarde en cours..." : "Sauvegarder les modifications",
                      style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: CouleursApp.primaire,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
