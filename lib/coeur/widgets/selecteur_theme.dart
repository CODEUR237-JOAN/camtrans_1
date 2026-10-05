import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:update_camtrans/coeur/etat/theme_provider.dart';

// =======================================================
//
// FICHIER : selecteur_theme.dart
// PROJET : CamTrans
//
// Widget réutilisable — section « Apparence » contenant
// 3 vignettes miniatures (Clair / Sombre / Auto).
//
// Peut être inclus tel quel dans :
//   - parametres.dart          (Client)
//   - profil.dart              (Transporteur)
//   - page_parametres.dart     (Admin)
//
// =======================================================

class SelecteurTheme extends ConsumerWidget {
  const SelecteurTheme({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeProvider);
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Titre de section ──
        Text(
          'APPARENCE',
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: cs.primary,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Choisissez le style qui vous convient, de jour comme de nuit.',
          style: GoogleFonts.inter(
            fontSize: 13,
            color: cs.onSurfaceVariant,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 16),

        // ── Les 3 vignettes ──
        Row(
          children: [
            Expanded(
              child: _VignetteTheme(
                mode: ThemeMode.light,
                estActif: theme.estActif(ThemeMode.light),
                onTap: () => _choisir(ref, ThemeMode.light),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _VignetteTheme(
                mode: ThemeMode.dark,
                estActif: theme.estActif(ThemeMode.dark),
                onTap: () => _choisir(ref, ThemeMode.dark),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _VignetteTheme(
                mode: ThemeMode.system,
                estActif: theme.estActif(ThemeMode.system),
                onTap: () => _choisir(ref, ThemeMode.system),
              ),
            ),
          ],
        ),

        // ── Mention pour le mode Auto ──
        AnimatedSize(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          child: theme.estActif(ThemeMode.system)
              ? Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline_rounded,
                          size: 14, color: cs.onSurfaceVariant),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          "S'adapte automatiquement selon l'heure et les réglages de votre téléphone.",
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: cs.onSurfaceVariant,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  void _choisir(WidgetRef ref, ThemeMode mode) {
    HapticFeedback.selectionClick();
    ref.read(themeProvider.notifier).definir(mode);
  }
}

// =============================================================
// Vignette miniature
// =============================================================

class _VignetteTheme extends StatelessWidget {
  final ThemeMode mode;
  final bool estActif;
  final VoidCallback onTap;

  const _VignetteTheme({
    required this.mode,
    required this.estActif,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        transform: estActif ? Matrix4.diagonal3Values(1.03, 1.03, 1.0) : Matrix4.identity(),
        transformAlignment: Alignment.center,
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: estActif ? cs.primary : cs.outlineVariant,
            width: estActif ? 2.0 : 1.0,
          ),
          boxShadow: estActif
              ? [
                  BoxShadow(
                    color: cs.primary.withValues(alpha: 0.10),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            // ── Miniature ──
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(14)),
              child: SizedBox(
                height: 90,
                width: double.infinity,
                child: _buildMiniature(),
              ),
            ),

            // ── Label + coche ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              // FittedBox : sur écrans étroits (~80 px par vignette),
              // la ligne se réduit au lieu de déborder.
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      ThemeProvider.icone(mode),
                      size: 14,
                      color: estActif ? cs.primary : cs.onSurfaceVariant,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      ThemeProvider.label(mode),
                      maxLines: 1,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight:
                            estActif ? FontWeight.w700 : FontWeight.w500,
                        color: estActif ? cs.primary : cs.onSurfaceVariant,
                      ),
                    ),
                    if (estActif) ...[
                      const SizedBox(width: 4),
                      Icon(Icons.check_circle_rounded,
                          size: 14, color: cs.primary),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // -----------------------------------------------------------------
  // Miniatures stylisées (dessinées avec des Containers)
  // -----------------------------------------------------------------
  Widget _buildMiniature() {
    switch (mode) {
      case ThemeMode.light:
        return const _MiniApp(
          fond: Color(0xFFF2F0EA),
          surface: Color(0xFFFFFFFF),
          primaire: Color(0xFF145C43),
          texte: Color(0xFF1A1C1E),
          texteSec: Color(0xFF6B7280),
        );
      case ThemeMode.dark:
        return const _MiniApp(
          fond: Color(0xFF0E1511),
          surface: Color(0xFF1B2420),
          primaire: Color(0xFF2E8C68),
          texte: Color(0xFFE8ECE9),
          texteSec: Color(0xFF9CA3AF),
        );
      case ThemeMode.system:
        return const _MiniAppAuto();
    }
  }
}

// =============================================================
// Miniature d'interface simulée
// =============================================================

class _MiniApp extends StatelessWidget {
  final Color fond;
  final Color surface;
  final Color primaire;
  final Color texte;
  final Color texteSec;

  const _MiniApp({
    required this.fond,
    required this.surface,
    required this.primaire,
    required this.texte,
    required this.texteSec,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: fond,
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // App bar simulée
          Row(
            children: [
              Container(
                width: 16,
                height: 4,
                decoration: BoxDecoration(
                  color: primaire,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: texte.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Carte simulée
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: texteSec.withValues(alpha: 0.15),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Lignes de texte
                  Container(
                    width: double.infinity,
                    height: 3,
                    decoration: BoxDecoration(
                      color: texte.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(1.5),
                    ),
                  ),
                  Container(
                    width: 40,
                    height: 3,
                    decoration: BoxDecoration(
                      color: texteSec.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(1.5),
                    ),
                  ),
                  // Mini bouton
                  Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: primaire,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================
// Miniature « Auto » : moitié clair / moitié sombre
// =============================================================

class _MiniAppAuto extends StatelessWidget {
  const _MiniAppAuto();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            // Moitié gauche : clair
            const Positioned.fill(
              child: ClipRect(
                clipper: _HalfClipper(gauche: true),
                child: _MiniApp(
                  fond: Color(0xFFF2F0EA),
                  surface: Color(0xFFFFFFFF),
                  primaire: Color(0xFF145C43),
                  texte: Color(0xFF1A1C1E),
                  texteSec: Color(0xFF6B7280),
                ),
              ),
            ),
            // Moitié droite : sombre
            const Positioned.fill(
              child: ClipRect(
                clipper: _HalfClipper(gauche: false),
                child: _MiniApp(
                  fond: Color(0xFF0E1511),
                  surface: Color(0xFF1B2420),
                  primaire: Color(0xFF2E8C68),
                  texte: Color(0xFFE8ECE9),
                  texteSec: Color(0xFF9CA3AF),
                ),
              ),
            ),
            // Ligne de séparation au centre
            Positioned(
              left: constraints.maxWidth / 2 - 0.5,
              top: 0,
              bottom: 0,
              child: Container(
                width: 1,
                color: Colors.white.withValues(alpha: 0.3),
              ),
            ),
          ],
        );
      },
    );
  }
}

// =============================================================
// Clipper pour couper le rendu en deux moitiés
// =============================================================

class _HalfClipper extends CustomClipper<Rect> {
  final bool gauche;
  const _HalfClipper({required this.gauche});

  @override
  Rect getClip(Size size) {
    if (gauche) {
      return Rect.fromLTWH(0, 0, size.width / 2, size.height);
    }
    return Rect.fromLTWH(size.width / 2, 0, size.width / 2, size.height);
  }

  @override
  bool shouldReclip(_HalfClipper oldClipper) => gauche != oldClipper.gauche;
}
