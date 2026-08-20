import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:update_camtrans/coeur/constantes/couleurs.dart';
import 'package:update_camtrans/coeur/constantes/tailles.dart';
import 'package:update_camtrans/coeur/widgets/bouton_principal.dart';

class EstimationVolume extends StatefulWidget {
  const EstimationVolume({super.key});

  @override
  State<EstimationVolume> createState() =>
      _EstimationVolumeState();
}

class _EstimationVolumeState
    extends State<EstimationVolume> {
  final _longueur = TextEditingController();
  final _largeur = TextEditingController();
  final _hauteur = TextEditingController();
  final _poids = TextEditingController();

  double _volume = 0;
  double _prix = 0;
  String _vehicule = "-";

  void _calculer() {
    final longueur =
        double.tryParse(_longueur.text) ?? 0;

    final largeur =
        double.tryParse(_largeur.text) ?? 0;

    final hauteur =
        double.tryParse(_hauteur.text) ?? 0;

    final poids =
        double.tryParse(_poids.text) ?? 0;

    setState(() {
      _volume =
          (longueur * largeur * hauteur) / 1000000;

      if (_volume <= 0.20 && poids <= 30) {
        _vehicule = "Moto";
        _prix = 2500;
      } else if (_volume <= 1 && poids <= 500) {
        _vehicule = "Tricycle";
        _prix = 6000;
      } else if (_volume <= 4 && poids <= 1000) {
        _vehicule = "Pick-up";
        _prix = 15000;
      } else if (_volume <= 10 && poids <= 3000) {
        _vehicule = "Camionnette";
        _prix = 30000;
      } else if (_volume <= 35 && poids <= 10000) {
        _vehicule = "Camion";
        _prix = 70000;
      } else {
        _vehicule = "Semi-remorque";
        _prix = 150000;
      }
    });
  }

  @override
  void dispose() {
    _longueur.dispose();
    _largeur.dispose();
    _hauteur.dispose();
    _poids.dispose();
    super.dispose();
  }

  Widget champ({
    required TextEditingController controleur,
    required String texte,
  }) {
    return TextField(
      controller: controleur,
      keyboardType:
      const TextInputType.numberWithOptions(
        decimal: true,
      ),
      decoration: InputDecoration(
        labelText: texte,
        border: OutlineInputBorder(
          borderRadius:
          BorderRadius.circular(15),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CouleursApp.fond,
      appBar: AppBar(
        title: const Text(
          "Estimation du volume",
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(
          TaillesApp.margePage,
        ),
        child: Column(
          children: [
            champ(
              controleur: _longueur,
              texte: "Longueur (cm)",
            ),

            const SizedBox(height: 15),

            champ(
              controleur: _largeur,
              texte: "Largeur (cm)",
            ),

            const SizedBox(height: 15),

            champ(
              controleur: _hauteur,
              texte: "Hauteur (cm)",
            ),

            const SizedBox(height: 15),

            champ(
              controleur: _poids,
              texte: "Poids (Kg)",
            ),

            const SizedBox(height: 25),

            BoutonPrincipal(
              texte: "Calculer",
              icone: Icons.calculate,
              auClic: _calculer,
            ),

            const SizedBox(height: 30),

            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius:
                BorderRadius.circular(20),
              ),
              child: Padding(
                padding:
                const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Icon(
                      Icons.analytics,
                      size: 70,
                      color: CouleursApp.primaire,
                    ),

                    const SizedBox(height: 20),

                    Text(
                      "Volume : ${_volume.toStringAsFixed(2)} m³",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight:
                        FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 15),

                    Text(
                      "Véhicule conseillé : $_vehicule",
                      style: const TextStyle(
                        fontSize: 18,
                      ),
                    ),

                    const SizedBox(height: 15),

                    Text(
                      "Prix estimatif",
                      style: TextStyle(
                        color: Colors.grey.shade600,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      "${_prix.toStringAsFixed(0)} FCFA",
                      style: const TextStyle(
                        fontSize: 30,
                        color: Colors.green,
                        fontWeight:
                        FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 30),

            BoutonPrincipal(
              texte: "Continuer",
              icone: Icons.arrow_forward,
              auClic: () {
                context.push("/carte");
              },
            ),
          ],
        ),
      ),
    );
  }
}