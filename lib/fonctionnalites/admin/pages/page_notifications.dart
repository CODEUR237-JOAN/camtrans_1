import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:update_camtrans/coeur/constantes/couleurs.dart';
import 'package:update_camtrans/coeur/widgets/loader_premium.dart';

class PageNotifications extends ConsumerStatefulWidget {
  const PageNotifications({super.key});

  @override
  ConsumerState<PageNotifications> createState() => _PageNotificationsState();
}

class _PageNotificationsState extends ConsumerState<PageNotifications> {
  final TextEditingController _titreController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  
  String _cible = "tous"; // tous, clients, transporteurs
  bool _enCours = false;

  Future<void> _envoyerNotification() async {
    final titre = _titreController.text.trim();
    final message = _messageController.text.trim();

    if (titre.isEmpty || message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Veuillez remplir tous les champs.")),
      );
      return;
    }

    setState(() => _enCours = true);

    try {
      final refNotif = FirebaseFirestore.instance.collection('notifications_push').doc();
      
      await refNotif.set({
        'id': refNotif.id,
        'titre': titre,
        'message': message,
        'cible': _cible,
        'status': 'pending', // Le script Node.js écoute ce statut
        'dateCreation': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        _titreController.clear();
        _messageController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Notification programmée avec succès !"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _enCours = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Notifications Push Globales",
            style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            "Rédigez un message pour alerter vos utilisateurs directement sur leur smartphone.",
            style: GoogleFonts.inter(fontSize: 14, color: Colors.grey.shade400),
          ),
          const SizedBox(height: 30),

          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                )
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLabel("Cible de l'envoi"),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: _cible,
                  dropdownColor: const Color(0xFF1E293B),
                  style: GoogleFonts.inter(color: Colors.white, fontSize: 16),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.black.withValues(alpha: 0.2),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                  items: const [
                    DropdownMenuItem(value: "tous", child: Text("Tous les utilisateurs")),
                    DropdownMenuItem(value: "clients", child: Text("Uniquement les clients")),
                    DropdownMenuItem(value: "transporteurs", child: Text("Uniquement les transporteurs")),
                  ],
                  onChanged: (val) => setState(() => _cible = val!),
                ),
                const SizedBox(height: 24),
                
                _buildLabel("Titre de la notification"),
                const SizedBox(height: 10),
                TextField(
                  controller: _titreController,
                  style: GoogleFonts.inter(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: "Ex: Nouvelle mise à jour !",
                    hintStyle: TextStyle(color: Colors.grey.shade600),
                    filled: true,
                    fillColor: Colors.black.withValues(alpha: 0.2),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 24),

                _buildLabel("Message"),
                const SizedBox(height: 10),
                TextField(
                  controller: _messageController,
                  style: GoogleFonts.inter(color: Colors.white),
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: "Saisissez votre message ici...",
                    hintStyle: TextStyle(color: Colors.grey.shade600),
                    filled: true,
                    fillColor: Colors.black.withValues(alpha: 0.2),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 30),

                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: CouleursApp.primaire,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _enCours ? null : _envoyerNotification,
                    icon: _enCours 
                      ? const SizedBox(width: 20, height: 20, child: LoaderPremium(size: 24))
                      : const Icon(Icons.send, color: Colors.white),
                    label: Text(
                      _enCours ? "Envoi en cours..." : "Envoyer le Push",
                      style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildLabel(String texte) {
    return Text(
      texte,
      style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey.shade300),
    );
  }
}
