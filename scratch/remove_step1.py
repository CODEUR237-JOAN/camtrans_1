import re
import sys

file_path = r'lib\fonctionnalites\client\creer_demande.dart'
try:
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
except Exception as e:
    print(f"Error reading file: {e}")
    sys.exit(1)

# 1. Update the steps array in _buildProgressBar
content = re.sub(
    r'final steps = \["Service", "Détails", "Gamme", "Trajet", "Offre"\];',
    r'final steps = ["Détails", "Gamme", "Trajet", "Offre"];',
    content
)

# 2. Update the body stack: remove _buildEtape1Service, shift indices
body_stack_old = r"""                Expanded(
                  child: IndexedStack(
                    index: _etapeCourante - 1,
                    children: [
                      _buildEtape1Service(context, etat, notifier),
                      _buildEtape2Details(context, etat, notifier),
                      _buildEtape3Gamme(context, etat, notifier),
                      _buildEtape4Itineraire(context, etat, notifier),
                      if (_etapeCourante == 5) _buildEtape5Matching(context, etat),
                    ],
                  ),
                ),"""
body_stack_new = r"""                Expanded(
                  child: IndexedStack(
                    index: _etapeCourante - 1,
                    children: [
                      _buildEtape2Details(context, etat, notifier),
                      _buildEtape3Gamme(context, etat, notifier),
                      _buildEtape4Itineraire(context, etat, notifier),
                      if (_etapeCourante == 4) _buildEtape5Matching(context, etat),
                    ],
                  ),
                ),"""
content = content.replace(body_stack_old, body_stack_new)

# 3. Update CTA logic to check for step 4 instead of 5
content = re.sub(
    r'_etapeCourante < 4',
    r'_etapeCourante < 3',
    content
)
content = re.sub(
    r'_etapeCourante == 4 \? const SizedBox.shrink\(\)',
    r'_etapeCourante == 4 ? const SizedBox.shrink()',
    content
)

# Wait, inside _buildBottomCTA:
# Text( _etapeCourante < 3 ? "Continuer" : _etapeCourante == 3 ? "Rechercher un chauffeur" : "Valider la Commande"
# If max is 4, then:
# step 1, 2 (< 3): "Continuer"
# step 3 (== 3): "Rechercher un chauffeur"
# step 4 (== 4): hidden.
# So the text logic is fine as is!

# 4. Remove _buildEtape1Service definition
content = re.sub(
    r'// ==========================================\s*// ETAPE 1 : SERVICE\s*// ==========================================\s*Widget _buildEtape1Service.*?// ==========================================\s*// ETAPE 2 : DETAILS ET GAMME\s*// ==========================================',
    r'// ==========================================\n  // ETAPE 1 : DETAILS\n  // ==========================================',
    content,
    flags=re.DOTALL
)

# 5. Update _etapeSuivante errors
etape_suivante_old = r"""  void _etapeSuivante(EtatDemandeExpedition etat, DemandeExpeditionNotifier notifier) {
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

    if (_etapeCourante == 4) {"""

etape_suivante_new = r"""  void _etapeSuivante(EtatDemandeExpedition etat, DemandeExpeditionNotifier notifier) {
    if (!etat.estEtapeValide(_etapeCourante)) {
      String message = "Veuillez remplir les informations requises.";
      if (_etapeCourante == 1) {
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
      if (_etapeCourante == 2) message = "Veuillez choisir une gamme de service.";
      if (_etapeCourante == 3) message = "L'itinéraire est incomplet.";
      
      _montrerErreur(message);
      return;
    }

    if (_etapeCourante == 3) {"""

content = content.replace(etape_suivante_old, etape_suivante_new)


with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)

print("Patch applied to creer_demande.dart successfully")
