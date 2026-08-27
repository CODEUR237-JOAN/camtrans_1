import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';


/// =======================================================
/// ANIMATIONS AVANCÉES
/// Staggered list, pulse, scale bounce, parallax
/// =======================================================

/// -------------------------------------------------------
/// ANIMATION STAGGERED LIST
/// Liste avec apparition en cascade des éléments
/// -------------------------------------------------------
class AnimationStaggeredList extends StatelessWidget {
  final List<Widget> children;
  final Duration delay;
  final Duration interval;
  final Axis direction;
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;
  final EdgeInsets? padding;

  const AnimationStaggeredList({
    super.key,
    required this.children,
    this.delay = Duration.zero,
    this.interval = const Duration(milliseconds: 80),
    this.direction = Axis.vertical,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.start,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final animatedChildren = children.asMap().entries.map((entry) {
      final index = entry.key;
      final widget = entry.value;
      final itemDelay = delay + (interval * index);

      return widget
          .animate(delay: itemDelay)
          .fadeIn(duration: 400.ms)
          .slideY(
            begin: 0.25,
            duration: 400.ms,
            curve: Curves.easeOutCubic,
          )
          .scale(
            begin: const Offset(0.95, 0.95),
            duration: 400.ms,
          );
    }).toList();

    if (direction == Axis.horizontal) {
      return Padding(
        padding: padding ?? EdgeInsets.zero,
        child: Row(
          mainAxisAlignment: mainAxisAlignment,
          crossAxisAlignment: crossAxisAlignment,
          children: animatedChildren,
        ),
      );
    }

    return Padding(
      padding: padding ?? EdgeInsets.zero,
      child: Column(
        mainAxisAlignment: mainAxisAlignment,
        crossAxisAlignment: crossAxisAlignment,
        children: animatedChildren,
      ),
    );
  }
}

/// -------------------------------------------------------
/// ANIMATION STAGGERED GRID
/// Grille avec apparition en cascade
/// -------------------------------------------------------
class AnimationStaggeredGrid extends StatelessWidget {
  final List<Widget> children;
  final int crossAxisCount;
  final Duration delay;
  final Duration interval;
  final double crossAxisSpacing;
  final double mainAxisSpacing;
  final EdgeInsets? padding;

  const AnimationStaggeredGrid({
    super.key,
    required this.children,
    this.crossAxisCount = 2,
    this.delay = Duration.zero,
    this.interval = const Duration(milliseconds: 80),
    this.crossAxisSpacing = 12,
    this.mainAxisSpacing = 12,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ?? EdgeInsets.zero,
      child: Wrap(
        spacing: crossAxisSpacing,
        runSpacing: mainAxisSpacing,
        children: children.asMap().entries.map((entry) {
          final index = entry.key;
          final widget = entry.value;
          final itemDelay = delay + (interval * index);

          return SizedBox(
            width: (MediaQuery.of(context).size.width -
                    (padding?.horizontal ?? 0) -
                    (crossAxisSpacing * (crossAxisCount - 1))) /
                crossAxisCount,
            child: widget
                .animate(delay: itemDelay)
                .fadeIn(duration: 400.ms)
                .slideY(
                  begin: 0.3,
                  duration: 400.ms,
                  curve: Curves.easeOutCubic,
                )
                .scale(
                  begin: const Offset(0.9, 0.9),
                  duration: 400.ms,
                ),
          );
        }).toList(),
      ),
    );
  }
}

/// -------------------------------------------------------
/// ANIMATION PULSE
/// Effet de pulsation pour attirer l'attention
/// -------------------------------------------------------
class AnimationPulse extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final double minScale;
  final double maxScale;

  const AnimationPulse({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 1500),
    this.minScale = 0.95,
    this.maxScale = 1.05,
  });

  @override
  State<AnimationPulse> createState() => _AnimationPulseState();
}

class _AnimationPulseState extends State<AnimationPulse>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final scale = widget.minScale +
            (widget.maxScale - widget.minScale) *
                (0.5 + 0.5 * _controller.value);
        return Transform.scale(
          scale: scale,
          child: widget.child,
        );
      },
    );
  }
}

/// -------------------------------------------------------
/// ANIMATION SCALE BOUNCE
/// Apparition avec rebond élastique
/// -------------------------------------------------------
class AnimationScaleBounce extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final Duration duration;
  final double beginScale;

  const AnimationScaleBounce({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 600),
    this.beginScale = 0.5,
  });

  @override
  State<AnimationScaleBounce> createState() => _AnimationScaleBounceState();
}

