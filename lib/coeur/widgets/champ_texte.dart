import 'package:flutter/material.dart';

import 'package:update_camtrans/coeur/constantes/couleurs.dart';
import 'package:update_camtrans/coeur/constantes/tailles.dart';
import 'package:flutter_animate/flutter_animate.dart';


/// =======================================================
/// CHAMP TEXTE MODERNISÉ
/// Avec animation au focus, icône animée, et style glassmorphism optionnel
/// =======================================================

class ChampTexte extends StatefulWidget {
  final TextEditingController? controleur;
  final String libelle;
  final String? indice;
  final IconData? icone;
  final Widget? suffixe;
  final TextInputType typeClavier;
  final bool estMotDePasse;
  final bool active;
  final bool lectureSeule;
  final int lignesMax;
  final String? Function(String?)? validateur;
  final ValueChanged<String>? lorsDuChangement;
  final bool glassmorphism;

  const ChampTexte({
    super.key,
    this.controleur,
    required this.libelle,
    this.indice,
    this.icone,
    this.suffixe,
    this.typeClavier = TextInputType.text,
    this.estMotDePasse = false,
    this.active = true,
    this.lectureSeule = false,
    this.lignesMax = 1,
    this.validateur,
    this.lorsDuChangement,
    this.glassmorphism = false,
  });

  @override
  State<ChampTexte> createState() => _ChampTexteState();
}

class _ChampTexteState extends State<ChampTexte>
    with SingleTickerProviderStateMixin {
  late bool masquerTexte;
  late AnimationController _focusController;
  late Animation<double> _iconAnimation;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    masquerTexte = widget.estMotDePasse;
    _focusController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _iconAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _focusController, curve: Curves.easeOutBack),
    );
  }

  @override
  void dispose() {
    _focusController.dispose();
    super.dispose();
  }

  void _onFocusChange(bool focused) {
    setState(() => _isFocused = focused);
    if (focused) {
      _focusController.forward();
    } else {
      _focusController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Focus(
      onFocusChange: _onFocusChange,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        decoration: widget.glassmorphism
            ? BoxDecoration(
                borderRadius: BorderRadius.circular(TaillesApp.rayonChamp),
                boxShadow: _isFocused
                    ? [
                        BoxShadow(
                          color: CouleursApp.primaire.withValues(alpha: 0.2),
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                      ]
                    : [],
              )
            : null,
        child: TextFormField(
          controller: widget.controleur,
          keyboardType: widget.typeClavier,
          obscureText: masquerTexte,
          enabled: widget.active,
          readOnly: widget.lectureSeule,
          maxLines: widget.estMotDePasse ? 1 : widget.lignesMax,
          validator: widget.validateur,
          onChanged: widget.lorsDuChangement,
          style: TextStyle(
            fontSize: 16,
            color: isDark ? Colors.white : CouleursApp.textePrincipal,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            labelText: widget.libelle,
            hintText: widget.indice,
            prefixIcon: widget.icone != null
                ? AnimatedBuilder(
                    animation: _iconAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _iconAnimation.value,
                        child: Icon(
                          widget.icone,
                          color: _isFocused
                              ? CouleursApp.primaire
                              : (isDark
                                  ? CouleursApp.texteTertiaire
                                  : CouleursApp.icone),
                          size: 22,
                        ),
                      );
                    },
                  )
                : null,
            suffixIcon: widget.estMotDePasse
                ? IconButton(
                    onPressed: () {
                      setState(() {
                        masquerTexte = !masquerTexte;
                      });
                    },
                    icon: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      transitionBuilder: (child, anim) {
                        return RotationTransition(
                          turns: Tween<double>(begin: 0.5, end: 1.0).animate(anim),
                          child: FadeTransition(
                            opacity: anim,
                            child: child,
                          ),
                        );
                      },
                      child: Icon(
                        masquerTexte ? Icons.visibility_off : Icons.visibility,
                        key: ValueKey<bool>(masquerTexte),
                        color: _isFocused
                            ? CouleursApp.primaire
                            : CouleursApp.texteTertiaire,
                        size: 22,
                      ),
                    ),
                  )
                : widget.suffixe,
            filled: true,
            fillColor: widget.glassmorphism
                ? (isDark
                    ? CouleursApp.glassNoir
                    : CouleursApp.glassBlanc)
                : (isDark
                    ? const Color(0xFF252538)
                    : CouleursApp.surface),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 18,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(TaillesApp.rayonChamp),
              borderSide: BorderSide(
                color: widget.glassmorphism
                    ? (isDark
                        ? CouleursApp.glassNoirBorder
                        : CouleursApp.glassBlancBorder)
                    : CouleursApp.bordure,
                width: 1.2,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(TaillesApp.rayonChamp),
              borderSide: BorderSide(
                color: widget.glassmorphism
                    ? (isDark
                        ? CouleursApp.glassNoirBorder
                        : CouleursApp.glassBlancBorder)
                    : CouleursApp.bordure,
                width: 1.2,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(TaillesApp.rayonChamp),
              borderSide: const BorderSide(
                color: CouleursApp.primaire,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(TaillesApp.rayonChamp),
              borderSide: const BorderSide(
                color: CouleursApp.erreur,
                width: 1,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(TaillesApp.rayonChamp),
              borderSide: const BorderSide(
                color: CouleursApp.erreur,
                width: 2,
              ),
            ),
            labelStyle: TextStyle(
              fontSize: 14,
              color: _isFocused
                  ? CouleursApp.primaire
                  : (isDark
                      ? CouleursApp.texteTertiaire
                      : CouleursApp.texteSecondaire),
              fontWeight: _isFocused ? FontWeight.w600 : FontWeight.w500,
            ),
            hintStyle: TextStyle(
              fontSize: 14,
              color: isDark
                  ? const Color(0xFF6B6B8C)
                  : CouleursApp.texteTertiaire,
            ),
          ),
        ).animate(
          target: _isFocused ? 1 : 0,
        ).scale(
          begin: const Offset(1.0, 1.0),
          end: const Offset(1.01, 1.01),
          duration: const Duration(milliseconds: 200),
        ),
      ),
    );
  }
}
