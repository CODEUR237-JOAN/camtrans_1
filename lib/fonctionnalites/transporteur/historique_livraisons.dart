import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:update_camtrans/coeur/constantes/couleurs.dart';
import 'package:update_camtrans/coeur/constantes/statuts.dart';
import 'package:update_camtrans/coeur/constantes/tailles.dart';
import 'package:update_camtrans/coeur/etat/transporteur_provider.dart';
import 'package:update_camtrans/modeles/course.dart';
import 'package:update_camtrans/services/service_authentification.dart';
import 'package:update_camtrans/services/service_firestore.dart';
import 'package:update_camtrans/coeur/widgets/loader_premium.dart';

class HistoriqueLivraisons extends ConsumerStatefulWidget {
  const HistoriqueLivraisons({super.key});

  @override
  ConsumerState<HistoriqueLivraisons> createState() =>
      _HistoriquelivraisonsState();
}

class _HistoriquelivraisonsState
    extends ConsumerState<HistoriqueLivraisons> {
  bool _suppressionEnCours = false;

  bool _peutSupprimer(Course course) =>
      StatutCourse.estTerminee(course.statut);

  Future<void> _supprimerTout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => _DialogConfirmation(
        titre: "Vider l'historique ?",
        message: "Toutes vos livraisons terminées/annulées seront supprimées définitivement.",
        bouton: "Tout supprimer",
        couleur: CouleursApp.erreur,
      ),
    );
    if (confirm != true || !mounted) return;
    setState(() => _suppressionEnCours = true);
    try {
      final userId =
          ref.read(serviceAuthentificationProvider).utilisateur?.uid ?? '';
      final nb = await ref
          .read(serviceFirestoreProvider)
          .supprimerCoursesTerminees(userId, estClient: false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("$nb livraison(s) supprimée(s)"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _suppressionEnCours = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final coursesAsync = ref.watch(fluxMesCoursesProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF08111F),
      appBar: AppBar(
        title: const Text("Historique des livraisons"),
        backgroundColor: const Color(0xFF08111F),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white70),
        titleTextStyle: const TextStyle(
            color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 18),
        actions: [
          Tooltip(
            message: "Supprimer les livraisons terminées/annulées",
            child: IconButton(
              icon: _suppressionEnCours
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: LoaderPremium(size: 20))
                  : const Icon(Icons.delete_sweep_rounded,
                      color: CouleursApp.erreur),
              onPressed: _suppressionEnCours ? null : _supprimerTout,
            ),
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(TaillesApp.margePage),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: CouleursApp.degradePrincipal,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                children: [
                  Icon(Icons.history, color: Colors.white, size: 45),
                  SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Historique",
                            style: TextStyle(color: Colors.white70)),
                        SizedBox(height: 6),
                        Text(
                          "Glissez vers la gauche pour supprimer une livraison terminée.",
                          style: TextStyle(color: Colors.white, fontSize: 14),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 25),
            Expanded(
              child: coursesAsync.when(
                loading: () => Center(child: LoaderPremium()),
                error: (error, _) =>
                    Center(child: Text("Impossible de charger l'historique : $error 🔧")),
                data: (courses) {
                  // Exclure les courses archivées côté transporteur (swipe suppression logique)
                  final coursesVisibles = courses
                      .where((c) => c.archivePourTransporteur != true)
                      .toList();
                  if (coursesVisibles.isEmpty) {
                    return const Center(
                        child:
                            Text("Aucune livraison complétée. C'est le moment de prendre la route ! 🚚"));
                  }

                  return ListView.builder(
                    itemCount: coursesVisibles.length,
                    itemBuilder: (context, index) {
                      final course = coursesVisibles[index];
                      final peutSuppr = _peutSupprimer(course);
                      final card = Card(
                        elevation: 3,
                        margin: const EdgeInsets.only(bottom: 15),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18)),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          leading: CircleAvatar(
                            radius: 28,
                            backgroundColor: peutSuppr
                                ? Colors.green.withValues(alpha: 0.2)
                                : Colors.orange.withValues(alpha: 0.2),
                            child: Icon(
                              peutSuppr
                                  ? Icons.check_circle
                                  : Icons.local_shipping,
                              color: peutSuppr
                                  ? Colors.green
                                  : Colors.orange,
                            ),
                          ),
                          title: Text(
                            "${course.adresseDepart} → ${course.adresseArrivee}",
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 13),
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 6),
                              Text(DateFormat('dd MMMM yyyy')
                                  .format(course.dateCreation)),
                              Text(
                                StatutCourse.libelle(course.statut)
                                    .toUpperCase(),
                                style: TextStyle(
                                    color: peutSuppr
                                        ? Colors.green
                                        : Colors.orange,
                                    fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "${course.prixFinal > 0 ? course.prixFinal : course.prixEstime} F",
                                style: const TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              const Icon(Icons.arrow_forward_ios, size: 16),
                            ],
                          ),
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text(
                                        "Détails bientôt disponibles.")));
                          },
                        ),
                      );

                      if (peutSuppr) {
                        return Dismissible(
                          key: Key(course.id),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            margin: const EdgeInsets.only(bottom: 15),
                            decoration: BoxDecoration(
                              color: CouleursApp.erreur,
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: const Icon(Icons.delete_rounded,
                                color: Colors.white, size: 30),
                          ),
                          confirmDismiss: (_) async {
                            return await showDialog<bool>(
                              context: context,
                              builder: (_) => _DialogConfirmation(
                                titre: "Supprimer cette livraison ?",
                                message: "Cette action est irréversible.",
                                bouton: "Supprimer",
                                couleur: CouleursApp.erreur,
                              ),
                            );
                          },
                          onDismissed: (_) async {
                            // On n'efface pas la course (données métier protégées).
                            // On la masque côté transporteur avec un flag d'archivage.
                            await ref
                                .read(serviceFirestoreProvider)
                                .modifierDocument(
                                    collection: 'courses',
                                    id: course.id,
                                    donnees: {'archivePourTransporteur': true});
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Livraison archivée"),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          },
                          child: card,
                        );
                      }
                      return card;
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DialogConfirmation extends StatelessWidget {
  final String titre;
  final String message;
  final String bouton;
  final Color couleur;

  const _DialogConfirmation({
    required this.titre,
    required this.message,
    required this.bouton,
    required this.couleur,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: couleur),
          const SizedBox(width: 10),
          Expanded(
            child: Text(titre,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ],
      ),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text("Annuler"),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: couleur,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: () => Navigator.pop(context, true),
          child: Text(bouton),
        ),
      ],
    );
  }
}