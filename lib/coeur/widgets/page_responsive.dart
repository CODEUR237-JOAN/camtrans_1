import 'package:flutter/material.dart';

/// Un conteneur qui limite la largeur maximale de son enfant et le centre.
/// Idéal pour empêcher les interfaces mobiles de s'étirer excessivement sur les tablettes et les écrans de bureau.
class PageResponsive extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final AlignmentGeometry alignment;
  final Color? backgroundColor;

  const PageResponsive({
    super.key,
    required this.child,
    this.maxWidth = 800.0,
    this.alignment = Alignment.topCenter,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: backgroundColor,
      alignment: alignment,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
