import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:latlong2/latlong.dart';

import 'package:update_camtrans/coeur/constantes/couleurs.dart';
import 'package:update_camtrans/coeur/constantes/tailles.dart';
import 'package:update_camtrans/coeur/widgets/marqueur_premium.dart';
import 'package:update_camtrans/modeles/course.dart';

/// Fiche détaillée d'une course proposée sur le marché.
///
/// Permet au transporteur de tout voir (trajet, marchandise, photos, prix)
/// avant de s'engager. L'acceptation elle-même est déléguée à [onAccepter]
/// (transaction atomique gérée par l'écran appelant).
class DetailsCourse extends StatelessWidget {
  const DetailsCourse({
    super.key,
    required this.course,
    this.onAccepter,
  });

  final Course course;

  /// Appelé quand le transporteur choisit d'accepter. `null` = lecture seule.
  final VoidCallback? onAccepter;


  bool get _aCoordonnees =>
      course.latitudeDepart != 0 &&
      course.longitudeDepart != 0 &&
      course.latitudeArrivee != 0 &&
      course.longitudeArrivee != 0;

  /// Prénom uniquement : le client reste discret tant que rien n'est conclu.
  String get _prenomClient {
    final nom = course.nomClient.trim();
    if (nom.isEmpty || nom == 'Client Anonyme') return 'Un client';
    return nom.split(' ').first;
  }

