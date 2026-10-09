import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'package:update_camtrans/coeur/constantes/couleurs.dart';
import 'package:update_camtrans/coeur/constantes/tailles.dart';

/// =======================================================
/// SÉLECTEUR DE COMPTE GOOGLE (inscription)
/// Remplace la saisie libre de l'e-mail : l'adresse provient
/// obligatoirement d'un compte Google réel, vérifié par Google.
/// S'intègre au [Form] parent (validation incluse).
/// =======================================================
class SelecteurCompteGoogle extends StatelessWidget {
  final GoogleSignInAccount? compte;
  final bool chargement;
  final VoidCallback? auClic;

  const SelecteurCompteGoogle({
    super.key,
    required this.compte,
    required this.auClic,
    this.chargement = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return FormField<GoogleSignInAccount>(
      // La clé force la revalidation quand le compte change.
      key: ValueKey(compte?.email),
      initialValue: compte,
      validator: (_) => compte == null
          ? 'Sélectionnez votre compte Google (adresse vérifiée)'
          : null,
      builder: (etat) {
        final aErreur = etat.hasError;
        final couleurBord = aErreur
            ? CouleursApp.erreur
            : (compte != null ? CouleursApp.succes : CouleursApp.bordure);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Material(
              color: isDark ? const Color(0xFF252538) : CouleursApp.surface,
              borderRadius: BorderRadius.circular(TaillesApp.rayonChamp),
              child: InkWell(
                key: const Key('bouton_selection_compte_google'),
                borderRadius: BorderRadius.circular(TaillesApp.rayonChamp),
                onTap: chargement ? null : auClic,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(TaillesApp.rayonChamp),
                    border: Border.all(color: couleurBord, width: 1.2),
                  ),
                  child: Row(
                    children: [
                      _avatar(),
                      const SizedBox(width: 14),
                      Expanded(child: _textes(isDark)),
                      if (chargement)
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      else
                        Text(
                          compte == null ? 'Choisir' : 'Changer',
                          style: const TextStyle(
                            color: CouleursApp.primaire,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            if (aErreur)
              Padding(
                padding: const EdgeInsets.only(left: 16, top: 6),
                child: Text(
                  etat.errorText!,
                  style:
                      const TextStyle(color: CouleursApp.erreur, fontSize: 12),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _avatar() {
    final photo = compte?.photoUrl;
    if (photo != null && photo.isNotEmpty) {
      return CircleAvatar(radius: 18, backgroundImage: NetworkImage(photo));
    }
    return CircleAvatar(
      radius: 18,
      backgroundColor: CouleursApp.primaire.withValues(alpha: 0.1),
      child: const Text(
        'G',
        style: TextStyle(
          color: CouleursApp.primaire,
          fontWeight: FontWeight.w900,
          fontSize: 18,
        ),
      ),
    );
  }

  Widget _textes(bool isDark) {
    if (compte == null) {
      return const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Adresse e-mail (compte Google)',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          SizedBox(height: 2),
          Text(
            'Appuyez pour choisir votre compte Google',
            style: TextStyle(fontSize: 12, color: CouleursApp.texteSecondaire),
          ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          compte!.email,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
            color: isDark ? Colors.white : CouleursApp.textePrincipal,
          ),
        ),
        const SizedBox(height: 2),
        const Row(
          children: [
            Icon(Icons.verified, size: 14, color: CouleursApp.succes),
            SizedBox(width: 4),
            Text(
              'Vérifié par Google',
              style: TextStyle(fontSize: 12, color: CouleursApp.succes),
            ),
          ],
        ),
      ],
    );
  }
}
