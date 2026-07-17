import 'package:flutter/material.dart';

import '../constantes/couleurs.dart';
import '../constantes/tailles.dart';

class BoutonPrincipal extends StatelessWidget {
  final String texte;
  final VoidCallback? auClic;
  final IconData? icone;
  final bool chargement;
  final bool pleineLargeur;
  final Color? couleur;
  final Color? couleurTexte;
  final double hauteur;
  final double largeur;

  const BoutonPrincipal({
    super.key,
    required this.texte,
    this.auClic,
    this.icone,
    this.chargement = false,
    this.pleineLargeur = true,
    this.couleur,
    this.couleurTexte,
    this.hauteur = TaillesApp.hauteurBouton,
    this.largeur = double.infinity,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: pleineLargeur ? largeur : null,
      height: hauteur,
      child: ElevatedButton(
        onPressed: chargement ? null : auClic,
        style: ElevatedButton.styleFrom(
          backgroundColor: couleur ?? CouleursApp.primaire,
          foregroundColor: couleurTexte ?? Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              TaillesApp.rayonBouton,
            ),
          ),
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: chargement
              ? const SizedBox(
            key: ValueKey("chargement"),
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: Colors.white,
            ),
          )
              : Row(
            key: const ValueKey("texte"),
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icone != null) ...[
                Icon(
                  icone,
                  size: 22,
                ),
                const SizedBox(width: 10),
              ],
              Text(
                texte,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}