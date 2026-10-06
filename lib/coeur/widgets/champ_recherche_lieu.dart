import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:update_camtrans/coeur/constantes/couleurs.dart';
import 'package:update_camtrans/services/service_lieux.dart';

// =====================================================================
// CHAMP DE RECHERCHE DE LIEU PRÉDICTIF (style Yango)
//
// - Saisie → debounce 500 ms → appel ServiceLieux (Nominatim, Cameroun).
// - Résultats affichés sous le champ (icône de lieu + libellé).
// - États gérés : chargement, résultats, « aucun lieu trouvé ».
//
// Réutilisable pour le DÉPART et la DESTINATION. Au choix d'un lieu,
// `onLieuChoisi` reçoit le libellé ET les coordonnées (lat/lon).
// =====================================================================
class ChampRechercheLieu extends ConsumerStatefulWidget {
  final String hint;
  final String? valeurInitiale;
  final IconData iconePrefixe;
  final Color couleurIcone;

  /// Appelé à la sélection d'une suggestion (libellé + coordonnées).
  final void Function(LieuSuggestion lieu) onLieuChoisi;

  const ChampRechercheLieu({
    super.key,
    required this.hint,
    required this.onLieuChoisi,
    this.valeurInitiale,
    this.iconePrefixe = Icons.location_on,
    this.couleurIcone = CouleursApp.erreur,
  });

  @override
  ConsumerState<ChampRechercheLieu> createState() =>
      _ChampRechercheLieuState();
}

class _ChampRechercheLieuState extends ConsumerState<ChampRechercheLieu> {
  final TextEditingController _controleur = TextEditingController();
  final FocusNode _focus = FocusNode();
  Timer? _debounce;

  List<LieuSuggestion> _resultats = const [];
  bool _enChargement = false;
  bool _rechercheEffectuee = false; // pour n'afficher l'état vide qu'après coup
  bool _choixFait = false; // masque la liste une fois un lieu choisi

  @override
  void initState() {
    super.initState();
    if (widget.valeurInitiale != null && widget.valeurInitiale!.isNotEmpty) {
      _controleur.text = widget.valeurInitiale!;
      _choixFait = true;
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controleur.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _surSaisie(String valeur) {
    _choixFait = false;
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    final requete = valeur.trim();
    if (requete.length < 3) {
      setState(() {
        _resultats = const [];
        _enChargement = false;
        _rechercheEffectuee = false;
      });
      return;
    }

    setState(() => _enChargement = true);
    // Debounce 500 ms pour ne pas solliciter l'API à chaque lettre.
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      final lieux = await ref.read(serviceLieuxProvider).rechercher(requete);
      if (!mounted) return;
      setState(() {
        _resultats = lieux;
        _enChargement = false;
        _rechercheEffectuee = true;
      });
    });
  }

  void _choisir(LieuSuggestion lieu) {
    _controleur.text = lieu.libelle;
    _controleur.selection = TextSelection.fromPosition(
      TextPosition(offset: lieu.libelle.length),
    );
    widget.onLieuChoisi(lieu);
    setState(() {
      _choixFait = true;
      _resultats = const [];
      _rechercheEffectuee = false;
    });
    _focus.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _controleur,
          focusNode: _focus,
          style: TextStyle(color: scheme.onSurface),
          onChanged: _surSaisie,
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: TextStyle(color: scheme.onSurface.withValues(alpha: 0.5)),
            prefixIcon: Icon(widget.iconePrefixe, color: widget.couleurIcone),
            suffixIcon: _enChargement
                ? const Padding(
                    padding: EdgeInsets.all(14),
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : (_controleur.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.close,
                            color: scheme.onSurface.withValues(alpha: 0.5)),
                        onPressed: () {
                          _controleur.clear();
                          setState(() {
                            _resultats = const [];
                            _rechercheEffectuee = false;
                            _choixFait = false;
                          });
                        },
                      )
                    : null),
            filled: true,
            // Fond légèrement bleuté, dans l'esprit du design system.
            fillColor: CouleursApp.primaire.withValues(alpha: 0.06),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide:
                  BorderSide(color: CouleursApp.primaire.withValues(alpha: 0.5)),
            ),
          ),
        ),

        // ── Résultats / état vide ────────────────────────────────────
        if (!_choixFait && _resultats.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 6),
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: scheme.onSurface.withValues(alpha: 0.08)),
            ),
            constraints: const BoxConstraints(maxHeight: 240),
            child: ListView.separated(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              itemCount: _resultats.length,
              separatorBuilder: (_, __) => Divider(
                height: 1,
                color: scheme.onSurface.withValues(alpha: 0.06),
              ),
              itemBuilder: (context, index) {
                final lieu = _resultats[index];
                return ListTile(
                  dense: true,
                  leading: Icon(Icons.location_on,
                      color: scheme.onSurface.withValues(alpha: 0.45), size: 20),
                  title: Text(
                    lieu.libelle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: scheme.onSurface, fontSize: 14),
                  ),
                  onTap: () => _choisir(lieu),
                );
              },
            ),
          ),

        // État vide : recherche faite, rien trouvé.
        if (!_choixFait &&
            _rechercheEffectuee &&
            !_enChargement &&
            _resultats.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 10, left: 4),
            child: Row(
              children: [
                Icon(Icons.search_off,
                    size: 18, color: scheme.onSurface.withValues(alpha: 0.5)),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    "Aucun lieu trouvé au Cameroun. Vérifiez l'orthographe.",
                    style: TextStyle(
                        color: scheme.onSurface.withValues(alpha: 0.6),
                        fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
