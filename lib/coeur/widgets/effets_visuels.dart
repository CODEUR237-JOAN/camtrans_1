import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';

import 'package:update_camtrans/coeur/constantes/couleurs.dart';


/// =======================================================
/// WIDGETS D'EFFETS VISUELS INNOVANTS
/// Glassmorphism, Néons, Dégradés animés, Ombres dynamiques
/// =======================================================

/// -------------------------------------------------------
/// GLASS CARD
/// Carte avec effet verre dépoli (glassmorphism)
/// -------------------------------------------------------
class GlassCard extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final double borderRadius;
  final double blur;
  final Color? backgroundColor;
  final Color? borderColor;
  final List<BoxShadow>? boxShadow;

  const GlassCard({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.borderRadius = 24,
    this.blur = 20,
    this.backgroundColor,
    this.borderColor,
    this.boxShadow,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: boxShadow ??
            [
              BoxShadow(
                color: (isDark ? Colors.black : CouleursApp.ombre)
                    .withValues(alpha: isDark ? 0.4 : 0.1),
                blurRadius: 30,
                spreadRadius: -5,
                offset: const Offset(0, 10),
              ),
            ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding ?? const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: backgroundColor ??
                  (isDark
                      ? CouleursApp.glassNoir
                      : CouleursApp.glassBlanc),
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(
                color: borderColor ??
                    (isDark
                        ? CouleursApp.glassNoirBorder
                        : CouleursApp.glassBlancBorder),
                width: 1.2,
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// -------------------------------------------------------
/// GRADIENT BUTTON
/// Bouton avec dégradé animé au survol/tap
/// -------------------------------------------------------
class GradientButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final LinearGradient? gradient;
  final double? width;
  final double height;
  final double borderRadius;

  const GradientButton({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.isLoading = false,
    this.gradient,
    this.width,
    this.height = 56,
    this.borderRadius = 30,
  });

  @override
  State<GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<GradientButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (!widget.isLoading && widget.onPressed != null) {
      setState(() => _isPressed = true);
      _controller.forward();
    }
  }

  void _onTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    _controller.reverse();
  }

  void _onTapCancel() {
    setState(() => _isPressed = false);
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final grad = widget.gradient ?? CouleursApp.degradePrincipal;

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: widget.isLoading ? null : widget.onPressed,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) => Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            width: widget.width ?? double.infinity,
            height: widget.height,
            decoration: BoxDecoration(
              gradient: grad,
              borderRadius: BorderRadius.circular(widget.borderRadius),
              boxShadow: _isPressed
                  ? []
                  : [
                      CouleursApp.ombreNeon(
                        couleur: grad.colors.last,
                        blurRadius: 20,
                      ),
                      BoxShadow(
                        color: grad.colors.first.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
            ),
            child: Center(
              child: widget.isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (widget.icon != null) ...[
                          Icon(widget.icon, color: Colors.white, size: 22),
                          const SizedBox(width: 10),
                        ],
                        Text(
                          widget.text,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

/// -------------------------------------------------------
/// GLOW ICON
/// Icône avec effet de lueur (glow) animée
/// -------------------------------------------------------
class GlowIcon extends StatefulWidget {
  final IconData icon;
  final double size;
  final Color color;
  final double glowIntensity;
  final bool animate;

  const GlowIcon({
    super.key,
    required this.icon,
    this.size = 24,
    this.color = CouleursApp.primaire,
    this.glowIntensity = 0.4,
    this.animate = true,
  });

  @override
  State<GlowIcon> createState() => _GlowIconState();
}

class _GlowIconState extends State<GlowIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _animation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    if (widget.animate) {
      _controller.repeat(reverse: true);
    } else {
      _controller.value = 1.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(
                  alpha: widget.glowIntensity * _animation.value,
                ),
                blurRadius: 20 * _animation.value,
                spreadRadius: 4 * _animation.value,
              ),
            ],
          ),
          child: Icon(
            widget.icon,
            size: widget.size,
            color: widget.color,
          ),
        );
      },
    );
  }
}

