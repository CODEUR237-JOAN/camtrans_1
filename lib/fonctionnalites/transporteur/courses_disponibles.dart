import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../coeur/constantes/couleurs.dart';
import '../../coeur/etat/transporteur_provider.dart';

class CoursesDisponibles extends ConsumerStatefulWidget {
  const CoursesDisponibles({super.key});

  @override
  ConsumerState<CoursesDisponibles> createState() => _CoursesDisponiblesState();
}

class _CoursesDisponiblesState extends ConsumerState<CoursesDisponibles> {
  final TextEditingController recherche = TextEditingController();
  String filtreActif = "Toutes";

  @override
  Widget build(BuildContext context) {
    final coursesAsync = ref.watch(fluxCoursesDisponiblesProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: AppBar(
        title: const Text("Marché du Fret", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: Column(
        children: [
          // En-tête avec Recherche et Filtres
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: recherche,
                  decoration: InputDecoration(
                    hintText: "Rechercher une destination...",
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  ),
                  onChanged: (val) {
                    setState(() {});
                  },
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _buildFiltre("Toutes"),
                      _buildFiltre("Proche"),
                      _buildFiltre("Longue distance"),
                      _buildFiltre("Urgent"),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 10),

          // Liste des courses
          Expanded(
            child: coursesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text("Erreur de chargement: $err")),
              data: (courses) {
                // Filtrage basique par recherche
                final term = recherche.text.toLowerCase();
                final filtrageRecherche = term.isEmpty 
                  ? courses 
                  : courses.where((c) => c.adresseArrivee.toLowerCase().contains(term) || c.adresseDepart.toLowerCase().contains(term)).toList();
                  
                if (filtrageRecherche.isEmpty) {
                  return const Center(child: Text("Aucune course disponible sur le marché."));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtrageRecherche.length,
                  itemBuilder: (context, index) {
                    final course = filtrageRecherche[index];
                    return _CourseCard(course: course, ref: ref).animate().fadeIn(delay: Duration(milliseconds: 100 * index)).slideY(begin: 0.1);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltre(String titre) {
    bool estSelectionne = titre == filtreActif;
    return GestureDetector(
      onTap: () {
        setState(() {
          filtreActif = titre;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: estSelectionne ? CouleursApp.primaire : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: estSelectionne ? CouleursApp.primaire : Colors.grey.shade300,
          ),
        ),
        child: Center(
          child: Text(
            titre,
            style: TextStyle(
              color: estSelectionne ? Colors.white : Colors.black87,
              fontWeight: estSelectionne ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}

class _CourseCard extends StatelessWidget {
  final dynamic course;
  final WidgetRef ref;

  const _CourseCard({required this.course, required this.ref});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icône
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: CouleursApp.primaire.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: const Icon(Icons.inventory_2, color: CouleursApp.primaire, size: 28),
                ),
                const SizedBox(width: 16),
                
                // Détails centraux
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "${course.adresseDepart} → ${course.adresseArrivee}",
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "${course.typeMarchandise} • ${course.poidsKg} kg",
                        style: const TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.route, size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text("${course.distanceKm} km", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                          const SizedBox(width: 16),
                          const Icon(Icons.schedule, size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          const Text("Immédiat", style: TextStyle(fontSize: 12, color: Colors.grey)), // En dur pour l'instant
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Prix
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      "${course.prixEstime.toStringAsFixed(0)} FCFA",
                      style: const TextStyle(fontWeight: FontWeight.w900, color: CouleursApp.primaire, fontSize: 16),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          const Divider(height: 1, thickness: 1, color: Color(0xFFF0F0F0)),
          
          // Action (Accepter)
          InkWell(
            onTap: () => _confirmerAcceptation(context),
            borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(20), bottomRight: Radius.circular(20)),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xFFF9FAFC),
                borderRadius: BorderRadius.only(bottomLeft: Radius.circular(20), bottomRight: Radius.circular(20)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 20),
                  SizedBox(width: 8),
                  Text("Accepter la course", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 15)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmerAcceptation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirmer l'acceptation"),
        content: Text("Êtes-vous sûr de vouloir accepter cette course vers ${course.adresseArrivee} ?"),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Annuler", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context); // Fermer dialog
              
              // Afficher chargement
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Acceptation en cours...")));
              
              try {
                await ref.read(transporteurActionsProvider).accepterCourse(course.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Course acceptée avec succès !")));
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erreur: $e"), backgroundColor: Colors.red));
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text("Confirmer"),
          ),
        ],
      ),
    );
  }
}