import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:update_camtrans/coeur/etat/admin_provider.dart';
import 'package:update_camtrans/coeur/constantes/couleurs.dart';
import 'package:update_camtrans/modeles/transporteur.dart';
import 'package:update_camtrans/modeles/course.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:update_camtrans/coeur/utilitaires/telechargement/telechargement.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;


class PageVueEnsemble extends ConsumerWidget {
  const PageVueEnsemble({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(adminStatsProvider);
    final weeklyRevenuesAsync = ref.watch(adminWeeklyRevenuesProvider);
    final transporteursAsync = ref.watch(adminTransporteursProvider);
    final isSatellite = ref.watch(isSatelliteViewProvider);
    final distributionAsync = ref.watch(adminCourseDistributionProvider);
    final activitiesAsync = ref.watch(adminRecentActivitiesProvider);
    final pendingApprovalsAsync = ref.watch(adminPendingApprovalsCountProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF08111F),
      body: Stack(
        children: [
          // Effets lumineux de fond (Blobs)
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                color: CouleursApp.primaire.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
            ).animate(onPlay: (controller) => controller.repeat(reverse: true)).scale(begin: const Offset(1, 1), end: const Offset(1.2, 1.2), duration: 4.seconds),
          ),
          Positioned(
            bottom: -50,
            right: -50,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                color: CouleursApp.secondaire.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
            ).animate(onPlay: (controller) => controller.repeat(reverse: true)).scale(begin: const Offset(1, 1), end: const Offset(1.3, 1.3), duration: 5.seconds),
          ),
          
          statsAsync.when(
            loading: () => const _SkeletonVueEnsemble(),
            error: (err, _) => Center(child: Text("Oups ! Chargement des stats impossible : $err 🔧", style: const TextStyle(color: Colors.white))),
            data: (stats) {
              return SingleChildScrollView(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Aperçu Global",
                              style: GoogleFonts.inter(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: -1),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              "Tableau de bord de gestion CamTrans",
                              style: GoogleFonts.inter(fontSize: 16, color: Colors.white.withValues(alpha: 0.6)),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            _buildPendingBadge(pendingApprovalsAsync, ref),
                            const SizedBox(width: 16),
                            PopupMenuButton<String>(
                              onSelected: (val) {
                                if (val == 'rapport') {
                                  _telechargerRapport(ref);
                                }
                              },
                              color: const Color(0xFF10192A),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
                              offset: const Offset(0, 50),
                              itemBuilder: (context) => [
                                PopupMenuItem(
                                  value: 'rapport',
                                  child: Row(
                                    children: [
                                      const Icon(Icons.download, color: Colors.white),
                                      const SizedBox(width: 8),
                                      Text("Télécharger le rapport", style: GoogleFonts.inter(color: Colors.white)),
                                    ],
                                  ),
                                ),
                              ],
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF10192A),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                                ),
                                child: Row(
                                  children: [
                                    Text("Actions", style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600)),
                                    const SizedBox(width: 8),
                                    const Icon(Icons.keyboard_arrow_down, color: Colors.white54, size: 20),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    
                    // Cartes KPI
                    LayoutBuilder(
                      builder: (context, constraints) {
                        int crossAxisCount = constraints.maxWidth > 1200 ? 4 : constraints.maxWidth > 800 ? 2 : 1;
                        return GridView.count(
                          crossAxisCount: crossAxisCount,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisSpacing: 24,
                          mainAxisSpacing: 24,
                          childAspectRatio: 2.2,
                          children: [
                            _KpiCard(titre: "Revenus", valeur: "${NumberFormat.compact().format(stats.revenusTotaux)} F", icone: Iconsax.wallet_3_copy, couleur: CouleursApp.succes, sparklineData: stats.revenusHistory, trend: stats.trendRevenus),
                            _KpiCard(titre: "Clients Actifs", valeur: stats.totalClients.toString(), icone: Iconsax.user_copy, couleur: CouleursApp.secondaire, sparklineData: stats.clientsHistory, trend: stats.trendClients),
                            _KpiCard(titre: "Transporteurs", valeur: stats.totalTransporteurs.toString(), icone: Iconsax.truck_fast_copy, couleur: CouleursApp.avertissement, sparklineData: stats.transporteursHistory, trend: stats.trendTransporteurs),
                            _KpiCard(titre: "Courses Totales", valeur: stats.totalCourses.toString(), icone: Iconsax.route_square_copy, couleur: CouleursApp.primaire, sparklineData: stats.coursesHistory, trend: stats.trendCourses),
                          ],
                        );
                      },
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Section Graphiques
                    LayoutBuilder(
                      builder: (context, constraints) {
                        if (constraints.maxWidth > 1100) {
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(flex: 2, child: _buildGraphiqueRevenus(weeklyRevenuesAsync)),
                              const SizedBox(width: 24),
                              Expanded(flex: 1, child: _buildPieDistribution(distributionAsync)),
                            ],
                          );
                        } else {
                          return Column(
                            children: [
                              _buildGraphiqueRevenus(weeklyRevenuesAsync),
                              const SizedBox(height: 24),
                              _buildPieDistribution(distributionAsync),
                            ],
                          );
                        }
                      }
                    ),

                    const SizedBox(height: 32),

                    // Section Activités et Carte
                    LayoutBuilder(
                      builder: (context, constraints) {
                        if (constraints.maxWidth > 1100) {
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(flex: 1, child: _buildRecentActivities(activitiesAsync)),
                              const SizedBox(width: 24),
                              Expanded(flex: 2, child: _buildCarteTransporteurs(transporteursAsync, ref, isSatellite)),
                            ],
                          );
                        } else {
                          return Column(
                            children: [
                              _buildRecentActivities(activitiesAsync),
                              const SizedBox(height: 24),
                              _buildCarteTransporteurs(transporteursAsync, ref, isSatellite),
                            ],
                          );
                        }
                      }
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      )
    );
  }

  void _telechargerRapport(WidgetRef ref) async {
    final coursesAsync = ref.read(adminCoursesProvider);
    if (coursesAsync is! AsyncData) return;
    
    final courses = coursesAsync.value!;
    
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return [
            pw.Header(level: 0, child: pw.Text("Rapport CamTrans - Courses")),
            pw.TableHelper.fromTextArray(
              context: context,
              headers: <String>['ID', 'Date', 'Client ID', 'Transporteur ID', 'Statut', 'Prix'],
              data: courses.map((c) => <String>[
                  c.id.length > 8 ? c.id.substring(0, 8) : c.id,
                  "${c.dateCreation.day}/${c.dateCreation.month}/${c.dateCreation.year}",
                  c.clientId.length > 8 ? c.clientId.substring(0, 8) : c.clientId,
                  c.transporteurId.isEmpty ? 'Aucun' : (c.transporteurId.length > 8 ? c.transporteurId.substring(0, 8) : c.transporteurId),
                  c.statut,
                  "${c.prixFinal > 0 ? c.prixFinal : c.prixEstime} F"
                ]).toList(),
            ),
          ];
        },
      ),
    );

    final bytes = await pdf.save();
    telechargerFichier(bytes, "rapport_camtrans_${DateTime.now().millisecondsSinceEpoch}.pdf");
  }

  void _afficherDetailsCourse(BuildContext context, Course course) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF10192A),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
          title: Text("Détails de la course", style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("ID: ${course.id}", style: GoogleFonts.inter(color: Colors.white54, fontSize: 12)),
              const SizedBox(height: 16),
              Row(children: [
                const Icon(Icons.my_location, color: CouleursApp.primaire, size: 18),
                const SizedBox(width: 8),
                Expanded(child: Text("Départ: ${course.adresseDepart}", style: GoogleFonts.inter(color: Colors.white70))),
              ]),
              const SizedBox(height: 8),
              Row(children: [
                const Icon(Icons.location_on, color: Colors.redAccent, size: 18),
                const SizedBox(width: 8),
                Expanded(child: Text("Arrivée: ${course.adresseArrivee}", style: GoogleFonts.inter(color: Colors.white70))),
              ]),
              const SizedBox(height: 16),
              Text("Prix: ${course.prixFinal > 0 ? course.prixFinal : course.prixEstime} F", style: GoogleFonts.inter(color: CouleursApp.succes, fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              Text("Statut: ${course.statut}", style: GoogleFonts.inter(color: Colors.white70)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Fermer", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      }
    );
  }

  void _confirmerAnnulation(BuildContext context, Course course) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF10192A),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
          title: Text("Annuler la course ?", style: GoogleFonts.inter(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          content: Text("Êtes-vous sûr de vouloir annuler cette course ? Cette action est irréversible.", style: GoogleFonts.inter(color: Colors.white70)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Retour", style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
              onPressed: () async {
                try {
                  await FirebaseFirestore.instance.collection('courses').doc(course.id).update({'statut': 'annulee'});
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Course annulée avec succès")));
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erreur: $e")));
                  }
                }
              },
              child: const Text("Annuler la course", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      }
    );
  }

  Widget _buildPendingBadge(AsyncValue<int> pendingAsync, WidgetRef ref) {
    return pendingAsync.maybeWhen(
      data: (count) => count > 0 ? GestureDetector(
        onTap: () => ref.read(adminMenuIndexProvider.notifier).state = 2,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.red.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.red.withValues(alpha: 0.5)),
            boxShadow: [
              BoxShadow(
                color: Colors.red.withValues(alpha: 0.2),
                blurRadius: 15,
                spreadRadius: 2,
              )
            ]
          ),
          child: Row(
            children: [
              const Icon(Iconsax.warning_2_copy, color: Colors.redAccent, size: 20),
              const SizedBox(width: 10),
              Text("$count en attente", style: GoogleFonts.inter(color: Colors.redAccent, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ) : const SizedBox.shrink(),
      orElse: () => const SizedBox.shrink(),
    );
  }

  Widget _buildPieDistribution(AsyncValue<Map<String, int>> distributionAsync) {
    return _CarteGlass(
      titre: "Répartition des Courses",
      hauteur: 420,
      enfant: distributionAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: CouleursApp.primaire)),
        error: (err, _) => Center(child: Text("Impossible de charger les activités : $err 🔧", style: const TextStyle(color: Colors.white))),
        data: (data) {
          // Normalisation des données pour regrouper les statuts similaires
          final Map<String, int> normalizedData = {};
          data.forEach((key, value) {
            String l = key.toLowerCase();
            String label;
            if (l.contains('termin') || l.contains('livr')) label = 'Terminée';
            else if (l.contains('annul')) label = 'Annulée';
            else if (l.contains('cours') || l.contains('transit') || l.contains('rout')) label = 'En cours';
            else if (l.contains('attent') || l.contains('recherch')) label = 'En attente';
            else if (l.contains('accept') || l.contains('attribu')) label = 'Attribué';
            else label = key;

            normalizedData[label] = (normalizedData[label] ?? 0) + value;
          });

          final List<PieChartSectionData> sections = [];
          
          Color getColorForLabel(String label) {
            String l = label.toLowerCase();
            if (l.contains('termin') || l.contains('livr')) return CouleursApp.succes; // Green
            if (l.contains('annul')) return CouleursApp.erreur; // Red
            if (l.contains('cours') || l.contains('transit') || l.contains('rout')) return Colors.blueAccent;
            if (l.contains('attent') || l.contains('recherch')) return Colors.orange;
            if (l.contains('accept') || l.contains('attribu')) return Colors.purpleAccent;
            // Fallbacks if unknown
            final fallbackColors = [Colors.teal, Colors.pink, Colors.amber, Colors.cyan, Colors.indigo];
            return fallbackColors[label.hashCode % fallbackColors.length];
          }

          normalizedData.forEach((key, value) {
            sections.add(PieChartSectionData(
              value: value.toDouble(),
              title: "$value",
              color: getColorForLabel(key),
              radius: 30, // Slightly thicker ring
              titleStyle: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14), // Show internal value
            ));
          });

          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text("Total", style: GoogleFonts.inter(color: Colors.white54, fontSize: 14)),
                        Text("${normalizedData.values.fold(0, (a, b) => a + b)}", style: GoogleFonts.inter(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    PieChart(PieChartData(
                      sections: sections, 
                      centerSpaceRadius: 70, // Slightly smaller center space
                      sectionsSpace: 4,
                    )),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Légende
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 16,
                runSpacing: 12,
                children: normalizedData.entries.toList().asMap().entries.map((entry) {
                  final _ = entry.key;  // index non utilisé
                  final key = entry.value.key;
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: getColorForLabel(key),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(key, style: GoogleFonts.inter(color: Colors.white70, fontSize: 13)),
                    ],
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
            ],
          );
        },
      ),
    );
  }

  Widget _buildRecentActivities(AsyncValue<List<Course>> activitiesAsync) {
    return _CarteGlass(
      titre: "Activités Récentes",
      hauteur: 450,
      enfant: activitiesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: CouleursApp.primaire)),
        error: (err, _) => Center(child: Text("Données financières inaccessibles : $err 🔧", style: const TextStyle(color: Colors.white))),
        data: (list) {
          if (list.isEmpty) return const Center(child: Text("Aucune activité", style: TextStyle(color: Colors.white54)));
          return ListView.builder(
            itemCount: list.length,
            itemBuilder: (context, index) {
              final c = list[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 8), // Tighter spacing
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF10192A), // Dark blue
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: CouleursApp.primaire.withValues(alpha: 0.2),
                      child: const Icon(Iconsax.box_copy, color: CouleursApp.primaire, size: 16),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(text: "Course ", style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white)),
                                TextSpan(text: c.adresseArrivee, style: GoogleFonts.inter(fontSize: 13, color: Colors.white70)),
                              ],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text("${DateFormat('dd MMM').format(c.dateCreation)} • ${c.prixFinal > 0 ? c.prixFinal : c.prixEstime} F", style: GoogleFonts.inter(fontSize: 11, color: Colors.white38)),
                        ],
                      ),
                    ),
                    // Action Buttons
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Tooltip(
                          message: "Voir les détails",
                          child: InkWell(
                            onTap: () => _afficherDetailsCourse(context, c),
                            borderRadius: BorderRadius.circular(20),
                            child: const Padding(
                              padding: EdgeInsets.all(6.0),
                              child: Icon(Iconsax.eye_copy, color: Colors.white54, size: 18),
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        if (c.statut != 'annulee' && c.statut != 'terminee')
                          Tooltip(
                            message: "Annuler la course",
                            child: InkWell(
                              onTap: () => _confirmerAnnulation(context, c),
                              borderRadius: BorderRadius.circular(20),
                              child: const Padding(
                                padding: EdgeInsets.all(6.0),
                                child: Icon(Iconsax.close_circle_copy, color: CouleursApp.erreur, size: 18),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ).animate().slideX();
            },
          );
        },
      ),
    );
  }

  Widget _buildGraphiqueRevenus(AsyncValue<List<double>> weeklyRevenuesAsync) {
    return _CarteGlass(
      titre: "Évolution des Revenus",
      hauteur: 420,
      enfant: weeklyRevenuesAsync.when(
        loading: () => Container(color: Colors.white.withValues(alpha: 0.05)).animate(onPlay: (controller) => controller.repeat()).shimmer(color: Colors.white.withValues(alpha: 0.1), duration: 1.5.seconds),
        error: (err, _) => Center(child: Text("Oups ! Graphe indisponible : $err 📊", style: const TextStyle(color: Colors.white))),
        data: (data) {
          final spots = data.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList();
          
          return LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true, 
                drawVerticalLine: false,
                getDrawingHorizontalLine: (value) => FlLine(color: Colors.white.withValues(alpha: 0.05), strokeWidth: 1),
              ),
              titlesData: FlTitlesData(
                rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 50,
                    getTitlesWidget: (value, meta) => Text(NumberFormat.compact().format(value), style: GoogleFonts.inter(color: Colors.white54, fontSize: 11)),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    interval: 1, // Fix fractional values creating duplicate labels
                    getTitlesWidget: (value, meta) {
                      // Only show titles for integer values
                      if (value != value.toInt()) return const Text('');
                      
                      const jours = ['J-6', 'J-5', 'J-4', 'J-3', 'J-2', 'Hier', 'Auj'];
                      if (value.toInt() >= 0 && value.toInt() < jours.length) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(jours[value.toInt()], style: GoogleFonts.inter(color: Colors.white54, fontSize: 12)),
                        );
                      }
                      return const Text('');
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  color: CouleursApp.secondaire,
                  barWidth: 5,
                  isStrokeCapRound: true,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      colors: [
                        CouleursApp.secondaire.withValues(alpha: 0.5),
                        CouleursApp.secondaire.withValues(alpha: 0.0),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCarteTransporteurs(AsyncValue<List<Transporteur>> transporteursAsync, WidgetRef ref, bool isSatellite) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      height: 450,
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          transporteursAsync.when(
            loading: () => Container(color: Colors.white.withValues(alpha: 0.05)).animate(onPlay: (controller) => controller.repeat()).shimmer(color: Colors.white.withValues(alpha: 0.1), duration: 1.5.seconds),
            error: (err, _) => Center(child: Text("Oups ! Carte indisponible : $err 🗺️", style: const TextStyle(color: Colors.white))),
            data: (transporteurs) {
              final markers = transporteurs
                  .where((t) => t.latitude != 0 && t.longitude != 0)
                  .map<Marker>((t) {
                      IconData iconData = Icons.directions_car;
                      final type = t.typeVehicule.toLowerCase();
                      if (type.contains('moto')) iconData = Icons.two_wheeler;
                      else if (type.contains('camion')) iconData = Icons.local_shipping;
                      else if (type.contains('fourgon') || type.contains('van')) iconData = Icons.airport_shuttle;

                      return Marker(
                        point: LatLng(t.latitude, t.longitude),
                        width: 44,
                        height: 44,
                        child: Container(
                          decoration: BoxDecoration(
                            color: t.disponible ? Colors.blue.withValues(alpha: 0.2) : Colors.grey.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                            border: Border.all(color: t.disponible ? Colors.blue : Colors.grey, width: 2),
                            boxShadow: [
                              BoxShadow(color: (t.disponible ? Colors.blue : Colors.grey).withValues(alpha: 0.3), blurRadius: 8, spreadRadius: 2)
                            ]
                          ),
                          child: Icon(iconData, color: t.disponible ? Colors.white : Colors.white70, size: 22),
                        ),
                      );
                    }).toList();

              return _MiniCarteStateful(
                markers: markers,
                isSatellite: isSatellite,
              );
            },
          ),
          Positioned(
            top: 24,
            right: 24,
            child: InkWell(
              onTap: () {
                ref.read(isSatelliteViewProvider.notifier).state = !isSatellite;
              },
              borderRadius: BorderRadius.circular(12),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                    ),
                    child: Icon(
                      isSatellite ? Icons.map : Icons.satellite_alt,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 24,
            left: 24,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  child: Row(
                    children: [
                      Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle)).animate(onPlay: (controller) => controller.repeat(reverse: true)).fade(begin: 0.4, end: 1),
                      const SizedBox(width: 10),
                      Text("Suivi en direct", style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String titre;
  final String valeur;
  final IconData icone;
  final Color couleur;
  final List<double> sparklineData;
  final double trend;

  const _KpiCard({
    required this.titre, 
    required this.valeur, 
    required this.icone, 
    required this.couleur,
    required this.sparklineData,
    required this.trend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF10192A), // Darker blue/grey background matching reference
        borderRadius: BorderRadius.circular(12), // Less rounded, more professional
        border: Border.all(color: Colors.white.withValues(alpha: 0.05), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(titre.toUpperCase(), style: GoogleFonts.inter(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
              Icon(icone, color: couleur.withValues(alpha: 0.7), size: 16),
            ],
          ),
          const SizedBox(height: 4),
          Expanded(
            child: FittedBox(
              alignment: Alignment.centerLeft,
              fit: BoxFit.scaleDown,
              child: Text(valeur, style: GoogleFonts.inter(color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold, letterSpacing: -1)),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(trend >= 0 ? Icons.arrow_drop_up : Icons.arrow_drop_down, color: trend >= 0 ? CouleursApp.succes : CouleursApp.erreur, size: 18),
              Text("${trend >= 0 ? '+' : ''}${trend.toStringAsFixed(1)}%", style: GoogleFonts.inter(color: trend >= 0 ? CouleursApp.succes : CouleursApp.erreur, fontSize: 11, fontWeight: FontWeight.bold)),
              const SizedBox(width: 4),
              Text("vs mois dernier", style: GoogleFonts.inter(color: Colors.white38, fontSize: 11)),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: false),
                titlesData: FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineTouchData: LineTouchData(enabled: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: sparklineData.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList(),
                    isCurved: true,
                    color: couleur,
                    barWidth: 2,
                    isStrokeCapRound: true,
                    dotData: FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: couleur.withValues(alpha: 0.1),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CarteGlass extends StatelessWidget {
  final String titre;
  final Widget enfant;
  final double hauteur;

  const _CarteGlass({required this.titre, required this.enfant, required this.hauteur});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          height: hauteur,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(titre, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
              const SizedBox(height: 28),
              Expanded(child: enfant),
            ],
          ),
        ),
      ),
    );
  }
}

class _SkeletonVueEnsemble extends StatelessWidget {
  const _SkeletonVueEnsemble();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(height: 40, width: 300, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(8))).animate(onPlay: (controller) => controller.repeat()).shimmer(color: Colors.white.withValues(alpha: 0.1), duration: 1.5.seconds),
          const SizedBox(height: 10),
          Container(height: 20, width: 400, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(8))).animate(onPlay: (controller) => controller.repeat()).shimmer(color: Colors.white.withValues(alpha: 0.1), duration: 1.5.seconds),
          const SizedBox(height: 32),
          LayoutBuilder(
            builder: (context, constraints) {
              int crossAxisCount = constraints.maxWidth > 1200 ? 4 : constraints.maxWidth > 800 ? 2 : 1;
              return GridView.count(
                crossAxisCount: crossAxisCount,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 24,
                mainAxisSpacing: 24,
                childAspectRatio: 2.2,
                children: List.generate(4, (index) => Container(
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(24)),
                ).animate(onPlay: (controller) => controller.repeat()).shimmer(color: Colors.white.withValues(alpha: 0.1), duration: 1.5.seconds)),
              );
            },
          ),
        ],
      ),
    );
  }
}


class _MiniCarteStateful extends StatefulWidget {
  final List<Marker> markers;
  final bool isSatellite;

  const _MiniCarteStateful({required this.markers, required this.isSatellite});

  @override
  State<_MiniCarteStateful> createState() => _MiniCarteStatefulState();
}

class _MiniCarteStatefulState extends State<_MiniCarteStateful> {
  final MapController _mapController = MapController();

  Widget _buildZoomButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A).withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: const MapOptions(
            initialCenter: LatLng(3.8480, 11.5021),
            initialZoom: 12,
          ),
          children: [
            TileLayer(
              urlTemplate: widget.isSatellite ? urlCarteSatellite : urlCarteStandard,
              userAgentPackageName: 'com.joan.update_camtrans',
            ),
            MarkerLayer(markers: widget.markers),
          ],
        ),
        Positioned(
          bottom: 16,
          right: 16,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildZoomButton(Icons.add, () {
                _mapController.move(_mapController.camera.center, _mapController.camera.zoom + 1);
              }),
              const SizedBox(height: 8),
              _buildZoomButton(Icons.remove, () {
                _mapController.move(_mapController.camera.center, _mapController.camera.zoom - 1);
              }),
            ],
          ),
        ),
      ],
    );
  }
}
