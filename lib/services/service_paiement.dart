import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:update_camtrans/coeur/constantes/api_keys.dart';
import 'package:update_camtrans/coeur/constantes/statuts.dart';
import 'package:update_camtrans/modeles/paiement.dart';
import 'package:update_camtrans/services/service_firestore.dart';
import 'package:flutter/foundation.dart';

final servicePaiementProvider = Provider<ServicePaiement>((ref) {
  return ServicePaiement(ref.read(serviceFirestoreProvider));
});

class ServicePaiement {
  final ServiceFirestore _firestore;
  
  ServicePaiement(this._firestore);
  
  String get _baseUrl => ApiKeys.isCampayProduction 
      ? 'https://www.campay.net/api' 
      : 'https://demo.campay.net/api';

  /// 1. Authentification : Obtenir le Token Campay
  Future<String> _obtenirToken() async {
    if (ApiKeys.campayUsername.isEmpty || ApiKeys.campayPassword.isEmpty) {
      throw Exception("Clés d'API Campay non configurées. Veuillez vérifier le fichier .env");
    }

    final response = await http.post(
      Uri.parse('$_baseUrl/token/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "username": ApiKeys.campayUsername,
        "password": ApiKeys.campayPassword
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['token'];
    } else {
      debugPrint("Erreur auth Campay: ${response.body}");
      throw Exception("Impossible de s'authentifier auprès de Campay.");
    }
  }

  /// 2. Collecte Mobile Money (MTN / Orange) avec Polling
  Future<Paiement> _initierCollecteMobileMoney({
    required String courseId,
    required String clientId,
    required String transporteurId,
    required double montant,
    required String telephonePayeur,
    required String operateur,
  }) async {
    // 1. Obtenir le token
    final token = await _obtenirToken();
    
    // 2. Lancer la demande de paiement (Push USSD sur le téléphone du client)
    // 237 est requis par l'API Campay pour le Cameroun, on s'assure du format
    String phone = telephonePayeur.replaceAll(RegExp(r'[^0-9]'), '');
    if (phone.length == 9) phone = "237$phone"; // Ajouter l'indicatif si manquant

    final refExterne = "CAMTRANS-${courseId.substring(0, 5).toUpperCase()}-${DateTime.now().millisecondsSinceEpoch}";

    final collectResponse = await http.post(
      Uri.parse('$_baseUrl/collect/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Token $token',
      },
      body: jsonEncode({
        "amount": montant.toInt().toString(), // Campay demande souvent un entier
        "currency": "XAF",
        "from": phone,
        "description": "Paiement Course Camtrans",
        "external_reference": refExterne
      }),
    );

    if (collectResponse.statusCode != 200) {
      debugPrint("Erreur de collecte Campay: ${collectResponse.body}");
      throw Exception("Erreur d'initialisation du paiement: ${jsonDecode(collectResponse.body)['message'] ?? 'Erreur inconnue'}");
    }

    final collectData = jsonDecode(collectResponse.body);
    final referenceId = collectData['reference'];

    // 3. Boucle de vérification (Polling) du statut de la transaction
    // On boucle jusqu'à ce que le statut soit SUCCESSFUL ou FAILED, ou qu'on dépasse 2 minutes.
    String status = "PENDING";
    int tentatives = 0;
    
    while (status == "PENDING" && tentatives < 40) { // 40 * 3s = 120 secondes max
      await Future.delayed(const Duration(seconds: 3));
      tentatives++;

      final statusResponse = await http.get(
        Uri.parse('$_baseUrl/transaction/$referenceId/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $token',
        },
      );

      if (statusResponse.statusCode == 200) {
        final statusData = jsonDecode(statusResponse.body);
        status = statusData['status'];
        
        if (status == "SUCCESSFUL") {
          return _creerPaiementReussi(
            courseId: courseId,
            clientId: clientId,
            transporteurId: transporteurId,
            montant: montant,
            methode: "$operateur Mobile Money",
            operateur: operateur,
            telephone: phone,
          );
        } else if (status == "FAILED") {
          throw Exception("Le paiement a échoué ou a été refusé par l'utilisateur.");
        }
      }
    }

    if (status == "PENDING") {
      throw Exception("Délai d'attente dépassé. Veuillez réessayer.");
    }
    throw Exception("Erreur lors de la validation du paiement.");
  }

  /// Traitement d'un paiement Orange Money
  Future<Paiement> initierPaiementOM({
    required String courseId,
    required String clientId,
    required String transporteurId,
    required double montant,
    required String telephonePayeur,
  }) async {
    return _initierCollecteMobileMoney(
      courseId: courseId,
      clientId: clientId,
      transporteurId: transporteurId,
      montant: montant,
      telephonePayeur: telephonePayeur,
      operateur: "Orange",
    );
  }

  /// Traitement d'un paiement MTN Mobile Money
  Future<Paiement> initierPaiementMTN({
    required String courseId,
    required String clientId,
    required String transporteurId,
    required double montant,
    required String telephonePayeur,
  }) async {
    return _initierCollecteMobileMoney(
      courseId: courseId,
      clientId: clientId,
      transporteurId: transporteurId,
      montant: montant,
      telephonePayeur: telephonePayeur,
      operateur: "MTN",
    );
  }

  /// Traitement d'un paiement par Carte Bancaire
  Future<Paiement> initierPaiementCarte({
    required String courseId,
    required String clientId,
    required String transporteurId,
    required double montant,
    required String nomTitulaire,
  }) async {
    // Non implémenté par Campay directement pour les cartes au Cameroun.
    // Simulation pour Stripe/Carte.
    await Future.delayed(const Duration(seconds: 4)); 
    return _creerPaiementReussi(
      courseId: courseId,
      clientId: clientId,
      transporteurId: transporteurId,
      montant: montant,
      methode: "Carte Bancaire",
      operateur: "Stripe/Visa",
      telephone: nomTitulaire,
    );
  }

  /// Paiement en espèces (À régler au chauffeur)
  Future<Paiement> initierPaiementEspeces({
    required String courseId,
    required String clientId,
    required String transporteurId,
    required double montant,
  }) async {
    await Future.delayed(const Duration(seconds: 1)); 
    return _creerPaiementReussi(
      courseId: courseId,
      clientId: clientId,
      transporteurId: transporteurId,
      montant: montant,
      methode: "Espèces",
      operateur: "Direct",
      telephone: "N/A", 
    );
  }

  Future<Paiement> _creerPaiementReussi({
    required String courseId,
    required String clientId,
    required String transporteurId,
    required double montant,
    required String methode,
    required String operateur,
    required String telephone,
  }) async {
    final id = "PAY-${DateTime.now().millisecondsSinceEpoch}";
    final transaction = "TXN-${DateTime.now().microsecondsSinceEpoch}";

    final paiement = Paiement(
      id: id,
      courseId: courseId,
      clientId: clientId,
      transporteurId: transporteurId,
      montant: montant,
      devise: "FCFA",
      methodePaiement: methode,
      numeroTransaction: transaction,
      statut: StatutPaiement.succes,
      datePaiement: DateTime.now(),
      paiementConfirme: true,
      reference: "Ref-$courseId",
      operateur: operateur,
      telephonePayeur: telephone,
      commentaire: "Paiement validé via $operateur",
      fraisTransaction: montant * 0.02, 
      montantNet: montant * 0.98,
      remboursementEffectue: false,
      motifRemboursement: "",
      facturePdf: "", 
    );

    // Enregistrer le paiement
    await _firestore.ajouterDocument(
      collection: 'paiements',
      id: paiement.id,
      donnees: paiement.toMap(),
    );

    // Mettre à jour le statut de la course
    await _firestore.modifierDocument(
      collection: 'courses',
      id: courseId,
      donnees: {'paiementEffectue': true},
    );

    return paiement;
  }
}
