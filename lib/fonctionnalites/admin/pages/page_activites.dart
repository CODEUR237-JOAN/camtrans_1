import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../coeur/etat/admin_provider.dart';
import '../../../coeur/constantes/couleurs.dart';
import '../../../coeur/widgets/etats_ui.dart';
import '../../../modeles/course.dart';

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
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text("Toutes les activités (Temps réel)", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Rechercher par adresse ou statut...",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
              onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
            ),
          ),
        ),
      ),
      body: coursesAsync.when(
        loading: () => const EtatChargement(message: "Chargement de l'historique..."),
        error: (err, _) => EtatErreur(
          erreur: err.toString(),
          onRetry: () => ref.refresh(adminCoursesProvider),
        ),
        data: (toutesCourses) {
          final courses = toutesCourses.where((c) {
            final texte = "${c.adresseDepart} ${c.adresseArrivee} ${c.statut}".toLowerCase();
            return texte.contains(_searchQuery);
          }).toList();

          // Trier par date décroissante
          courses.sort((a, b) => b.dateCreation.compareTo(a.dateCreation));

          return courses.isEmpty
              ? const EtatVide(
                  titre: "Aucune activité",
                  message: "Aucune course ne correspond à vos critères.",
                  icone: Icons.history,
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(24),
                  itemCount: courses.length,
                  itemBuilder: (context, index) {
                    final course = courses[index];
                    return _CourseCard(course: course);
                  },
                );
        },
      ),
    );
  }
}

class _CourseCard extends StatelessWidget {
  final Course course;

  const _CourseCard({required this.course});

  Color _getStatutColor(String statut) {
    switch (statut.toLowerCase()) {
      case 'en_attente':
      case 'en attente':
        return Colors.orange;
      case 'en_cours':
      case 'en cours':
        return Colors.blue;
      case 'livree':
      case 'livré':
      case 'terminee':
        return Colors.green;
      case 'annulee':
      case 'annulé':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    final color = _getStatutColor(course.statut);
    final prix = course.prixFinal > 0 ? course.prixFinal : course.prixEstime;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    course.statut.toUpperCase(),
                    style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
                Text(
                  dateFormat.format(course.dateCreation),
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.my_location, color: CouleursApp.primaire, size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text(course.adresseDepart, maxLines: 1, overflow: TextOverflow.ellipsis)),
              ],
            ),
            const Padding(
              padding: EdgeInsets.only(left: 9.0),
              child: SizedBox(height: 15, child: VerticalDivider(color: Colors.grey, thickness: 1)),
            ),
            Row(
              children: [
                const Icon(Icons.location_on, color: Colors.red, size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text(course.adresseArrivee, maxLines: 1, overflow: TextOverflow.ellipsis)),
              ],
            ),
            const Divider(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.person_outline, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text("Client ID: ${course.clientId.length > 8 ? course.clientId.substring(0, 8) : course.clientId}...", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
                Text(
                  "${NumberFormat.compact().format(prix)} FCFA",
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: CouleursApp.succes),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
