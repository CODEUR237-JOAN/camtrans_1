import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../constantes/couleurs.dart';

/// =======================================================
/// FICHIER : etats_ui.dart
/// Contient les widgets génériques pour gérer les états (Loading, Error, Empty)
/// avec un support complet d'accessibilité (Semantics).
/// =======================================================

class EtatChargement extends StatelessWidget {
  final String message;

  const EtatChargement({
    super.key, 
    this.message = "Chargement en cours...",
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: message,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: CouleursApp.primaire),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                fontSize: 14,
              ),
            ),
          ],
        ).animate().fadeIn(duration: 300.ms),
      ),
    );
  }
}

class EtatVide extends StatelessWidget {
  final String titre;
  final String message;
  final IconData icone;
  final VoidCallback? onAction;
  final String? actionLabel;

  const EtatVide({
    super.key,
    required this.titre,
    required this.message,
    this.icone = Icons.inbox,
    this.onAction,
    this.actionLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: "$titre. $message",
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icone,
                size: 80,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2),
              ),
              const SizedBox(height: 24),
              Text(
                titre,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  fontSize: 15,
                ),
              ),
              if (onAction != null && actionLabel != null) ...[
                const SizedBox(height: 32),
                OutlinedButton(
                  onPressed: onAction,
                  child: Text(actionLabel!),
                )
              ]
            ],
          ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1),
        ),
      ),
    );
  }
}

class EtatErreur extends StatelessWidget {
  final String erreur;
  final VoidCallback onRetry;

  const EtatErreur({
    super.key,
    required this.erreur,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: "Une erreur est survenue : $erreur",
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: CouleursApp.erreur.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.error_outline,
                  color: CouleursApp.erreur,
                  size: 48,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                "Oups ! Quelque chose s'est mal passé.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                erreur,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh, color: Colors.white),
                label: const Text("Réessayer", style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: CouleursApp.erreur,
                ),
              )
            ],
          ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.95, 0.95)),
        ),
      ),
    );
  }
}
