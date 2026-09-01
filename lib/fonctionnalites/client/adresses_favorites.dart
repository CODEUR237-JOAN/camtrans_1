import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:update_camtrans/coeur/constantes/couleurs.dart';

// Modèle temporaire pour l'UI (Sera géré par Firebase dans la phase suivante)
class AdresseFavorite {
  final String id;
  final String label;
  final String adresse;
  final IconData icone;
  final Color couleur;

  AdresseFavorite({required this.id, required this.label, required this.adresse, required this.icone, required this.couleur});
}

class AdressesFavoritesPage extends ConsumerStatefulWidget {
  const AdressesFavoritesPage({super.key});

  @override
  ConsumerState<AdressesFavoritesPage> createState() => _AdressesFavoritesPageState();
}

class _AdressesFavoritesPageState extends ConsumerState<AdressesFavoritesPage> {
  final List<AdresseFavorite> _adresses = [
    AdresseFavorite(id: '1', label: 'Maison', adresse: 'Quartier Bonamoussadi, Douala', icone: Iconsax.home_2_copy, couleur: CouleursApp.primaire),
    AdresseFavorite(id: '2', label: 'Travail', adresse: 'Akwa, Boulevard de la Liberté', icone: Iconsax.building_copy, couleur: CouleursApp.succes),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF08111F), // Fond clair premium
      appBar: AppBar(
        backgroundColor: const Color(0xFF08111F),
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left_2_copy, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Adresses favorites",
          style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Vos lieux enregistrés",
                style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white),
              ),
              const SizedBox(height: 8),
              Text(
                "Accédez rapidement à vos destinations récurrentes lors de vos prochaines expéditions.",
                style: GoogleFonts.inter(fontSize: 14, color: Colors.white70, height: 1.5),
              ),
              const SizedBox(height: 32),
              
              Expanded(
                child: ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  itemCount: _adresses.length,
                  itemBuilder: (context, index) {
                    final adr = _adresses[index];
                    return _buildAdresseCard(adr, index);
                  },
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Bouton d'ajout
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    _showAddAddressModal(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: CouleursApp.primaire,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  icon: const Icon(Iconsax.add_copy),
                  label: Text("Ajouter une adresse", style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAdresseCard(AdresseFavorite adr, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF10192A),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.white.withValues(alpha: 0.07), blurRadius: 15, offset: const Offset(0, 5))
        ],
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: adr.couleur.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(adr.icone, color: adr.couleur, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  adr.label,
                  style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                ),
                const SizedBox(height: 4),
                Text(
                  adr.adresse,
                  style: GoogleFonts.inter(fontSize: 13, color: Colors.white70),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Iconsax.more_copy, color: Colors.white70),
            onPressed: () {
              // Options: modifier, supprimer
            },
          ),
        ],
      ),
    ).animate().slideY(begin: 0.2);
  }

  void _showAddAddressModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          top: 32, left: 24, right: 24,
        ),
        decoration: const BoxDecoration(
          color: const Color(0xFF10192A),
          borderRadius: BorderRadius.only(topLeft: Radius.circular(32), topRight: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(width: 50, height: 5, decoration: BoxDecoration(color: Colors.white38, borderRadius: BorderRadius.circular(10))),
            ),
            const SizedBox(height: 24),
            Text("Nouvelle adresse", style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            
            // TextField Nom
            TextField(
              decoration: InputDecoration(
                hintText: "Label (ex: Maison, Parents...)",
                hintStyle: GoogleFonts.inter(color: Colors.white54),
                filled: true,
                fillColor: const Color(0xFF1A2640),
                prefixIcon: const Icon(Iconsax.tag_copy, color: Colors.white54),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 16),
            
            // TextField Adresse
            TextField(
              decoration: InputDecoration(
                hintText: "Adresse complète",
                hintStyle: GoogleFonts.inter(color: Colors.white54),
                filled: true,
                fillColor: const Color(0xFF1A2640),
                prefixIcon: const Icon(Iconsax.location_copy, color: Colors.white54),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 32),
            
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Adresse ajoutée avec succès.")));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: CouleursApp.primaire,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: Text("Enregistrer", style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
