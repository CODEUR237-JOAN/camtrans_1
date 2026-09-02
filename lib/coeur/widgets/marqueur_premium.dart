import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:update_camtrans/coeur/constantes/couleurs.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

enum TypeMarqueur {
  depart,
  arrivee,
  camion,
}

class MarqueurPremium extends StatelessWidget {
  final TypeMarqueur type;
  final double size;

  const MarqueurPremium({
    super.key,
    required this.type,
    this.size = 40.0,
  });

  @override
  Widget build(BuildContext context) {
    Color couleurBase;
    IconData icone;
    bool pulse = false;

    switch (type) {
      case TypeMarqueur.depart:
        couleurBase = const Color(0xFF3B82F6); // Bleu pro
        icone = Iconsax.record_circle_copy;
        pulse = true;
        break;
      case TypeMarqueur.arrivee:
        couleurBase = const Color(0xFFF43F5E); // Rose/Rouge premium
        icone = Iconsax.location_copy;
        pulse = true;
        break;
      case TypeMarqueur.camion:
        couleurBase = CouleursApp.primaire; // Vert de marque
        icone = Icons.local_shipping;
        pulse = false;
        break;
    }

    Widget content = Stack(
      alignment: Alignment.center,
      children: [
        if (pulse)
          Container(
            width: size * 1.5,
            height: size * 1.5,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: couleurBase.withValues(alpha: 0.2),
            ),
          ).animate(onPlay: (c) => c.repeat(reverse: true))
           .scale(begin: const Offset(0.8, 0.8), end: const Offset(1.2, 1.2), duration: 1.5.seconds)
           .fade(begin: 0.5, end: 1.0, duration: 1.5.seconds),
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: couleurBase.withValues(alpha: 0.5),
                blurRadius: 10,
                spreadRadius: 2,
                offset: const Offset(0, 4),
              )
            ],
            border: Border.all(color: couleurBase, width: 2.5),
          ),
          child: Center(
            child: Icon(
              icone,
              color: couleurBase,
              size: size * 0.55,
            ),
          ),
        ),
      ],
    );

    // Effet d'apparition initial
    return content.animate().scale(curve: Curves.elasticOut, duration: 600.ms);
  }
}
