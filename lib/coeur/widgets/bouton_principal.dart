import 'package:flutter/material.dart';

import '../constantes/couleurs.dart';
import '../constantes/tailles.dart';
import 'package:google_fonts/google_fonts.dart';

/// =======================================================
/// BOUTON PRINCIPAL MODERNISÉ
/// Avec effet de pression, scale animation, et glow optionnel
/// =======================================================

class BoutonPrincipal extends StatefulWidget {
  final String texte;
  final VoidCallback? auClic;
  final IconData? icone;
  final bool chargement;
  final bool pleineLargeur;
  final Color? couleur;
  final Color? couleurTexte;
  final double? hauteur;
  final double largeur;
  final bool glow;
  final LinearGradient? gradient;

  const BoutonPrincipal({
    super.key,
    required this.texte,
    this.auClic,
    this.icone,
    this.chargement = false,
    this.pleineLargeur = true,
    this.couleur,
    this.couleurTexte,
    this.hauteur,
    this.largeur = double.infinity,
    this.glow = true,
    this.gradient,
  });

  @override
  State<BoutonPrincipal> createState() => _BoutonPrincipalState();
}

class _BoutonPrincipalState extends State<BoutonPrincipal>
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
    if (!widget.chargement && widget.auClic != null) {
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
    final bgColor = widget.couleur ?? CouleursApp.primaire;
    final fgColor = widget.couleurTexte ?? Colors.white;

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: widget.chargement ? null : widget.auClic,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              width: widget.pleineLargeur ? widget.largeur : null,
              height: widget.hauteur ?? TaillesApp.hauteurBouton,
              decoration: BoxDecoration(
                color: widget.gradient == null ? bgColor : null,
                gradient: widget.gradient,
                borderRadius: BorderRadius.circular(16),
                boxShadow: (!widget.glow || _isPressed || widget.chargement)
                    ? []
                    : [
                        BoxShadow(
                          color: bgColor.withValues(alpha: 0.25),
                          blurRadius: 20,
                          spreadRadius: 0,
                          offset: const Offset(0, 8),
                        ),
                      ],
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                transitionBuilder: (child, animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: ScaleTransition(
                      scale: animation,
                      child: child,
                    ),
                  );
                },
                child: widget.chargement
                    ? SizedBox(
                        key: const ValueKey("chargement"),
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: fgColor,
                        ),
                      )
                    : Row(
                        key: const ValueKey("texte"),
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (widget.icone != null) ...[
                            Icon(widget.icone, size: 22, color: fgColor),
                            const SizedBox(width: 10),
                          ],
                            Text(
                              widget.texte,
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: fgColor,
                                letterSpacing: -0.3,
                              ),
                            ),
                        ],
                      ),
              ),
            ),
          );
        },
      ),
    );
  }
}
