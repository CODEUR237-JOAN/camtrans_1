import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../coeur/etat/demande_expedition_provider.dart';
import 'widgets/resume_expedition_bottom_sheet.dart';
import '../../coeur/widgets/page_responsive.dart';

/// =================================================================
/// NEO PREMIUM GLASS DARK - CRÉATION DE COMMANDE
/// =================================================================
class CreerDemande extends ConsumerWidget {
  const CreerDemande({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final etat = ref.watch(demandeExpeditionProvider);
    final notifier = ref.read(demandeExpeditionProvider.notifier);

    // Détermination de l'étape actuelle (Progression)
    int etape = 1;
    if (etat.depart.isNotEmpty && etat.destination.isNotEmpty) etape = 2;
    if (etat.typeMarchandise.isNotEmpty) etape = 3;
    if (etat.dateTransport != null && etat.heureTransport != null) etape = 4;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: const Color(0xFF08111F), // Fond de base très sombre
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16.0, top: 8.0, bottom: 8.0),
          child: _GlassButton(
            icon: Iconsax.arrow_left_2_copy,
            onTap: () => Navigator.pop(context),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 20.0),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: const Color(0xFF1E293B),
              child: const Icon(Iconsax.user_copy, color: Color(0xFF94A3B8), size: 18),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Background Gradient Sombre (Neo Premium Dark)
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF08111F), Color(0xFF111827)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          
          // Blob lumineux en fond pour le style
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF3B82F6).withValues(alpha: 0.15),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
                child: const SizedBox(),
              ),
            ),
          ),

          SafeArea(
            bottom: false,
            child: PageResponsive(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                padding: const EdgeInsets.only(left: 24, right: 24, top: 10, bottom: 180),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeroHeader(),
                    const SizedBox(height: 28),
                    _buildProgressBar(etape),
                    const SizedBox(height: 32),
                    
                    _buildSectionTitle("Votre itinéraire"),
                    const SizedBox(height: 16),
                    _buildTrajetCard(context, etat, notifier),
                    
                    const SizedBox(height: 36),
                    _buildSectionTitle("Que transportez-vous ?"),
                    const SizedBox(height: 16),
                    _buildMarchandiseGrid(etat, notifier),
                    
                    const SizedBox(height: 36),
                    _buildSectionTitle("Planification"),
                    const SizedBox(height: 16),
                    _buildPlanificationCard(context, etat, notifier),
                  ],
                ),
              ),
            ),
          ),
          
          // Sticky Bottom CTA & Summary
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildBottomSummaryAndCTA(context, etat),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Nouvelle commande",
          style: GoogleFonts.poppins(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            letterSpacing: -0.5,
          ),
        ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.2, end: 0),
        const SizedBox(height: 8),
        Text(
          "Expédiez vos marchandises partout au Cameroun.",
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: const Color(0xFF94A3B8),
            height: 1.4,
          ),
        ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2, end: 0),
      ],
    );
  }

  Widget _buildProgressBar(int currentStep) {
    final steps = ["Trajet", "Marchandise", "Planification", "Confirmation"];
    return Row(
      children: List.generate(steps.length, (index) {
        final stepNum = index + 1;
        final isActive = stepNum == currentStep;
        final isCompleted = stepNum < currentStep;

        Color circleColor = const Color(0xFF1E293B);
        Color textColor = const Color(0xFF475569);
        
        if (isCompleted) {
          circleColor = const Color(0xFF10B981); // Accent Vert
          textColor = const Color(0xFF10B981);
        } else if (isActive) {
          circleColor = const Color(0xFF3B82F6); // Bleu Principal
          textColor = Colors.white;
        }

        return Expanded(
          child: Row(
            children: [
              Column(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: circleColor.withValues(alpha: isActive || isCompleted ? 0.2 : 1),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: circleColor,
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: isCompleted
                          ? const Icon(Icons.check, size: 14, color: Color(0xFF10B981))
                          : Text(
                              "$stepNum",
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isActive ? Colors.white : const Color(0xFF94A3B8),
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    steps[index],
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                      color: textColor,
                    ),
                  ),
                ],
              ),
              if (index < steps.length - 1)
                Expanded(
                  child: Container(
                    height: 2,
                    margin: const EdgeInsets.only(bottom: 20, left: 8, right: 8),
                    color: isCompleted ? const Color(0xFF10B981) : const Color(0xFF1E293B),
                  ),
                ),
            ],
          ).animate().fadeIn(delay: (300 + index * 100).ms),
        );
      }),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
    ).animate().fadeIn(delay: 400.ms).slideX(begin: -0.1);
  }

  Widget _buildTrajetCard(BuildContext context, EtatDemandeExpedition etat, DemandeExpeditionNotifier notifier) {
    return _GlassCard(
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  const SizedBox(height: 18),
                  const Icon(Icons.my_location_rounded, size: 18, color: Color(0xFF3B82F6)),
                  Container(
                    height: 40,
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B82F6).withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const Icon(Icons.location_on_rounded, size: 20, color: Color(0xFF10B981)),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  children: [
                    _buildFloatingTextField(
                      initialValue: etat.depart,
                      hint: "Lieu de départ",
                      icon: Iconsax.send_2_copy,
                      onChanged: notifier.setDepart,
                    ),
                    const SizedBox(height: 12),
                    _buildFloatingTextField(
                      initialValue: etat.destination,
                      hint: "Destination",
                      icon: Iconsax.location_add_copy,
                      onChanged: notifier.setDestination,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Suggestions intelligentes
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _SuggestionChip(icon: "📍", label: "Maison", onTap: () => notifier.setDestination("Maison")),
                _SuggestionChip(icon: "🏢", label: "Travail", onTap: () => notifier.setDestination("Travail")),
                _SuggestionChip(icon: "⭐", label: "Dernière dest.", onTap: () {}),
                _SuggestionChip(icon: "🕒", label: "Récent", onTap: () {}),
              ],
            ),
          ),
          
          if (etat.depart.isNotEmpty && etat.destination.isNotEmpty) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B).withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _InfoItem(icon: Iconsax.routing_2_copy, value: "15.4 km"),
                  Container(width: 1, height: 30, color: const Color(0xFF334155)),
                  _InfoItem(icon: Iconsax.clock_copy, value: "45 min"),
                ],
              ),
            ).animate().fadeIn().slideY(begin: 0.2),
          ]
        ],
      ),
    ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.1);
  }

  Widget _buildFloatingTextField({
    required String initialValue,
    required String hint,
    required IconData icon,
    required Function(String) onChanged,
  }) {
    return TextFormField(
      initialValue: initialValue,
      onChanged: onChanged,
      style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.poppins(color: const Color(0xFF64748B), fontWeight: FontWeight.w400),
        prefixIcon: Icon(icon, color: const Color(0xFF94A3B8), size: 20),
        suffixIcon: const Icon(Icons.my_location, color: Color(0xFF3B82F6), size: 18),
        filled: true,
        fillColor: const Color(0xFF0F172A).withValues(alpha: 0.7),
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 1.5),
        ),
      ),
    );
  }

  Widget _buildMarchandiseGrid(EtatDemandeExpedition etat, DemandeExpeditionNotifier notifier) {
    final categories = [
      {"nom": "Colis", "emoji": "📦"},
      {"nom": "Mobilier", "emoji": "🛋️"},
      {"nom": "Électroménager", "emoji": "📺"},
      {"nom": "Matériaux", "emoji": "🏗️"},
      {"nom": "Déménagement", "emoji": "🚛"},
      {"nom": "Véhicule", "emoji": "🚗"},
      {"nom": "Moto", "emoji": "🏍️"},
      {"nom": "Autres", "emoji": "✨"},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.4,
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final nom = categories[index]["nom"]!;
        final emoji = categories[index]["emoji"]!;
        final isSelected = etat.typeMarchandise == nom;

        return GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            notifier.setTypeMarchandise(isSelected ? "" : nom);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutQuart,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF3B82F6).withValues(alpha: 0.15) : const Color(0xFF1E293B).withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isSelected ? const Color(0xFF3B82F6) : Colors.white.withValues(alpha: 0.05),
                width: isSelected ? 2 : 1,
              ),
              boxShadow: isSelected
                  ? [BoxShadow(color: const Color(0xFF3B82F6).withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 8))]
                  : [],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  emoji,
                  style: const TextStyle(fontSize: 28),
                ).animate(target: isSelected ? 1 : 0).scaleXY(end: 1.2, duration: 200.ms),
                const SizedBox(height: 10),
                Text(
                  nom,
                  style: GoogleFonts.poppins(
                    color: isSelected ? Colors.white : const Color(0xFF94A3B8),
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ).animate().fadeIn(delay: (600 + index * 50).ms).scale(begin: const Offset(0.9, 0.9));
      },
    );
  }

  Widget _buildPlanificationCard(BuildContext context, EtatDemandeExpedition etat, DemandeExpeditionNotifier notifier) {
    return Row(
      children: [
        Expanded(
          child: _GlassDateTimePicker(
            icon: Iconsax.calendar_1_copy,
            label: "Date",
            value: etat.dateTransport != null ? DateFormat('dd/MMM/yyyy').format(etat.dateTransport!) : "Aujourd'hui",
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime.now(),
                lastDate: DateTime(2035),
                builder: (context, child) {
                  return Theme(
                    data: ThemeData.dark().copyWith(
                      colorScheme: const ColorScheme.dark(
                        primary: Color(0xFF3B82F6),
                        onPrimary: Colors.white,
                        surface: Color(0xFF1E293B),
                        onSurface: Colors.white,
                      ),
                    ),
                    child: child!,
                  );
                },
              );
              if (date != null) notifier.setDateTransport(date);
            },
          ),
        ).animate().fadeIn(delay: 800.ms).slideX(begin: -0.1),
        const SizedBox(width: 16),
        Expanded(
          child: _GlassDateTimePicker(
            icon: Iconsax.clock_copy,
            label: "Heure",
            value: etat.heureTransport != null ? etat.heureTransport!.format(context) : "Immédiat",
            onTap: () async {
              final time = await showTimePicker(
                context: context,
                initialTime: TimeOfDay.now(),
                builder: (context, child) {
                  return Theme(
                    data: ThemeData.dark().copyWith(
                      colorScheme: const ColorScheme.dark(
                        primary: Color(0xFF3B82F6),
                        onPrimary: Colors.white,
                        surface: Color(0xFF1E293B),
                        onSurface: Colors.white,
                      ),
                    ),
                    child: child!,
                  );
                },
              );
              if (time != null) notifier.setHeureTransport(time);
            },
          ),
        ).animate().fadeIn(delay: 900.ms).slideX(begin: 0.1),
      ],
    );
  }

  Widget _buildBottomSummaryAndCTA(BuildContext context, EtatDemandeExpedition etat) {
    return Container(
      padding: const EdgeInsets.only(top: 24, left: 24, right: 24, bottom: 40),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A).withValues(alpha: 0.85),
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(36), topRight: Radius.circular(36)),
        border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 30,
            offset: const Offset(0, -10),
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(36),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Summary
              if (etat.volumeEstime.isNotEmpty) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Recommandé", style: GoogleFonts.poppins(color: const Color(0xFF94A3B8), fontSize: 12)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Iconsax.truck_fast_copy, color: Color(0xFF60A5FA), size: 16),
                            const SizedBox(width: 6),
                            Text(etat.categorieVehicule, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                          ],
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text("Est. Prix (IA)", style: GoogleFonts.poppins(color: const Color(0xFF94A3B8), fontSize: 12)),
                        const SizedBox(height: 4),
                        Text(
                          etat.prixEstime.isNotEmpty ? "${etat.prixEstime} FCFA" : "---",
                          style: GoogleFonts.poppins(color: const Color(0xFF10B981), fontWeight: FontWeight.bold, fontSize: 16),
                        ).animate(onPlay: (c) => c.repeat(reverse: true)).shimmer(duration: 2.seconds, color: Colors.white),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
              
              // CTA Button
              GestureDetector(
                onTap: etat.estValide
                    ? () {
                        HapticFeedback.heavyImpact();
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (context) => const ResumeExpeditionBottomSheet(),
                        );
                      }
                    : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: double.infinity,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: etat.estValide
                        ? const LinearGradient(colors: [Color(0xFF3B82F6), Color(0xFF2563EB)])
                        : LinearGradient(colors: [const Color(0xFF334155), const Color(0xFF1E293B)]),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: etat.estValide
                        ? [BoxShadow(color: const Color(0xFF3B82F6).withValues(alpha: 0.4), blurRadius: 20, offset: const Offset(0, 8))]
                        : [],
                  ),
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Continuer",
                          style: GoogleFonts.poppins(
                            color: etat.estValide ? Colors.white : const Color(0xFF64748B),
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(Iconsax.arrow_right_1_copy, color: etat.estValide ? Colors.white : const Color(0xFF64748B), size: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().slideY(begin: 1.0, duration: 600.ms, curve: Curves.easeOutExpo);
  }
}

/// Composants Visuels Spécifiques (Glassmorphism)

class _GlassCard extends StatelessWidget {
  final Widget child;
  const _GlassCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 30,
            offset: const Offset(0, 15),
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: child,
          ),
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
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.1),
          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        ),
        child: ClipOval(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
        ),
      ),
    );
  }
}

class _SuggestionChip extends StatelessWidget {
  final String icon;
  final String label;
  final VoidCallback onTap;

  const _SuggestionChip({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF334155).withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(icon, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.poppins(color: const Color(0xFFE2E8F0), fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String value;

  const _InfoItem({required this.icon, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF60A5FA), size: 18),
        const SizedBox(width: 8),
        Text(value, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
      ],
    );
  }
}

class _GlassDateTimePicker extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  const _GlassDateTimePicker({required this.icon, required this.label, required this.value, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B).withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6).withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: const Color(0xFF60A5FA), size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label, style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF94A3B8))),
                      const SizedBox(height: 2),
                      Text(value, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}