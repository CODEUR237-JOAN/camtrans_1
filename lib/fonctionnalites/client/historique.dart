import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../coeur/constantes/couleurs.dart';
import '../../coeur/constantes/tailles.dart';

class Historique extends StatefulWidget {
  const Historique({super.key});

  @override
  State<Historique> createState() => _HistoriqueState();
}

class _HistoriqueState extends State<Historique> {
  final TextEditingController _recherche = TextEditingController();
  int _filtreSelectionne = 0;
  final List<String> _filtres = ["Toutes", "En cours", "Livrées", "Annulées"];

  final List<Map<String, dynamic>> _courses = [
    {
      "depart": "Douala",
      "arrivee": "Yaoundé",
      "date": "06 Juillet 2026",
      "prix": "30 000 FCFA",
      "statut": "Livré",
      "couleur": Colors.green,
      "icone": Icons.check_circle_outline,
    },
    {
      "depart": "Bafoussam",
      "arrivee": "Douala",
      "date": "02 Juillet 2026",
      "prix": "55 000 FCFA",
      "statut": "Annulé",
      "couleur": Colors.red,
      "icone": Icons.cancel_outlined,
    },
    {
      "depart": "Garoua",
      "arrivee": "Ngaoundéré",
      "date": "28 Juin 2026",
      "prix": "120 000 FCFA",
      "statut": "En cours",
      "couleur": Colors.orange,
      "icone": Icons.local_shipping_outlined,
    },
    {
      "depart": "Kribi",
      "arrivee": "Douala",
      "date": "20 Juin 2026",
      "prix": "18 000 FCFA",
      "statut": "Livré",
      "couleur": Colors.green,
      "icone": Icons.check_circle_outline,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CouleursApp.fond,
      appBar: AppBar(
        title: const Text("Historique des demandes", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: CouleursApp.fond,
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(TaillesApp.margePage),
            child: TextField(
              controller: _recherche,
              decoration: InputDecoration(
                hintText: "Rechercher une course...",
                prefixIcon: const Icon(Icons.search, color: CouleursApp.texteSecondaire),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 15),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
              ),
            ),
          ).animate().fadeIn(delay: 100.ms).slideY(begin: -0.1),

          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: TaillesApp.margePage),
              itemCount: _filtres.length,
              itemBuilder: (context, index) {
                return _creerFiltre(index, _filtres[index]);
              },
            ),
          ).animate().fadeIn(delay: 200.ms),

          const SizedBox(height: 15),

          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(TaillesApp.margePage),
              itemCount: _courses.length,
              itemBuilder: (context, index) {
                final course = _courses[index];
                return _creerCarteCourse(course).animate().fadeIn(delay: (300 + (index * 100)).ms).slideX(begin: 0.1);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _creerFiltre(int index, String texte) {
    bool estSelectionne = _filtreSelectionne == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _filtreSelectionne = index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: estSelectionne ? CouleursApp.primaire : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: estSelectionne ? CouleursApp.primaire : Colors.grey.shade300),
          boxShadow: estSelectionne 
            ? [BoxShadow(color: CouleursApp.primaire.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4))] 
            : [],
        ),
        child: Text(
          texte,
          style: TextStyle(
            color: estSelectionne ? Colors.white : CouleursApp.texteSecondaire,
            fontWeight: estSelectionne ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _creerCarteCourse(Map<String, dynamic> course) {
    Color couleur = course["couleur"];
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 5))
        ]
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: couleur.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(course["icone"], color: couleur, size: 26),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "${course["depart"]} ➜ ${course["arrivee"]}",
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 5),
                      Text(course["date"], style: const TextStyle(color: CouleursApp.texteSecondaire, fontSize: 13)),
                    ],
                  ),
                ),
                Text(
                  course["prix"],
                  style: const TextStyle(color: CouleursApp.primaire, fontWeight: FontWeight.w900, fontSize: 15),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 15),
              child: Divider(height: 1, color: Color(0xFFEEEEEE)),
            ),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: couleur.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.circle, color: couleur, size: 10),
                      const SizedBox(width: 6),
                      Text(
                        course["statut"],
                        style: TextStyle(color: couleur, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () {
                    context.push("/factures");
                  },
                  icon: const Icon(Icons.receipt_long, size: 18),
                  label: const Text("Voir facture", style: TextStyle(fontWeight: FontWeight.bold)),
                  style: TextButton.styleFrom(
                    foregroundColor: CouleursApp.primaire,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}