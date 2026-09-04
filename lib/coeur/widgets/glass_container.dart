import 'dart:ui';
import 'package:flutter/material.dart';

/// Un conteneur universel qui applique un effet de Glassmorphism.
/// Totalement gratuit, utilise uniquement les filtres natifs de Flutter.
class GlassContainer extends StatelessWidget {
  final Widget child;
  final double blur;
  final double opaciteFond;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final Border? customBorder;

  const GlassContainer({
    super.key,
    required this.child,
    this.blur = 15.0,
    this.opaciteFond = 0.08,
    this.borderRadius,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.customBorder,
  });

  @override
  Widget build(BuildContext context) {
    final defaultRadius = borderRadius ?? BorderRadius.circular(24);
    
    return Container(
      margin: margin,
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: defaultRadius,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: defaultRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding ?? const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: opaciteFond),
              borderRadius: defaultRadius,
              border: customBorder ?? Border.all(
                color: Colors.white.withValues(alpha: 0.15),
                width: 1.0,
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
