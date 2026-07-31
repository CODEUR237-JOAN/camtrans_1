import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../coeur/constantes/couleurs.dart';
import '../../coeur/constantes/tailles.dart';
import '../../coeur/constantes/textes.dart';
import '../../coeur/routes/routes.dart';
import '../../coeur/widgets/effets_visuels.dart';
import '../../services/service_authentification.dart';
import '../../services/service_firestore.dart';

class EcranSplash extends ConsumerStatefulWidget {
  const EcranSplash({super.key});

  @override
  ConsumerState<EcranSplash> createState() => _EcranSplashState();
}

class _EcranSplashState extends ConsumerState<EcranSplash>
    with TickerProviderStateMixin {
  late AnimationController _particleController;

  @override
  void initState() {
    super.initState();
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..forward();

    _demarrerRedirection();
  }

  Future<void> _demarrerRedirection() async {
    // On attend au moins 3 secondes pour l'effet visuel
    await Future.delayed(const Duration(seconds: 3));
    
    if (!mounted) return;

    final user = ref.read(serviceAuthentificationProvider).utilisateur;
    
    if (user == null) {
      if (!mounted) return;
      // Non connecté -> Onboarding
      context.go(RoutesApplication.onboarding);
      return;
    }

    // Connecté -> Déterminer le rôle
    try {
      final uid = user.uid;
      final serviceDb = ref.read(serviceFirestoreProvider);

      // Admin hardcodé
      if (user.email == 'admintrans@gmail.com') {
        if (!mounted) return;
        context.go(RoutesApplication.admin);
        return;
      }

      // Check Admin collection
      final docAdmin = await serviceDb.lireDocument(collection: 'admin', id: uid);
      if (!mounted) return;
      if (docAdmin.exists) {
        context.go(RoutesApplication.admin);
        return;
      }

      // Check Client
      final docClient = await serviceDb.lireDocument(collection: 'clients', id: uid);
      if (!mounted) return;
      if (docClient.exists) {
        context.go(RoutesApplication.tableauBordClient);
        return;
      }

      // Check Transporteur
      final docTransp = await serviceDb.lireDocument(collection: 'transporteurs', id: uid);
      if (!mounted) return;
      if (docTransp.exists) {
        context.go(RoutesApplication.tableauBordTransporteur);
        return;
      }

      // Si aucun rôle trouvé, vers le choix de profil
      if (!mounted) return;
      context.go(RoutesApplication.choixProfil);
    } catch (e) {
      if (!mounted) return;
      // En cas d'erreur (ex: pas d'internet), on va à la connexion par sécurité
      context.go(RoutesApplication.connexion);
    }
  }

  @override
  void dispose() {
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: CouleursApp.degradeSplash,
        ),
        child: Stack(
          children: [
            // Particules animées en arrière-plan
            _ParticulesAnimees(controller: _particleController),

            // Contenu principal
            SafeArea(
              child: Column(
                children: [
                  const Spacer(),

                  // Logo avec glow néon
                  Container(
                    width: 170,
                    height: 170,
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(40),
                      boxShadow: [
                        BoxShadow(
                          color: CouleursApp.primaireNeon.withValues(alpha: 0.4),
                          blurRadius: 40,
                          spreadRadius: 8,
                        ),
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 30,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.local_shipping,
                      size: 140,
                      color: CouleursApp.primaire,
                    ),
                  )
                      .animate()
                      .scale(duration: 1000.ms, curve: Curves.elasticOut)
                      .fadeIn(duration: 800.ms)
                      .shimmer(delay: 1000.ms, duration: 1500.ms),

                  const SizedBox(height: 40),

                  // Nom de l'app avec dégradé de texte
                  ShaderMask(
                    shaderCallback: (bounds) {
                      return const LinearGradient(
                        colors: [Colors.white, Color(0xFFC7D2FE)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ).createShader(bounds);
                    },
                    child: Text(
                      TextesApp.nomApplication,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 1.5,
                        height: 1.1,
                      ),
                    ),
                  )
                      .animate()
                      .fadeIn(delay: 500.ms, duration: 600.ms)
                      .slideY(begin: 0.5, end: 0, curve: Curves.easeOutBack),

                  const SizedBox(height: 14),

                  // Slogan
                  Text(
                    TextesApp.slogan,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                      height: 1.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ).animate().fadeIn(delay: 1000.ms, duration: 600.ms),

                  const SizedBox(height: 30),

                  // Badge premium
                  GlassCard(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    borderRadius: 30,
                    blur: 15,
                    child: const Text(
                      "L'Excellence Logistique",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ).animate().fadeIn(delay: 800.ms).slideY(begin: 0.5),

                  const Spacer(),

                  // Indicateur de progression stylisé
                  SizedBox(
                    width: 180,
                    height: 4,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: 1),
                        duration: const Duration(seconds: 3),
                        builder: (context, value, child) {
                          return LinearProgressIndicator(
                            value: value,
                            backgroundColor: Colors.white.withValues(alpha: 0.15),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          );
                        },
                      ),
                    ),
                  ).animate().fadeIn(delay: 1400.ms, duration: 600.ms),

                  const SizedBox(height: 20),

                  Text(
                    "Chargement...",
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  )
                      .animate(onPlay: (controller) => controller.repeat())
                      .shimmer(duration: 2.seconds, color: Colors.white24),

                  SizedBox(height: TaillesApp.espaceGeant),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget de particules animées pour le fond du splash
class _ParticulesAnimees extends StatelessWidget {
  final AnimationController controller;

  const _ParticulesAnimees({required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _ParticulesPainter(progress: controller.value),
          size: Size.infinite,
        );
      },
    );
  }
}

class _ParticulesPainter extends CustomPainter {
  final double progress;
  final Random _random = Random(42);

  _ParticulesPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.15)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 30; i++) {
      final x = _random.nextDouble() * size.width;
      final baseY = _random.nextDouble() * size.height;
      final radius = 2 + _random.nextDouble() * 4;
      final speed = 0.3 + _random.nextDouble() * 0.7;
      final y = (baseY - progress * speed * size.height * 0.5) % size.height;
      final opacity = 0.1 + _random.nextDouble() * 0.2;

      paint.color = Colors.white.withValues(alpha: opacity);
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
