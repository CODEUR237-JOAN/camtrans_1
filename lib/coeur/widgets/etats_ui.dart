import 'package:flutter/material.dart';

import 'package:update_camtrans/coeur/constantes/couleurs.dart';
import 'effets_visuels.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:update_camtrans/coeur/widgets/loader_premium.dart';


/// =======================================================
/// ÉTATS UI MODERNISÉS
/// Loading shimmer, Empty avec animation, Error avec bounce
/// =======================================================

class EtatChargement extends StatelessWidget {
  final String message;

  const EtatChargement({
    super.key,
    this.message = "Chargement en cours...",
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Semantics(
      label: message,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: CouleursApp.primaire.withValues(alpha: isDark ? 0.15 : 0.08),
                shape: BoxShape.circle,
              ),
              child: const SizedBox(
                width: 32,
                height: 32,
                child: LoaderPremium(size: 24),
              ),
            )
                .animate(onPlay: (c) => c.repeat())
                .scale(
                  duration: const Duration(milliseconds: 1200),
                  begin: const Offset(0.9, 0.9),
                  end: const Offset(1.05, 1.05),
                )
                .then()
                .scale(
                  duration: const Duration(milliseconds: 1200),
                  begin: const Offset(1.05, 1.05),
                  end: const Offset(0.9, 0.9),
                ),
            const SizedBox(height: 24),
            Text(
              message,
              style: TextStyle(
                color: isDark ? Colors.white60 : CouleursApp.texteSecondaire,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            )
                ,
          ],
        ),
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
  final bool glassmorphism;

  const EtatVide({
    super.key,
    required this.titre,
    required this.message,
    this.icone = Icons.inbox,
    this.onAction,
    this.actionLabel,
    this.glassmorphism = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget content = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                CouleursApp.primaire.withValues(alpha: isDark ? 0.2 : 0.08),
                CouleursApp.secondaire.withValues(alpha: isDark ? 0.15 : 0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icone,
            size: 48,
            color: CouleursApp.primaire.withValues(alpha: isDark ? 0.8 : 0.6),
          ),
        )
            ,
        const SizedBox(height: 24),
        Text(
          titre,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : CouleursApp.textePrincipal,
          ),
        )
            ,
        const SizedBox(height: 8),
        Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isDark ? Colors.white60 : CouleursApp.texteSecondaire,
            fontSize: 14,
            height: 1.5,
          ),
        )
            ,
        if (onAction != null && actionLabel != null) ...[
          const SizedBox(height: 28),
          GradientButton(
            text: actionLabel!,
            onPressed: onAction,
            height: 48,
            width: 200,
          )
              ,
        ],
      ],
    );

    return Semantics(
      label: "$titre. $message",
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: glassmorphism
              ? GlassCard(
                  padding: const EdgeInsets.all(32),
                  child: content,
                )
              : content,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: CouleursApp.degradeErreur,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: CouleursApp.erreur.withValues(alpha: 0.3),
                      blurRadius: 20,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.error_outline,
                  color: Colors.white,
                  size: 40,
                ),
              )
                  ,
              const SizedBox(height: 24),
              Text(
                "Oups ! Quelque chose s'est mal passé.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : CouleursApp.textePrincipal,
                ),
              )
                  ,
              const SizedBox(height: 8),
              Text(
                erreur,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isDark ? Colors.white60 : CouleursApp.texteSecondaire,
                  fontSize: 14,
                  height: 1.5,
                ),
              )
                  ,
              const SizedBox(height: 28),
              GradientButton(
                text: "Réessayer",
                onPressed: onRetry,
                icon: Icons.refresh,
                height: 48,
                width: 200,
                gradient: CouleursApp.degradeErreur,
              )
                  ,
            ],
          ),
        ),
      ),
    );
  }
}
