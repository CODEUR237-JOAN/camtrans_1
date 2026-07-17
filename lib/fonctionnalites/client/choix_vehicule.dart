import 'package:flutter/material.dart';

import '../../coeur/constantes/couleurs.dart';
import '../../coeur/constantes/tailles.dart';
import '../../coeur/widgets/bouton_principal.dart';

class ChoixVehicule extends StatefulWidget {
  const ChoixVehicule({super.key});

  @override
  State<ChoixVehicule> createState() => _ChoixVehiculeState();
}

class _ChoixVehiculeState extends State<ChoixVehicule> {
  int _vehiculeSelectionne = -1;

  final List<Map<String, dynamic>> _vehicules = [
    {
      "nom": "Moto",
      "image": "assets/images/vehicules/moto.png",
      "capacite": "30 Kg",
      "prix": "2 500 FCFA",
      "description": "Petits colis et documents"
    },
    {
      "nom": "Tricycle",
      "image": "assets/images/vehicules/tricycle.png",
      "capacite": "500 Kg",
      "prix": "6 000 FCFA",
      "description": "Petites marchandises"
    },
    {
      "nom": "Pick-up",
      "image": "assets/images/vehicules/pickup.png",
      "capacite": "1 Tonne",
      "prix": "15 000 FCFA",
      "description": "Mobilier et électroménager"
    },
    {
      "nom": "Camionnette",
      "image": "assets/images/vehicules/camionnette.png",
      "capacite": "3 Tonnes",
      "prix": "30 000 FCFA",
      "description": "Déménagement léger"
    },
    {
      "nom": "Camion",
      "image": "assets/images/vehicules/camion.png",
      "capacite": "10 Tonnes",
      "prix": "70 000 FCFA",
      "description": "Marchandises volumineuses"
    },
    {
      "nom": "Semi-remorque",
      "image": "assets/images/vehicules/remorque.png",
      "capacite": "30 Tonnes",
      "prix": "150 000 FCFA",
      "description": "Transport industriel"
    },
  ];

  void _continuer() {
    if (_vehiculeSelectionne == -1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Veuillez sélectionner un véhicule.",
          ),
        ),
      );
      return;
    }

    Navigator.pushNamed(
      context,
      "/estimation-volume",
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CouleursApp.fond,
      appBar: AppBar(
        title: const Text(
          "Choix du véhicule",
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 15),

          const Padding(
            padding: EdgeInsets.symmetric(
              horizontal: TaillesApp.margePage,
            ),
            child: Text(
              "Choisissez le véhicule adapté à votre marchandise.",
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          const SizedBox(height: 15),

          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(
                TaillesApp.margePage,
              ),
              itemCount: _vehicules.length,
              itemBuilder: (context, index) {
                final vehicule = _vehicules[index];

                final selectionne =
                    _vehiculeSelectionne == index;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _vehiculeSelectionne = index;
                    });
                  },
                  child: AnimatedContainer(
                    duration:
                    const Duration(milliseconds: 250),
                    margin: const EdgeInsets.only(
                      bottom: 18,
                    ),
                    decoration: BoxDecoration(
                      color: selectionne
                          ? CouleursApp.primaireClair
                          : Colors.white,
                      borderRadius:
                      BorderRadius.circular(20),
                      border: Border.all(
                        color: selectionne
                            ? CouleursApp.primaire
                            : Colors.grey.shade300,
                        width: 2,
                      ),
                    ),
                    child: Padding(
                      padding:
                      const EdgeInsets.all(15),
                      child: Row(
                        children: [
                          Container(
                            width: 95,
                            height: 95,
                            decoration: BoxDecoration(
                              color:
                              Colors.grey.shade100,
                              borderRadius:
                              BorderRadius.circular(
                                  15),
                            ),
                            child: Padding(
                              padding:
                              const EdgeInsets.all(
                                  10),
                              child: Image.asset(
                                vehicule["image"],
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),

                          const SizedBox(width: 18),

                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                              CrossAxisAlignment
                                  .start,
                              children: [
                                Text(
                                  vehicule["nom"],
                                  style:
                                  const TextStyle(
                                    fontSize: 20,
                                    fontWeight:
                                    FontWeight.bold,
                                  ),
                                ),

                                const SizedBox(height: 8),

                                Text(
                                  vehicule[
                                  "description"],
                                ),

                                const SizedBox(height: 8),

                                Text(
                                  "Capacité : ${vehicule["capacite"]}",
                                  style:
                                  const TextStyle(
                                    color: Colors.grey,
                                  ),
                                ),

                                const SizedBox(height: 8),

                                Text(
                                  "À partir de ${vehicule["prix"]}",
                                  style:
                                  const TextStyle(
                                    color: Colors.green,
                                    fontWeight:
                                    FontWeight.bold,
                                    fontSize: 17,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          Icon(
                            selectionne
                                ? Icons.check_circle
                                : Icons
                                .radio_button_unchecked,
                            color: selectionne
                                ? Colors.green
                                : Colors.grey,
                            size: 30,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(
              TaillesApp.margePage,
            ),
            child: BoutonPrincipal(
              texte: "Continuer",
              icone: Icons.arrow_forward,
              auClic: _continuer,
            ),
          ),
        ],
      ),
    );
  }
}