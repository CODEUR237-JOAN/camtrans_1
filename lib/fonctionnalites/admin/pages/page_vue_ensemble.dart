import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:intl/intl.dart';

import '../../../coeur/etat/admin_provider.dart';
import '../../../coeur/constantes/couleurs.dart';
import '../../../modeles/transporteur.dart';
import '../../../modeles/course.dart';
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
      backgroundColor: const Color(0xFFF4F7FB),
      body: statsAsync.when(
        loading: () => const _SkeletonVueEnsemble(),
        error: (err, _) => Center(child: Text("Erreur: $err")),
        data: (stats) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Bienvenue, Admin",
                          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: CouleursApp.textePrincipal),
                        ),
                        const SizedBox(height: 5),
                        const Text(
                          "Voici l'état de la plateforme aujourd'hui.",
                          style: TextStyle(fontSize: 16, color: CouleursApp.texteSecondaire),
                        ),
                      ],
                    ),
                    _buildPendingBadge(pendingApprovalsAsync, ref),
                  ],
                ),
                const SizedBox(height: 24),
                
                // Cartes KPI
                LayoutBuilder(
                  builder: (context, constraints) {
                    int crossAxisCount = constraints.maxWidth > 1200 ? 4 : constraints.maxWidth > 800 ? 2 : 1;
                    return GridView.count(
                      crossAxisCount: crossAxisCount,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 2.5,
                      children: [
                        _KpiCard(titre: "Revenus (FCFA)", valeur: NumberFormat.compact().format(stats.revenusTotaux), icone: Iconsax.wallet_3, couleur: CouleursApp.succes).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1),
                        _KpiCard(titre: "Clients Actifs", valeur: stats.totalClients.toString(), icone: Iconsax.user_copy, couleur: CouleursApp.secondaire).animate().fadeIn(duration: 400.ms, delay: 100.ms).slideY(begin: 0.1),
                        _KpiCard(titre: "Transporteurs", valeur: stats.totalTransporteurs.toString(), icone: Iconsax.truck_fast_copy, couleur: CouleursApp.avertissement).animate().fadeIn(duration: 400.ms, delay: 200.ms).slideY(begin: 0.1),
                        _KpiCard(titre: "Courses Totales", valeur: stats.totalCourses.toString(), icone: Iconsax.map, couleur: CouleursApp.primaire).animate().fadeIn(duration: 400.ms, delay: 300.ms).slideY(begin: 0.1),
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
                          Expanded(flex: 1, child: _buildCarteTransporteurs(transporteursAsync).animate().fadeIn(duration: 600.ms, delay: 200.ms)),
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
    );
  }

  Widget _buildPendingBadge(AsyncValue<int> pendingAsync, WidgetRef ref) {
    return pendingAsync.maybeWhen(
      data: (count) => count > 0 ? GestureDetector(
        onTap: () => ref.read(adminMenuIndexProvider.notifier).state = 2,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.red.shade200),
          ),
          child: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 20),
              const SizedBox(width: 8),
              Text("$count dossiers à valider", style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ).animate().shake() : const SizedBox.shrink(),
      orElse: () => const SizedBox.shrink(),
    );
  }

  Widget _buildPieDistribution(AsyncValue<Map<String, int>> distributionAsync) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
      ),
      height: 400,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Répartition des Courses", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 24),
          Expanded(
            child: distributionAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text("Erreur: $err")),
              data: (data) {
                if (data.isEmpty) return const Center(child: Text("Pas de données"));
                
                final List<PieChartSectionData> sections = [];
                final colors = [CouleursApp.primaire, CouleursApp.succes, CouleursApp.secondaire, CouleursApp.erreur, CouleursApp.avertissement];
                int i = 0;
                
                data.forEach((key, value) {
                  sections.add(PieChartSectionData(
                    value: value.toDouble(),
                    title: "$value",
                    color: colors[i % colors.length],
                    radius: 50,
                    titleStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                  ));
                  i++;
                });

                return Column(
                  children: [
                    Expanded(child: PieChart(PieChartData(sections: sections, centerSpaceRadius: 40))),
                    const SizedBox(height: 20),
                    Wrap(
                      spacing: 12,
                      children: data.keys.toList().asMap().entries.map((e) {
                        return Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(width: 12, height: 12, decoration: BoxDecoration(color: colors[e.key % colors.length], shape: BoxShape.circle)),
                            const SizedBox(width: 4),
                            Text(e.value, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                          ],
                        );
                      }).toList(),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivities(AsyncValue<List<Course>> activitiesAsync) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
      ),
      height: 400,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Activités Récentes", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 16),
          Expanded(
            child: activitiesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text("Erreur: $err")),
              data: (list) {
                if (list.isEmpty) return const Center(child: Text("Aucune activité"));
                return ListView.builder(
                  itemCount: list.length,
                  itemBuilder: (context, index) {
                    final c = list[index];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: CouleursApp.primaire.withValues(alpha: 0.1), shape: BoxShape.circle),
                        child: const Icon(Icons.shopping_bag_outlined, size: 18, color: CouleursApp.primaire),
                      ),
                      title: Text(c.adresseArrivee, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), overflow: TextOverflow.ellipsis),
                      subtitle: Text(DateFormat('HH:mm').format(c.dateCreation), style: const TextStyle(fontSize: 11)),
                      trailing: Text("${c.prixFinal > 0 ? c.prixFinal : c.prixEstime} F", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGraphiqueRevenus(AsyncValue<List<double>> weeklyRevenuesAsync) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
      ),
      height: 400,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Évolution des Revenus (7 derniers jours)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 24),
          Expanded(
            child: weeklyRevenuesAsync.when(
              loading: () => Container(
                color: Colors.grey.shade100,
              ).animate(onPlay: (controller) => controller.repeat()).shimmer(color: Colors.grey.shade300, duration: 1.5.seconds),
              error: (err, _) => Center(child: Text("Erreur chart: $err")),
              data: (data) {
                final spots = data.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList();
                
                return LineChart(
                  LineChartData(
                    gridData: FlGridData(show: true, drawVerticalLine: false),
                    titlesData: FlTitlesData(
                      rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            const jours = ['J-6', 'J-5', 'J-4', 'J-3', 'J-2', 'Hier', 'Auj'];
                            if (value.toInt() >= 0 && value.toInt() < jours.length) {
                              return Text(jours[value.toInt()], style: const TextStyle(color: Colors.grey, fontSize: 10));
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
                        color: CouleursApp.primaire,
                        barWidth: 4,
                        belowBarData: BarAreaData(
                          show: true,
                          color: CouleursApp.primaire.withValues(alpha: 0.1),
                        ),
                        dotData: const FlDotData(show: true),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCarteTransporteurs(AsyncValue<List<Transporteur>> transporteursAsync) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
      ),
      height: 400,
      clipBehavior: Clip.hardEdge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(20.0),
            child: Text("Activité en temps réel", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          Expanded(
            child: transporteursAsync.when(
              loading: () => Container(
                color: Colors.grey.shade100,
              ).animate(onPlay: (controller) => controller.repeat()).shimmer(color: Colors.grey.shade300, duration: 1.5.seconds),
              error: (err, _) => Center(child: Text("Erreur map: $err")),
              data: (transporteurs) {
                final markers = transporteurs
                    .where((t) => t.latitude != 0 && t.longitude != 0)
                    .map<Marker>((t) => Marker(
                          point: LatLng(t.latitude, t.longitude),
                          child: Icon(Icons.local_shipping, color: t.disponible ? Colors.green : Colors.orange, size: 24),
                        ))
                    .toList();

                return FlutterMap(
                  options: const MapOptions(
                    initialCenter: LatLng(4.0511, 9.7679), // Douala
                    initialZoom: 11,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.joan.update_camtrans',
                    ),
                    MarkerLayer(markers: markers),
                  ],
                );
              },
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
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: couleur.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icone, color: couleur, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(titre, style: const TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                FittedBox(fit: BoxFit.scaleDown, child: Text(valeur, style: const TextStyle(color: Colors.black87, fontSize: 22, fontWeight: FontWeight.bold))),
              ],
            ),
          )
        ],
      ),
    );
  }
}

class _SkeletonVueEnsemble extends StatelessWidget {
  const _SkeletonVueEnsemble();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(height: 30, width: 250, color: Colors.grey.shade200).animate(onPlay: (controller) => controller.repeat()).shimmer(color: Colors.grey.shade300, duration: 1.5.seconds),
          const SizedBox(height: 10),
          Container(height: 20, width: 350, color: Colors.grey.shade200).animate(onPlay: (controller) => controller.repeat()).shimmer(color: Colors.grey.shade300, duration: 1.5.seconds),
          const SizedBox(height: 24),
          LayoutBuilder(
            builder: (context, constraints) {
              int crossAxisCount = constraints.maxWidth > 1200 ? 4 : constraints.maxWidth > 800 ? 2 : 1;
              return GridView.count(
                crossAxisCount: crossAxisCount,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 2.5,
                children: List.generate(4, (index) => Container(
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                ).animate(onPlay: (controller) => controller.repeat()).shimmer(color: Colors.grey.shade300, duration: 1.5.seconds)),
              );
            },
          ),
        ],
      ),
    );
  }
}
