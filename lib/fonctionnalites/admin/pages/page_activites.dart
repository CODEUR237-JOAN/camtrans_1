import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import 'package:update_camtrans/coeur/etat/admin_provider.dart';
import 'package:update_camtrans/coeur/constantes/couleurs.dart';
import 'package:update_camtrans/coeur/constantes/statuts.dart';
import 'package:update_camtrans/coeur/widgets/etats_ui.dart';
import 'package:update_camtrans/modeles/course.dart';

class PageActivites extends ConsumerStatefulWidget {
  const PageActivites({super.key});

  @override
  ConsumerState<PageActivites> createState() => _PageActivitesState();
}

class _PageActivitesState extends ConsumerState<PageActivites> {
  String _searchQuery = "";

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
                  error: (err, _) => EtatErreur(erreur: err.toString(), onRetry: () => ref.refresh(adminCoursesProvider)),
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
                        return _CourseCard(course: courses[index])
                            .animate().fadeIn(delay: Duration(milliseconds: 50 * index)).slideX();
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
          Text(
            "Toutes les activités (Temps réel)",
            style: GoogleFonts.inter(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: -1),
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