/// -------------------------------------------------------
/// ANIMATED SHADOW CARD
/// Carte dont l'ombre réagit au tap avec effet de soulèvement
/// -------------------------------------------------------
class AnimatedShadowCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final double borderRadius;
  final Color? backgroundColor;

  const AnimatedShadowCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding,
    this.margin,
    this.borderRadius = 24,
    this.backgroundColor,
  });

  @override
  State<AnimatedShadowCard> createState() => _AnimatedShadowCardState();
}

class _AnimatedShadowCardState extends State<AnimatedShadowCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _elevationAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _elevationAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (widget.onTap != null) {
      _controller.forward();
    }
  }

  void _onTapUp(TapUpDetails details) {
    _controller.reverse();
  }

  void _onTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _elevationAnimation,
        builder: (context, child) {
          final elevation = _elevationAnimation.value;
          return Transform.translate(
            offset: Offset(0, elevation * -2),
            child: Container(
              margin: widget.margin,
              decoration: BoxDecoration(
                color: widget.backgroundColor ??
                    (isDark ? const Color(0xFF2D2D44) : Colors.white),
                borderRadius: BorderRadius.circular(widget.borderRadius),
                boxShadow: [
                  BoxShadow(
                    color: (isDark ? Colors.black : CouleursApp.ombre)
                        .withValues(alpha: 0.08 + (elevation * 0.12)),
                    blurRadius: 20 + (elevation * 15),
                    spreadRadius: -5 + (elevation * 2),
                    offset: Offset(0, 8 - (elevation * 4)),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(widget.borderRadius),
                child: Padding(
                  padding: widget.padding ?? const EdgeInsets.all(20),
                  child: widget.child,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// -------------------------------------------------------
/// RIPPLE BUTTON
/// Bouton avec effet d'onde (ripple) personnalisé
/// -------------------------------------------------------
class RippleButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final Color? rippleColor;
  final double borderRadius;
  final EdgeInsets? padding;

  const RippleButton({
    super.key,
    required this.child,
    this.onTap,
    this.rippleColor,
    this.borderRadius = 16,
    this.padding,
  });

  @override
  State<RippleButton> createState() => _RippleButtonState();
}

class _RippleButtonState extends State<RippleButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _rippleController;
  late Animation<double> _rippleAnimation;
  Offset _tapPosition = Offset.zero;

  @override
  void initState() {
    super.initState();
    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _rippleAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _rippleController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _rippleController.dispose();
    super.dispose();
  }

  void _handleTap(TapDownDetails details) {
    setState(() {
      _tapPosition = details.localPosition;
    });
    _rippleController.forward(from: 0);
    Future.delayed(const Duration(milliseconds: 200), () {
      widget.onTap?.call();
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        child: Stack(
          children: [
            Padding(
              padding: widget.padding ?? EdgeInsets.zero,
              child: widget.child,
            ),
            AnimatedBuilder(
              animation: _rippleAnimation,
              builder: (context, child) {
                return Positioned.fill(
                  child: CustomPaint(
                    painter: _RipplePainter(
                      position: _tapPosition,
                      progress: _rippleAnimation.value,
                      color: widget.rippleColor ??
                          CouleursApp.primaire.withValues(alpha: 0.2),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _RipplePainter extends CustomPainter {
  final Offset position;
  final double progress;
  final Color color;

  _RipplePainter({
    required this.position,
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final maxRadius = size.longestSide * 1.2;
    final radius = maxRadius * progress;
    final paint = Paint()
      ..color = color.withValues(alpha: (1 - progress) * 0.3)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(position, radius, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// -------------------------------------------------------
/// NEO MORPHIC CONTAINER
/// Effet néomorphique subtil (élévation douce)
/// -------------------------------------------------------
class NeoContainer extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final Color? color;
  final bool isPressed;

  const NeoContainer({
    super.key,
    required this.child,
    this.borderRadius = 24,
    this.padding,
    this.margin,
    this.color,
    this.isPressed = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = color ?? (isDark ? const Color(0xFF2D2D44) : Colors.white);

    return Container(
      margin: margin,
      padding: padding ?? const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: baseColor,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: isPressed
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
                  blurRadius: 4,
                  offset: const Offset(2, 2),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.08),
                  blurRadius: 12,
                  offset: const Offset(4, 4),
                ),
                BoxShadow(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.03)
                      : Colors.white.withValues(alpha: 0.8),
                  blurRadius: 12,
                  offset: const Offset(-4, -4),
                ),
              ],
      ),
      child: child,
    );
  }
}

/// -------------------------------------------------------
/// SHIMMER LOADING WIDGET
/// Effet shimmer moderne pour les états de chargement
/// -------------------------------------------------------
class ShimmerLoading extends StatefulWidget {
  final Widget child;
  final bool isLoading;

  const ShimmerLoading({
    super.key,
    required this.child,
    this.isLoading = true,
  });

  @override
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isLoading) return widget.child;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              colors: [
                Colors.grey.shade300,
                Colors.grey.shade100,
                Colors.grey.shade300,
              ],
              stops: const [0.0, 0.5, 1.0],
              begin: Alignment(-1.0 + _controller.value * 2, 0),
              end: Alignment(1.0 + _controller.value * 2, 0),
            ).createShader(bounds);
          },
          child: widget.child,
        );
      },
    );
  }
}

/// -------------------------------------------------------
/// BADGE NOTIFICATION
/// Badge avec animation de pulsation
/// -------------------------------------------------------
class AnimatedBadge extends StatelessWidget {
  final int count;
  final double size;
  final Color color;

  const AnimatedBadge({
    super.key,
    required this.count,
    this.size = 20,
    this.color = CouleursApp.erreur,
  });

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return const SizedBox.shrink();

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 400),
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.4),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Center(
              child: Text(
                count > 99 ? '99+' : '$count',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}


/// -------------------------------------------------------
/// FOND PREMIUM ANIME
/// Arriere-plan lisible avec routes stylisees et lumiere mobile.
/// -------------------------------------------------------
class FondPremiumAnime extends StatefulWidget {
  final Widget child;
  final LinearGradient? gradient;
  final Color? patternColor;
  final bool safeArea;
  final EdgeInsets padding;

  const FondPremiumAnime({
    super.key,
    required this.child,
    this.gradient,
    this.patternColor,
    this.safeArea = false,
    this.padding = EdgeInsets.zero,
  });

  @override
  State<FondPremiumAnime> createState() => _FondPremiumAnimeState();
}

class _FondPremiumAnimeState extends State<FondPremiumAnime>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gradient = widget.gradient ??
        const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF08111F),
            Color(0xFF0D1828),
            Color(0xFF08111F),
          ],
        );
    final content = Padding(padding: widget.padding, child: widget.child);

    return DecoratedBox(
      decoration: BoxDecoration(gradient: gradient),
      child: Stack(
        fit: StackFit.expand,
        children: [
          RepaintBoundary(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return CustomPaint(
                  painter: _FondPremiumPainter(
                    progress: _controller.value,
                    isDark: true,
                    patternColor: widget.patternColor,
                  ),
                );
              },
            ),
          ),
          widget.safeArea ? SafeArea(child: content) : content,
        ],
      ),
    );
  }
}

class _FondPremiumPainter extends CustomPainter {
  final double progress;
  final bool isDark;
  final Color? patternColor;

  const _FondPremiumPainter({
    required this.progress,
    required this.isDark,
    this.patternColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final base = patternColor ??
        (isDark ? Colors.white : CouleursApp.primaireFonce);
    final routePaint = Paint()
      ..color = base.withValues(alpha: isDark ? 0.04 : 0.025)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..strokeCap = StrokeCap.round;
    final pulsePaint = Paint()
      ..color = CouleursApp.secondaire.withValues(alpha: isDark ? 0.12 : 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;
    final gridPaint = Paint()
      ..color = base.withValues(alpha: isDark ? 0.02 : 0.015)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    final spacing = size.shortestSide < 420 ? 56.0 : 72.0;
    final drift = progress * spacing;
    for (double x = -spacing + drift; x < size.width + spacing; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x - size.height * 0.22, size.height), gridPaint);
    }

    final paths = <Path>[
      Path()
        ..moveTo(-size.width * 0.08, size.height * 0.18)
        ..cubicTo(size.width * 0.22, size.height * 0.08, size.width * 0.42,
            size.height * 0.42, size.width * 0.72, size.height * 0.28)
        ..cubicTo(size.width * 0.9, size.height * 0.2, size.width * 1.04,
            size.height * 0.32, size.width * 1.12, size.height * 0.24),
      Path()
        ..moveTo(-size.width * 0.12, size.height * 0.72)
        ..cubicTo(size.width * 0.12, size.height * 0.58, size.width * 0.42,
            size.height * 0.84, size.width * 0.64, size.height * 0.62)
        ..cubicTo(size.width * 0.78, size.height * 0.48, size.width * 0.98,
            size.height * 0.58, size.width * 1.14, size.height * 0.44),
      Path()
        ..moveTo(size.width * 0.06, -size.height * 0.08)
        ..cubicTo(size.width * 0.22, size.height * 0.2, size.width * 0.18,
            size.height * 0.42, size.width * 0.4, size.height * 0.58)
        ..cubicTo(size.width * 0.62, size.height * 0.74, size.width * 0.54,
            size.height * 0.9, size.width * 0.76, size.height * 1.08),
    ];

    for (final path in paths) {
      canvas.drawPath(path, routePaint);
    }

    final metrics = paths[progress > 0.5 ? 1 : 0].computeMetrics().toList();
    if (metrics.isNotEmpty) {
      final metric = metrics.first;
      final segmentLength = metric.length * 0.18;
      final start = (metric.length + (progress * metric.length) - segmentLength) % metric.length;
      final end = math.min(metric.length, start + segmentLength).toDouble();
      canvas.drawPath(metric.extractPath(start, end), pulsePaint);
      if (end - start < segmentLength) {
        canvas.drawPath(metric.extractPath(0, segmentLength - (end - start)), pulsePaint);
      }
    }

    final nodePaint = Paint()..style = PaintingStyle.fill;
    final nodes = <Offset>[
      Offset(size.width * 0.18, size.height * 0.18),
      Offset(size.width * 0.68, size.height * 0.29),
      Offset(size.width * 0.34, size.height * 0.62),
      Offset(size.width * 0.74, size.height * 0.57),
      Offset(size.width * 0.42, size.height * 0.82),
    ];

    for (var i = 0; i < nodes.length; i++) {
      final shimmer = 0.45 + (math.sin((progress * math.pi * 2) + i) * 0.25);
      nodePaint.color = CouleursApp.primaire.withValues(alpha: (isDark ? 0.10 : 0.06) * shimmer);
      canvas.drawCircle(nodes[i], 5 + shimmer * 1.5, nodePaint);
      nodePaint.color = CouleursApp.secondaire.withValues(alpha: isDark ? 0.18 : 0.10);
      canvas.drawCircle(nodes[i], 1.8, nodePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _FondPremiumPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.isDark != isDark ||
        oldDelegate.patternColor != patternColor;
  }
}

/// -------------------------------------------------------
/// BADGE VERRE
/// Petit libelle lisible sur fonds colores ou images.
/// -------------------------------------------------------
class BadgeVerre extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final double borderRadius;
  final Color? color;

  const BadgeVerre({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
    this.borderRadius = 999,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: padding,
      borderRadius: borderRadius,
      blur: 18,
      backgroundColor: color ?? Colors.white.withValues(alpha: 0.18),
      borderColor: Colors.white.withValues(alpha: 0.28),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.08),
          blurRadius: 18,
          offset: const Offset(0, 8),
        ),
      ],
      child: child,
    );
  }
}

