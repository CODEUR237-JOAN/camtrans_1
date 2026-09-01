import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:go_router/go_router.dart';

import 'package:update_camtrans/coeur/etat/admin_provider.dart';
import 'package:update_camtrans/coeur/constantes/couleurs.dart';
import 'package:update_camtrans/coeur/constantes/statuts.dart';
import 'package:update_camtrans/coeur/widgets/etats_ui.dart';
import 'package:update_camtrans/modeles/course.dart';
import 'package:update_camtrans/services/service_firestore.dart';
import 'package:flutter_animate/flutter_animate.dart';


class PageActivites extends ConsumerStatefulWidget {
  const PageActivites({super.key});

  @override
  ConsumerState<PageActivites> createState() => _PageActivitesState();
}

class _PageActivitesState extends ConsumerState<PageActivites> {
  String _searchQuery = "";
  bool _purgerEnCours = false;

  Future<void> _purgerHistorique() async {
    // Double confirmation : dialog + saisie
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => _DialogPurge(),
    );
    if (confirm != true || !mounted) return;
    setState(() => _purgerEnCours = true);
    try {
      final nb = await ref.read(serviceFirestoreProvider).purgerHistoriqueGlobal();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("$nb course(s) purgée(s) avec succès"),
            backgroundColor: Colors.green,
          ),
        );
        final _ = ref.refresh(adminCoursesProvider);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Aïe, impossible de purger l'historique : $e 🧹"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _purgerEnCours = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final coursesAsync = ref.watch(adminCoursesProvider);

    return Scaffold(
      backgroundColor: Colors.transparent, // Background handled by parent or stack
      body: Stack(
        children: [
          Container(color: const Color(0xFF08111F)),
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                color: CouleursApp.succes.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
            ).animate(onPlay: (controller) => controller.repeat(reverse: true)).scale(duration: 4.seconds, begin: const Offset(1,1), end: const Offset(1.2,1.2)),
          ),
          
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              Expanded(
                child: coursesAsync.when(
                  loading: () => const EtatChargement(message: "Chargement de l'historique..."),
                  error: (err, _) => EtatErreur(erreur: "Impossible de charger les activités : ${err.toString()} 🔧", onRetry: () => ref.refresh(adminCoursesProvider)),
                  data: (toutesCourses) {
                    final courses = toutesCourses.where((c) {
                      final texte = "${c.adresseDepart} ${c.adresseArrivee} ${c.statut}".toLowerCase();
                      return texte.contains(_searchQuery);
                    }).toList();

                    courses.sort((a, b) => b.dateCreation.compareTo(a.dateCreation));

                    if (courses.isEmpty) {
                      return Center(child: Text("Aucune activité ne correspond à vos critères.", style: GoogleFonts.inter(color: Colors.white54)));
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      itemCount: courses.length,
                      itemBuilder: (context, index) {
                        final course = courses[index];
                        final estTerminee = StatutCourse.estTerminee(course.statut);
                        final card = _CourseCard(course: course)
                            .animate(delay: (index * 50).ms).slideX();

                        if (estTerminee) {
                          return Dismissible(
                            key: Key(course.id),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 24),
                              margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                color: Colors.red.shade700,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.delete_forever_rounded, color: Colors.white, size: 32),
                                  SizedBox(height: 4),
                                  Text("Supprimer", style: TextStyle(color: Colors.white, fontSize: 12)),
                                ],
                              ),
                            ),
                            confirmDismiss: (_) async {
                              return await showDialog<bool>(
                                context: context,
                                builder: (_) => AlertDialog(
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                  title: const Text("Supprimer cette course ?", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                  content: const Text("Cette action est irréversible."),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Annuler")),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                                      onPressed: () => Navigator.pop(context, true),
                                      child: const Text("Supprimer"),
                                    ),
                                  ],
                                ),
                              );
                            },
                            onDismissed: (_) async {
                              await ref.read(serviceFirestoreProvider)
                                  .supprimerDocument(collection: 'courses', id: course.id);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                   SnackBar(content: Text("L'historique a été nettoyé avec succès ! ✨"), backgroundColor: CouleursApp.succes),
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
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.only(left: 32, right: 32, top: 32, bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  "Toutes les activités (Temps réel)",
                  style: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: -1),
                ),
              ),
              // Bouton Purge Admin
              Tooltip(
                message: "Purger l'historique terminé/annulé",
                child: ElevatedButton.icon(
                  onPressed: _purgerEnCours ? null : _purgerHistorique,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade800,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  icon: _purgerEnCours
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.cleaning_services_rounded, size: 18),
                  label: Text(_purgerEnCours ? "Purge..." : "Purger", style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: TextField(
              style: GoogleFonts.inter(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Rechercher par adresse ou statut...",
                hintStyle: GoogleFonts.inter(color: Colors.white54),
                prefixIcon: const Icon(Iconsax.search_normal_copy, color: Colors.white54, size: 20),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────
// Dialog de double-confirmation pour la purge admin
// ─────────────────────────────────────────────────
class _DialogPurge extends StatefulWidget {
  @override
  State<_DialogPurge> createState() => _DialogPurgeState();
}

class _DialogPurgeState extends State<_DialogPurge> {
  final _ctrl = TextEditingController();
  bool get _valid => _ctrl.text.trim() == 'CONFIRMER';

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.red.shade700),
          const SizedBox(width: 10),
          const Expanded(
            child: Text("Purge globale de l'historique",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "️ Cette action va supprimer définitivement TOUTES les courses terminées et annulées de TOUS les utilisateurs.",
          ),
          const SizedBox(height: 16),
          const Text(
            'Tapez CONFIRMER pour valider :',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _ctrl,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'CONFIRMER',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onChanged: (_) => setState(() {}),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text("Annuler"),
        ),
        ValueListenableBuilder(
          valueListenable: _ctrl,
          builder: (context, value, child) => ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _valid ? Colors.red.shade700 : Colors.grey,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: _valid ? () => Navigator.pop(context, true) : null,
            child: const Text("Purger"),
          ),
        ),
      ],
    );
  }
}

class _CourseCard extends StatelessWidget {
  final Course course;

  const _CourseCard({required this.course});

  Color _getStatutColor(String statut) {
    if (statut == StatutCourse.recherche) return Colors.orange;
    if (statut == StatutCourse.attribue) return Colors.blue.shade300;
    if (statut == StatutCourse.enRouteDepart) return CouleursApp.primaire;
    if (statut == StatutCourse.enTransit) return Colors.indigo;
    if (statut == StatutCourse.arriveDepart) return Colors.purpleAccent;
    if (statut == StatutCourse.arriveDestination || statut == StatutCourse.terminee) return CouleursApp.succes;
    if (statut == StatutCourse.annulee) return CouleursApp.erreur;
    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    final color = _getStatutColor(course.statut);
    final prix = course.prixFinal > 0 ? course.prixFinal : course.prixEstime;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    StatutCourse.libelle(course.statut).toUpperCase(),
                    style: GoogleFonts.inter(color: color, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
                Text(
                  dateFormat.format(course.dateCreation),
                  style: GoogleFonts.inter(color: Colors.white54, fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: CouleursApp.primaire.withValues(alpha: 0.15), shape: BoxShape.circle),
                  child: const Icon(Iconsax.location_copy, color: CouleursApp.primaire, size: 16),
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(course.adresseDepart, style: GoogleFonts.inter(color: Colors.white), maxLines: 1, overflow: TextOverflow.ellipsis)),
              ],
            ),
            Container(
              height: 20,
              width: 2,
              margin: const EdgeInsets.only(left: 15),
              color: Colors.white.withValues(alpha: 0.1),
            ),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: CouleursApp.erreur.withValues(alpha: 0.15), shape: BoxShape.circle),
                  child: const Icon(Iconsax.routing_2_copy, color: CouleursApp.erreur, size: 16),
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(course.adresseArrivee, style: GoogleFonts.inter(color: Colors.white), maxLines: 1, overflow: TextOverflow.ellipsis)),
              ],
            ),
            const SizedBox(height: 20),
            Divider(color: Colors.white.withValues(alpha: 0.1), height: 1),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Iconsax.user_copy, size: 16, color: Colors.white54),
                    const SizedBox(width: 8),
                    Text("Client: ${course.clientId.length > 8 ? course.clientId.substring(0, 8) : course.clientId}...", style: GoogleFonts.inter(color: Colors.white54, fontSize: 12)),
                  ],
                ),
                Text(
                  "${NumberFormat.compact().format(prix)} FCFA",
                  style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 18, color: CouleursApp.succes),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Bouton "Suivre en direct"
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  context.push('/suivi/${course.id}');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: CouleursApp.primaire.withValues(alpha: 0.2),
                  foregroundColor: CouleursApp.primaire,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                icon: const Icon(Iconsax.radar_2_copy),
                label: const Text("Suivre en direct", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
