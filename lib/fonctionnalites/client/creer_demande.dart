import 'dart:ui';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:update_camtrans/coeur/etat/demande_expedition_provider.dart';
import 'package:update_camtrans/services/service_gps.dart';
import 'widgets/resume_expedition_bottom_sheet.dart';
import 'package:update_camtrans/coeur/widgets/page_responsive.dart';
import 'package:update_camtrans/coeur/constantes/couleurs.dart';

/// =================================================================
/// NEO PREMIUM GLASS DARK - TUNNEL DE COMMANDE SPRINT 10
/// =================================================================

// ~30 marques de véhicules populaires au Cameroun (Douala, Yaoundé)
const List<String> _marquesVehicules = [
  'Toyota', 'Mercedes', 'Hyundai', 'Kia', 'Nissan', 'Peugeot',
  'Renault', 'Ford', 'Volkswagen', 'Honda', 'Mitsubishi', 'Suzuki',
  'Isuzu', 'Hino', 'Man', 'Iveco', 'Fuso', 'JAC', 'Foton',
  'Tata', 'Land Rover', 'BMW', 'Audi', 'Citroën', 'Opel',
  'Mazda', 'Volvo', 'Scania', 'DAF', 'Autre',
];

class CreerDemande extends ConsumerStatefulWidget {
  const CreerDemande({super.key});

  @override
  ConsumerState<CreerDemande> createState() => _CreerDemandeState();
}

class _CreerDemandeState extends ConsumerState<CreerDemande> {
  int _etapeCourante = 1;
  bool _isLoadingGps = false;

