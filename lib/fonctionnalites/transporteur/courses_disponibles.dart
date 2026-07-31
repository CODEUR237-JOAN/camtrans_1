import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../coeur/constantes/couleurs.dart';
import '../../coeur/etat/transporteur_provider.dart';
import '../../modeles/course.dart';

class CoursesDisponibles extends ConsumerStatefulWidget {
  const CoursesDisponibles({super.key});

  @override
  ConsumerState<CoursesDisponibles> createState() =>
      _CoursesDisponiblesState();
}

class _CoursesDisponiblesState extends ConsumerState<CoursesDisponibles> {
  final TextEditingController recherche = TextEditingController();
  String filtreActif = "Toutes";

  // Filtrage réel des courses
  List<Course> _appliquerFiltres(List<Course> courses) {
    // 1. Filtre texte
    final term = recherche.text.toLowerCase();
    var resultat = term.isEmpty
        ? courses
        : courses
            .where((c) =>
                c.adresseArrivee.toLowerCase().contains(term) ||
                c.adresseDepart.toLowerCase().contains(term) ||
                c.typeMarchandise.toLowerCase().contains(term))
            .toList();

    // 2. Filtre catégorie
    switch (filtreActif) {
      case "Proche":
        // ✅ Courses de moins de 50 km
        resultat = resultat.where((c) => c.distanceKm < 50).toList();
        break;
      case "Longue distance":
        // ✅ Courses de plus de 200 km
        resultat = resultat.where((c) => c.distanceKm >= 200).toList();
        break;
      case "Urgent":
        // ✅ Courses dont la date de transport est dans moins de 4 heures
        final seuilUrgence = DateTime.now().add(const Duration(hours: 4));
        resultat = resultat
            .where((c) =>
                c.dateDebut != null &&
                c.dateDebut!.isBefore(seuilUrgence) &&
                c.dateDebut!.isAfter(DateTime.now()))
            .toList();
        break;
      case "Toutes":
      default:
        break;
    }

    return resultat;
  }

