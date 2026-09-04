import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:update_camtrans/coeur/constantes/couleurs.dart';
import 'package:update_camtrans/services/service_assistant_vocal.dart';

class BoutonAssistantVocal extends ConsumerWidget {
  /// Si [compact] est true, le bouton s'affiche en mode mini (40px)
  /// pour s'intégrer dans la barre de navigation sans cacher les autres onglets.
  final bool compact;
  const BoutonAssistantVocal({super.key, this.compact = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final etatAssistant = ref.watch(serviceAssistantVocalProvider);
    final service = ref.read(serviceAssistantVocalProvider.notifier);

    // Ne s'affiche que si l'état est "repos", "veille" ou "erreur"
    if (etatAssistant != EtatAssistant.repos && etatAssistant != EtatAssistant.veille && etatAssistant != EtatAssistant.erreur) {
      return const SizedBox.shrink();
    }

    final double size = compact ? 44 : 56;
    final double iconSize = compact ? 20 : 28;

    return GestureDetector(
      onTap: () {
        _afficherBottomSheet(context, ref, service);
        if (etatAssistant == EtatAssistant.repos || etatAssistant == EtatAssistant.erreur) {
           service.demarrerEcoute(isWakeWord: true);
        }
      },
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: CouleursApp.primaire,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: CouleursApp.primaire.withValues(alpha: 0.45),
              blurRadius: compact ? 12 : 18,
              spreadRadius: compact ? 1 : 3,
            ),
          ],
        ),
        child: Icon(Iconsax.microphone_2_copy, color: Colors.white, size: iconSize),
      ),
    )
    .animate(onPlay: (controller) => controller.repeat(reverse: true))
    .scale(begin: const Offset(1, 1), end: const Offset(1.05, 1.05), duration: 1500.ms)
    .boxShadow(
      begin: BoxShadow(color: CouleursApp.primaire.withValues(alpha: 0.3), blurRadius: 10, spreadRadius: 0),
      end: BoxShadow(color: CouleursApp.primaire.withValues(alpha: 0.7), blurRadius: 25, spreadRadius: 5),
      duration: 1500.ms,
    );
  }

  void _afficherBottomSheet(BuildContext context, WidgetRef ref, ServiceAssistantVocal service) {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (context) => const AssistantBottomSheet(),
    ).whenComplete(() {
      service.arreterEcoute();
    });
  }
}

class AssistantBottomSheet extends ConsumerStatefulWidget {
  const AssistantBottomSheet({super.key});

  @override
  ConsumerState<AssistantBottomSheet> createState() => _AssistantBottomSheetState();
}

class _AssistantBottomSheetState extends ConsumerState<AssistantBottomSheet> {
  String _texteAffiche = "J'écoute...";

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final service = ref.read(serviceAssistantVocalProvider.notifier);
      service.onTextChanged = (texte) {
        if (mounted) {
          setState(() {
            _texteAffiche = texte;
          });
        }
      };
      
      service.onNavigate = (route) {
        if (mounted) {
          Navigator.pop(context); // Fermer le bottom sheet
          context.go(route);
        }
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    final etatAssistant = ref.watch(serviceAssistantVocalProvider);
    final service = ref.read(serviceAssistantVocalProvider.notifier);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 30, offset: const Offset(0, -10))
        ],
      ),
      // Le SingleChildScrollView permet au contenu de défiler si l'écran est trop petit,
      // évitant le débordement (overflow) de 14 pixels observé sur petits écrans.
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Bouton fermer
            Align(
              alignment: Alignment.topRight,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white54),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
            ),
            
            const SizedBox(height: 10),

            // Animation centrale qui change selon l'état de l'assistant
            _buildAnimation(etatAssistant),

            const SizedBox(height: 30),

            // Texte de statut mis à jour en temps réel
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Text(
                _texteAffiche,
                key: ValueKey<String>(_texteAffiche),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: etatAssistant == EtatAssistant.erreur ? Colors.redAccent : Colors.white,
                  fontSize: 18,
                  fontWeight: etatAssistant == EtatAssistant.parle ? FontWeight.normal : FontWeight.w600,
                ),
              ),
            ),

            const SizedBox(height: 40),

            // Bouton d'action dont l'icône change selon l'état de l'assistant
            if (etatAssistant == EtatAssistant.ecoute || etatAssistant == EtatAssistant.veille)
              ElevatedButton(
                onPressed: () => service.arreterEcoute(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: CouleursApp.primaire,
                  shape: const CircleBorder(),
                  padding: const EdgeInsets.all(16),
                ),
                child: const Icon(Icons.stop, color: Colors.white, size: 28),
              )
            else if (etatAssistant == EtatAssistant.repos || etatAssistant == EtatAssistant.erreur)
              ElevatedButton(
                onPressed: () => service.demarrerEcoute(isWakeWord: false),
                style: ElevatedButton.styleFrom(
                  backgroundColor: CouleursApp.primaire,
                  shape: const CircleBorder(),
                  padding: const EdgeInsets.all(16),
                ),
                child: const Icon(Icons.mic, color: Colors.white, size: 28),
              )
            else if (etatAssistant == EtatAssistant.parle)
              ElevatedButton(
                onPressed: () => service.arreterEcoute(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white24,
                  shape: const CircleBorder(),
                  padding: const EdgeInsets.all(16),
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 28),
              ),
              
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimation(EtatAssistant etat) {
    switch (etat) {
      case EtatAssistant.veille:
        return _buildPulsingMic(Colors.orangeAccent);
      case EtatAssistant.ecoute:
        return _buildPulsingMic(CouleursApp.primaire);
      case EtatAssistant.traitement:
        return const CircularProgressIndicator(color: CouleursApp.succes)
            .animate(onPlay: (controller) => controller.repeat())
            .scale(begin: const Offset(0.8, 0.8), end: const Offset(1.2, 1.2), duration: 800.ms);
      case EtatAssistant.parle:
        return _buildPulsingMic(CouleursApp.succes);
      case EtatAssistant.erreur:
        return const Icon(Icons.error_outline, color: Colors.redAccent, size: 60);
      default:
        return const Icon(Icons.mic_none, color: Colors.white54, size: 60);
    }
  }

  Widget _buildPulsingMic(Color couleur) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: couleur.withValues(alpha: 0.2),
        shape: BoxShape.circle,
      ),
      child: Icon(Iconsax.microphone_2_copy, color: couleur, size: 40),
    )
    .animate(onPlay: (controller) => controller.repeat(reverse: true))
    .scale(begin: const Offset(1, 1), end: const Offset(1.3, 1.3), duration: 800.ms)
    .boxShadow(
      begin: BoxShadow(color: couleur.withValues(alpha: 0.0), blurRadius: 0),
      end: BoxShadow(color: couleur.withValues(alpha: 0.5), blurRadius: 20, spreadRadius: 10),
      duration: 800.ms,
    );
  }
}
