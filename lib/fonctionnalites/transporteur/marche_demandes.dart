import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:update_camtrans/coeur/constantes/couleurs.dart';
import 'package:update_camtrans/coeur/constantes/statuts.dart';
import 'package:update_camtrans/coeur/etat/transporteur_provider.dart';
import 'package:update_camtrans/modeles/course.dart';
import 'package:update_camtrans/coeur/widgets/loader_premium.dart';

class MarcheDemandes extends ConsumerStatefulWidget {
  const MarcheDemandes({super.key});

  @override
  ConsumerState<MarcheDemandes> createState() => _MarcheDemandesState();
}

class _MarcheDemandesState extends ConsumerState<MarcheDemandes> {
  bool _isProcessing = false;

  /// Accepte une course via une transaction Firestore atomique.
  /// Cela garantit qu'un seul transporteur peut accepter la course,
  /// même en cas de tentatives simultanées (corrige le bug de double-acceptation).
  Future<void> _accepterCourse(Course course) async {
    final transporteur = ref.read(currentTransporteurProvider).valueOrNull;
    if (transporteur == null) return;

    final confirmation = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF10192A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: CouleursApp.primaire.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Iconsax.truck_copy, color: CouleursApp.primaire, size: 20),
            ),
            const SizedBox(width: 12),
            Text(
              "Accepter la course",
              style: GoogleFonts.inter(
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontSize: 16,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Vous êtes sur le point d'accepter cette course.",
              style: GoogleFonts.inter(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: CouleursApp.primaire.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: CouleursApp.primaire.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.attach_money, color: CouleursApp.accent, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    "${course.prixEstime.toInt()} FCFA",
                    style: GoogleFonts.inter(
                      color: CouleursApp.accent,
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "⚡ Cette action est immédiate et sécurisée.",
              style: GoogleFonts.inter(color: Colors.white38, fontSize: 11),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text("Annuler", style: GoogleFonts.inter(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: CouleursApp.primaire,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(
              "Oui, j'accepte !",
              style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirmation != true) return;

    setState(() => _isProcessing = true);
    HapticFeedback.mediumImpact();

    try {
      // ✅ CORRECTION BUG 1.1: Utilisation d'une transaction atomique Firestore
      // pour éviter la double-acceptation simultanée par deux transporteurs.
      final docRef = FirebaseFirestore.instance.collection('courses').doc(course.id);

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final snapshot = await transaction.get(docRef);

        if (!snapshot.exists || snapshot.data() == null) {
          throw Exception("Course introuvable.");
        }

        final data = snapshot.data()!;
        // Vérification atomique : la course doit encore être en recherche
        // et ne pas avoir de transporteur assigné
        if (data['statut'] != StatutCourse.recherche ||
            (data['transporteurId'] != null && (data['transporteurId'] as String).isNotEmpty)) {
          throw Exception("Cette course vient d'être acceptée par quelqu'un d'autre. 😅");
        }

        // Attribution atomique
        transaction.update(docRef, {
          'transporteurId': transporteur.id,
          'nomTransporteur': '${transporteur.prenom} ${transporteur.nom}',
          'telephoneTransporteur': transporteur.telephone,
          'statut': StatutCourse.attribue,
        });
      });

      HapticFeedback.heavyImpact();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text("Super ! Course acceptée 🎉", style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
              ],
            ),
            backgroundColor: CouleursApp.succes,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Oups ! ${e.toString().replaceAll('Exception: ', '')} 🔧"),
            backgroundColor: CouleursApp.erreur,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final coursesAsync = ref.watch(fluxCoursesDisponiblesProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF08111F),
      appBar: AppBar(
        // ✅ CORRECTION BUG: foregroundColor blanc (était noir sur fond noir)
        title: Text(
          "Marché des demandes",
          style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF08111F),
        elevation: 0,
        foregroundColor: Colors.white,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: CouleursApp.accent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: CouleursApp.accent.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(color: CouleursApp.accent, shape: BoxShape.circle),
                ),
                const SizedBox(width: 6),
                Text(
                  "EN LIGNE",
                  style: GoogleFonts.inter(color: CouleursApp.accent, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          coursesAsync.when(
            loading: () => Center(child: LoaderPremium()),
            error: (err, _) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.wifi_off_rounded, size: 60, color: Colors.white38),
                  const SizedBox(height: 16),
                  Text(
                    "Mince ! Problème réseau 📡",
                    style: GoogleFonts.inter(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Vérifiez votre connexion et réessayez",
                    style: GoogleFonts.inter(color: Colors.white38, fontSize: 13),
                  ),
                ],
              ),
            ),
            data: (courses) {
              if (courses.isEmpty) {
                // ✅ HUMANISATION 3.3: État vide chaleureux et motivant
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: CouleursApp.primaire.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                            border: Border.all(color: CouleursApp.primaire.withValues(alpha: 0.2), width: 2),
                          ),
                          child: const Icon(Iconsax.box_search, size: 48, color: CouleursApp.primaire),
                        ).animate(onPlay: (c) => c.repeat(reverse: true))
                          .scale(begin: const Offset(1, 1), end: const Offset(1.05, 1.05), duration: 2.seconds),
                        const SizedBox(height: 24),
                        Text(
                          "Le calme avant la tempête ☕",
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          "Aucune demande disponible pour l'instant. Restez disponible — votre prochaine course arrive bientôt !",
                          style: GoogleFonts.inter(color: Colors.white54, fontSize: 14, height: 1.5),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.refresh_rounded, size: 16, color: Colors.white38),
                              const SizedBox(width: 6),
                              Text(
                                "Mise à jour automatique en temps réel",
                                style: GoogleFonts.inter(color: Colors.white38, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: courses.length,
                itemBuilder: (context, index) {
                  final course = courses[index];
                  return _buildCourseCard(course, index);
                },
              );
            },
          ),
          if (_isProcessing)
            Container(
              color: Colors.black54,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10192A),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white12),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 30)],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const LoaderPremium(size: 24),
                      const SizedBox(height: 16),
                      Text(
                        "Attribution en cours...",
                        style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Sécurisation de la course 🔐",
                        style: GoogleFonts.inter(color: Colors.white54, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCourseCard(Course course, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF10192A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: CouleursApp.primaire.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête : type + prix
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: CouleursApp.primaire.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: CouleursApp.primaire.withValues(alpha: 0.25)),
                  ),
                  child: Text(
                    course.typeMarchandise.isNotEmpty ? course.typeMarchandise : "Marchandise",
                    style: GoogleFonts.inter(color: CouleursApp.primaire, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      "${course.prixEstime.toInt()} FCFA",
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w800,
                        fontSize: 20,
                        color: CouleursApp.accent,
                      ),
                    ),
                    Text(
                      "${course.distanceKm.toStringAsFixed(1)} km",
                      style: GoogleFonts.inter(color: Colors.white38, fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Itinéraire
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(color: CouleursApp.primaire, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          course.adresseDepart,
                          style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Column(
                      children: List.generate(3, (_) => Container(
                        width: 2,
                        height: 4,
                        margin: const EdgeInsets.symmetric(vertical: 2),
                        color: Colors.white24,
                      )),
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: CouleursApp.accent,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          course.adresseArrivee,
                          style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Chips info
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (course.typeVehicule.isNotEmpty)
                  _buildInfoChip(Iconsax.truck_copy, course.typeVehicule),
                if (course.volumeM3 > 0)
                  _buildInfoChip(Icons.view_in_ar_rounded, "${course.volumeM3.toStringAsFixed(1)} m³"),
                if (course.poidsKg > 0)
                  _buildInfoChip(Icons.scale_rounded, "${course.poidsKg.toStringAsFixed(0)} kg"),
                if (course.fragile) _buildOptionChip("⚠️ Fragile", Colors.orange),
                if (course.aideChargement) _buildOptionChip("🤝 Aide chargement", Colors.blue),
                if (course.aideDechargement) _buildOptionChip("🤝 Aide déchargement", Colors.blue),
              ],
            ),

            const SizedBox(height: 16),

            // Bouton accepter
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _accepterCourse(course),
                style: ElevatedButton.styleFrom(
                  backgroundColor: CouleursApp.primaire,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: 0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      "Accepter cette course",
                      style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 15),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: (index * 80).ms, duration: 300.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: Colors.white54),
          const SizedBox(width: 5),
          Text(label, style: GoogleFonts.inter(fontSize: 12, color: Colors.white54)),
        ],
      ),
    );
  }

  Widget _buildOptionChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(fontSize: 12, color: color, fontWeight: FontWeight.bold),
      ),
    );
  }
}