  @override
  void dispose() {
    recherche.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final coursesAsync = ref.watch(fluxCoursesDisponiblesProvider);
    final transporteurAsync = ref.watch(currentTransporteurProvider);
    final documentsValides = transporteurAsync.valueOrNull?.documentsValides ?? false;

    // Blocage complet du marché si les documents ne sont pas validés
    if (!documentsValides && transporteurAsync.valueOrNull != null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF4F7FB),
        appBar: AppBar(
          title: const Text("Marché du Fret",
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
          backgroundColor: Colors.white,
          elevation: 0,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock_outline, size: 80, color: Colors.red.shade300),
                const SizedBox(height: 24),
                const Text(
                  "Accès Restreint",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Text(
                  "Pour accéder aux courses disponibles et commencer à générer des revenus, vos documents doivent d'abord être vérifiés et validés par l'administration.\n\nMerci de patienter.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade600, height: 1.5),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: AppBar(
        title: const Text("Marché du Fret",
            style: TextStyle(
                fontWeight: FontWeight.bold, color: Colors.black87)),
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
                    hintText: "Rechercher ville, type de marchandise...",
                    prefixIcon:
                        const Icon(Icons.search, color: Colors.grey),
                    suffixIcon: recherche.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear,
                                color: Colors.grey),
                            onPressed: () {
                              recherche.clear();
                              setState(() {});
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 0),
                  ),
                  onChanged: (val) => setState(() {}),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _buildFiltre("Toutes"),
                      _buildFiltre("Proche", subtitle: "< 50 km"),
                      _buildFiltre("Longue distance",
                          subtitle: "> 200 km"),
                      _buildFiltre("Urgent", subtitle: "< 4h"),
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
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (err, stack) => _WidgetErreur(
                message: err.toString(),
                onRetry: () =>
                    ref.invalidate(fluxCoursesDisponiblesProvider),
              ),
              data: (courses) {
                final coursesFiltrees = _appliquerFiltres(courses);

                if (courses.isEmpty) {
                  return const _WidgetVideMarche();
                }

                if (coursesFiltrees.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.filter_list_off,
                            size: 60,
                            color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text(
                          "Aucune course pour ce filtre",
                          style: TextStyle(
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () => setState(() {
                            filtreActif = "Toutes";
                            recherche.clear();
                          }),
                          child: const Text("Réinitialiser les filtres"),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: coursesFiltrees.length,
                  itemBuilder: (context, index) {
                    final course = coursesFiltrees[index];
                    return _CourseCard(course: course, ref: ref)
                        .animate()
                        .fadeIn(delay: Duration(milliseconds: 80 * index))
                        .slideY(begin: 0.1);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltre(String titre, {String? subtitle}) {
    bool estSelectionne = titre == filtreActif;
    return GestureDetector(
      onTap: () => setState(() => filtreActif = titre),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color:
              estSelectionne ? CouleursApp.primaire : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: estSelectionne
                ? CouleursApp.primaire
                : Colors.grey.shade300,
          ),
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                titre,
                style: TextStyle(
                  color:
                      estSelectionne ? Colors.white : Colors.black87,
                  fontWeight: estSelectionne
                      ? FontWeight.bold
                      : FontWeight.normal,
                  fontSize: 13,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(width: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: estSelectionne
                        ? Colors.white70
                        : Colors.grey.shade500,
                    fontSize: 11,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================================
// WIDGET D'ERREUR avec bouton Réessayer
// ==========================================
class _WidgetErreur extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _WidgetErreur({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.wifi_off_rounded,
                size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 20),
            const Text(
              "Problème de connexion",
              style:
                  TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              message.length > 100
                  ? "${message.substring(0, 100)}..."
                  : message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text("Réessayer"),
              style: ElevatedButton.styleFrom(
                backgroundColor: CouleursApp.primaire,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// WIDGET MARCHÉ VIDE
// ==========================================
class _WidgetVideMarche extends StatelessWidget {
  const _WidgetVideMarche();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.local_shipping_outlined,
              size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 20),
          const Text(
            "Aucune course disponible",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            "Revenez plus tard, de nouvelles courses\nseront ajoutées prochainement.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// CARTE DE COURSE
// ==========================================
class _CourseCard extends StatelessWidget {
  final Course course;
  final WidgetRef ref;

  const _CourseCard({required this.course, required this.ref});

  @override
  Widget build(BuildContext context) {
    final bool estUrgent = course.dateDebut != null &&
        course.dateDebut!.difference(DateTime.now()).inHours < 4 &&
        course.dateDebut!.isAfter(DateTime.now());

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: estUrgent
            ? Border.all(color: Colors.orange.shade300, width: 1.5)
            : null,
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
                  child: const Icon(Icons.inventory_2,
                      color: CouleursApp.primaire, size: 28),
                ),
                const SizedBox(width: 16),

                // Détails centraux
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (estUrgent)
                        Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.bolt,
                                  size: 12,
                                  color: Colors.orange.shade700),
                              const SizedBox(width: 4),
                              Text(
                                "URGENT",
                                style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange.shade700),
                              ),
                            ],
                          ),
                        ),
                      Text(
                        "${course.adresseDepart} → ${course.adresseArrivee}",
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "${course.typeMarchandise} • ${course.poidsKg.toStringAsFixed(0)} kg",
                        style: const TextStyle(
                            color: Colors.grey, fontSize: 13),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.route,
                              size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            "${course.distanceKm.toStringAsFixed(0)} km",
                            style: const TextStyle(
                                fontSize: 12, color: Colors.grey),
                          ),
                          if (course.dateDebut != null) ...[
                            const SizedBox(width: 16),
                            const Icon(Icons.schedule,
                                size: 14, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(
                              _formaterDate(course.dateDebut!),
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                // Prix
                Text(
                  "${course.prixEstime.toStringAsFixed(0)} FCFA",
                  style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      color: CouleursApp.primaire,
                      fontSize: 15),
                ),
              ],
            ),
          ),

          const Divider(height: 1, thickness: 1, color: Color(0xFFF0F0F0)),

          // Action (Accepter)
          InkWell(
            onTap: () => _confirmerAcceptation(context),
            borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20)),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xFFF9FAFC),
                borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 20),
                  SizedBox(width: 8),
                  Text("Accepter la course",
                      style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                          fontSize: 15)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formaterDate(DateTime date) {
    final diff = date.difference(DateTime.now());
    if (diff.inHours < 1) {
      return "Dans ${diff.inMinutes} min";
    } else if (diff.inHours < 24) {
      return "Dans ${diff.inHours}h";
    } else {
      return "${date.day}/${date.month}/${date.year}";
    }
  }

  void _confirmerAcceptation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirmer l'acceptation"),
        content: Text(
            "Êtes-vous sûr de vouloir accepter la course vers ${course.adresseArrivee} pour ${course.prixEstime.toStringAsFixed(0)} FCFA ?"),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Annuler",
                style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);

              try {
                await ref
                    .read(transporteurActionsProvider)
                    .accepterCourse(course.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.white),
                          SizedBox(width: 8),
                          Text("Course acceptée ! Bonne route 🚛"),
                        ],
                      ),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(e.toString().replaceAll('Exception: ', '')),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text("Confirmer"),
          ),
        ],
      ),
    );
  }
}