import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:update_camtrans/coeur/constantes/couleurs.dart';
import 'package:update_camtrans/coeur/constantes/tailles.dart';
import 'package:update_camtrans/coeur/constantes/textes.dart';
import 'package:update_camtrans/coeur/routes/routes.dart';
import 'package:update_camtrans/coeur/widgets/effets_visuels.dart';
import 'package:update_camtrans/coeur/etat/utilisateur_provider.dart';
import 'package:update_camtrans/services/service_authentification.dart';
import 'package:flutter_animate/flutter_animate.dart';

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

    // Connecté -> Déterminer le rôle via le provider centralisé
    try {
      final role = await ref.read(userRoleProvider.future);

      if (!mounted) return;

      if (role == 'admin') {
        context.go(RoutesApplication.admin);
      } else if (role == 'client') {
        context.go(RoutesApplication.tableauBordClient);
      } else if (role == 'transporteur') {
        context.go(RoutesApplication.tableauBordTransporteur);
      } else {
        context.go(RoutesApplication.choixProfil);
      }
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

                  // Logo
                  Expanded(
                    child: Center(
                      child: Container(
                        width: 320,
                        height: 320,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  CouleursApp.primaireNeon.withValues(alpha: 0.4),
                              blurRadius: 50,
                              spreadRadius: 10,
                            ),
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 30,
                              offset: const Offset(0, 10),
                            ),
                          ],
                          image: const DecorationImage(
                            image: AssetImage('assets/images/logo_splash.jpg'),
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                  ),

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
                            backgroundColor:
                                Colors.white.withValues(alpha: 0.15),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          );
                        },
                      ),
                    ),
                  ),

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
