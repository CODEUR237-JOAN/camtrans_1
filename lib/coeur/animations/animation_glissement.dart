import 'package:flutter/material.dart';


class AnimationGlissement extends StatefulWidget {
  final Widget enfant;
  final Offset debut;
  final Duration duree;
  final Curve courbe;
  final Duration delai;

  const AnimationGlissement({
    super.key,
    required this.enfant,
    this.debut = const Offset(0, 0.25),
    this.duree = const Duration(milliseconds: 700),
    this.courbe = Curves.easeOutCubic,
    this.delai = Duration.zero,
  });

  @override
  State<AnimationGlissement> createState() =>
      _AnimationGlissementState();
}

class _AnimationGlissementState
    extends State<AnimationGlissement>
    with SingleTickerProviderStateMixin {
  late AnimationController _controleur;

  late Animation<Offset> _animationGlissement;

  late Animation<double> _animationOpacite;

  @override
  void initState() {
    super.initState();

    _controleur = AnimationController(
      vsync: this,
      duration: widget.duree,
    );

    _animationGlissement = Tween<Offset>(
      begin: widget.debut,
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controleur,
        curve: widget.courbe,
      ),
    );

    _animationOpacite = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(
      CurvedAnimation(
        parent: _controleur,
        curve: widget.courbe,
      ),
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
      opacity: _animationOpacite,
      child: SlideTransition(
        position: _animationGlissement,
        child: widget.enfant,
      ),
    );
  }
}
