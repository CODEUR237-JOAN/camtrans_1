import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'dart:ui';

import '../../coeur/constantes/couleurs.dart';
import '../../coeur/constantes/images.dart';
import '../../coeur/constantes/tailles.dart';
import '../../coeur/constantes/textes.dart';
import '../../coeur/routes/routes.dart';

class Onboarding extends StatefulWidget {
  const Onboarding({super.key});

  @override
  State<Onboarding> createState() => _OnboardingState();
}

class _OnboardingState extends State<Onboarding> {
  final PageController _controleurPage = PageController();
  int _pageActuelle = 0;

  final List<_PageOnboarding> _pages = [
    _PageOnboarding(
      image: ImagesApp.onboarding1,
      titre: TextesApp.titreOnboarding1,
      description: TextesApp.descriptionOnboarding1,
    ),
    _PageOnboarding(
      image: ImagesApp.onboarding2,
      titre: TextesApp.titreOnboarding2,
      description: TextesApp.descriptionOnboarding2,
    ),
    _PageOnboarding(
      image: ImagesApp.onboarding3,
      titre: TextesApp.titreOnboarding3,
      description: TextesApp.descriptionOnboarding3,
    ),
  ];

  void _pageSuivante() {
    if (_pageActuelle < _pages.length - 1) {
      _controleurPage.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic,
      );
    } else {
      context.go(RoutesApplication.connexion);
    }
  }

  @override
  void dispose() {
    _controleurPage.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CouleursApp.fond,
      body: Stack(
        children: [
          // 1. PageView for images and texts
          PageView.builder(
            controller: _controleurPage,
            itemCount: _pages.length,
            onPageChanged: (index) {
              setState(() {
                _pageActuelle = index;
              });
            },
            itemBuilder: (context, index) {
              final page = _pages[index];
              return Stack(
                fit: StackFit.expand,
                children: [
                  // Image (Top half)
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    height: MediaQuery.of(context).size.height * 0.65,
                    child: Image.asset(
                      page.image,
                      fit: BoxFit.cover,
                    ).animate(key: ValueKey(index)).fadeIn(duration: 600.ms).scale(begin: const Offset(1.1, 1.1), end: const Offset(1, 1)),
                  ),
                  // Gradient to blend image into the white background
                  Positioned(
                    top: MediaQuery.of(context).size.height * 0.4,
                    left: 0,
                    right: 0,
                    height: MediaQuery.of(context).size.height * 0.25,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            CouleursApp.fond.withValues(alpha: 0.0),
                            CouleursApp.fond,
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Text Area (Glassmorphism look)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    height: MediaQuery.of(context).size.height * 0.45,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 30),
                      decoration: BoxDecoration(
                        color: CouleursApp.fond,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(40),
                          topRight: Radius.circular(40),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 30,
                            offset: const Offset(0, -10),
                          )
                        ],
                      ),
                      child: Column(
                        children: [
                          const SizedBox(height: 40),
                          Text(
                            page.titre,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              color: CouleursApp.textePrincipal,
                              letterSpacing: -0.5,
                              height: 1.2,
                            ),
                          ).animate(key: ValueKey("t_$index")).fadeIn(delay: 200.ms).slideY(begin: 0.2, end: 0, curve: Curves.easeOutBack),
                          const SizedBox(height: 20),
                          Text(
                            page.description,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 16,
                              height: 1.6,
                              color: CouleursApp.texteSecondaire,
                            ),
                          ).animate(key: ValueKey("d_$index")).fadeIn(delay: 400.ms).slideY(begin: 0.2, end: 0, curve: Curves.easeOutBack),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),

          // 2. Skip Button
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            right: 20,
            child: TextButton(
              onPressed: () => context.go(RoutesApplication.connexion),
              style: TextButton.styleFrom(
                backgroundColor: Colors.white.withValues(alpha: 0.8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text(
                "Passer",
                style: TextStyle(fontWeight: FontWeight.bold, color: CouleursApp.textePrincipal),
              ),
            ).animate().fadeIn(delay: 1.seconds),
          ),

          // 3. Dots and Next Button
          Positioned(
            bottom: 40,
            left: 30,
            right: 30,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Dots
                Row(
                  children: List.generate(
                    _pages.length,
                    (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.only(right: 8),
                      width: _pageActuelle == index ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _pageActuelle == index
                            ? CouleursApp.primaire
                            : CouleursApp.primaire.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),

                // Next Button
                GestureDetector(
                  onTap: _pageSuivante,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    height: 60,
                    width: _pageActuelle == _pages.length - 1 ? 160 : 60,
                    decoration: BoxDecoration(
                      color: CouleursApp.primaire,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: CouleursApp.primaire.withValues(alpha: 0.4),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Center(
                      child: _pageActuelle == _pages.length - 1
                          ? const Text(
                              "Commencer",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          : const Icon(
                              Icons.arrow_forward_ios,
                              color: Colors.white,
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PageOnboarding {
  final String image;
  final String titre;
  final String description;

  _PageOnboarding({
    required this.image,
    required this.titre,
    required this.description,
  });
}