  String get _prixFormate {
    final montant = course.prixEstime.toInt().toString().replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]} ');
    return '$montant FCFA';
  }

  String get _consignes {
    if (course.detailsSpecifiques.isNotEmpty) return course.detailsSpecifiques;
    return course.description;
  }

  @override
  Widget build(BuildContext context) {
    final fond = Theme.of(context).scaffoldBackgroundColor;
    return Scaffold(
      backgroundColor: fond,
      appBar: AppBar(
        backgroundColor: fond,
        title: Text(
          "Détails de la course",
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(TaillesApp.margePage),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCarte(context),
            const SizedBox(height: 24),
            _buildPrix(context),
            const SizedBox(height: 24),
            const _TitreSection("Le trajet"),
            _buildTrajet(context),
            const SizedBox(height: 24),
            const _TitreSection("Le client"),
            _buildClient(context),
            const SizedBox(height: 24),
            const _TitreSection("La marchandise"),
            _buildMarchandise(context),
            if (_consignes.isNotEmpty) ...[
              const SizedBox(height: 24),
              const _TitreSection("Ce que précise le client"),
              _Bloc(
                child: Text(
                  _consignes,
                  style: GoogleFonts.inter(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7), fontSize: 14, height: 1.5),
                ),
              ),
            ],
            if (course.photos.isNotEmpty) ...[
              const SizedBox(height: 24),
              _TitreSection("Photos (${course.photos.length})"),
              _buildPhotos(),
            ],
            const SizedBox(height: 32),
            _buildActions(context),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ─── Carte du trajet ────────────────────────────────────────────────
  Widget _buildCarte(BuildContext context) {
    if (!_aCoordonnees) {
      return _Bloc(
        child: Row(
          children: [
            Icon(Iconsax.map_copy, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                "La carte n'est pas disponible pour ce trajet, "
                "mais les adresses sont indiquées ci-dessous.",
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54)),
              ),
            ),
          ],
        ),
      );
    }

    final depart = LatLng(course.latitudeDepart, course.longitudeDepart);
    final arrivee = LatLng(course.latitudeArrivee, course.longitudeArrivee);

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: SizedBox(
        height: 220,
        child: FlutterMap(
          options: MapOptions(
            initialCameraFit: CameraFit.bounds(
              bounds: LatLngBounds(depart, arrivee),
              padding: const EdgeInsets.all(48),
            ),
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
            ),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.joan.update_camtrans',
            ),
            MarkerLayer(
              markers: [
                Marker(
                  point: depart,
                  child: const MarqueurPremium(type: TypeMarqueur.depart),
                ),
                Marker(
                  point: arrivee,
                  child: const MarqueurPremium(type: TypeMarqueur.arrivee),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─── Prix ───────────────────────────────────────────────────────────
  Widget _buildPrix(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            CouleursApp.succes.withValues(alpha: 0.18),
            CouleursApp.succes.withValues(alpha: 0.06),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: CouleursApp.succes.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Vous gagnerez",
            style: GoogleFonts.inter(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6), fontSize: 13),
          ),
          const SizedBox(height: 4),
          Text(
            _prixFormate,
            style: GoogleFonts.poppins(
              color: CouleursApp.succes,
              fontSize: 30,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Prix fixé à l'avance, sans négociation.",
            style: GoogleFonts.inter(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38), fontSize: 12),
          ),
        ],
      ),
    );
  }

  // ─── Trajet ─────────────────────────────────────────────────────────
  Widget _buildTrajet(BuildContext context) {
    return _Bloc(
      child: Column(
        children: [
          _Ligne(
            icone: Icons.trip_origin_rounded,
            couleur: CouleursApp.primaire,
            titre: "Départ",
            valeur: course.adresseDepart.isNotEmpty
                ? course.adresseDepart
                : "Adresse non précisée",
          ),
          const _Separateur(),
          _Ligne(
            icone: Icons.flag_rounded,
            couleur: CouleursApp.succes,
            titre: "Arrivée",
            valeur: course.adresseArrivee.isNotEmpty
                ? course.adresseArrivee
                : "Adresse non précisée",
          ),
          if (course.distanceKm > 0) ...[
            const _Separateur(),
            _Ligne(
              icone: Icons.route_rounded,
              couleur: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54),
              titre: "Distance",
              valeur: "${course.distanceKm.toStringAsFixed(1)} km",
            ),
          ],
          if (course.etaMinutes > 0) ...[
            const _Separateur(),
            _Ligne(
              icone: Icons.timer_outlined,
              couleur: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54),
              titre: "Durée estimée",
              valeur: "environ ${course.etaMinutes} min",
            ),
          ],
        ],
      ),
    );
  }

  // ─── Client ─────────────────────────────────────────────────────────
  Widget _buildClient(BuildContext context) {
    return _Bloc(
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: CouleursApp.primaire.withValues(alpha: 0.15),
            child: const Icon(Iconsax.user_copy, color: CouleursApp.primaire),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _prenomClient,
                  style: GoogleFonts.poppins(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "Son numéro s'affichera dès que vous aurez accepté la course.",
                  style: GoogleFonts.inter(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54), fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Marchandise ────────────────────────────────────────────────────
  Widget _buildMarchandise(BuildContext context) {
    final service = [
      if (course.categorieService.isNotEmpty) course.categorieService,
      if (course.optionGamme.isNotEmpty) "Gamme ${course.optionGamme}",
    ].join(' · ');

    return _Bloc(
      child: Column(
        children: [
          _Ligne(
            icone: Iconsax.box_copy,
            couleur: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54),
            titre: "Type",
            valeur: course.typeMarchandise.isNotEmpty
                ? course.typeMarchandise
                : "Non précisé",
          ),
          if (service.isNotEmpty) ...[
            const _Separateur(),
            _Ligne(
              icone: Iconsax.category_copy,
              couleur: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54),
              titre: "Service",
              valeur: service,
            ),
          ],
          if (course.typeVehicule.isNotEmpty) ...[
            const _Separateur(),
            _Ligne(
              icone: Iconsax.truck_copy,
              couleur: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54),
              titre: "Véhicule demandé",
              valeur: course.typeVehicule,
            ),
          ],
          if (course.poidsKg > 0) ...[
            const _Separateur(),
            _Ligne(
              icone: Icons.scale_rounded,
              couleur: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54),
              titre: "Poids",
              valeur: "${course.poidsKg.toStringAsFixed(0)} kg",
            ),
          ],
          if (course.volumeM3 > 0) ...[
            const _Separateur(),
            _Ligne(
              icone: Icons.view_in_ar_rounded,
              couleur: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54),
              titre: "Volume",
              valeur: "${course.volumeM3.toStringAsFixed(1)} m³",
            ),
          ],
          if (course.fragile || course.aideChargement || course.aideDechargement)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (course.fragile)
                    const _Pastille("Fragile, à manipuler avec soin",
                        CouleursApp.avertissement),
                  if (course.aideChargement)
                    const _Pastille("Aide au chargement", CouleursApp.primaire),
                  if (course.aideDechargement)
                    const _Pastille("Aide au déchargement", CouleursApp.primaire),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ─── Photos ─────────────────────────────────────────────────────────
  Widget _buildPhotos() {
    return SizedBox(
      height: 110,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: course.photos.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.network(
              course.photos[index],
              width: 120,
              height: 110,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, progression) {
                if (progression == null) return child;
                return const _VignetteVide(
                  child: CircularProgressIndicator(strokeWidth: 2),
                );
              },
              errorBuilder: (context, error, stack) => _VignetteVide(
                child: Icon(Icons.broken_image_outlined,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38), size: 32),
              ),
            ),
          );
        },
      ),
    );
  }

  // ─── Actions ────────────────────────────────────────────────────────
  Widget _buildActions(BuildContext context) {
    final accepter = onAccepter;
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(54),
              side: BorderSide(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.24)),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              accepter == null ? "Retour" : "Pas cette fois",
              style: GoogleFonts.inter(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)),
            ),
          ),
        ),
        if (accepter != null) ...[
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: CouleursApp.primaire,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(54),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () {
                // On revient au marché, qui gère la confirmation et
                // l'attribution atomique de la course.
                Navigator.of(context).pop();
                accepter();
              },
              icon: const Icon(Icons.check_circle_outline),
              label: Text(
                "Je prends cette course",
                style: GoogleFonts.inter(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// ─── Petits composants réutilisables ──────────────────────────────────

class _TitreSection extends StatelessWidget {
  const _TitreSection(this.texte);
  final String texte;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        texte,
        style: GoogleFonts.poppins(
          color: Theme.of(context).colorScheme.onSurface,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _Bloc extends StatelessWidget {
  const _Bloc({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.06)),
      ),
      child: child,
    );
  }
}

class _Ligne extends StatelessWidget {
  const _Ligne({
    required this.icone,
    required this.couleur,
    required this.titre,
    required this.valeur,
  });

  final IconData icone;
  final Color couleur;
  final String titre;
  final String valeur;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icone, color: couleur, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(titre,
                  style:
                      GoogleFonts.inter(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54), fontSize: 12)),
              const SizedBox(height: 2),
              Text(
                valeur,
                style: GoogleFonts.inter(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Separateur extends StatelessWidget {
  const _Separateur();

  @override
  Widget build(BuildContext context) {
    return Divider(height: 24, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.06));
  }
}

class _Pastille extends StatelessWidget {
  const _Pastille(this.texte, this.couleur);
  final String texte;
  final Color couleur;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: couleur.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: couleur.withValues(alpha: 0.35)),
      ),
      child: Text(
        texte,
        style: GoogleFonts.inter(
            color: couleur, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _VignetteVide extends StatelessWidget {
  const _VignetteVide({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      height: 110,
      color: const Color(0xFF1A2640),
      alignment: Alignment.center,
      child: child,
    );
  }
}
