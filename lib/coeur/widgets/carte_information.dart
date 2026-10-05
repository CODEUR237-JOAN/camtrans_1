import 'package:flutter/material.dart';

import 'package:update_camtrans/coeur/constantes/couleurs.dart';
import 'package:google_fonts/google_fonts.dart';

/// =======================================================
/// CARTE INFORMATION MODERNISÉE
/// Avec ombres dynamiques, icône avec glow, et micro-interactions
///
/// Deux dispositions :
///  - Standard (horizontale) : [icône] [titre/sous-titre ......] [valeur]
///    → adaptée aux cartes pleine largeur.
///  - Compacte (verticale), via `compacte: true` :
///        [icône]          [valeur]
///        Titre sur 2 lignes max
///    → adaptée aux grilles 2 colonnes sur petits écrans
///      (Actions rapides, Mes Statistiques).
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

  /// Active la disposition verticale pour les cartes en demi-largeur.
  final bool compacte;

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
    this.compacte = false,
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

    // Padding réduit en mode compact : chaque pixel horizontal compte
    // dans une demi-largeur d'écran (~130-170 px).
    final remplissageParDefaut = widget.compacte
        ? const EdgeInsets.all(14)
        : const EdgeInsets.symmetric(horizontal: 18, vertical: 16);

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
                color: widget.couleur ??
                    (isDark ? CouleursApp.carteSombre : CouleursApp.carte),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                    color: isDark
                        ? CouleursApp.bordureSombre
                        : CouleursApp.bordure.withValues(alpha: 0.5),
                    width: 1),
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
                            color: iconColor.withValues(
                                alpha: isDark ? 0.08 : 0.06),
                            blurRadius: 24,
                            spreadRadius: 0,
                            offset: const Offset(0, 4),
                          ),
                      ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Padding(
                  padding: widget.remplissage ?? remplissageParDefaut,
                  child: widget.compacte
                      ? _buildDispositionCompacte(isDark, iconColor)
                      : _buildDispositionStandard(isDark, iconColor),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // =================================================================
  // DISPOSITION STANDARD (horizontale) — inchangée
  // =================================================================
  Widget _buildDispositionStandard(bool isDark, Color iconColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (widget.icone != null) _buildIcone(isDark, iconColor, 44),
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
                    style: _styleTitre(isDark, 15),
                  ),
                  if (widget.sousTitre != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        widget.sousTitre!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: _styleSousTitre(isDark),
                      ),
                    ),
                ],
              ),
            ),
            if (widget.valeur != null) _buildBadgeValeur(isDark, iconColor),
          ],
        ),
        if (widget.enfant != null) ...[
          const SizedBox(height: 14),
          widget.enfant!,
        ],
      ],
    );
  }

  // =================================================================
  // DISPOSITION COMPACTE (verticale)
  //
  // Changement de contraintes :
  //  - Avant : le titre partageait UNE ligne avec l'icône (44 px),
  //    un espace (14 px) et le badge valeur → il ne lui restait
  //    qu'environ 40 px → « Cours... », « C... 0 ».
  //  - Maintenant : icône et valeur occupent la ligne du haut ;
  //    le titre dispose de TOUTE la largeur intérieure de la carte
  //    et peut passer sur 2 lignes. La hauteur de la carte n'est
  //    plus imposée par un ratio : elle suit le contenu.
  // =================================================================
  Widget _buildDispositionCompacte(bool isDark, Color iconColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            if (widget.icone != null) _buildIcone(isDark, iconColor, 40),
            const Spacer(),
            if (widget.valeur != null)
              // Flexible + FittedBox(scaleDown) : un nombre long
              // (ex. « 1 250 ») rétrécit légèrement au lieu de
              // déborder sur l'icône. Taille normale sinon.
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: _buildBadgeValeur(isDark, iconColor),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        // maxLines: 2 → « Courses disponibles » s'affiche en entier.
        // L'ellipsis n'est qu'un dernier recours (texte anormalement long).
        Text(
          widget.titre,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: _styleTitre(isDark, 14).copyWith(height: 1.25),
        ),
        if (widget.sousTitre != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              widget.sousTitre!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: _styleSousTitre(isDark),
            ),
          ),
        if (widget.enfant != null) ...[
          const SizedBox(height: 12),
          widget.enfant!,
        ],
      ],
    );
  }

  // =================================================================
  // Éléments partagés
  // =================================================================
  Widget _buildIcone(bool isDark, Color iconColor, double taille) {
    return Container(
      width: taille,
      height: taille,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            iconColor.withValues(alpha: isDark ? 0.25 : 0.12),
            iconColor.withValues(alpha: isDark ? 0.15 : 0.06),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(taille * 0.32),
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
        size: taille * 0.5,
      ),
    );
  }

  Widget _buildBadgeValeur(bool isDark, Color iconColor) {
    final couleur = widget.couleurValeur ?? iconColor;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: couleur.withValues(alpha: isDark ? 0.15 : 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        widget.valeur!,
        maxLines: 1,
        style: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: couleur,
          letterSpacing: -0.3,
        ),
      ),
    );
  }

  TextStyle _styleTitre(bool isDark, double taille) {
    return GoogleFonts.inter(
      fontSize: taille,
      fontWeight: FontWeight.w600,
      color: isDark ? Colors.white : CouleursApp.textePrincipal,
      letterSpacing: -0.2,
    );
  }

  TextStyle _styleSousTitre(bool isDark) {
    return GoogleFonts.inter(
      fontSize: 13,
      color: isDark
          ? CouleursApp.texteSombreSecondaire
          : CouleursApp.texteSecondaire,
    );
  }
}
