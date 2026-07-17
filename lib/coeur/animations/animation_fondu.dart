import 'package:flutter/material.dart';

class AnimationFondu extends StatefulWidget {
  final Widget enfant;
  final Duration duree;
  final Curve courbe;
  final Duration delai;

  const AnimationFondu({
    super.key,
    required this.enfant,
    this.duree = const Duration(milliseconds: 700),
    this.courbe = Curves.easeInOut,
    this.delai = Duration.zero,
  });

  @override
  State<AnimationFondu> createState() => _AnimationFonduState();
}

class _AnimationFonduState extends State<AnimationFondu>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controleur;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    _controleur = AnimationController(
      vsync: this,
      duration: widget.duree,
    );

    _animation = CurvedAnimation(
      parent: _controleur,
      curve: widget.courbe,
    );

    Future.delayed(widget.delai, () {
      if (mounted) {
        _controleur.forward();
      }
    });
  }

  @override
  void dispose() {
    _controleur.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: widget.enfant,
    );
  }
}