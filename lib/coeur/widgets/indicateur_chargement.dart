import 'package:flutter/material.dart';

import 'package:update_camtrans/coeur/constantes/couleurs.dart';
import 'package:update_camtrans/coeur/constantes/tailles.dart';

class IndicateurChargement extends StatelessWidget {
  final String? message;
  final double taille;
  final Color? couleur;
  final bool afficherCarte;

  const IndicateurChargement({
    super.key,
    this.message,
    this.taille = 45,
    this.couleur,
    this.afficherCarte = true,
  });

  @override
  Widget build(BuildContext context) {
    final Widget contenu = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: taille,
          height: taille,
          child: CircularProgressIndicator(
            strokeWidth: 4,
            valueColor: AlwaysStoppedAnimation<Color>(
              couleur ?? CouleursApp.primaire,
            ),
          ),
        ),

        if (message != null) ...[
          SizedBox(
            height: TaillesApp.espaceGrand,
          ),
          Text(
            message!,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              color: CouleursApp.texteSecondaire,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );

    if (!afficherCarte) {
      return Center(
        child: contenu,
      );
    }

    return Center(
      child: Container(
        padding: EdgeInsets.all(
          TaillesApp.espaceGrand,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(
            TaillesApp.rayonCarte,
          ),
          boxShadow: [
            BoxShadow(
              color: CouleursApp.ombre,
              blurRadius: 15,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: contenu,
      ),
    );
  }
}