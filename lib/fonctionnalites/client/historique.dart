import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:update_camtrans/coeur/constantes/couleurs.dart';
import 'package:update_camtrans/coeur/constantes/tailles.dart';
import 'package:update_camtrans/coeur/etat/course_provider.dart';
import 'package:update_camtrans/modeles/course.dart';

class Historique extends ConsumerStatefulWidget {
  const Historique({super.key});

  @override
  ConsumerState<Historique> createState() => _HistoriqueState();
}

class _HistoriqueState extends ConsumerState<Historique> {
  final TextEditingController _recherche = TextEditingController();
  int _filtreSelectionne = 0;
  final List<String> _filtres = ["Toutes", "En cours", "Livrées", "Annulées"];

  @override
  Widget build(BuildContext context) {
    final coursesAsync = ref.watch(coursesClientProvider);

    return Scaffold(
      backgroundColor: CouleursApp.fond,
      appBar: AppBar(
        title: const Text("Historique des demandes", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: CouleursApp.fond,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(TaillesApp.margePage),
            child: TextField(
              controller: _recherche,
              onChanged: (v) => setState(() {}),
              decoration: InputDecoration(
                hintText: "Rechercher une course...",
                prefixIcon: const Icon(Icons.search, color: CouleursApp.texteSecondaire),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 15),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
              ),
            ),
          ).animate().fadeIn(delay: 100.ms).slideY(begin: -0.1),

          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: TaillesApp.margePage),
              itemCount: _filtres.length,
              itemBuilder: (context, index) {
                return _creerFiltre(index, _filtres[index]);
              },
            ),
          ).animate().fadeIn(delay: 200.ms),

          const SizedBox(height: 15),

          Expanded(
            child: coursesAsync.when(
              data: (courses) {
                // Filtrage
                List<Course> coursesFiltrees = courses.where((c) {
                  // Filtre par statut
                  bool matchFiltre = true;
                  if (_filtreSelectionne == 1) matchFiltre = c.statut != "Livré" && c.statut != "Annulé";
                  if (_filtreSelectionne == 2) matchFiltre = c.statut == "Livré";
                  if (_filtreSelectionne == 3) matchFiltre = c.statut == "Annulé";

                  // Filtre par recherche
                  bool matchRecherche = true;
                  if (_recherche.text.isNotEmpty) {
                    final query = _recherche.text.toLowerCase();
                    matchRecherche = c.description.toLowerCase().contains(query) || 
                                     c.adresseDepart.toLowerCase().contains(query) || 
                                     c.adresseArrivee.toLowerCase().contains(query) ||
                                     c.codeSuivi.toLowerCase().contains(query);
                  }

                  return matchFiltre && matchRecherche;
                }).toList();

                if (coursesFiltrees.isEmpty) {
                  return const Center(child: Text("Aucun résultat trouvé"));
                }

                return ListView.builder(
                  padding: EdgeInsets.all(TaillesApp.margePage),
                  itemCount: coursesFiltrees.length,
                  itemBuilder: (context, index) {
                    final course = coursesFiltrees[index];
                    return _creerCarteCourse(course).animate().fadeIn(delay: (300 + (index * 50)).ms).slideX(begin: 0.1);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text("Erreur: $err")),
            ),
          ),
        ],
      ),
    );
  }

  Widget _creerFiltre(int index, String texte) {
    bool estSelectionne = _filtreSelectionne == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _filtreSelectionne = index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: estSelectionne ? CouleursApp.primaire : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: estSelectionne ? CouleursApp.primaire : Colors.grey.shade300),
          boxShadow: estSelectionne 
            ? [BoxShadow(color: CouleursApp.primaire.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4))] 
            : [],
        ),
        child: Text(
          texte,
          style: TextStyle(
            color: estSelectionne ? Colors.white : CouleursApp.texteSecondaire,
            fontWeight: estSelectionne ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _creerCarteCourse(Course course) {
    Color couleur = Colors.blue;
    IconData icone = Icons.local_shipping_outlined;
    
    if (course.statut == "Livré") {
      couleur = Colors.green;
      icone = Icons.check_circle_outline;
    } else if (course.statut == "Annulé") {
      couleur = Colors.red;
      icone = Icons.cancel_outlined;
    } else if (course.statut == "En cours" || course.statut == "En Transit") {
      couleur = Colors.orange;
      icone = Icons.local_shipping_outlined;
    }

    final dateStr = DateFormat('dd MMMM yyyy', 'fr_FR').format(course.dateCreation);

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 5))
        ]
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
                        "${course.adresseDepart} ➜ ${course.adresseArrivee}",
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 5),
                      Text(dateStr, style: const TextStyle(color: CouleursApp.texteSecondaire, fontSize: 13)),
                    ],
                  ),
                ),
                Text(
                  "${course.prixEstime.toStringAsFixed(0)} FCFA",
                  style: const TextStyle(color: CouleursApp.primaire, fontWeight: FontWeight.w900, fontSize: 15),
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
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                        course.statut,
                        style: TextStyle(color: couleur, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () {
                    context.push("/facture", extra: course);
                  },
                  icon: const Icon(Icons.receipt_long, size: 18),
                  label: const Text("Détails", style: TextStyle(fontWeight: FontWeight.bold)),
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