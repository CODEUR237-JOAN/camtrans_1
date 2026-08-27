import 'package:flutter/material.dart';


import 'package:update_camtrans/coeur/constantes/couleurs.dart';
import 'package:google_fonts/google_fonts.dart';


/// =======================================================
/// CARTE INFORMATION MODERNISÉE
/// Avec ombres dynamiques, icône avec glow, et micro-interactions
/// =======================================================

class CarteInformation extends StatefulWidget {
  final String titre;
  final String? sousTitre;
  final String? valeur;
  final IconData? icone;
  final Widget? enfant;
  final VoidCallback? auClic;
  final Color? couleur;
  final Color? couleurIcone;
  final Color? couleurValeur;
  final EdgeInsets? marge;
  final EdgeInsets? remplissage;
  final bool glow;
  final LinearGradient? gradient;

  const CarteInformation({
    super.key,
    required this.titre,
    this.sousTitre,
    this.valeur,
    this.icone,
    this.enfant,
    this.auClic,
    this.couleur,
    this.couleurIcone,
    this.couleurValeur,
    this.marge,
    this.remplissage,
    this.glow = true,
    this.gradient,
  });

  @override
  State<CarteInformation> createState() => _CarteInformationState();
}

class _CarteInformationState extends State<CarteInformation>
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
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (widget.auClic != null) {
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconColor = widget.couleurIcone ?? CouleursApp.primaire;

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: widget.auClic,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              margin: widget.marge ?? const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                color: widget.couleur ?? (isDark ? CouleursApp.carteSombre : CouleursApp.carte),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: isDark ? CouleursApp.bordureSombre : CouleursApp.bordure.withValues(alpha: 0.5), width: 1),
                gradient: widget.gradient,
                boxShadow: _isPressed
                    ? []
                    : [
                        BoxShadow(
                          color: (isDark ? Colors.black : CouleursApp.ombre)
                              .withValues(alpha: isDark ? 0.3 : 0.08),
                          blurRadius: 16,
                          spreadRadius: -4,
                          offset: const Offset(0, 8),
                        ),
                        if (widget.glow)
                          BoxShadow(
                            color: iconColor.withValues(alpha: isDark ? 0.08 : 0.06),
                            blurRadius: 24,
                            spreadRadius: 0,
                            offset: const Offset(0, 4),
                          ),
                      ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Padding(
                  padding: widget.remplissage ?? const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          if (widget.icone != null)
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    iconColor.withValues(alpha: isDark ? 0.25 : 0.12),
                                    iconColor.withValues(alpha: isDark ? 0.15 : 0.06),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: widget.glow
                                    ? [
                                        BoxShadow(
                                          color: iconColor.withValues(alpha: 0.15),
                                          blurRadius: 12,
                                          spreadRadius: 1,
                                        ),
                                      ]
                                    : [],
                              ),
                              child: Icon(
                                widget.icone,
                                color: iconColor,
                                size: 22,
                              ),
                            ),
                          if (widget.icone != null) const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  widget.titre,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.inter(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? Colors.white : CouleursApp.textePrincipal,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                                if (widget.sousTitre != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      widget.sousTitre!,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        color: isDark ? CouleursApp.texteSombreSecondaire : CouleursApp.texteSecondaire,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          if (widget.valeur != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: (widget.couleurValeur ?? iconColor).withValues(alpha: isDark ? 0.15 : 0.08),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                widget.valeur!,
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: widget.couleurValeur ?? iconColor,
                                  letterSpacing: -0.3,
                                ),
                              ),
                            ),
                        ],
                      ),
                      if (widget.enfant != null) ...[
                        const SizedBox(height: 14),
                        widget.enfant!,
                      ],
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
