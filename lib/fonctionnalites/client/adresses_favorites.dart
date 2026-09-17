import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import 'package:update_camtrans/coeur/constantes/couleurs.dart';
import 'package:update_camtrans/coeur/etat/utilisateur_provider.dart';
import 'package:update_camtrans/services/service_firestore.dart';

// =====================================================================
// Page : Adresses Favorites
// Entièrement connectée à Firestore via currentClientProvider.
// Lecture, ajout et suppression en temps réel.
// =====================================================================

class AdressesFavoritesPage extends ConsumerStatefulWidget {
  const AdressesFavoritesPage({super.key});

  @override
  ConsumerState<AdressesFavoritesPage> createState() =>
      _AdressesFavoritesPageState();
}

class _AdressesFavoritesPageState extends ConsumerState<AdressesFavoritesPage> {
  // Controleurs du formulaire d'ajout
  final _labelController = TextEditingController();
  final _adresseController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _labelController.dispose();
    _adresseController.dispose();
    super.dispose();
  }

  // -----------------------------------------------------------------
  // Sauvegarde d'une adresse dans Firestore (mise à jour du tableau)
  // -----------------------------------------------------------------
  Future<void> _ajouterAdresse() async {
    final label = _labelController.text.trim();
    final adresse = _adresseController.text.trim();
    if (label.isEmpty || adresse.isEmpty) return;

    final client = ref.read(currentClientProvider).value;
    if (client == null) return;

    setState(() => _isSaving = true);

    final nouvelleAdresse =
        '$label|$adresse'; // format "Label|Adresse complète"
    final liste = List<String>.from(client.adressesFavorites)
      ..add(nouvelleAdresse);

    try {
      await ref.read(serviceFirestoreProvider).modifierDocument(
        collection: 'clients',
        id: client.id,
        donnees: {'adressesFavorites': liste},
      );
      if (mounted) {
        Navigator.pop(context);
        _labelController.clear();
        _adresseController.clear();
        _afficherSnackbar(
            '✅ Adresse enregistrée avec succès !', CouleursApp.succes);
      }
    } catch (e) {
      if (mounted) {
        _afficherSnackbar(
            '❌ Erreur lors de l\'enregistrement.', CouleursApp.erreur);
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // -----------------------------------------------------------------
  // Suppression d'une adresse de la liste Firestore
  // -----------------------------------------------------------------
  Future<void> _supprimerAdresse(String entree) async {
    final client = ref.read(currentClientProvider).value;
    if (client == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF10192A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Supprimer l\'adresse ?',
            style: GoogleFonts.inter(
                color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text('Cette action est irréversible.',
            style: GoogleFonts.inter(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Annuler',
                style: GoogleFonts.inter(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Supprimer',
                style: GoogleFonts.inter(
                    color: CouleursApp.erreur, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final liste = List<String>.from(client.adressesFavorites)..remove(entree);

    try {
      await ref.read(serviceFirestoreProvider).modifierDocument(
        collection: 'clients',
        id: client.id,
        donnees: {'adressesFavorites': liste},
      );
      if (mounted) {
        _afficherSnackbar('Adresse supprimée.', CouleursApp.avertissement);
      }
    } catch (e) {
      if (mounted) {
        _afficherSnackbar('Erreur lors de la suppression.', CouleursApp.erreur);
      }
    }
  }

  void _afficherSnackbar(String message, Color couleur) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message, style: GoogleFonts.inter()),
      backgroundColor: couleur,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  // -----------------------------------------------------------------
  // BUILD
  // -----------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final clientAsync = ref.watch(currentClientProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF08111F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF08111F),
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left_2_copy, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Adresses favorites',
          style: GoogleFonts.inter(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: SafeArea(
        child: clientAsync.when(
          loading: () => const Center(
              child: CircularProgressIndicator(color: CouleursApp.primaire)),
          error: (e, _) => Center(
              child: Text('Erreur de chargement.',
                  style: GoogleFonts.inter(color: Colors.white70))),
          data: (client) {
            if (client == null) {
              return Center(
                  child: Text('Utilisateur non connecté.',
                      style: GoogleFonts.inter(color: Colors.white70)));
            }

            // Décodage des entrées "Label|Adresse"
            final adresses = client.adressesFavorites;

            return Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Vos lieux enregistrés',
                    style: GoogleFonts.inter(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Accédez rapidement à vos destinations récurrentes lors de vos prochaines courses.',
                    style: GoogleFonts.inter(
                        fontSize: 14, color: Colors.white70, height: 1.5),
                  ),
                  const SizedBox(height: 28),

                  // --- Liste des adresses ---
                  Expanded(
                    child: adresses.isEmpty
                        ? _buildEtatVide()
                        : ListView.builder(
                            physics: const BouncingScrollPhysics(),
                            itemCount: adresses.length,
                            itemBuilder: (context, index) {
                              final entree = adresses[index];
                              final parts = entree.split('|');
                              final label =
                                  parts.isNotEmpty ? parts[0] : entree;
                              final adresse = parts.length > 1 ? parts[1] : '';
                              return _buildAdresseCard(
                                  label, adresse, entree, index);
                            },
                          ),
                  ),

                  const SizedBox(height: 20),

                  // --- Bouton Ajouter ---
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
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      icon: const Icon(Iconsax.add_copy),
                      label: Text(
                        'Ajouter une adresse',
                        style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600, fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // -----------------------------------------------------------------
  // État vide (aucune adresse enregistrée)
  // -----------------------------------------------------------------
  Widget _buildEtatVide() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: CouleursApp.primaire.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Iconsax.location_copy,
                color: CouleursApp.primaire, size: 48),
          ),
          const SizedBox(height: 20),
          Text(
            'Aucune adresse enregistrée',
            style: GoogleFonts.inter(
                color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            'Ajoutez vos lieux fréquents pour\ngagner du temps lors de vos commandes.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
                color: Colors.white54, fontSize: 14, height: 1.5),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  // -----------------------------------------------------------------
  // Carte d'une adresse avec menu contextuel fonctionnel
  // -----------------------------------------------------------------
  Widget _buildAdresseCard(
      String label, String adresse, String entreeComplete, int index) {
    final icones = [
      Iconsax.home_2_copy,
      Iconsax.building_copy,
      Iconsax.location_copy,
      Iconsax.map_copy,
    ];
    final couleurs = [
      CouleursApp.primaire,
      CouleursApp.secondaire,
      CouleursApp.accentNeon,
      CouleursApp.accentViolet,
    ];
    final icone = icones[index % icones.length];
    final couleur = couleurs[index % couleurs.length];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF10192A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: CouleursApp.bordureSombre),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: couleur.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icone, color: couleur, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Colors.white),
                ),
                if (adresse.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    adresse,
                    style:
                        GoogleFonts.inter(fontSize: 13, color: Colors.white60),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          // Menu contextuel opérationnel
          PopupMenuButton<String>(
            icon: const Icon(Iconsax.more_copy, color: Colors.white54),
            color: const Color(0xFF1A2640),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            onSelected: (value) {
              if (value == 'supprimer') {
                _supprimerAdresse(entreeComplete);
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'supprimer',
                child: Row(
                  children: [
                    const Icon(Iconsax.trash_copy,
                        color: CouleursApp.erreur, size: 18),
                    const SizedBox(width: 10),
                    Text('Supprimer',
                        style: GoogleFonts.inter(
                            color: CouleursApp.erreur,
                            fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().slideY(begin: 0.15, duration: 350.ms, delay: (index * 60).ms);
  }

  // -----------------------------------------------------------------
  // Modal d'ajout d'adresse — sauvegarde réelle dans Firestore
  // -----------------------------------------------------------------
  void _showAddAddressModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            top: 32,
            left: 24,
            right: 24,
          ),
          decoration: const BoxDecoration(
            color: Color(0xFF10192A),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(32),
              topRight: Radius.circular(32),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 50,
                  height: 5,
                  decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Nouvelle adresse favorite',
                style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
              const SizedBox(height: 6),
              Text(
                'Elle sera enregistrée dans votre profil et disponible hors ligne.',
                style: GoogleFonts.inter(
                    fontSize: 13, color: Colors.white54, height: 1.4),
              ),
              const SizedBox(height: 24),

              // Champ Label
              TextField(
                controller: _labelController,
                style: GoogleFonts.inter(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Label (ex : Maison, Bureau, Parents...)',
                  hintStyle: GoogleFonts.inter(color: Colors.white38),
                  filled: true,
                  fillColor: const Color(0xFF1A2640),
                  prefixIcon: const Icon(Iconsax.tag_copy,
                      color: CouleursApp.primaire, size: 20),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 14),

              // Champ Adresse
              TextField(
                controller: _adresseController,
                style: GoogleFonts.inter(color: Colors.white),
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: 'Adresse complète (quartier, ville...)',
                  hintStyle: GoogleFonts.inter(color: Colors.white38),
                  filled: true,
                  fillColor: const Color(0xFF1A2640),
                  prefixIcon: const Padding(
                    padding: EdgeInsets.only(bottom: 22),
                    child: Icon(Iconsax.location_copy,
                        color: CouleursApp.primaire, size: 20),
                  ),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 28),

              // Bouton Enregistrer — déclenche la vraie sauvegarde Firestore
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _ajouterAdresse,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: CouleursApp.primaire,
                    disabledBackgroundColor:
                        CouleursApp.primaire.withValues(alpha: 0.4),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2.5),
                        )
                      : Text(
                          'Enregistrer',
                          style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                        ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
