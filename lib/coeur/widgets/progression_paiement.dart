import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:update_camtrans/coeur/constantes/couleurs.dart';

/// ============================================================
/// WIDGET: ProgressionPaiement
/// ============================================================
/// Affiche les étapes progressives d'un paiement Mobile Money
/// avec animations fluides pour rassurer l'utilisateur pendant
/// le processus (qui peut durer jusqu'à 2 minutes avec CamPay).
///
/// ✅ HUMANISATION 3.1: Remplace le simple "Traitement en cours..."
/// par une expérience guidée, étape par étape, avec feedback visuel.
/// ============================================================
class ProgressionPaiement extends StatefulWidget {
  /// Les étapes à afficher séquentiellement
  final List<EtapePaiement> etapes;

  /// Durée entre chaque étape (en ms)
  final int dureeEntreEtapesMs;

  /// Callback quand toutes les étapes sont terminées
  final VoidCallback? onTermine;

  const ProgressionPaiement({
    super.key,
    required this.etapes,
    this.dureeEntreEtapesMs = 3000,
    this.onTermine,
  });

  /// Étapes prédéfinies pour un paiement Mobile Money (MTN/Orange)
  static List<EtapePaiement> etapesMobileMoney({required String montant, required String operateur}) {
    return [
      EtapePaiement(
        icone: Icons.send_rounded,
        titre: "Envoi de la demande...",
        description: "Connexion à $operateur en cours",
        couleur: CouleursApp.primaire,
      ),
      EtapePaiement(
        icone: Icons.phone_android_rounded,
        titre: "Confirmez sur votre téléphone",
        description: "Un message USSD va s'afficher. Acceptez le paiement de $montant FCFA.",
        couleur: const Color(0xFFFF8C00),
      ),
      EtapePaiement(
        icone: Icons.sync_rounded,
        titre: "Vérification en cours...",
        description: "Nous attendons la confirmation de $operateur",
        couleur: CouleursApp.primaireNeon,
      ),
      EtapePaiement(
        icone: Icons.security_rounded,
        titre: "Sécurisation du paiement",
        description: "Enregistrement de la transaction",
        couleur: CouleursApp.accent,
      ),
    ];
  }

  /// Étapes prédéfinies pour un abonnement
  static List<EtapePaiement> etapesAbonnement({required String montant, required String operateur}) {
    return [
      EtapePaiement(
        icone: Icons.send_rounded,
        titre: "Envoi de la demande...",
        description: "Connexion à $operateur en cours",
        couleur: CouleursApp.primaire,
      ),
      EtapePaiement(
        icone: Icons.phone_android_rounded,
        titre: "Confirmez sur votre téléphone",
        description: "Acceptez le paiement de $montant FCFA pour votre abonnement",
        couleur: const Color(0xFFFF8C00),
      ),
      EtapePaiement(
        icone: Icons.sync_rounded,
        titre: "Vérification du paiement...",
        description: "Validation auprès de $operateur — cela peut prendre jusqu'à 2 minutes",
        couleur: CouleursApp.primaireNeon,
      ),
      EtapePaiement(
        icone: Icons.workspace_premium_rounded,
        titre: "Activation de l'abonnement",
        description: "Bientôt prêt ! Votre accès est en cours d'activation 🚀",
        couleur: Colors.amber,
      ),
    ];
  }

  @override
  State<ProgressionPaiement> createState() => _ProgressionPaiementState();
}

class _ProgressionPaiementState extends State<ProgressionPaiement>
    with SingleTickerProviderStateMixin {
  int _etapeCourante = 0;
  Timer? _timer;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _demarrerProgression();
  }

  void _demarrerProgression() {
    _timer = Timer.periodic(
      Duration(milliseconds: widget.dureeEntreEtapesMs),
      (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }

        if (_etapeCourante < widget.etapes.length - 1) {
          setState(() => _etapeCourante++);
        } else {
          timer.cancel();
          widget.onTermine?.call();
        }
      },
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final etapeActuelle = widget.etapes[_etapeCourante];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Indicateur animé principal
        AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            return Container(
              width: 80 + (_pulseController.value * 10),
              height: 80 + (_pulseController.value * 10),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: etapeActuelle.couleur.withValues(alpha: 0.1 + (_pulseController.value * 0.05)),
                border: Border.all(
                  color: etapeActuelle.couleur.withValues(alpha: 0.4 + (_pulseController.value * 0.3)),
                  width: 2,
                ),
              ),
              child: child,
            );
          },
          child: Icon(
            etapeActuelle.icone,
            color: etapeActuelle.couleur,
            size: 36,
          ),
        ),

        const SizedBox(height: 24),

        // Titre de l'étape
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          child: Text(
            etapeActuelle.titre,
            key: ValueKey(_etapeCourante),
            style: GoogleFonts.inter(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
        ),

        const SizedBox(height: 8),

        // Description de l'étape
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          child: Text(
            etapeActuelle.description,
            key: ValueKey('desc_$_etapeCourante'),
            style: GoogleFonts.inter(
              color: Colors.white54,
              fontSize: 12,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ),

        const SizedBox(height: 24),

        // Barre de progression par étapes
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(widget.etapes.length, (index) {
            final isActive = index == _etapeCourante;
            final isDone = index < _etapeCourante;

            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: isActive ? 28 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: isDone
                    ? CouleursApp.succes
                    : isActive
                        ? etapeActuelle.couleur
                        : Colors.white12,
                borderRadius: BorderRadius.circular(4),
              ),
            );
          }),
        ),

        const SizedBox(height: 16),

        // Numéro d'étape
        Text(
          "Étape ${_etapeCourante + 1} sur ${widget.etapes.length}",
          style: GoogleFonts.inter(color: Colors.white24, fontSize: 11),
        ),
      ],
    ).animate().fadeIn(duration: 300.ms);
  }
}

/// Modèle d'une étape de paiement
class EtapePaiement {
  final IconData icone;
  final String titre;
  final String description;
  final Color couleur;

  const EtapePaiement({
    required this.icone,
    required this.titre,
    required this.description,
    required this.couleur,
  });
}
