
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:intl/intl.dart';

import 'package:update_camtrans/services/service_estimation.dart';
import 'package:update_camtrans/coeur/constantes/couleurs.dart';
import 'package:update_camtrans/coeur/widgets/glass_container.dart';

class CarteEstimationIntelligente extends StatelessWidget {
  final ResultatEstimation resultat;

  const CarteEstimationIntelligente({super.key, required this.resultat});

  @override
  Widget build(BuildContext context) {
    final formatCurrency = NumberFormat.currency(locale: 'fr_FR', symbol: 'FCFA', decimalDigits: 0);

    return GlassContainer(
      padding: const EdgeInsets.all(24),
      child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Icon(Iconsax.magic_star_copy, color: CouleursApp.primaire),
                  const SizedBox(width: 8),
                  const Text(
                    "Estimation Terminée",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              LayoutBuilder(
                builder: (context, constraints) {
                  return Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      _buildMetricCard(
                        constraints.maxWidth,
                        icon: Iconsax.routing_2_copy,
                        label: "Distance",
                        value: resultat.distanceKm,
                        suffix: " km",
                        delay: 100,
                      ),
                      _buildMetricCard(
                        constraints.maxWidth,
                        icon: Iconsax.clock_copy,
                        label: "Durée est.",
                        value: resultat.dureeMinutes,
                        suffix: " min",
                        delay: 200,
                      ),
                      _buildMetricCard(
                        constraints.maxWidth,
                        icon: Iconsax.box_copy,
                        label: "Volume",
                        value: resultat.volumeM3,
                        suffix: " m³",
                        delay: 300,
                      ),
                      _buildMetricCard(
                        constraints.maxWidth,
                        icon: Iconsax.weight_copy,
                        label: "Poids",
                        value: resultat.poidsKg,
                        suffix: " kg",
                        delay: 400,
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: CouleursApp.primaire.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Véhicule Recommandé", style: TextStyle(color: Colors.white70, fontSize: 13), overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.local_shipping, size: 18, color: CouleursApp.primaire),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  resultat.vehiculeRecommande,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text("Coût Estimé", style: TextStyle(color: Colors.white70, fontSize: 13), overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 4),
                          // Compteur d'animation pour le prix
                          TweenAnimationBuilder<double>(
                            tween: Tween<double>(begin: 0, end: resultat.coutTotal),
                            duration: const Duration(seconds: 2),
                            curve: Curves.easeOutQuart,
                            builder: (context, value, child) {
                              return FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  formatCurrency.format(value),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: CouleursApp.primaire,
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
    );
  }

  Widget _buildMetricCard(double parentWidth, {required IconData icon, required String label, required double value, required String suffix, required int delay}) {
    // Calcul de largeur pour faire une grille de 2 colonnes sur mobile
    final width = (parentWidth - 16) / 2;

    return Container(
      width: width,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(icon, size: 16, color: Colors.white),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label, style: const TextStyle(fontSize: 10, color: Colors.white70), overflow: TextOverflow.ellipsis),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      TweenAnimationBuilder<double>(
                        tween: Tween<double>(begin: 0, end: value),
                        duration: Duration(milliseconds: 1000 + delay),
                        curve: Curves.easeOutQuart,
                        builder: (context, val, child) {
                          return Text(
                            val.toStringAsFixed(1),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
                          );
                        },
                      ),
                      Text(suffix, style: const TextStyle(fontSize: 11, color: Colors.white70)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
