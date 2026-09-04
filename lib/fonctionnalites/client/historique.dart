import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:update_camtrans/coeur/constantes/couleurs.dart';
import 'package:update_camtrans/coeur/constantes/statuts.dart';
import 'package:update_camtrans/coeur/widgets/indicateur_chargement.dart';
import 'package:update_camtrans/coeur/constantes/tailles.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:update_camtrans/coeur/etat/course_provider.dart';
import 'package:update_camtrans/modeles/course.dart';
import 'package:update_camtrans/services/service_authentification.dart';
import 'package:update_camtrans/services/service_firestore.dart';
import 'package:update_camtrans/coeur/widgets/loader_premium.dart';

class Historique extends ConsumerStatefulWidget {
  const Historique({super.key});

  @override
  ConsumerState<Historique> createState() => _HistoriqueState();
}

class _HistoriqueState extends ConsumerState<Historique> {
  final TextEditingController _recherche = TextEditingController();
  int _filtreSelectionne = 0;
  bool _suppressionEnCours = false;
  final List<String> _filtres = ["Toutes", "En cours", "Livrées", "Annulées"];

  bool _peutSupprimer(Course course) =>
      StatutCourse.estTerminee(course.statut);

  Future<void> _supprimerCourse(Course course) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => _DialogConfirmation(
        titre: "Supprimer cette course ?",
        message: "Cette action est irréversible.",
        bouton: "Supprimer",
        couleur: CouleursApp.erreur,
      ),
    );
    if (confirm != true || !mounted) return;
    final firestore = ref.read(serviceFirestoreProvider);
    await firestore.modifierDocument(
        collection: 'courses',
        id: course.id,
        donnees: {'archivePourClient': true});
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Course archivée avec succès"),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _supprimerTout(List<Course> courses) async {
    final terminees = courses.where(_peutSupprimer).toList();
    if (terminees.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Aucune course terminée/annulée à supprimer.")),
      );
      return;
    }
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => _DialogConfirmation(
        titre: "Vider l'historique ?",
        message: "${terminees.length} course(s) terminée(s)/annulée(s) seront supprimées définitivement.",
        bouton: "Tout supprimer",
        couleur: CouleursApp.erreur,
      ),
    );
    if (confirm != true || !mounted) return;
    setState(() => _suppressionEnCours = true);
    try {
      final authService = ref.read(serviceAuthentificationProvider);
      final userId = authService.utilisateur?.uid ?? '';
      final firestore = ref.read(serviceFirestoreProvider);
      final nb = await firestore.supprimerCoursesTerminees(userId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("$nb course(s) supprimée(s)"),
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
    final coursesAsync = ref.watch(coursesClientProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF08111F),
      appBar: AppBar(
        title: const Text("Historique des demandes", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF08111F),
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          coursesAsync.whenOrNull(
            data: (courses) => courses.isNotEmpty
                ? Tooltip(
                    message: "Supprimer les courses terminées/annulées",
                    child: IconButton(
                      icon: _suppressionEnCours
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: LoaderPremium(size: 20),
                            )
                          : const Icon(Icons.delete_sweep_rounded, color: CouleursApp.erreur),
                      onPressed: _suppressionEnCours ? null : () => _supprimerTout(courses),
                    ),
                  )
                : const SizedBox.shrink(),
          ) ?? const SizedBox.shrink(),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(TaillesApp.margePage),
            child: TextField(
              controller: _recherche,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: "Rechercher une course...",
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _recherche.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _recherche.clear();
                          setState(() {});
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: const Color(0xFF1A2640),
              ),
            ),
          ),
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: TaillesApp.margePage),
              itemCount: _filtres.length,
              itemBuilder: (_, i) => _creerFiltre(i, _filtres[i]),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: coursesAsync.when(
              data: (courses) {
                // Exclure les courses archivées par le client (masquage logique)
                List<Course> coursesFiltrees = courses
                    .where((c) => c.archivePourClient != true)
                    .toList();

                if (_recherche.text.isNotEmpty) {
                  final q = _recherche.text.toLowerCase();
                  coursesFiltrees = coursesFiltrees
                      .where((c) =>
                          c.adresseDepart.toLowerCase().contains(q) ||
                          c.adresseArrivee.toLowerCase().contains(q))
                      .toList();
                }

                if (_filtreSelectionne == 1) {
                  coursesFiltrees = coursesFiltrees
                      .where((c) => !StatutCourse.estTerminee(c.statut))
                      .toList();
                } else if (_filtreSelectionne == 2) {
                  coursesFiltrees = coursesFiltrees
                      .where((c) => c.statut == StatutCourse.terminee)
                      .toList();
                } else if (_filtreSelectionne == 3) {
                  coursesFiltrees = coursesFiltrees
                      .where((c) => c.statut == StatutCourse.annulee)
                      .toList();
                }

                if (coursesFiltrees.isEmpty) {
                  return const Center(child: Text("Aucun résultat trouvé"));
                }

                return ListView.builder(
                  padding: EdgeInsets.fromLTRB(TaillesApp.margePage, TaillesApp.margePage, TaillesApp.margePage, 120),
                  itemCount: coursesFiltrees.length,
                  itemBuilder: (context, index) {
                    final course = coursesFiltrees[index];
                    final widget = _creerCarteCourse(course)
                        .animate(delay: (index * 50).ms)
                        .slideX(begin: 0.1);

                    if (_peutSupprimer(course)) {
                      return Dismissible(
                        key: Key(course.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          decoration: BoxDecoration(
                            color: CouleursApp.erreur,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(Icons.delete_rounded, color: Colors.white, size: 30),
                        ),
                        confirmDismiss: (_) async {
                          return await showDialog<bool>(
                            context: context,
                            builder: (_) => _DialogConfirmation(
                              titre: "Supprimer cette course ?",
                              message: "Cette action est irréversible.",
                              bouton: "Supprimer",
                              couleur: CouleursApp.erreur,
                            ),
                          );
                        },
                        onDismissed: (_) async {
                          // Archivage logique — seul le client masque sa vue
                          final firestore = ref.read(serviceFirestoreProvider);
                          await firestore.modifierDocument(
                              collection: 'courses',
                              id: course.id,
                              donnees: {'archivePourClient': true});
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Course archivée"),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        },
                        child: widget,
                      );
                    }
                    return widget;
                  },
                );
              },
              loading: () => const Center(child: IndicateurChargement(taille: 30)),
              error: (err, stack) => Center(child: Text("Oups ! Impossible de charger l'historique : $err 🔧")),
            ),
          ),
        ],
      ),
    );
  }

  Widget _creerFiltre(int index, String texte) {
    bool estSelectionne = _filtreSelectionne == index;
    return GestureDetector(
      onTap: () => setState(() => _filtreSelectionne = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: estSelectionne ? CouleursApp.primaire : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: estSelectionne ? CouleursApp.primaire : Colors.white38),
          boxShadow: estSelectionne
              ? [
                  BoxShadow(
                      color: CouleursApp.primaire.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4))
                ]
              : [],
        ),
        child: Text(
          texte,
          style: TextStyle(
            color: estSelectionne ? Colors.white : CouleursApp.texteSecondaire,
            fontWeight:
                estSelectionne ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _creerCarteCourse(Course course) {
    Color couleur = Colors.blue;
    IconData icone = Icons.local_shipping_outlined;

    if (course.statut == StatutCourse.terminee) {
      couleur = Colors.green;
      icone = Icons.check_circle_outline;
    } else if (course.statut == StatutCourse.annulee) {
      couleur = Colors.red;
      icone = Icons.cancel_outlined;
    } else if (StatutCourse.estActive(course.statut)) {
      couleur = Colors.orange;
      icone = Icons.local_shipping_outlined;
    }

    final dateStr =
        DateFormat('dd MMMM yyyy', 'fr_FR').format(course.dateCreation);

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        color: const Color(0xFF10192A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEEEEEE)),
        boxShadow: [
          BoxShadow(
              color: Colors.white.withValues(alpha: 0.07),
              blurRadius: 10,
              offset: const Offset(0, 5))
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: couleur.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(icone, color: couleur, size: 26),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "${course.adresseDepart}  ${course.adresseArrivee}",
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 5),
                      Text(dateStr,
                          style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13)),
                    ],
                  ),
                ),
                Text(
                  "${course.prixEstime.toStringAsFixed(0)} FCFA",
                  style: const TextStyle(
                      color: CouleursApp.primaire,
                      fontWeight: FontWeight.w900,
                      fontSize: 15),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 15),
              child: Divider(height: 1, color: Color(0xFFEEEEEE)),
            ),
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: couleur.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.circle, color: couleur, size: 10),
                      const SizedBox(width: 6),
                      Text(
                        StatutCourse.libelle(course.statut),
                        style: TextStyle(
                            color: couleur,
                            fontWeight: FontWeight.bold,
                            fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                if (_peutSupprimer(course))
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded,
                        color: CouleursApp.erreur),
                    onPressed: () => _supprimerCourse(course),
                    tooltip: "Supprimer",
                  ),
                TextButton.icon(
                  onPressed: () => context.push("/facture", extra: course),
                  icon: const Icon(Icons.receipt_long, size: 18),
                  label: const Text("Détails",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  style: TextButton.styleFrom(
                    foregroundColor: CouleursApp.primaire,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────
// Dialog de confirmation réutilisable
// ──────────────────────────────────────────────
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
          Text(titre, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: () => Navigator.pop(context, true),
          child: Text(bouton),
        ),
      ],
    );
  }
}
