import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

// ==========================================
// PALETTE PREMIUM
// ==========================================
const Color pBlue = Color(0xFF2697FF);
const Color pDarkBlue = Color(0xFF1E3A8A);
const Color pBg = Color(0xFFF4F7FB);
const Color pSurface = Colors.white;
const Color pSuccess = Color(0xFF16A34A);
const Color pTextMain = Color(0xFF1E293B);
const Color pTextMuted = Color(0xFF64748B);

class CreerDemande extends StatefulWidget {
  const CreerDemande({super.key});

  @override
  State<CreerDemande> createState() => _CreerDemandeState();
}

class _CreerDemandeState extends State<CreerDemande> {
  final _depart = TextEditingController();
  final _destination = TextEditingController();
  final _description = TextEditingController();

  String _categorie = "Lourd";
  DateTime? _dateTransport;
  bool _calculIA = false;

  void _simulerCalculIA() {
    if (_depart.text.isNotEmpty && _destination.text.isNotEmpty) {
      setState(() => _calculIA = true);
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) setState(() => _calculIA = false);
      });
    }
  }

  Future<void> _choisirDate() async {
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime(2035),
      initialDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: pBlue,
              onPrimary: Colors.white,
              onSurface: pTextMain,
            ),
          ),
          child: child!,
        );
      },
    );

    if (date != null && mounted) {
      setState(() => _dateTransport = date);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: pBg,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTrajetSection(),
                  const SizedBox(height: 30),
                  _buildMarchandiseSection(),
                  const SizedBox(height: 30),
                  _buildAISection(),
                  const SizedBox(height: 30),
                  _buildDateSection(),
                  const SizedBox(height: 30),
                  _buildPhotoSection(),
                  const SizedBox(height: 100), // Espace pour le FAB
                ],
              ),
            ),
          )
        ],
      ),
      floatingActionButton: _buildSubmitFAB(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  // ==========================================
  // HEADER CARTE (OPENSTREETMAP)
  // ==========================================
  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 250.0,
      pinned: true,
      backgroundColor: pDarkBlue,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            FlutterMap(
              options: const MapOptions(
                initialCenter: LatLng(4.0511, 9.7679),
                initialZoom: 13,
                interactionOptions: InteractionOptions(flags: InteractiveFlag.none),
              ),
              children: [
                TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.joan.update_camtrans',
          ),
              ],
            ),
            // Glassmorphism Overlay
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [pDarkBlue.withOpacity(0.7), pDarkBlue.withOpacity(0.2), pBg],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 30,
              left: 20,
              child: const Text(
                "Nouvelle Expédition",
                style: TextStyle(color: pTextMain, fontSize: 28, fontWeight: FontWeight.bold),
              ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.5),
            )
          ],
        ),
      ),
    );
  }

  // ==========================================
  // SECTION TRAJET
  // ==========================================
  Widget _buildTrajetSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: pSurface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        children: [
          _buildAddressField("Point de départ", Iconsax.location_copy, _depart, isDest: false),
          Padding(
            padding: const EdgeInsets.only(left: 22),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(width: 2, height: 25, color: pBlue.withOpacity(0.3)),
            ),
          ),
          _buildAddressField("Destination", Iconsax.location_tick_copy, _destination, isDest: true),
        ],
      ),
    ).animate().fadeIn(delay: 300.ms).slideX(begin: 0.1);
  }

  Widget _buildAddressField(String hint, IconData icon, TextEditingController controller, {required bool isDest}) {
    return Focus(
      onFocusChange: (hasFocus) {
        if (!hasFocus) _simulerCalculIA();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
        decoration: BoxDecoration(
          color: pBg,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.transparent),
        ),
        child: Row(
          children: [
            Icon(icon, color: isDest ? pBlue : pDarkBlue, size: 22),
            const SizedBox(width: 15),
            Expanded(
              child: TextField(
                controller: controller,
                decoration: InputDecoration(
                  hintText: hint,
                  hintStyle: const TextStyle(color: pTextMuted, fontSize: 14),
                  border: InputBorder.none,
                ),
              ),
            ),
            if (!isDest)
              IconButton(
                icon: const Icon(Iconsax.gps_copy, color: pBlue, size: 20),
                onPressed: () {
                  controller.text = "Position Actuelle (Douala, Akwa)";
                  _simulerCalculIA();
                },
              )
          ],
        ),
      ),
    );
  }

  // ==========================================
  // SECTION MARCHANDISE
  // ==========================================
  Widget _buildMarchandiseSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Type de Colis", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: pTextMain)),
        const SizedBox(height: 15),
        Row(
          children: [
            _buildCategoryChip("Lourd", Iconsax.truck_fast_copy),
            const SizedBox(width: 15),
            _buildCategoryChip("Léger", Iconsax.box_copy),
          ],
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          decoration: BoxDecoration(color: pSurface, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 5))]),
          child: TextField(
            controller: _description,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: "Décrivez ce que vous transportez...",
              hintStyle: TextStyle(color: pTextMuted, fontSize: 14),
              border: InputBorder.none,
            ),
          ),
        ),
      ],
    ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1);
  }

  Widget _buildCategoryChip(String title, IconData icon) {
    bool isSelected = _categorie == title;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _categorie = title),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(vertical: 15),
          decoration: BoxDecoration(
            color: isSelected ? pBlue : pSurface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isSelected ? pBlue : pBg, width: 2),
            boxShadow: isSelected ? [BoxShadow(color: pBlue.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 5))] : [],
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? Colors.white : pDarkBlue, size: 28),
              const SizedBox(height: 8),
              Text(title, style: TextStyle(color: isSelected ? Colors.white : pTextMain, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // SECTION IA (ESTIMATION)
  // ==========================================
  Widget _buildAISection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [pDarkBlue, pDarkBlue.withOpacity(0.8)]),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: pDarkBlue.withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: _calculIA
          ? Column(
              children: [
                const Icon(Iconsax.magic_star_copy, color: Colors.white, size: 30).animate(onPlay: (c) => c.repeat()).shake(),
                const SizedBox(height: 15),
                const Text("L'IA analyse le meilleur trajet...", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                const SizedBox(height: 15),
                Container(height: 10, width: 150, decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(10)))
                    .animate(onPlay: (c) => c.repeat())
                    .shimmer(duration: 1.seconds, color: Colors.white),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Iconsax.magic_star_copy, color: pBlue),
                    const SizedBox(width: 10),
                    const Text("Estimation Intelligente", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildAIValue("Volume", "12 m³"),
                    _buildAIValue("Poids", "800 Kg"),
                    _buildAIValue("Recommandé", "Camion 10t"),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(15)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Prix Estimé", style: TextStyle(color: Colors.white, fontSize: 16)),
                      const Text("45 000 FCFA", style: TextStyle(color: pBlue, fontSize: 22, fontWeight: FontWeight.bold)),
                    ],
                  ),
                )
              ],
            ),
    ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.1);
  }

  Widget _buildAIValue(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12)),
        const SizedBox(height: 5),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
      ],
    );
  }

  // ==========================================
  // SECTION DATE & HEURE
  // ==========================================
  Widget _buildDateSection() {
    return GestureDetector(
      onTap: _choisirDate,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: pSurface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 5))],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: pBlue.withOpacity(0.1), borderRadius: BorderRadius.circular(15)),
              child: const Icon(Iconsax.calendar_1_copy, color: pBlue),
            ),
            const SizedBox(width: 15),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Date de Départ", style: TextStyle(color: pTextMuted, fontSize: 13)),
                const SizedBox(height: 5),
                Text(
                  _dateTransport == null ? "Dès que possible" : "${_dateTransport!.day}/${_dateTransport!.month}/${_dateTransport!.year}",
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: pTextMain),
                ),
              ],
            ),
            const Spacer(),
            const Icon(Icons.arrow_forward_ios, size: 15, color: pTextMuted),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.1);
  }

  // ==========================================
  // SECTION PHOTOS
  // ==========================================
  Widget _buildPhotoSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: pBlue.withOpacity(0.05),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          const Icon(Iconsax.camera_copy, size: 40, color: pBlue),
          const SizedBox(height: 10),
          const Text("Ajouter des photos du colis", style: TextStyle(color: pBlue, fontWeight: FontWeight.bold)),
          const SizedBox(height: 5),
          const Text("(Facultatif mais recommandé)", style: TextStyle(color: pTextMuted, fontSize: 12)),
        ],
      ),
    ).animate().fadeIn(delay: 700.ms).slideY(begin: 0.1);
  }

  // ==========================================
  // BOUTON ACTION (FAB)
  // ==========================================
  Widget _buildSubmitFAB() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SizedBox(
        width: double.infinity,
        height: 60,
        child: ElevatedButton(
          onPressed: () {
            if (_depart.text.isEmpty || _destination.text.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Veuillez remplir les adresses.")));
              return;
            }
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Recherche de camions en cours...")));
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: pBlue,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            elevation: 10,
            shadowColor: pBlue.withOpacity(0.5),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("Rechercher un transporteur", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              SizedBox(width: 10),
              Icon(Icons.arrow_forward, color: Colors.white),
            ],
          ),
        ),
      ).animate().scale(delay: 900.ms, curve: Curves.easeOutBack),
    );
  }
}