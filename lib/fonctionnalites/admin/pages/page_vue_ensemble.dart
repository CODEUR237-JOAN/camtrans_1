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
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

class PageVueEnsemble extends ConsumerWidget {
  const PageVueEnsemble({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(adminStatsProvider);
    final weeklyRevenuesAsync = ref.watch(adminWeeklyRevenuesProvider);
    final transporteursAsync = ref.watch(adminTransporteursProvider);
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
            error: (err, _) => Center(child: Text("Erreur: $err", style: const TextStyle(color: Colors.white))),
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
                        _buildPendingBadge(pendingApprovalsAsync, ref),
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
                            _KpiCard(titre: "Revenus", valeur: "${NumberFormat.compact().format(stats.revenusTotaux)} F", icone: Iconsax.wallet_3_copy, couleur: CouleursApp.succes).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1),
                            _KpiCard(titre: "Clients Actifs", valeur: stats.totalClients.toString(), icone: Iconsax.user_copy, couleur: CouleursApp.secondaire).animate().fadeIn(duration: 400.ms, delay: 100.ms).slideY(begin: 0.1),
                            _KpiCard(titre: "Transporteurs", valeur: stats.totalTransporteurs.toString(), icone: Iconsax.truck_fast_copy, couleur: CouleursApp.avertissement).animate().fadeIn(duration: 400.ms, delay: 200.ms).slideY(begin: 0.1),
                            _KpiCard(titre: "Courses Totales", valeur: stats.totalCourses.toString(), icone: Iconsax.route_square_copy, couleur: CouleursApp.primaire).animate().fadeIn(duration: 400.ms, delay: 300.ms).slideY(begin: 0.1),
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
                              Expanded(flex: 2, child: _buildGraphiqueRevenus(weeklyRevenuesAsync).animate().fadeIn(duration: 600.ms)),
                              const SizedBox(width: 24),
                              Expanded(flex: 1, child: _buildPieDistribution(distributionAsync).animate().fadeIn(duration: 600.ms, delay: 200.ms)),
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
                              Expanded(flex: 1, child: _buildRecentActivities(activitiesAsync).animate().fadeIn(duration: 600.ms)),
                              const SizedBox(width: 24),
                              Expanded(flex: 2, child: _buildCarteTransporteurs(transporteursAsync).animate().fadeIn(duration: 600.ms, delay: 200.ms)),
                            ],
                          );
                        } else {
                          return Column(
                            children: [
                              _buildRecentActivities(activitiesAsync),
                              const SizedBox(height: 24),
                              _buildCarteTransporteurs(transporteursAsync),
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
      ).animate().shake(delay: 2.seconds) : const SizedBox.shrink(),
      orElse: () => const SizedBox.shrink(),
    );
  }

  Widget _buildPieDistribution(AsyncValue<Map<String, int>> distributionAsync) {
    return _CarteGlass(
      titre: "Répartition des Courses",
      hauteur: 420,
      enfant: distributionAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: CouleursApp.primaire)),
        error: (err, _) => Center(child: Text("Erreur: $err", style: const TextStyle(color: Colors.white))),
        data: (data) {
          if (data.isEmpty) return const Center(child: Text("Pas de données", style: TextStyle(color: Colors.white54)));
          
          final List<PieChartSectionData> sections = [];
          final colors = [CouleursApp.secondaire, CouleursApp.primaire, CouleursApp.succes, CouleursApp.avertissement, CouleursApp.erreur];
          int i = 0;
          
          data.forEach((key, value) {
            sections.add(PieChartSectionData(
              value: value.toDouble(),
              title: "$value",
              color: colors[i % colors.length],
              radius: 60,
              titleStyle: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14),
              badgeWidget: _Badge(key, colors[i % colors.length]),
              badgePositionPercentageOffset: 1.3,
            ));
            i++;
          });

          return PieChart(PieChartData(
            sections: sections, 
            centerSpaceRadius: 50,
            sectionsSpace: 4,
          )).animate().scale(delay: 300.ms, duration: 600.ms, curve: Curves.easeOutBack);
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
        error: (err, _) => Center(child: Text("Erreur: $err", style: const TextStyle(color: Colors.white))),
        data: (list) {
          if (list.isEmpty) return const Center(child: Text("Aucune activité", style: TextStyle(color: Colors.white54)));
          return ListView.builder(
            itemCount: list.length,
            itemBuilder: (context, index) {
              final c = list[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: CouleursApp.secondaire.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Iconsax.box_copy, color: CouleursApp.secondaire, size: 20),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(c.adresseArrivee, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white), overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 4),
                          Text(DateFormat('HH:mm - dd MMM').format(c.dateCreation), style: GoogleFonts.inter(fontSize: 12, color: Colors.white54)),
                        ],
                      ),
                    ),
                    Text("${c.prixFinal > 0 ? c.prixFinal : c.prixEstime} F", style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 15, color: CouleursApp.succes)),
                  ],
                ),
              ).animate().fadeIn(delay: Duration(milliseconds: 100 * index)).slideX();
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
        error: (err, _) => Center(child: Text("Erreur chart: $err", style: const TextStyle(color: Colors.white))),
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
                    getTitlesWidget: (value, meta) {
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
          ).animate().fadeIn(duration: 800.ms, delay: 200.ms);
        },
      ),
    );
  }

  Widget _buildCarteTransporteurs(AsyncValue<List<Transporteur>> transporteursAsync) {
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
            error: (err, _) => Center(child: Text("Erreur map: $err", style: const TextStyle(color: Colors.white))),
            data: (transporteurs) {
              final markers = transporteurs
                  .where((t) => t.latitude != 0 && t.longitude != 0)
                  .map<Marker>((t) => Marker(
                        point: LatLng(t.latitude, t.longitude),
                        width: 40,
                        height: 40,
                        child: Container(
                          decoration: BoxDecoration(
                            color: t.disponible ? CouleursApp.succes.withValues(alpha: 0.2) : Colors.orange.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Iconsax.truck_fast_copy, color: t.disponible ? CouleursApp.succes : Colors.orange, size: 20),
                        ),
                      ))
                  .toList();

              return FlutterMap(
                options: const MapOptions(
                  initialCenter: LatLng(4.0511, 9.7679), // Douala
                  initialZoom: 12,
                ),
                children: [
                  TileLayer(
                    // Utilisation d'une carte sombre (CartoDB Dark Matter) pour coller au thème Neo Premium
                    urlTemplate: 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
                    subdomains: const ['a', 'b', 'c', 'd'],
                    userAgentPackageName: 'com.joan.update_camtrans',
                  ),
                  MarkerLayer(markers: markers),
                ],
              );
            },
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
                      Text("Direct Tracker", style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white)),
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

  const _KpiCard({required this.titre, required this.valeur, required this.icone, required this.couleur});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 30,
                offset: const Offset(0, 10),
              )
            ]
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: couleur.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: couleur.withValues(alpha: 0.2), blurRadius: 15)
                  ]
                ),
                child: Icon(icone, color: couleur, size: 28),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(titre, style: GoogleFonts.inter(color: Colors.white54, fontSize: 14, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 6),
                    FittedBox(fit: BoxFit.scaleDown, child: Text(valeur, style: GoogleFonts.inter(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold, letterSpacing: -0.5))),
                  ],
                ),
              )
            ],
          ),
        ),
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

class _Badge extends StatelessWidget {
  final String texte;
  final Color couleur;

  const _Badge(this.texte, this.couleur);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: couleur.withValues(alpha: 0.5)),
      ),
      child: Text(
        texte,
        style: GoogleFonts.inter(
          fontSize: 12,
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
