import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:update_camtrans/coeur/constantes/couleurs.dart';
import 'package:update_camtrans/coeur/constantes/tailles.dart';
import 'package:update_camtrans/coeur/routes/routes.dart';
import 'package:update_camtrans/coeur/widgets/effets_visuels.dart';

class ChoixProfil extends StatelessWidget {
  const ChoixProfil({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CouleursApp.fond,
      body: FondPremiumAnime(
        safeArea: true,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 20, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded),
                    color: CouleursApp.textePrincipal,
                    onPressed: () => context.pop(),
                    tooltip: 'Retour',
                  ),
                  const Spacer(),
                  BadgeVerre(
                    color: Colors.white.withValues(alpha: 0.72),
                    child: const Text(
                      'Inscription',
                      style: TextStyle(
                        color: CouleursApp.textePrincipal,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.fromLTRB(
                  TaillesApp.margePage,
                  16,
                  TaillesApp.margePage,
                  24,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 620),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        BadgeVerre(
                          color: CouleursApp.primaire.withValues(alpha: 0.10),
                          borderRadius: 18,
                          child: const Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 8,
                            runSpacing: 4,
                            children: [
                              Icon(Icons.auto_awesome_rounded,
                                  size: 16, color: CouleursApp.primaire),
                              Text(
                                'Experience personnalisee',
                                style: TextStyle(
                                  color: CouleursApp.primaire,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        const Text(
                          'Comment souhaitez-vous utiliser CamTrans ?',
                          style: TextStyle(
                            fontSize: 31,
                            fontWeight: FontWeight.w900,
                            color: CouleursApp.textePrincipal,
                            height: 1.08,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Choisissez votre espace pour obtenir les bons outils, les bons indicateurs et les bonnes actions des le depart.',
                          style: TextStyle(
                            fontSize: 15,
                            color: CouleursApp.texteSecondaire,
                            height: 1.55,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 34),
                        _creerCarteProfil(
                          context,
                          titre: 'Client / Expediteur',
                          description:
                              'Expediez des colis, meubles ou marchandises et suivez chaque trajet en temps reel.',
                          badge: 'Je reserve un transport',
                          icone: Icons.inventory_2_outlined,
                          couleur: CouleursApp.primaire,
                          routeDest: RoutesApplication.inscriptionClient,
                          delay: 300,
                        ),
                        const SizedBox(height: 18),
                        _creerCarteProfil(
                          context,
                          titre: 'Transporteur / Chauffeur',
                          description:
                              'Recevez des courses, optimisez vos trajets et pilotez vos revenus depuis un espace dedie.',
                          badge: 'Je trouve des courses',
                          icone: Icons.local_shipping_outlined,
                          couleur: CouleursApp.accentOrange,
                          routeDest: RoutesApplication.inscriptionTransporteur,
                          delay: 400,
                        ),
                        const SizedBox(height: 28),
                        Center(
                          child: TextButton(
                            onPressed: () => context.go(RoutesApplication.connexion),
                            child: const Text(
                              'J\'ai deja un compte. Se connecter',
                              style: TextStyle(fontWeight: FontWeight.w800),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _creerCarteProfil(
    BuildContext context, {
    required String titre,
    required String description,
    required String badge,
    required IconData icone,
    required Color couleur,
    required String routeDest,
    required int delay,
  }) {
    return AnimatedShadowCard(
      onTap: () => context.push(routeDest),
      borderRadius: 26,
      padding: EdgeInsets.zero,
      backgroundColor: Colors.white.withValues(alpha: 0.9),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: couleur.withValues(alpha: 0.18)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(26),
          child: Stack(
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        couleur.withValues(alpha: 0.10),
                        Colors.white.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(22),
                child: Row(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [couleur, couleur.withValues(alpha: 0.68)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: couleur.withValues(alpha: 0.26),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Icon(icone, color: Colors.white, size: 32),
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            titre,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: CouleursApp.textePrincipal,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            description,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              color: CouleursApp.texteSecondaire,
                              height: 1.45,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: couleur.withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(99),
                            ),
                            child: Text(
                              badge,
                              style: TextStyle(
                                color: couleur,
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(
                      Icons.arrow_forward_rounded,
                      color: couleur,
                      size: 24,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