class _AnimationScaleBounceState extends State<AnimationScaleBounce>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    );

    Future.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
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
        final scale = widget.beginScale +
            (1.0 - widget.beginScale) * _animation.value;
        return Transform.scale(
          scale: scale,
          child: Opacity(
            opacity: _animation.value.clamp(0.0, 1.0),
            child: widget.child,
          ),
        );
      },
    );
  }
}

/// -------------------------------------------------------
/// ANIMATION FLOATING
/// Effet de flottement léger (pour les illustrations)
/// -------------------------------------------------------
class AnimationFloating extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final double offset;

  const AnimationFloating({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 3000),
    this.offset = 10,
  });

  @override
  State<AnimationFloating> createState() => _AnimationFloatingState();
}

class _AnimationFloatingState extends State<AnimationFloating>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final offset = widget.offset * (0.5 - _controller.value);
        return Transform.translate(
          offset: Offset(0, offset),
          child: widget.child,
        );
      },
    );
  }
}

/// -------------------------------------------------------
/// ANIMATION SHIMMER LOADING
/// Effet shimmer pour les skeleton screens
/// -------------------------------------------------------
class AnimationShimmer extends StatefulWidget {
  final Widget child;
  final bool isLoading;
  final Color? baseColor;
  final Color? highlightColor;

  const AnimationShimmer({
    super.key,
    required this.child,
    this.isLoading = true,
    this.baseColor,
    this.highlightColor,
  });

  @override
  State<AnimationShimmer> createState() => _AnimationShimmerState();
}

class _AnimationShimmerState extends State<AnimationShimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    if (widget.isLoading) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant AnimationShimmer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isLoading && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.isLoading && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isLoading) return widget.child;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = widget.baseColor ??
        (isDark ? const Color(0xFF2D2D44) : Colors.grey.shade300);
    final highlight = widget.highlightColor ??
        (isDark ? const Color(0xFF3D3D5C) : Colors.grey.shade100);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              colors: [base, highlight, base],
              stops: const [0.0, 0.5, 1.0],
              begin: Alignment(-1.0 + _controller.value * 3, 0),
              end: Alignment(1.0 + _controller.value * 3, 0),
            ).createShader(bounds);
          },
          blendMode: BlendMode.srcIn,
          child: widget.child,
        );
      },
    );
  }
}

/// -------------------------------------------------------
/// ANIMATION COUNT UP
/// Compteur animé pour les statistiques
/// -------------------------------------------------------
class AnimationCountUp extends StatefulWidget {
  final double end;
  final Duration duration;
  final String? prefix;
  final String? suffix;
  final TextStyle? style;
  final int decimals;

  const AnimationCountUp({
    super.key,
    required this.end,
    this.duration = const Duration(milliseconds: 1500),
    this.prefix,
    this.suffix,
    this.style,
    this.decimals = 0,
  });

  @override
  State<AnimationCountUp> createState() => _AnimationCountUpState();
}

class _AnimationCountUpState extends State<AnimationCountUp>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _animation = Tween<double>(begin: 0, end: widget.end).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutExpo),
    );
    _controller.forward();
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
        final value = _animation.value;
        String text;
        if (widget.decimals > 0) {
          text = value.toStringAsFixed(widget.decimals);
        } else {
          text = value.toInt().toString();
        }
        return Text(
          '${widget.prefix ?? ''}$text${widget.suffix ?? ''}',
          style: widget.style,
        );
      },
    );
  }
}

/// -------------------------------------------------------
/// ANIMATION SLIDE FADE
/// Apparition avec slide + fade combinés
/// -------------------------------------------------------
class AnimationSlideFade extends StatefulWidget {
  final Widget child;
  final AxisDirection direction;
  final Duration delay;
  final Duration duration;
  final double distance;

  const AnimationSlideFade({
    super.key,
    required this.child,
    this.direction = AxisDirection.up,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 500),
    this.distance = 30,
  });

  @override
  State<AnimationSlideFade> createState() => _AnimationSlideFadeState();
}

class _AnimationSlideFadeState extends State<AnimationSlideFade>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    Offset begin;
    switch (widget.direction) {
      case AxisDirection.up:
        begin = Offset(0, widget.distance / 100);
        break;
      case AxisDirection.down:
        begin = Offset(0, -widget.distance / 100);
        break;
      case AxisDirection.left:
        begin = Offset(widget.distance / 100, 0);
        break;
      case AxisDirection.right:
        begin = Offset(-widget.distance / 100, 0);
        break;
    }

    _slideAnimation = Tween<Offset>(begin: begin, end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    Future.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: widget.child,
      ),
    );
  }
}
