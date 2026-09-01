import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:update_camtrans/coeur/constantes/couleurs.dart';
import 'package:update_camtrans/coeur/constantes/statuts.dart';
import 'package:update_camtrans/coeur/etat/transporteur_provider.dart';
import 'package:update_camtrans/modeles/course.dart';
import 'package:update_camtrans/services/service_firestore.dart';

class MarcheDemandes extends ConsumerStatefulWidget {
  const MarcheDemandes({super.key});

  @override
  ConsumerState<MarcheDemandes> createState() => _MarcheDemandesState();
}

class _MarcheDemandesState extends ConsumerState<MarcheDemandes> {
  bool _isProcessing = false;

  Future<void> _accepterCourse(Course course) async {
    final transporteur = ref.read(currentTransporteurProvider).valueOrNull;
    if (transporteur == null) return;

    final confirmation = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Accepter la course"),
        content: Text("Voulez-vous accepter cette course de ${course.prixEstime.toInt()} F ?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Annuler"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: CouleursApp.primaire),
            child: const Text("Accepter"),
          ),
        ],
      ),
    );

    if (confirmation != true) return;

    setState(() => _isProcessing = true);

    try {
      final db = ref.read(serviceFirestoreProvider);
      await db.modifierDocument(
        collection: 'courses',
        id: course.id,
        donnees: {
          'transporteurId': transporteur.id,
          'statut': StatutCourse.attribue,
        },
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Course acceptée avec succès !")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Oups ! Impossible d'accepter la course : $e 🔧")),
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
        title: Text("Marché des demandes", style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF08111F),
        elevation: 0,
        foregroundColor: Colors.black87,
      ),
      body: Stack(
        children: [
          coursesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator(color: CouleursApp.primaire)),
            error: (err, _) => Center(child: Text("Mince ! Problème réseau : $err 📡", style: const TextStyle(color: Colors.red))),
            data: (courses) {
              if (courses.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Iconsax.box_search, size: 80, color: Colors.white38),
                      const SizedBox(height: 16),
                      Text("Aucune demande disponible pour le moment. Allez prendre un café ! ☕", style: GoogleFonts.inter(color: Colors.white38, fontSize: 16)),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: courses.length,
                itemBuilder: (context, index) {
                  final course = courses[index];
                  return Card(
                    elevation: 2,
                    margin: const EdgeInsets.only(bottom: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                                  color: CouleursApp.primaire.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  course.typeMarchandise,
                                  style: const TextStyle(color: CouleursApp.primaire, fontWeight: FontWeight.bold),
                                ),
                              ),
                              Text(
                                "${course.prixEstime.toInt()} F",
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.green),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              const Icon(Icons.location_on, color: Colors.white54, size: 20),
                              const SizedBox(width: 8),
                              Expanded(child: Text(course.adresseDepart, style: const TextStyle(fontSize: 14))),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.flag, color: Colors.white54, size: 20),
                              const SizedBox(width: 8),
                              Expanded(child: Text(course.adresseArrivee, style: const TextStyle(fontSize: 14))),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _buildInfoChip(Icons.directions_car, course.typeVehicule.isNotEmpty ? course.typeVehicule : "Camion standard"),
                              _buildInfoChip(Icons.route, "${course.distanceKm.toStringAsFixed(1)} km"),
                              if (course.volumeM3 > 0) _buildInfoChip(Icons.view_in_ar, "${course.volumeM3.toStringAsFixed(1)} m³"),
                              if (course.poidsKg > 0) _buildInfoChip(Icons.scale, "${course.poidsKg.toStringAsFixed(1)} kg"),
                            ],
                          ),
                          if (course.fragile || course.aideChargement || course.aideDechargement)
                            Padding(
                              padding: const EdgeInsets.only(top: 12.0),
                              child: Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  if (course.fragile) _buildOptionChip("Fragile", Colors.orange),
                                  if (course.aideChargement) _buildOptionChip("Aide chargement", Colors.blue),
                                  if (course.aideDechargement) _buildOptionChip("Aide déchargement", Colors.blue),
                                ],
                              ),
                            ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () => _accepterCourse(course),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: CouleursApp.primaire,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              child: const Text("Accepter cette course", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
          if (_isProcessing)
            Container(
              color: Colors.white54,
              child: const Center(
                child: CircularProgressIndicator(color: CouleursApp.primaire),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white38),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 12, color: Colors.white38)),
        ],
      ),
    );
  }

  Widget _buildOptionChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(label, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.bold)),
    );
  }
}
