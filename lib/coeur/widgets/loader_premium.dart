import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:update_camtrans/coeur/constantes/couleurs.dart';

class LoaderPremium extends StatelessWidget {
  final double size;
  final Color? color;

  const LoaderPremium({
    super.key,
    this.size = 40.0,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final loaderColor = color ?? CouleursApp.primaire;
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Anneau extérieur qui pulse
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: loaderColor.withValues(alpha: 0.3),
                width: size * 0.08,
              ),
            ),
          )
              .animate(onPlay: (controller) => controller.repeat())
              .scale(duration: 1.5.seconds, begin: const Offset(0.5, 0.5), end: const Offset(1.2, 1.2))
              .fade(duration: 1.5.seconds, begin: 0.8, end: 0.0),
              
          // Anneau intérieur qui tourne
          SizedBox(
            width: size * 0.6,
            height: size * 0.6,
            child: CircularProgressIndicator(
              strokeWidth: size * 0.08,
              valueColor: AlwaysStoppedAnimation<Color>(loaderColor),
              backgroundColor: Colors.transparent,
            ),
          ).animate(onPlay: (controller) => controller.repeat())
           .shimmer(duration: 2.seconds, color: Colors.white70),
           
          // Cœur lumineux
          Container(
            width: size * 0.2,
            height: size * 0.2,
            decoration: BoxDecoration(
              color: loaderColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: loaderColor.withValues(alpha: 0.8),
                  blurRadius: size * 0.3,
                  spreadRadius: size * 0.1,
                )
              ],
            ),
          )
              .animate(onPlay: (controller) => controller.repeat(reverse: true))
              .scale(duration: 800.ms, begin: const Offset(0.8, 0.8), end: const Offset(1.2, 1.2)),
        ],
      ),
    );
  }
}
