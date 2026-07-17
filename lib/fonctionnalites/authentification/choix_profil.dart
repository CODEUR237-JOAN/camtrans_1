import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../coeur/constantes/couleurs.dart';
import '../../coeur/constantes/tailles.dart';
import '../../coeur/routes/routes.dart';

class ChoixProfil extends StatelessWidget {
  const ChoixProfil({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CouleursApp.fond,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: CouleursApp.textePrincipal),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: TaillesApp.margePage),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              const Text(
                "Comment souhaitez-vous\nutiliser Camtrans ?",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: CouleursApp.textePrincipal,
                  height: 1.2,
                  letterSpacing: -0.5,
                ),
              ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.2, end: 0),
              
              const SizedBox(height: 15),
              
              const Text(
                "Choisissez le profil qui correspond à vos besoins.",
                style: TextStyle(
                  fontSize: 16,
                  color: CouleursApp.texteSecondaire,
                ),
              ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2, end: 0),

              const SizedBox(height: 40),

              // Carte Client
              _creerCarteProfil(
                context,
                titre: "Client / Expéditeur",
                description: "Je veux expédier des colis, meubles ou marchandises à travers le pays.",
                icone: Icons.inventory_2_outlined,
                couleur: CouleursApp.primaire,
                routeDest: RoutesApplication.inscriptionClient,
                delay: 300,
              ),

              const SizedBox(height: 25),

              // Carte Transporteur
              _creerCarteProfil(
                context,
                titre: "Transporteur / Chauffeur",
                description: "Je possède un véhicule et je souhaite trouver des courses et rentabiliser mes trajets.",
                icone: Icons.local_shipping_outlined,
                couleur: Colors.orange,
                routeDest: RoutesApplication.inscriptionTransporteur,
                delay: 400,
              ),
              
              const Spacer(),
              
              Center(
                child: TextButton(
                  onPressed: () => context.go(RoutesApplication.connexion),
                  child: const Text("J'ai déjà un compte. Se connecter", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ).animate().fadeIn(delay: 600.ms),
              
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _creerCarteProfil(
    BuildContext context, {
    required String titre,
    required String description,
    required IconData icone,
    required Color couleur,
    required String routeDest,
    required int delay,
  }) {
    return GestureDetector(
      onTap: () => context.push(routeDest),
      child: Container(
        padding: const EdgeInsets.all(25),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: couleur.withValues(alpha: 0.3), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: couleur.withValues(alpha: 0.05),
              blurRadius: 20,
              offset: const Offset(0, 10),
            )
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: couleur.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icone, color: couleur, size: 35),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titre,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: CouleursApp.textePrincipal,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 14,
                      color: CouleursApp.texteSecondaire,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Icon(Icons.arrow_forward_ios, color: couleur.withValues(alpha: 0.5), size: 20),
          ],
        ),
      ).animate().fadeIn(delay: delay.ms).slideX(begin: 0.1, end: 0, curve: Curves.easeOutBack),
    );
  }
}
