import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../coeur/constantes/couleurs.dart';
import '../../coeur/constantes/images.dart';
import '../../coeur/constantes/tailles.dart';
import '../../coeur/constantes/textes.dart';
import '../../coeur/routes/routes.dart';

class EcranSplash extends StatefulWidget {
  const EcranSplash({super.key});

  @override
  State<EcranSplash> createState() => _EcranSplashState();
}

class _EcranSplashState extends State<EcranSplash> {
  @override
  void initState() {
    super.initState();

    Timer(
      const Duration(seconds: 4), // Wait an extra second for animations
      () {
        if (!mounted) return;
        context.go(RoutesApplication.onboarding);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: CouleursApp.degradeSplash,
        ),
        child: SafeArea(
          child: Column(
            children: [
              const Spacer(),
              Container(
                width: 160,
                height: 160,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(35),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.local_shipping,
                  size: 150,
                  color: CouleursApp.primaire,
                ),
              )
                  .animate()
                  .scale(duration: 1000.ms, curve: Curves.elasticOut)
                  .fadeIn(duration: 800.ms)
                  .shimmer(delay: 1000.ms, duration: 1500.ms),

              const SizedBox(height: 35),

              const Text(
                TextesApp.nomApplication,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.2,
                ),
              )
                  .animate()
                  .fadeIn(delay: 500.ms, duration: 600.ms)
                  .slideY(begin: 0.5, end: 0, curve: Curves.easeOutBack),

              const SizedBox(height: 12),

              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 35),
                child: Text(
                  TextesApp.slogan,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                    height: 1.5,
                  ),
                ),
              ).animate().fadeIn(delay: 1000.ms, duration: 600.ms),

              const Spacer(),

              const SizedBox(
                width: 50,
                height: 50,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 4,
                ),
              ).animate().fadeIn(delay: 1400.ms, duration: 600.ms),

              const SizedBox(height: 25),

              const Text(
                "Chargement...",
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              )
                  .animate(onPlay: (controller) => controller.repeat())
                  .shimmer(duration: 2.seconds, color: Colors.white24),

              const SizedBox(height: TaillesApp.espaceGeant),
            ],
          ),
        ),
      ),
    );
  }
}