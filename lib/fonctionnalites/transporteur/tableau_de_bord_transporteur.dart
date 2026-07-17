import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../coeur/constantes/couleurs.dart';
import '../../coeur/constantes/tailles.dart';
import '../../coeur/widgets/barre_navigation.dart';
import '../../coeur/widgets/carte_information.dart';

class TableauDeBordTransporteur extends StatefulWidget {
  const TableauDeBordTransporteur({super.key});

  @override
  State<TableauDeBordTransporteur> createState() => _TableauDeBordTransporteurState();
}

class _TableauDeBordTransporteurState extends State<TableauDeBordTransporteur> {
  int indexNavigation = 0;
  bool estDisponible = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CouleursApp.fond,
      bottomNavigationBar: BarreNavigation(
        indexSelectionne: indexNavigation,
        lorsDuChangement: (index) {
          setState(() {
            indexNavigation = index;
          });
        },
      ).animate().slideY(begin: 1, end: 0, delay: 500.ms, duration: 400.ms),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(TaillesApp.margePage),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // HEADER
              Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: CouleursApp.primaire.withValues(alpha: 0.2),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        )
                      ]
                    ),
                    child: const CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.orange,
                      child: Icon(Icons.local_shipping, color: Colors.white, size: 28),
                    ),
                  ).animate().scale(delay: 100.ms, curve: Curves.easeOutBack),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Bienvenue,",
                          style: TextStyle(color: CouleursApp.texteSecondaire, fontSize: 14),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          "Jean Mvondo",
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: -0.5),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.1),
                  Switch(
                    value: estDisponible,
                    activeColor: Colors.white,
                    activeTrackColor: Colors.green,
                    inactiveThumbColor: Colors.white,
                    inactiveTrackColor: Colors.grey.shade300,
                    onChanged: (value) {
                      setState(() {
                        estDisponible = value;
                      });
                    },
                  ).animate().scale(delay: 300.ms),
                ],
              ),
              const SizedBox(height: 30),

              // BANNER REVENUS
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(25),
                decoration: BoxDecoration(
                  gradient: CouleursApp.degradePrincipal,
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: CouleursApp.primaire.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    )
                  ]
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Revenus du jour",
                      style: TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "75 000 FCFA",
                      style: TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.w900, letterSpacing: -1),
                    ),
                    const SizedBox(height: 15),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.circle,
                            color: estDisponible ? Colors.greenAccent : Colors.redAccent,
                            size: 12,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            estDisponible ? "En ligne et disponible" : "Hors ligne",
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1),

              const SizedBox(height: 35),

              // STATISTIQUES
              const Text(
                "Statistiques",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ).animate().fadeIn(delay: 500.ms),
              const SizedBox(height: 15),

              Row(
                children: [
                  Expanded(
                    child: CarteInformation(titre: "Courses", valeur: "18", icone: Icons.local_shipping),
                  ).animate().slideX(begin: -0.1, delay: 600.ms),
                  const SizedBox(width: 15),
                  Expanded(
                    child: CarteInformation(titre: "Livrées", valeur: "15", icone: Icons.check_circle, couleurIcone: Colors.green, couleurValeur: Colors.green),
                  ).animate().slideX(begin: 0.1, delay: 600.ms),
                ],
              ),
              const SizedBox(height: 15),
              Row(
                children: [
                  Expanded(
                    child: CarteInformation(titre: "En attente", valeur: "05", icone: Icons.schedule, couleurIcone: Colors.orange, couleurValeur: Colors.orange),
                  ).animate().slideX(begin: -0.1, delay: 700.ms),
                  const SizedBox(width: 15),
                  Expanded(
                    child: CarteInformation(titre: "Note", valeur: "4.9 ★", icone: Icons.star, couleurIcone: Colors.amber, couleurValeur: Colors.amber),
                  ).animate().slideX(begin: 0.1, delay: 700.ms),
                ],
              ),

              const SizedBox(height: 35),

              // ACTIONS RAPIDES
              const Text(
                "Actions rapides",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ).animate().fadeIn(delay: 800.ms),
              const SizedBox(height: 15),

              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 15,
                mainAxisSpacing: 15,
                childAspectRatio: 1.4,
                children: [
                  CarteInformation(
                    titre: "Courses\ndisponibles",
                    icone: Icons.map,
                    auClic: () {
                      context.push("/courses-disponibles");
                    },
                  ).animate().scale(delay: 900.ms, curve: Curves.easeOutBack),
                  CarteInformation(
                    titre: "Revenus",
                    icone: Icons.account_balance_wallet,
                    auClic: () {
                      context.push("/revenus");
                    },
                  ).animate().scale(delay: 1000.ms, curve: Curves.easeOutBack),
                  CarteInformation(
                    titre: "Portefeuille",
                    icone: Icons.wallet,
                    auClic: () {
                      context.push("/portefeuille");
                    },
                  ).animate().scale(delay: 1100.ms, curve: Curves.easeOutBack),
                  CarteInformation(
                    titre: "Documents",
                    icone: Icons.description,
                    auClic: () {
                      context.push("/documents");
                    },
                  ).animate().scale(delay: 1200.ms, curve: Curves.easeOutBack),
                ],
              ),

              const SizedBox(height: 35),

              // DERNIERES COURSES
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Dernières courses", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  TextButton(onPressed: () {}, child: const Text("Voir tout", style: TextStyle(fontWeight: FontWeight.bold))),
                ],
              ).animate().fadeIn(delay: 1300.ms),
              const SizedBox(height: 15),

              _creationCarteTrajet(
                "Douala → Yaoundé", "Mobilier", "30 000 FCFA", Icons.local_shipping, Colors.blue
              ).animate().fadeIn(delay: 1400.ms).slideY(begin: 0.1),
              const SizedBox(height: 10),
              _creationCarteTrajet(
                "Kribi → Douala", "Poissons", "18 000 FCFA", Icons.local_shipping, Colors.blue
              ).animate().fadeIn(delay: 1500.ms).slideY(begin: 0.1),
              const SizedBox(height: 10),
              _creationCarteTrajet(
                "Bafoussam → Douala", "Cacao", "55 000 FCFA", Icons.local_shipping, Colors.blue
              ).animate().fadeIn(delay: 1600.ms).slideY(begin: 0.1),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _creationCarteTrajet(String titre, String sousTitre, String prix, IconData icone, Color couleurIcone) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 5),
          )
        ]
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: couleurIcone.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(icone, color: couleurIcone, size: 26),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titre, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 6),
                Text(sousTitre, style: const TextStyle(color: CouleursApp.texteSecondaire, fontSize: 13)),
              ],
            ),
          ),
          Text(prix, style: const TextStyle(fontWeight: FontWeight.w900, color: CouleursApp.primaire, fontSize: 15)),
        ],
      ),
    );
  }
}