import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:intl/intl.dart';

import '../../coeur/etat/demande_expedition_provider.dart';
import '../../coeur/constantes/couleurs.dart';
import 'widgets/resume_expedition_bottom_sheet.dart';

class CreerDemande extends ConsumerWidget {
  const CreerDemande({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final etat = ref.watch(demandeExpeditionProvider);
    final notifier = ref.read(demandeExpeditionProvider.notifier);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: const Text(
          "Nouvelle Expédition",
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle("1. Trajet"),
            _buildTrajetCard(context, etat, notifier),
            
            const SizedBox(height: 24),
            _buildSectionTitle("2. Marchandise & Véhicule"),
            _buildMarchandiseVehiculeCard(context, etat, notifier),
            
            const SizedBox(height: 24),
            _buildSectionTitle("3. Planification"),
            _buildPlanificationCard(context, etat, notifier),

            const SizedBox(height: 24),
            _buildSectionTitle("4. Détails Supplémentaires"),
            _buildDetailsCard(context, etat, notifier),
            
            const SizedBox(height: 100),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: _buildSubmitButton(context, etat),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
      ),
    ).animate().fadeIn(delay: 100.ms).slideX(begin: -0.1);
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildTrajetCard(BuildContext context, EtatDemandeExpedition etat, DemandeExpeditionNotifier notifier) {
    return _buildCard(
      child: Column(
        children: [
          _buildTextField(
            hint: "Point de départ (ex: Douala, Akwa)",
            icon: Iconsax.location_copy,
            iconColor: Colors.black54,
            initialValue: etat.depart,
            onChanged: notifier.setDepart,
          ),
          Padding(
            padding: const EdgeInsets.only(left: 22, top: 4, bottom: 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(width: 2, height: 20, color: Colors.grey.withValues(alpha: 0.3)),
            ),
          ),
          _buildTextField(
            hint: "Destination (ex: Yaoundé, Bastos)",
            icon: Iconsax.location_tick_copy,
            iconColor: CouleursApp.primaire,
            initialValue: etat.destination,
            onChanged: notifier.setDestination,
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1);
  }

  Widget _buildMarchandiseVehiculeCard(BuildContext context, EtatDemandeExpedition etat, DemandeExpeditionNotifier notifier) {
    final marchandises = ["Colis standard", "Matériaux", "Électroménager", "Déménagement", "Autre"];
    final vehicules = [
      {"nom": "Moto", "icon": Icons.motorcycle},
      {"nom": "Voiture", "icon": Icons.directions_car},
      {"nom": "Camionnette", "icon": Icons.airport_shuttle},
      {"nom": "Camion léger", "icon": Icons.local_shipping},
      {"nom": "Camion lourd", "icon": Icons.fire_truck},
    ];

    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Type de marchandise", style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black87)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: marchandises.map((m) {
              final isSelected = etat.typeMarchandise == m;
              return ChoiceChip(
                label: Text(m),
                selected: isSelected,
                onSelected: (val) => notifier.setTypeMarchandise(val ? m : ""),
                selectedColor: Colors.black87,
                labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black87),
                backgroundColor: Colors.grey.shade100,
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          const Text("Catégorie de véhicule", style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black87)),
          const SizedBox(height: 12),
          SizedBox(
            height: 90,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: vehicules.length,
              itemBuilder: (context, index) {
                final v = vehicules[index];
                final isSelected = etat.categorieVehicule == v["nom"];
                return GestureDetector(
                  onTap: () => notifier.setCategorieVehicule(v["nom"] as String),
                  child: Container(
                    width: 90,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.black87 : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isSelected ? Colors.black : Colors.transparent),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(v["icon"] as IconData, color: isSelected ? Colors.white : Colors.black54, size: 28),
                        const SizedBox(height: 8),
                        Text(
                          v["nom"] as String,
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : Colors.black87, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          )
        ],
      ),
    ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1);
  }

  Widget _buildPlanificationCard(BuildContext context, EtatDemandeExpedition etat, DemandeExpeditionNotifier notifier) {
    return _buildCard(
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime.now(),
                  lastDate: DateTime(2035),
                );
                if (date != null) notifier.setDateTransport(date);
              },
              child: _buildDateTimePickerBox(
                icon: Iconsax.calendar_1_copy,
                label: "Date",
                value: etat.dateTransport != null ? DateFormat('dd/MM/yyyy').format(etat.dateTransport!) : "Sélectionner",
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: GestureDetector(
              onTap: () async {
                final time = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.now(),
                );
                if (time != null) notifier.setHeureTransport(time);
              },
              child: _buildDateTimePickerBox(
                icon: Iconsax.clock_copy,
                label: "Heure",
                value: etat.heureTransport != null ? etat.heureTransport!.format(context) : "Sélectionner",
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1);
  }

  Widget _buildDateTimePickerBox({required IconData icon, required String label, required String value}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.black54, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 12, color: Colors.black54)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsCard(BuildContext context, EtatDemandeExpedition etat, DemandeExpeditionNotifier notifier) {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            initialValue: etat.description,
            onChanged: notifier.setDescription,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: "Instructions spécifiques, informations sur le lieu...",
              hintStyle: const TextStyle(fontSize: 14, color: Colors.black38),
              filled: true,
              fillColor: Colors.grey.shade100,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 16),
          const Text("Photos de la marchandise", style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black87)),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => notifier.ajouterPhotos(),
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
                    ),
                    child: const Icon(Icons.add_a_photo, color: Colors.black54),
                  ),
                ),
                const SizedBox(width: 12),
                ...List.generate(etat.photos.length, (index) {
                  return Stack(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          image: DecorationImage(
                            image: FileImage(File(etat.photos[index].path)),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 16,
                        child: GestureDetector(
                          onTap: () => notifier.supprimerPhoto(index),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                            child: const Icon(Icons.close, color: Colors.white, size: 14),
                          ),
                        ),
                      ),
                    ],
                  );
                }),
              ],
            ),
          )
        ],
      ),
    ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.1);
  }

  Widget _buildTextField({required String hint, required IconData icon, required Color iconColor, required String initialValue, required Function(String) onChanged}) {
    return TextFormField(
      initialValue: initialValue,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 14, color: Colors.black38),
        prefixIcon: Icon(icon, color: iconColor, size: 20),
        filled: true,
        fillColor: Colors.grey.shade100,
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
    );
  }

  Widget _buildSubmitButton(BuildContext context, EtatDemandeExpedition etat) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -4))],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: 55,
          child: ElevatedButton(
            onPressed: etat.estValide
                ? () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) => const ResumeExpeditionBottomSheet(),
                    );
                  }
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black87,
              disabledBackgroundColor: Colors.grey.shade300,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text("Continuer", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ),
      ),
    ).animate().slideY(begin: 1.0, delay: 600.ms, duration: 400.ms, curve: Curves.easeOutBack);
  }
}