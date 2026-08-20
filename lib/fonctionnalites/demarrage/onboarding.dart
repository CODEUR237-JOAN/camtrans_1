import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import 'package:update_camtrans/coeur/constantes/couleurs.dart';
import 'package:update_camtrans/coeur/constantes/images.dart';
import 'package:update_camtrans/coeur/constantes/tailles.dart';
import 'package:update_camtrans/coeur/constantes/textes.dart';
import 'package:update_camtrans/coeur/routes/routes.dart';
import 'package:update_camtrans/coeur/widgets/effets_visuels.dart';

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
      couleur: CouleursApp.primaire,
      icone: Icons.local_shipping_outlined,
    ),
    _PageOnboarding(
      image: ImagesApp.onboarding2,
      titre: TextesApp.titreOnboarding2,
      description: TextesApp.descriptionOnboarding2,
      couleur: CouleursApp.secondaire,
      icone: Icons.location_on_outlined,
    ),
    _PageOnboarding(
      image: ImagesApp.onboarding3,
      titre: TextesApp.titreOnboarding3,
      description: TextesApp.descriptionOnboarding3,
      couleur: CouleursApp.accentRose,
      icone: Icons.auto_awesome_outlined,
    ),
  ];

  void _pageSuivante() {
    if (_pageActuelle < _pages.length - 1) {
      _controleurPage.nextPage(
        duration: const Duration(milliseconds: 520),
        curve: Curves.easeOutCubic,
      );
      return;
    }
    context.go(RoutesApplication.connexion);
  }

  @override
  void dispose() {
    _controleurPage.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isCompact = size.height < 720;
    final panelHeight = size.height * (isCompact ? 0.48 : 0.43);

    return Scaffold(
      backgroundColor: CouleursApp.fond,
      body: FondPremiumAnime(
        child: Stack(
          children: [
            PageView.builder(
              controller: _controleurPage,
              itemCount: _pages.length,
              onPageChanged: (index) => setState(() => _pageActuelle = index),
              itemBuilder: (context, index) {
                return _OnboardingSlide(
                  page: _pages[index],
                  index: index,
                  panelHeight: panelHeight,
                  isCompact: isCompact,
                );
              },
            ),
            Positioned(
              top: MediaQuery.paddingOf(context).top + 12,
              right: 20,
              child: BadgeVerre(
                color: Colors.white.withValues(alpha: 0.78),
                child: InkWell(
                  borderRadius: BorderRadius.circular(TaillesApp.rayonPill),
                  onTap: () => context.go(RoutesApplication.connexion),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    child: Text(
                      'Passer',
                      style: TextStyle(
                        color: CouleursApp.textePrincipal,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ).animate().fadeIn(delay: 500.ms).slideY(begin: -0.2),
            ),
            Positioned(
              left: TaillesApp.margePage,
              right: TaillesApp.margePage,
              bottom: 28,
              child: Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 20,
                runSpacing: 12,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(
                      _pages.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 280),
                        curve: Curves.easeOutCubic,
                        margin: const EdgeInsets.only(right: 8),
                        width: _pageActuelle == index ? 30 : 9,
                        height: 9,
                        decoration: BoxDecoration(
                          gradient: _pageActuelle == index
                              ? CouleursApp.degradeNeon
                              : null,
                          color: _pageActuelle == index
                              ? null
                              : CouleursApp.primaire.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: _pageSuivante,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 280),
                      curve: Curves.easeOutCubic,
                      height: 58,
                      width: _pageActuelle == _pages.length - 1 ? 168 : 58,
                      decoration: BoxDecoration(
                        gradient: CouleursApp.degradePrincipal,
                        borderRadius: BorderRadius.circular(99),
                        boxShadow: [
                          BoxShadow(
                            color: CouleursApp.primaire.withValues(alpha: 0.28),
                            blurRadius: 22,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Center(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 180),
                          child: _pageActuelle == _pages.length - 1
                              ? const Text(
                                  'Commencer',
                                  key: ValueKey('start'),
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                  ),
                                )
                              : const Icon(
                                  Icons.arrow_forward_rounded,
                                  key: ValueKey('next'),
                                  color: Colors.white,
                                ),
                        ),
                      ),
                    ),
                  ),
                ],
              ).animate().fadeIn(delay: 700.ms).slideY(begin: 0.25),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingSlide extends StatelessWidget {
  final _PageOnboarding page;
  final int index;
  final double panelHeight;
  final bool isCompact;

  const _OnboardingSlide({
    required this.page,
    required this.index,
    required this.panelHeight,
    required this.isCompact,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final imageHeight = size.height - panelHeight + 52;

    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: imageHeight,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                page.image,
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
              )
                  .animate(key: ValueKey('image_$index'))
                  .fadeIn(duration: 500.ms)
                  .scale(begin: const Offset(1.04, 1.04), end: const Offset(1, 1)),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.08),
                      Colors.black.withValues(alpha: 0.08),
                      CouleursApp.fond.withValues(alpha: 0.98),
                    ],
                    stops: const [0, 0.58, 1],
                  ),
                ),
              ),
            ],
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: panelHeight,
          child: Container(
            padding: EdgeInsets.fromLTRB(24, isCompact ? 24 : 32, 24, 112),
            decoration: BoxDecoration(
              color: CouleursApp.fond.withValues(alpha: 0.96),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(34)),
              border: Border.all(color: Colors.white.withValues(alpha: 0.82)),
              boxShadow: [
                BoxShadow(
                  color: CouleursApp.ombre.withValues(alpha: 0.18),
                  blurRadius: 34,
                  offset: const Offset(0, -14),
                ),
              ],
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 12,
                      runSpacing: 8,
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                page.couleur,
                                page.couleur.withValues(alpha: 0.68),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: page.couleur.withValues(alpha: 0.22),
                                blurRadius: 18,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Icon(page.icone, color: Colors.white),
                        ),
                        BadgeVerre(
                          color: Colors.white.withValues(alpha: 0.72),
                          child: Text(
                            'Etape ${index + 1} / 3',
                            style: TextStyle(
                              color: page.couleur,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ).animate(key: ValueKey('badge_$index')).fadeIn().slideX(begin: -0.12),
                    SizedBox(height: isCompact ? 18 : 24),
                    Text(
                      page.titre,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: isCompact ? 25 : 29,
                        fontWeight: FontWeight.w900,
                        color: CouleursApp.textePrincipal,
                        height: 1.13,
                      ),
                    )
                        .animate(key: ValueKey('titre_$index'))
                        .fadeIn(delay: 120.ms)
                        .slideY(begin: 0.18, curve: Curves.easeOutCubic),
                    const SizedBox(height: 14),
                    Text(
                      page.description,
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        height: 1.58,
                        color: CouleursApp.texteSecondaire,
                        fontWeight: FontWeight.w500,
                      ),
                    )
                        .animate(key: ValueKey('desc_$index'))
                        .fadeIn(delay: 230.ms)
                        .slideY(begin: 0.14, curve: Curves.easeOutCubic),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PageOnboarding {
  final String image;
  final String titre;
  final String description;
  final Color couleur;
  final IconData icone;

  _PageOnboarding({
    required this.image,
    required this.titre,
    required this.description,
    required this.couleur,
    required this.icone,
  });
}
