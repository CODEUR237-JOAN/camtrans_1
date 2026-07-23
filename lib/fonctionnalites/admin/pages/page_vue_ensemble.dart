import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:intl/intl.dart';

import '../../../coeur/etat/admin_provider.dart';
import '../../../coeur/constantes/couleurs.dart';
import '../../../modeles/transporteur.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

class PageVueEnsemble extends ConsumerWidget {
  const PageVueEnsemble({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(adminStatsProvider);
    final weeklyRevenuesAsync = ref.watch(adminWeeklyRevenuesProvider);
    final transporteursAsync = ref.watch(adminTransporteursProvider);

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
                const Text(
                  "Bienvenue, Admin",
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: CouleursApp.textePrincipal),
                ),
                const SizedBox(height: 5),
                const Text(
                  "Voici l'état de la plateforme aujourd'hui.",
                  style: TextStyle(fontSize: 16, color: CouleursApp.texteSecondaire),
                ),
                const SizedBox(height: 24),
                
                // Cartes KPI (Responsives)
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
                
                // Section Graphique et Carte
                LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth > 1000) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 2, child: _buildGraphiqueRevenus(weeklyRevenuesAsync).animate().fadeIn(duration: 600.ms).scale(begin: const Offset(0.95, 0.95))),
                          const SizedBox(width: 24),
                          Expanded(flex: 1, child: _buildCarteTransporteurs(transporteursAsync).animate().fadeIn(duration: 600.ms, delay: 200.ms).scale(begin: const Offset(0.95, 0.95))),
                        ],
                      );
                    } else {
                      return Column(
                        children: [
                          _buildGraphiqueRevenus(weeklyRevenuesAsync),
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

  Widget _buildGraphiqueRevenus(AsyncValue<List<double>> weeklyRevenuesAsync) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
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
                          color: CouleursApp.primaire.withOpacity(0.1),
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
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
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
              color: couleur.withOpacity(0.1),
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
