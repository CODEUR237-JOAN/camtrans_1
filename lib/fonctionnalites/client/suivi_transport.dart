import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

// ==========================================
// PALETTE PREMIUM (YANGO/UBER EATS STYLE)
// ==========================================
const Color pBlue = Color(0xFF2697FF);
const Color pDarkBlue = Color(0xFF1E3A8A);
const Color pSurface = Colors.white;
const Color pSuccess = Color(0xFF16A34A);
const Color pWarning = Color(0xFFF59E0B);
const Color pError = Color(0xFFDC2626);
const Color pTextMain = Color(0xFF1E293B);
const Color pTextMuted = Color(0xFF64748B);
const Color pBg = Color(0xFFF4F7FB);

class SuiviTransport extends StatefulWidget {
  const SuiviTransport({super.key});

  @override
  State<SuiviTransport> createState() => _SuiviTransportState();
}

class _SuiviTransportState extends State<SuiviTransport> with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  
  // Coordonnées de test (Douala)
  final LatLng _clientPos = const LatLng(4.0411, 9.7579);
  late LatLng _truckPos;
  
  // Tracé simulé
  final List<LatLng> _routePoints = [
    const LatLng(4.0611, 9.7779),
    const LatLng(4.0550, 9.7650),
    const LatLng(4.0411, 9.7579),
  ];

  late AnimationController _truckAnimController;

  @override
  void initState() {
    super.initState();
    _truckPos = _routePoints.first;

    // Simulation de mouvement du camion pour la démo
    _truckAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..addListener(() {
        setState(() {
          // Interpolation simplifiée entre le premier et le dernier point
          double t = _truckAnimController.value;
          double lat = _routePoints.first.latitude + (_routePoints.last.latitude - _routePoints.first.latitude) * t;
          double lng = _routePoints.first.longitude + (_routePoints.last.longitude - _routePoints.first.longitude) * t;
          _truckPos = LatLng(lat, lng);
        });
      });
      
    // Démarrer l'animation après 1 seconde
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) _truckAnimController.forward();
    });
  }

  @override
  void dispose() {
    _truckAnimController.dispose();
    super.dispose();
  }

  void _recentrerCarte() {
    _mapController.move(_truckPos, 14.5);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. CARTE PLEIN ÉCRAN
          _buildMap(),

          // 2. BOUTON RETOUR (En haut à gauche)
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 20,
            child: _buildBackButton(),
          ),

          // 3. BOUTON RECENTRER (Au-dessus du BottomSheet)
          Positioned(
            right: 20,
            bottom: MediaQuery.of(context).size.height * 0.45,
            child: _buildLocationButton(),
          ),

          // 4. BOTTOM SHEET (Infos, Chauffeur, Timeline)
          _buildDraggableBottomSheet(),
        ],
      ),
    );
  }

  // ==========================================
  // CARTE & MARQUEURS
  // ==========================================
  Widget _buildMap() {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: const LatLng(4.0511, 9.7679),
        initialZoom: 13.5,
        interactionOptions: const InteractionOptions(flags: InteractiveFlag.all),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.joan.update_camtrans',
          maxZoom: 19,
        ),
        PolylineLayer(
          polylines: [
            Polyline<Object>(
              points: _routePoints,
              color: pBlue,
              strokeWidth: 4.0,
            ),
          ],
        ),
        MarkerLayer(
          markers: [
            // Marqueur Client (Maison)
            Marker(
              point: _clientPos,
              width: 60,
              height: 60,
              child: _buildMarker(Iconsax.home_copy, pError),
            ),
            // Marqueur Transporteur (Camion Animé)
            Marker(
              point: _truckPos,
              width: 80,
              height: 80,
              child: _buildTruckMarker(),
            ),
          ],
        ),
      ],
    ).animate().fadeIn(duration: 800.ms);
  }

  Widget _buildMarker(IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: color.withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 5))],
            border: Border.all(color: Colors.white, width: 2),
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(begin: const Offset(1, 1), end: const Offset(1.1, 1.1), duration: 1.seconds),
        Container(
          width: 2,
          height: 10,
          color: color,
        ),
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        )
      ],
    );
  }

  Widget _buildTruckMarker() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Effet Radar (Ripple)
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: pBlue.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
        ).animate(onPlay: (c) => c.repeat()).scale(begin: const Offset(0.5, 0.5), end: const Offset(1.5, 1.5), duration: 1.5.seconds).fadeOut(),
        // Icône Camion
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: pSurface,
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)],
          ),
          child: const Icon(Iconsax.truck_fast_copy, color: pBlue, size: 24),
        ),
      ],
    );
  }

  // ==========================================
  // BOUTONS FLOTTANTS (UI)
  // ==========================================
  Widget _buildBackButton() {
    return FloatingActionButton.small(
      heroTag: "btn_back",
      backgroundColor: pSurface,
      onPressed: () => Navigator.pop(context),
      child: const Icon(Icons.arrow_back_ios_new, color: pTextMain, size: 18),
    ).animate().slideX(begin: -1, delay: 200.ms);
  }

  Widget _buildLocationButton() {
    return FloatingActionButton(
      heroTag: "btn_loc",
      backgroundColor: pSurface,
      onPressed: _recentrerCarte,
      child: const Icon(Iconsax.gps_copy, color: pBlue),
    ).animate().scale(delay: 400.ms);
  }

  // ==========================================
  // BOTTOM SHEET (Panneau d'information)
  // ==========================================
  Widget _buildDraggableBottomSheet() {
    return DraggableScrollableSheet(
      initialChildSize: 0.40,
      minChildSize: 0.15,
      maxChildSize: 0.85,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.95),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, -5))],
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: ListView(
                controller: scrollController,
                padding: EdgeInsets.zero,
                physics: const BouncingScrollPhysics(),
                children: [
                  const SizedBox(height: 12),
                  // Petite poignée (Drag handle)
                  Center(child: Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)))),
                  const SizedBox(height: 20),
                  
                  // ETA & Status
                  _buildETAHeader(),
                  const Padding(padding: EdgeInsets.symmetric(horizontal: 20), child: Divider(height: 30, color: pBg)),
                  
                  // Timeline Livraison
                  _buildDeliveryTimeline(),
                  const Padding(padding: EdgeInsets.symmetric(horizontal: 20), child: Divider(height: 30, color: pBg)),
                  
                  // Profil Chauffeur
                  _buildDriverProfile(),
                  const SizedBox(height: 20),
                  
                  // Boutons d'Action Rapide
                  _buildQuickActions(),
                  const SizedBox(height: 30),
                  
                  // Détails Véhicule & Plaque
                  _buildVehicleDetails(),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ).animate().slideY(begin: 1, duration: 600.ms, curve: Curves.easeOutCubic);
      },
    );
  }

  // ==========================================
  // COMPOSANTS DU BOTTOM SHEET
  // ==========================================
  Widget _buildETAHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Arrivée estimée", style: TextStyle(color: pTextMuted, fontSize: 14, fontWeight: FontWeight.w600)),
              Row(
                children: [
                  const Text("15 min", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: pTextMain)),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: pSuccess.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                    child: const Text("À l'heure", style: TextStyle(color: pSuccess, fontSize: 12, fontWeight: FontWeight.bold)),
                  )
                ],
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text("Distance", style: TextStyle(color: pTextMuted, fontSize: 14)),
              const Text("4.2 km", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: pTextMain)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildDeliveryTimeline() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          _buildTimelineItem("Commande acceptée", "14:30", true, isFirst: true),
          _buildTimelineItem("Camion en route", "14:35", true, isCurrent: true),
          _buildTimelineItem("Arrivée au point de départ", "--:--", false),
          _buildTimelineItem("Marchandise livrée", "--:--", false, isLast: true),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(String title, String time, bool isDone, {bool isCurrent = false, bool isFirst = false, bool isLast = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: isDone ? pBlue : pBg,
                shape: BoxShape.circle,
                border: isCurrent ? Border.all(color: pBlue.withOpacity(0.3), width: 4) : Border.all(color: isDone ? pBlue : Colors.grey.shade300, width: 2),
              ),
              child: isDone && !isCurrent ? const Icon(Icons.check, size: 10, color: Colors.white) : null,
            ),
            if (!isLast) Container(width: 2, height: 30, color: isDone ? pBlue : pBg),
          ],
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontSize: 15, fontWeight: isCurrent ? FontWeight.bold : FontWeight.w600, color: isDone ? pTextMain : pTextMuted)),
              if (!isLast) const SizedBox(height: 20),
            ],
          ),
        ),
        Text(time, style: TextStyle(fontSize: 13, color: isDone ? pTextMain : pTextMuted, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildDriverProfile() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: pBlue, width: 2),
            ),
            child: const CircleAvatar(
              radius: 28,
              backgroundColor: pBg,
              child: Icon(Iconsax.user_copy, color: pTextMuted),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Samuel Eto'o", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: pTextMain)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.star, color: pWarning, size: 16),
                    const SizedBox(width: 4),
                    const Text("4.9", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(width: 8),
                    Text("(124 courses)", style: TextStyle(color: pTextMuted, fontSize: 13)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildActionButton("Appeler", Iconsax.call_copy, pSuccess, true),
          const SizedBox(width: 15),
          _buildActionButton("Message", Iconsax.message_copy, pBlue, false),
          const SizedBox(width: 15),
          _buildActionButton("Urgence", Iconsax.warning_2_copy, pError, false),
        ],
      ),
    );
  }

  Widget _buildActionButton(String label, IconData icon, Color color, bool isPrimary) {
    return Expanded(
      child: InkWell(
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("$label en cours...")));
        },
        borderRadius: BorderRadius.circular(15),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isPrimary ? color : color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Column(
            children: [
              Icon(icon, color: isPrimary ? Colors.white : color, size: 24),
              const SizedBox(height: 5),
              Text(label, style: TextStyle(color: isPrimary ? Colors.white : color, fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVehicleDetails() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: pBg,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Iconsax.truck_fast_copy, color: pDarkBlue, size: 28),
              const SizedBox(width: 15),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Camion Lourd 10t", style: TextStyle(fontWeight: FontWeight.bold, color: pTextMain)),
                  const Text("Mercedes-Benz Actros", style: TextStyle(color: pTextMuted, fontSize: 12)),
                ],
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(5),
              border: Border.all(color: Colors.grey.shade400, width: 2),
            ),
            child: const Text("LT 456 AB", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
          )
        ],
      ),
    );
  }
}