import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../coeur/etat/admin_provider.dart';
import '../../../coeur/constantes/couleurs.dart';

class PageVueEnsemble extends ConsumerWidget {
  const PageVueEnsemble({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(adminStatsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      body: statsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text("Erreur: $err")),
        data: (stats) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Vue d'ensemble",
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black87),
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
                        _KpiCard(titre: "Revenus (FCFA)", valeur: stats.revenusTotaux.toStringAsFixed(0), icone: Icons.monetization_on, couleur: Colors.green),
                        _KpiCard(titre: "Clients Actifs", valeur: stats.totalClients.toString(), icone: Icons.person, couleur: Colors.blue),
                        _KpiCard(titre: "Transporteurs", valeur: stats.totalTransporteurs.toString(), icone: Icons.local_shipping, couleur: Colors.orange),
                        _KpiCard(titre: "Courses Totales", valeur: stats.totalCourses.toString(), icone: Icons.map, couleur: CouleursApp.primaire),
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
                          Expanded(flex: 2, child: _buildGraphiqueRevenus()),
                          const SizedBox(width: 24),
                          Expanded(flex: 1, child: _buildCarteTransporteurs()),
                        ],
                      );
                    } else {
                      return Column(
                        children: [
                          _buildGraphiqueRevenus(),
                          const SizedBox(height: 24),
                          _buildCarteTransporteurs(),
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

  Widget _buildGraphiqueRevenus() {
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
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: true, drawVerticalLine: false),
                titlesData: FlTitlesData(
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        const jours = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
                        if (value.toInt() >= 0 && value.toInt() < jours.length) {
                          return Text(jours[value.toInt()], style: const TextStyle(color: Colors.grey, fontSize: 12));
                        }
                        return const Text('');
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: const [
                      FlSpot(0, 15000),
                      FlSpot(1, 20000),
                      FlSpot(2, 18000),
                      FlSpot(3, 35000),
                      FlSpot(4, 25000),
                      FlSpot(5, 45000),
                      FlSpot(6, 40000),
                    ],
                    isCurved: true,
                    color: CouleursApp.primaire,
                    barWidth: 4,
                    belowBarData: BarAreaData(
                      show: true,
                      color: CouleursApp.primaire.withValues(alpha: 0.1),
                    ),
                    dotData: FlDotData(show: true),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCarteTransporteurs() {
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
            child: FlutterMap(
              options: MapOptions(
                initialCenter: const LatLng(4.0511, 9.7679), // Douala
                initialZoom: 12,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.camtrans.app',
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: const LatLng(4.0511, 9.7679),
                      child: const Icon(Icons.local_shipping, color: CouleursApp.primaire, size: 30),
                    ),
                    Marker(
                      point: const LatLng(4.0611, 9.7579),
                      child: const Icon(Icons.local_shipping, color: CouleursApp.primaire, size: 30),
                    ),
                  ],
                ),
              ],
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
            child: Icon(icone, color: couleur, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(titre, style: const TextStyle(color: Colors.grey, fontSize: 14, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(valeur, style: const TextStyle(color: Colors.black87, fontSize: 24, fontWeight: FontWeight.bold)),
              ],
            ),
          )
        ],
      ),
    );
  }
}
