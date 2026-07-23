import 'package:flutter/material.dart';

import '../constantes/couleurs.dart';
import '../constantes/tailles.dart';

class CarteInformation extends StatelessWidget {
  final String titre;
  final String? sousTitre;
  final String? valeur;
  final IconData? icone;
  final Widget? enfant;
  final VoidCallback? auClic;
  final Color? couleur;
  final Color? couleurIcone;
  final Color? couleurValeur;
  final EdgeInsets? marge;
  final EdgeInsets? remplissage;

  const CarteInformation({
    super.key,
    required this.titre,
    this.sousTitre,
    this.valeur,
    this.icone,
    this.enfant,
    this.auClic,
    this.couleur,
    this.couleurIcone,
    this.couleurValeur,
    this.marge,
    this.remplissage,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: couleur ?? Colors.white,
      margin: marge ?? const EdgeInsets.symmetric(vertical: 8),
      elevation: 0,
      shadowColor: CouleursApp.ombre.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(TaillesApp.rayonCarte),
        side: BorderSide(color: Colors.grey.shade200, width: 1),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(TaillesApp.rayonCarte),
        onTap: auClic,
        child: Padding(
          padding: remplissage ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (icone != null)
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: (couleurIcone ?? CouleursApp.primaire).withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        icone,
                        color: couleurIcone ?? CouleursApp.primaire,
                        size: 20,
                      ),
                    ),

                  if (icone != null) const SizedBox(width: 10),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          titre,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: CouleursApp.textePrincipal,
                            height: 1.2,
                          ),
                        ),
                        if (sousTitre != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              sousTitre!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                color: CouleursApp.texteSecondaire,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  if (valeur != null)
                    Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: Text(
                        valeur!,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: couleurValeur ?? CouleursApp.primaire,
                        ),
                      ),
                    ),
                ],
              ),
              if (enfant != null) ...[
                const SizedBox(height: 12),
                enfant!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}