  late TextEditingController _departController;
  late TextEditingController _destinationController;
  late TextEditingController _detailsController;
  late TextEditingController _modeleController;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    final etatInitial = ref.read(demandeExpeditionProvider);
    _departController = TextEditingController(text: etatInitial.depart);
    _destinationController = TextEditingController(text: etatInitial.destination);
    _detailsController = TextEditingController(text: etatInitial.detailsSpecifiques);
    _modeleController = TextEditingController(text: etatInitial.modeleVehiculeRemorque);
  }

  @override
  void dispose() {
    _departController.dispose();
    _destinationController.dispose();
    _detailsController.dispose();
    _modeleController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _etapeSuivante(EtatDemandeExpedition etat, DemandeExpeditionNotifier notifier) {
    if (!etat.estEtapeValide(_etapeCourante)) {
      String message = "Veuillez remplir les informations requises.";
      if (_etapeCourante == 1) message = "Veuillez sélectionner une catégorie de service.";
      if (_etapeCourante == 2) {
        if (etat.categorieService == "Remorque") {
          if (etat.marqueVehiculeRemorque.isEmpty) {
            message = "Veuillez sélectionner la marque du véhicule.";
          } else {
            message = "Veuillez saisir le modèle du véhicule.";
          }
        } else {
          message = "Veuillez remplir les détails obligatoires.";
        }
      }
      if (_etapeCourante == 3) message = "Veuillez choisir une gamme de service.";
      if (_etapeCourante == 4) message = "L'itinéraire est incomplet.";
      
      _montrerErreur(message);
      return;
    }

    if (_etapeCourante == 4) {
      // Auto-assignation de la date et de l'heure (Commande immédiate)
      notifier.setDateTransport(DateTime.now());
      notifier.setHeureTransport(TimeOfDay.now());
      
      // On déclenche le matching/estimation en passant à l'étape 5
      notifier.estimerAvecIA();
    }

    setState(() {
      if (_etapeCourante < 5) _etapeCourante++;
    });
  }

  void _etapePrecedente() {
    setState(() {
      if (_etapeCourante > 1) _etapeCourante--;
    });
  }

  void _montrerErreur(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: CouleursApp.erreur, behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    final etat = ref.watch(demandeExpeditionProvider);
    final notifier = ref.read(demandeExpeditionProvider.notifier);

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: const Color(0xFF08111F),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16.0, top: 8.0, bottom: 8.0),
          child: _GlassButton(
            icon: Iconsax.arrow_left_2_copy,
            onTap: () {
              if (_etapeCourante > 1) {
                _etapePrecedente();
              } else {
                Navigator.pop(context);
              }
            },
          ),
        ),
      ),
      body: Stack(
        children: [
          // Background Gradient Sombre
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF08111F), Color(0xFF111827)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          
          // Orbe lumineux vert émeraude (à la Pinterest glassmorphism)
          Positioned(
            top: -80,
            left: -60,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF12B76A).withValues(alpha: 0.12),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
                child: const SizedBox(),
              ),
            ),
          ),
          // Orbe ambre (bas-droite)
          Positioned(
            bottom: -120,
            right: -80,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFF5A623).withValues(alpha: 0.08),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 120, sigmaY: 120),
                child: const SizedBox(),
              ),
            ),
          ),
          // Orbe dynamique lié à l'étape courante
          AnimatedPositioned(
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOutCubic,
            top: _etapeCourante * 80.0,
            right: _etapeCourante.isEven ? -40.0 : MediaQuery.of(context).size.width * 0.3,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 600),
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: etat.categorieService == "Remorque"
                    ? const Color(0xFF12B76A).withValues(alpha: 0.1)
                    : const Color(0xFF3B82F6).withValues(alpha: 0.1),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
                child: const SizedBox(),
              ),
            ),
          ),

          SafeArea(
            bottom: false,
            child: PageResponsive(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.only(left: 24, right: 24, top: 10, bottom: 180),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildProgressBar(_etapeCourante),
                    const SizedBox(height: 32),
                    
                    if (_etapeCourante == 1) _buildEtape1Categorie(etat, notifier),
                    if (_etapeCourante == 2) _buildEtape2Formulaire(etat, notifier),
                    if (_etapeCourante == 3) _buildEtape3Gamme(etat, notifier),
                    if (_etapeCourante == 4) _buildEtape4Itineraire(context, etat, notifier),
                    if (_etapeCourante == 5) _buildEtape5Matching(context, etat),
                  ],
                ),
              ),
            ),
          ),
          
          // Sticky Bottom CTA
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildBottomCTA(etat, notifier),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(int currentStep) {
    final steps = ["Service", "Détails", "Gamme", "Trajet", "Offre"];
    return LayoutBuilder(
      builder: (context, constraints) {
        return Row(
          children: List.generate(steps.length, (index) {
            final stepNum = index + 1;
            final isActive = stepNum == currentStep;
            final isCompleted = stepNum < currentStep;

            Color circleColor = const Color(0xFF1E293B);
            Color textColor = const Color(0xFF475569);
            
            if (isCompleted) {
              circleColor = CouleursApp.succes;
              textColor = CouleursApp.succes;
            } else if (isActive) {
              circleColor = CouleursApp.primaire;
              textColor = Colors.white;
            }

            return Expanded(
              child: Row(
                children: [
                  Column(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: 24, // Réduit de 28 à 24
                        height: 24, // Réduit de 28 à 24
                        decoration: BoxDecoration(
                          color: circleColor.withValues(alpha: isActive || isCompleted ? 0.2 : 1),
                          shape: BoxShape.circle,
                          border: Border.all(color: circleColor, width: 2),
                        ),
                        child: Center(
                          child: isCompleted
                              ? const Icon(Icons.check, size: 12, color: CouleursApp.succes)
                              : Text(
                                  "$stepNum",
                                  style: GoogleFonts.poppins(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: isActive ? Colors.white : const Color(0xFF94A3B8),
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        steps[index],
                        style: GoogleFonts.poppins(
                          fontSize: 9, // Réduit de 10 à 9
                          fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                          color: textColor,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                  if (index < steps.length - 1)
                    Expanded(
                      child: Container(
                        height: 2,
                        margin: const EdgeInsets.only(bottom: 18, left: 2, right: 2),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(1),
                          gradient: isCompleted
                              ? const LinearGradient(
                                  colors: [Color(0xFF12B76A), Color(0xFF3B82F6)],
                                )
                              : null,
                          color: isCompleted ? null : const Color(0xFF1E293B),
                        ),
                      ),
                    ),
                ],
              ).animate().fadeIn(delay: (100 * index).ms),
            );
          }),
        );
      }
    );
  }

  Widget _buildSectionTitle(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: -0.5),
        ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.1),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: GoogleFonts.poppins(fontSize: 14, color: Colors.white54),
        ).animate().fadeIn(delay: 300.ms).slideX(begin: -0.1),
        const SizedBox(height: 24),
      ],
    );
  }

  // ==========================================
  // ETAPE 1 : CATEGORIE
  // ==========================================
  Widget _buildEtape1Categorie(EtatDemandeExpedition etat, DemandeExpeditionNotifier notifier) {
    final categories = [
      {"titre": "Déménagement", "desc": "Appartement, maison, bureaux", "icon": Iconsax.home_2_copy},
      {"titre": "Remorque", "desc": "Véhicules, objets très lourds", "icon": Iconsax.car_copy},
      {"titre": "Marchandises", "desc": "Colis, palettes, matériaux", "icon": Iconsax.box_copy},
      {"titre": "Autre", "desc": "Besoins spécifiques", "icon": Iconsax.category_copy},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle("Que souhaitez-vous transporter ?", "Sélectionnez le service adapté à votre besoin."),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.9, // Augmenté pour donner plus de hauteur (ratio largeur/hauteur)
          ),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final cat = categories[index];
            final isSelected = etat.categorieService == cat["titre"];

            return GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                notifier.setCategorieService(cat["titre"] as String);
                notifier.setDetailsSpecifiques(""); // Reset du formulaire
                _detailsController.clear();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                decoration: BoxDecoration(
                  color: isSelected ? CouleursApp.primaire.withValues(alpha: 0.15) : const Color(0xFF1E293B).withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isSelected ? CouleursApp.primaire : Colors.white.withValues(alpha: 0.05),
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min, // Utilise le minimum d'espace
                  children: [
                    Icon(cat["icon"] as IconData, size: 28, color: isSelected ? CouleursApp.primaire : Colors.white), // Réduit de 32 à 28
                    const SizedBox(height: 6), // Réduit de 8 à 6
                    Flexible(
                      child: Text(
                        cat["titre"] as String,
                        style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white), // Réduit de 13 à 12
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 2), // Réduit de 4 à 2
                    Text(
                      cat["desc"] as String,
                      style: GoogleFonts.poppins(fontSize: 9, color: Colors.white54),
                      textAlign: TextAlign.center,
                      maxLines: 1, // Limité à 1 ligne pour éviter l'overflow vertical
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: (100 * index).ms).scale(begin: const Offset(0.9, 0.9)),
            );
          },
        ),
      ],
    );
  }

  // ==========================================
  // ETAPE 2 : FORMULAIRE DYNAMIQUE
  // ==========================================
  Widget _buildEtape2Formulaire(EtatDemandeExpedition etat, DemandeExpeditionNotifier notifier) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle("Détails de la demande", "Aidez-nous à mieux comprendre votre besoin pour le service : ${etat.categorieService}."),
        _GlassCard(
          child: Column(
            children: [
              if (etat.categorieService == "Déménagement") ...[
                _buildFloatingTextField(
                  controller: _detailsController,
                  hint: "Ex: F3, 3ème étage sans ascenseur",
                  icon: Iconsax.building_copy,
                  onChanged: (val) => notifier.setDetailsSpecifiques(val),
                  maxLines: 3,
                ),
              ] else if (etat.categorieService == "Remorque") ...[
                // ── Label section ────────────────────────────────
                Row(
                  children: [
                    const Icon(Icons.directions_car_outlined, color: Color(0xFF12B76A), size: 18),
                    const SizedBox(width: 8),
                    Text(
                      "Marque du véhicule",
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const Spacer(),
                    if (etat.marqueVehiculeRemorque.isNotEmpty)
                      Text(
                        etat.marqueVehiculeRemorque,
                        style: GoogleFonts.poppins(
                          color: const Color(0xFF12B76A),
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ).animate().fadeIn(),
                  ],
                ),
                const SizedBox(height: 12),
                // ── Grille horizontale scrollable ~30 marques ────
                SizedBox(
                  height: 48,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    itemCount: _marquesVehicules.length,
                    itemBuilder: (context, index) {
                      final marque = _marquesVehicules[index];
                      final isSelected = etat.marqueVehiculeRemorque == marque;
                      return GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          notifier.setMarqueRemorque(marque);
                          // Relancer l'estimation si le modèle est déjà saisi
                          if (etat.modeleVehiculeRemorque.isNotEmpty) {
                            notifier.estimerMasseIA();
                          }
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 280),
                          curve: Curves.easeOutBack,
                          margin: const EdgeInsets.only(right: 10),
                          padding: const EdgeInsets.symmetric(horizontal: 18),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF12B76A).withValues(alpha: 0.18)
                                : const Color(0xFF1E293B),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFF12B76A)
                                  : Colors.white.withValues(alpha: 0.08),
                              width: isSelected ? 2 : 1,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: const Color(0xFF12B76A).withValues(alpha: 0.35),
                                      blurRadius: 12,
                                      spreadRadius: 0,
                                    )
                                  ]
                                : [
                                    BoxShadow(
                                      color: Colors.transparent,
                                      blurRadius: 0,
                                      spreadRadius: 0,
                                    )
                                  ],
                          ),
                          child: Text(
                            marque,
                            style: GoogleFonts.inter(
                              color: isSelected ? const Color(0xFF12B76A) : Colors.white60,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                              fontSize: 13,
                            ),
                          ),
                        ).animate(target: isSelected ? 1 : 0).scale(
                          begin: const Offset(1.0, 1.0),
                          end: const Offset(1.06, 1.06),
                          duration: 200.ms,
                          curve: Curves.easeOutBack,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
                // ── Champ Modèle ─────────────────────────────────
                Row(
                  children: [
                    const Icon(Icons.edit_outlined, color: Color(0xFF94A3B8), size: 16),
                    const SizedBox(width: 6),
                    Text(
                      "Modèle",
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _buildFloatingTextField(
                  controller: _modeleController,
                  hint: etat.marqueVehiculeRemorque.isNotEmpty
                      ? "Ex: Prado, Yaris, Canter..."
                      : "Saisissez d'abord la marque",
                  icon: Iconsax.car_copy,
                  onChanged: (val) {
                    notifier.setModeleRemorque(val);
                    // Debounce 1.5s avant d'appeler l'IA
                    if (_debounce?.isActive ?? false) _debounce!.cancel();
                    _debounce = Timer(const Duration(milliseconds: 1500), () {
                      if (val.length >= 2 && etat.marqueVehiculeRemorque.isNotEmpty) {
                        notifier.estimerMasseIA();
                      }
                    });
                  },
                ),
                const SizedBox(height: 16),
                // ── État loader / badge masse ─────────────────────
                if (etat.estEnAttenteMasseIA)
                  Center(
                    child: Column(
                      children: [
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Icône dépanneuse pulsante — jamais un spinner générique
                            const Icon(Icons.car_repair, color: Color(0xFF12B76A), size: 28)
                                .animate(onPlay: (c) => c.repeat())
                                .shimmer(duration: 900.ms, color: Colors.white70)
                                .then()
                                .scale(
                                  begin: const Offset(0.9, 0.9),
                                  end: const Offset(1.1, 1.1),
                                  duration: 450.ms,
                                  curve: Curves.easeInOut,
                                )
                                .then()
                                .scale(
                                  begin: const Offset(1.1, 1.1),
                                  end: const Offset(0.9, 0.9),
                                  duration: 450.ms,
                                  curve: Curves.easeInOut,
                                ),
                            const SizedBox(width: 12),
                            Text(
                              "L'IA analyse le véhicule…",
                              style: GoogleFonts.inter(color: Colors.white54, fontSize: 13),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  )
                else if (etat.masseEstimeeKg > 0) ...[
                  // ── Badge masse avec count-up ──────────────────
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5A623).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFFF5A623).withValues(alpha: 0.35),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.scale_outlined, color: Color(0xFFF5A623), size: 20),
                        const SizedBox(width: 10),
                        Text(
                          "Masse estimée : ~",
                          style: GoogleFonts.inter(color: Colors.white70, fontSize: 14),
                        ),
                        TweenAnimationBuilder<double>(
                          key: ValueKey(etat.masseEstimeeKg),
                          tween: Tween<double>(begin: 0, end: etat.masseEstimeeKg),
                          duration: const Duration(milliseconds: 1200),
                          curve: Curves.easeOutCubic,
                          builder: (context, value, _) {
                            return Text(
                              "${value.toInt()} kg",
                              style: GoogleFonts.poppins(
                                color: const Color(0xFFF5A623),
                                fontWeight: FontWeight.w800,
                                fontSize: 17,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.15, curve: Curves.easeOutCubic),
                ],
              ] else if (etat.categorieService == "Marchandises") ...[
                _buildFloatingTextField(
                  controller: _detailsController,
                  hint: "Ex: 2 Palettes, Fragile, 200kg",
                  icon: Iconsax.weight_copy,
                  onChanged: (val) => notifier.setDetailsSpecifiques(val),
                  maxLines: 3,
                ),
              ] else ...[
                _buildFloatingTextField(
                  controller: _detailsController,
                  hint: "Décrivez précisément ce que vous souhaitez transporter...",
                  icon: Iconsax.textalign_left_copy,
                  onChanged: (val) => notifier.setDetailsSpecifiques(val),
                  maxLines: 4,
                ),
              ],
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: notifier.ajouterPhotos,
                icon: const Icon(Iconsax.camera_copy),
                label: const Text("Ajouter des photos (Optionnel)"),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                ),
              ),
              if (etat.photos.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: SizedBox(
                    height: 80,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: etat.photos.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  etat.photos[index].path,
                                  width: 80, height: 80, fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => Container(width: 80, height: 80, color: Colors.grey.withValues(alpha: 0.3), child: const Icon(Icons.image, color: Colors.white54)),
                                ),
                              ),
                              Positioned(
                                right: 4, top: 4,
                                child: GestureDetector(
                                  onTap: () => notifier.supprimerPhoto(index),
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                                    child: const Icon(Icons.close, size: 14, color: Colors.white),
                                  ),
                                ),
                              )
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                )
            ],
          ),
        ).animate().fadeIn().slideY(begin: 0.1),
      ],
    );
  }

  // ==========================================
  // ETAPE 3 : GAMME ECO / CONFORT
  // ==========================================
  Widget _buildEtape3Gamme(EtatDemandeExpedition etat, DemandeExpeditionNotifier notifier) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle("Options de Service", "Choisissez la gamme qui correspond à votre budget et à vos exigences."),
        
        _buildGammeCard(
          titre: "Éco",
          desc: "L'option la plus abordable. Idéal pour les transports simples.",
          icon: Iconsax.wallet_copy,
          prixPromo: "-15% approx.",
          color: CouleursApp.succes,
          isSelected: etat.optionGamme == "Eco",
          onTap: () => notifier.setOptionGamme("Eco"),
        ),
        const SizedBox(height: 16),
        _buildGammeCard(
          titre: "Confort",
          desc: "Service Premium. Chauffeurs les mieux notés, aide au chargement incluse.",
          icon: Iconsax.star_1_copy,
          prixPromo: "Premium",
          color: CouleursApp.avertissement,
          isSelected: etat.optionGamme == "Confort",
          onTap: () => notifier.setOptionGamme("Confort"),
        ),
      ],
    );
  }

  Widget _buildGammeCard({required String titre, required String desc, required IconData icon, required String prixPromo, required Color color, required bool isSelected, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.1) : const Color(0xFF1E293B).withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? color : Colors.white.withValues(alpha: 0.05),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.2), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(titre, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 4),
                  Text(desc, style: GoogleFonts.poppins(fontSize: 12, color: Colors.white54)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
              child: Text(prixPromo, style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
            )
          ],
        ),
      ).animate().fadeIn().slideY(begin: 0.1),
    );
  }

  // ==========================================
  // ETAPE 4 : ITINERAIRE
  // ==========================================
  Widget _buildEtape4Itineraire(BuildContext context, EtatDemandeExpedition etat, DemandeExpeditionNotifier notifier) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle("Itinéraire du Trajet", "Où allons-nous ? (Départ immédiat)"),
        _GlassCard(
          child: Column(
            children: [
              _buildFloatingTextField(
                controller: _departController,
                hint: "Lieu de départ",
                icon: Iconsax.send_2_copy,
                onChanged: (val) {
                  notifier.setDepart(val);
                },
                isLoadingSuffix: _isLoadingGps,
                onSuffixTap: () async {
                  setState(() => _isLoadingGps = true);
                  final gps = ref.read(serviceGpsProvider);
                  final position = await gps.obtenirPositionActuelle();
                  
                  if (position != null) {
                    final adresse = await gps.obtenirAdresse(latitude: position.latitude, longitude: position.longitude);
                    if (adresse.isNotEmpty) {
                      notifier.setDepart(adresse);
                      _departController.text = adresse;
                      notifier.setLatitudeDepart(position.latitude);
                      notifier.setLongitudeDepart(position.longitude);
                    } else {
                      _montrerErreur("Impossible de trouver l'adresse.");
                    }
                  } else {
                    _montrerErreur("Localisation non disponible. Veuillez vérifier vos permissions GPS.");
                  }
                  setState(() => _isLoadingGps = false);
                },
              ),
              const SizedBox(height: 16),
              _buildFloatingTextField(
                controller: _destinationController,
                hint: "Lieu d'arrivée",
                icon: Iconsax.location_add_copy,
                onChanged: (val) {
                  notifier.setDestination(val);
                },
              ),
            ],
          ),
        ),
      ],
    ).animate().fadeIn().slideY(begin: 0.1);
  }

  // ==========================================
  // ETAPE 5 : MATCHING & PROPOSITION
  // ==========================================
  Widget _buildEtape5Matching(BuildContext context, EtatDemandeExpedition etat) {
    if (etat.estEnAttenteIA) {
      return Center(
        child: Column(
          children: [
            const SizedBox(height: 40),
            const CircularProgressIndicator(color: CouleursApp.primaire),
            const SizedBox(height: 24),
            Text("Recherche du meilleur chauffeur...", style: GoogleFonts.poppins(color: Colors.white, fontSize: 16)),
            const SizedBox(height: 8),
            Text("Calcul de l'itinéraire et de l'estimation en cours", style: GoogleFonts.poppins(color: Colors.white54, fontSize: 12)),
          ],
        ),
      );
    }

    final chauffeur = etat.chauffeurPropose;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle("Proposition", "Voici l'offre trouvée pour votre trajet."),
        
        // Carte Chauffeur
        if (chauffeur != null) ...[
          _GlassCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28, // Réduit de 30 à 28
                  backgroundImage: chauffeur.photo.isNotEmpty ? NetworkImage(chauffeur.photo) : null,
                  backgroundColor: CouleursApp.primaire.withValues(alpha: 0.2),
                  child: chauffeur.photo.isEmpty ? const Icon(Iconsax.user_copy, color: CouleursApp.primaire) : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "${chauffeur.prenom} ${chauffeur.nom}",
                        style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Wrap( // Utilisation de Wrap au lieu de Row pour éviter l'overflow
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star, color: CouleursApp.avertissement, size: 14),
                              const SizedBox(width: 4),
                              Text("4.8", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12)),
                            ],
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.drive_eta, color: Colors.white54, size: 14),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  chauffeur.typeVehicule.isNotEmpty ? chauffeur.typeVehicule : "Camionnette",
                                  style: GoogleFonts.poppins(color: Colors.white54, fontSize: 11),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ).animate().fadeIn().slideY(begin: 0.1),
          
          const SizedBox(height: 16),
          // Distance & Temps
          Row(
            children: [
              Expanded(
                child: _GlassCard(
                  child: Column(
                    children: [
                      const Icon(Iconsax.routing_2_copy, color: CouleursApp.primaire),
                      const SizedBox(height: 8),
                      Text("À ${etat.distanceApprocheKm.toStringAsFixed(1)} km", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
                      Text("Distance d'approche", style: GoogleFonts.poppins(color: Colors.white54, fontSize: 10)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _GlassCard(
                  child: Column(
                    children: [
                      const Icon(Iconsax.clock_copy, color: CouleursApp.avertissement),
                      const SizedBox(height: 8),
                      Text("${etat.tempsApprocheMin} min", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
                      Text("Temps estimé", style: GoogleFonts.poppins(color: Colors.white54, fontSize: 10)),
                    ],
                  ),
                ),
              ),
            ],
          ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),
        ] else ...[
          _GlassCard(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Center(
                child: Text("Aucun chauffeur disponible pour le moment. La commande sera mise en file d'attente.", textAlign: TextAlign.center, style: GoogleFonts.poppins(color: CouleursApp.avertissement)),
              ),
            ),
          ),
        ],

        const SizedBox(height: 24),
        // Résumé IA (Prix, Volume, Conseil)
        _GlassCard(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Estimation IA", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              const Divider(color: Colors.white12, height: 32),
              _buildEstimationRow(
                "Véhicule Recommandé",
                etat.categorieService == "Remorque"
                    ? (etat.chauffeurPropose?.typeVehicule.isNotEmpty == true
                        ? etat.chauffeurPropose!.typeVehicule
                        : "Dépanneuse")
                    : etat.categorieVehicule.isNotEmpty
                        ? etat.categorieVehicule
                        : "Adapté à votre charge",
                Iconsax.truck_fast_copy,
              ),
              const SizedBox(height: 12),
              _buildEstimationRow("Volume", etat.volumeEstime, Iconsax.box_copy),
              const SizedBox(height: 12),
              _buildEstimationRow("Prix Estimé", etat.prixEstime, Iconsax.wallet_3_copy, isHighlight: true),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: CouleursApp.succes.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Iconsax.info_circle_copy, color: CouleursApp.succes, size: 20),
                    const SizedBox(width: 12),
                    Expanded(child: Text(etat.conseilIA, style: GoogleFonts.poppins(color: CouleursApp.succes, fontSize: 12))),
                  ],
                ),
              )
            ],
          ),
        ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1),
      ],
    );
  }

  Widget _buildEstimationRow(String label, String value, IconData icon, {bool isHighlight = false}) {
    return Row(
      children: [
        Icon(icon, size: 16, color: isHighlight ? CouleursApp.succes : Colors.white54),
        const SizedBox(width: 8),
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: GoogleFonts.poppins(color: Colors.white54, fontSize: 13),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 3,
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: GoogleFonts.poppins(
              color: isHighlight ? CouleursApp.succes : Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: isHighlight ? 16 : 13,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // ==========================================
  // WIDGETS UTILES
  // ==========================================
  Widget _buildBottomCTA(EtatDemandeExpedition etat, DemandeExpeditionNotifier notifier) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A).withValues(alpha: 0.9),
        border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.06))),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: etat.estEnAttenteIA
                  ? null
                  : const LinearGradient(
                      colors: [Color(0xFF12B76A), Color(0xFF0E9456)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
              boxShadow: etat.estEnAttenteIA
                  ? []
                  : [
                      BoxShadow(
                        color: const Color(0xFF12B76A).withValues(alpha: 0.35),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
            ),
            child: ElevatedButton(
              onPressed: etat.estEnAttenteIA
                  ? null
                  : () {
                      HapticFeedback.mediumImpact();
                      if (_etapeCourante < 5) {
                        _etapeSuivante(etat, notifier);
                      } else {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (context) => Padding(
                            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
                            child: const ResumeExpeditionBottomSheet(),
                          ),
                        );
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _etapeCourante < 4
                        ? "Continuer"
                        : _etapeCourante == 4
                            ? "Rechercher un chauffeur"
                            : "Valider la Commande",
                    style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  if (_etapeCourante < 5) ...[
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward_rounded, size: 20),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingTextField({
    TextEditingController? controller,
    required String hint,
    required IconData icon,
    required Function(String) onChanged,
    int maxLines = 1,
    VoidCallback? onSuffixTap,
    bool isLoadingSuffix = false,
  }) {
    return TextFormField(
      controller: controller,
      onChanged: onChanged,
      maxLines: maxLines,
      style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.poppins(color: const Color(0xFF64748B), fontWeight: FontWeight.w400),
        prefixIcon: Padding(
          padding: EdgeInsets.only(bottom: maxLines > 1 ? (maxLines - 1) * 20.0 : 0),
          child: Icon(icon, color: const Color(0xFF94A3B8), size: 20),
        ),
        suffixIcon: onSuffixTap != null
            ? GestureDetector(
                onTap: isLoadingSuffix ? null : onSuffixTap,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: isLoadingSuffix
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF3B82F6)))
                      : const Icon(Icons.my_location, color: Color(0xFF3B82F6), size: 22),
                ),
              )
            : null,
        filled: true,
        fillColor: const Color(0xFF0F172A).withValues(alpha: 0.7),
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 1.5)),
      ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  const _GlassCard({required this.child, this.padding = const EdgeInsets.all(24)});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B).withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.08),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 20,
                spreadRadius: -5,
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class _GlassButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _GlassButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}