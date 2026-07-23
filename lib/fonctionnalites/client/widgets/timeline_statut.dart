import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../coeur/constantes/couleurs.dart';

class TimelineStatut extends StatelessWidget {
  final String statutActuel;

  const TimelineStatut({super.key, required this.statutActuel});

  // Liste ordonnée des statuts possibles
  final List<String> _etapes = const [
    "En attente",
    "Acceptée",
    "Chargement",
    "En route",
    "Arrivée",
    "Livrée"
  ];

  @override
  Widget build(BuildContext context) {
    int indexActuel = _etapes.indexOf(statutActuel);
    if (indexActuel == -1) indexActuel = 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(_etapes.length, (index) {
        final etape = _etapes[index];
        final bool estPasse = index < indexActuel;
        final bool estActuel = index == indexActuel;
        final bool estDernier = index == _etapes.length - 1;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                // Cercle
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: estPasse || estActuel ? CouleursApp.primaire : Colors.grey.shade300,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: estActuel ? Colors.black : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: estPasse
                      ? const Icon(Icons.check, size: 12, color: Colors.white)
                      : (estActuel
                          ? Container(
                              margin: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                            )
                          : null),
                ).animate(target: (estPasse || estActuel) ? 1 : 0).scale(duration: 300.ms),
                // Ligne connectrice
                if (!estDernier)
                  Container(
                    width: 2,
                    height: 30,
                    color: estPasse ? CouleursApp.primaire : Colors.grey.shade300,
                  ),
              ],
            ),
            const SizedBox(width: 16),
            // Texte
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 1),
                child: Text(
                  etape,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: estActuel ? FontWeight.bold : FontWeight.normal,
                    color: estPasse || estActuel ? Colors.black87 : Colors.black38,
                  ),
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}
