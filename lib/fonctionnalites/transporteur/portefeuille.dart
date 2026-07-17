import 'package:flutter/material.dart';

import '../../coeur/constantes/couleurs.dart';
import '../../coeur/constantes/tailles.dart';
import '../../coeur/widgets/bouton_principal.dart';

class Portefeuille extends StatelessWidget {
  const Portefeuille({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CouleursApp.fond,
      appBar: AppBar(
        title: const Text("Mon portefeuille"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(
          TaillesApp.margePage,
        ),
        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(25),
              decoration: BoxDecoration(
                gradient:
                CouleursApp.degradePrincipal,
                borderRadius:
                BorderRadius.circular(20),
              ),
              child: const Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  Text(
                    "Solde disponible",
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    "425 000 FCFA",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 34,
                      fontWeight:
                      FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            Row(
              children: [
                Expanded(
                  child: _statistique(
                    "Aujourd'hui",
                    "75 000 FCFA",
                    Icons.today,
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: _statistique(
                    "Cette semaine",
                    "310 000 FCFA",
                    Icons.date_range,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 15),

            Row(
              children: [
                Expanded(
                  child: _statistique(
                    "Ce mois",
                    "1 240 000 FCFA",
                    Icons.calendar_month,
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: _statistique(
                    "Courses",
                    "58",
                    Icons.local_shipping,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 30),

            const Text(
              "Retrait",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 15),

            BoutonPrincipal(
              texte: "Retirer via Orange Money",
              icone: Icons.account_balance_wallet,
              auClic: () {},
            ),

            const SizedBox(height: 15),

            BoutonPrincipal(
              texte: "Retirer via MTN Mobile Money",
              icone: Icons.phone_android,
              auClic: () {},
            ),

            const SizedBox(height: 15),

            BoutonPrincipal(
              texte: "Virement bancaire",
              icone: Icons.account_balance,
              auClic: () {},
            ),

            const SizedBox(height: 30),

            const Text(
              "Historique des transactions",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 15),

            _transaction(
              "Paiement course",
              "Douala → Yaoundé",
              "+30 000 FCFA",
              Colors.green,
              Icons.arrow_downward,
            ),

            _transaction(
              "Retrait Orange Money",
              "N° 699123456",
              "-100 000 FCFA",
              Colors.red,
              Icons.arrow_upward,
            ),

            _transaction(
              "Paiement course",
              "Kribi → Douala",
              "+18 000 FCFA",
              Colors.green,
              Icons.arrow_downward,
            ),

            _transaction(
              "Paiement course",
              "Bafoussam → Douala",
              "+55 000 FCFA",
              Colors.green,
              Icons.arrow_downward,
            ),

            const SizedBox(height: 25),
          ],
        ),
      ),
    );
  }

  Widget _statistique(
      String titre,
      String valeur,
      IconData icone,
      ) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius:
        BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            Icon(
              icone,
              color: CouleursApp.primaire,
              size: 35,
            ),
            const SizedBox(height: 12),
            Text(
              valeur,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              titre,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _transaction(
      String titre,
      String sousTitre,
      String montant,
      Color couleur,
      IconData icone,
      ) {
    return Card(
      margin: const EdgeInsets.only(
        bottom: 12,
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor:
          couleur.withOpacity(.15),
          child: Icon(
            icone,
            color: couleur,
          ),
        ),
        title: Text(titre),
        subtitle: Text(sousTitre),
        trailing: Text(
          montant,
          style: TextStyle(
            color: couleur,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}