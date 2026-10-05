import 'package:flutter/material.dart';

import 'package:update_camtrans/coeur/widgets/loader_premium.dart';

/// =====================================================================
/// LOADER DE PAGE (système unifié)
///
/// Affiche le [LoaderPremium] centré sur un fond sombre cohérent, avec un
/// message optionnel. À utiliser pour les états de chargement PLEINE PAGE
/// (corps de Scaffold, branche `loading:` d'un AsyncValue d'écran).
/// Pour un simple spinner de bouton, garder un petit CircularProgressIndicator.
/// =====================================================================
class LoaderPage extends StatelessWidget {
  /// Message rassurant affiché sous le loader (optionnel).
  final String? message;

  /// Taille du loader.
  final double taille;

  /// Rendre le fond transparent (pour superposer sur un contenu existant).
  final bool fondTransparent;

  const LoaderPage({
    super.key,
    this.message,
    this.taille = 46,
    this.fondTransparent = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: fondTransparent ? Colors.transparent : const Color(0xFF08111F),
      alignment: Alignment.center,
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          LoaderPremium(size: taille),
          if (message != null && message!.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text(
              message!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
