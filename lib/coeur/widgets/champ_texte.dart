import 'package:flutter/material.dart';

import '../constantes/couleurs.dart';
import '../constantes/tailles.dart';

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
  });

  @override
  State<ChampTexte> createState() => _ChampTexteState();
}

class _ChampTexteState extends State<ChampTexte> {
  late bool masquerTexte;

  @override
  void initState() {
    super.initState();
    masquerTexte = widget.estMotDePasse;
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controleur,
      keyboardType: widget.typeClavier,
      obscureText: masquerTexte,
      enabled: widget.active,
      readOnly: widget.lectureSeule,
      maxLines: widget.estMotDePasse ? 1 : widget.lignesMax,
      validator: widget.validateur,
      onChanged: widget.lorsDuChangement,
      style: const TextStyle(
        fontSize: 16,
        color: CouleursApp.textePrincipal,
      ),
      decoration: InputDecoration(
        labelText: widget.libelle,
        hintText: widget.indice,

        prefixIcon: widget.icone != null
            ? Icon(
          widget.icone,
          color: CouleursApp.primaire,
        )
            : null,

        suffixIcon: widget.estMotDePasse
            ? IconButton(
          onPressed: () {
            setState(() {
              masquerTexte = !masquerTexte;
            });
          },
          icon: Icon(
            masquerTexte
                ? Icons.visibility_off
                : Icons.visibility,
          ),
        )
            : widget.suffixe,

        filled: true,
        fillColor: Colors.white,

        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 18,
        ),

        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            TaillesApp.rayonChamp,
          ),
          borderSide: const BorderSide(
            color: CouleursApp.bordure,
          ),
        ),

        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            TaillesApp.rayonChamp,
          ),
          borderSide: const BorderSide(
            color: CouleursApp.bordure,
          ),
        ),

        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            TaillesApp.rayonChamp,
          ),
          borderSide: const BorderSide(
            color: CouleursApp.primaire,
            width: 2,
          ),
        ),

        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            TaillesApp.rayonChamp,
          ),
          borderSide: const BorderSide(
            color: CouleursApp.erreur,
          ),
        ),

        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            TaillesApp.rayonChamp,
          ),
          borderSide: const BorderSide(
            color: CouleursApp.erreur,
            width: 2,
          ),
        ),
      ),
    );
  }
}