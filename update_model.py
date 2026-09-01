import re

with open('lib/modeles/transporteur.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Add field
content = content.replace('final String gamme;', 'final String gamme;\n  final bool gammeValidee;')

# Add to constructor
content = content.replace('this.gamme = "Éco",', 'this.gamme = "Éco",\n      this.gammeValidee = true,')

# Add to copyWith signature
content = content.replace('String? gamme,', 'String? gamme,\n      bool? gammeValidee,')

# Add to copyWith implementation
content = content.replace('gamme: gamme ?? this.gamme,', 'gamme: gamme ?? this.gamme,\n        gammeValidee: gammeValidee ?? this.gammeValidee,')

# Add to toMap
content = content.replace('"gamme": gamme,', '"gamme": gamme,\n        "gammeValidee": gammeValidee,')

# Add to fromMap
content = content.replace('gamme: map["gamme"] ?? "Éco",', 'gamme: map["gamme"] ?? "Éco",\n        gammeValidee: map["gammeValidee"] ?? true,')

# traiterSignalementClient logic
sig_logic = '''    if (nouveauxSignalements >= 2 && nouvelleGamme == "Confort") {
      nouvelleGamme = "Éco"; // Rétrogradation automatique
    }
    
    return copyWith(
      signalementsEtatVehicule: nouveauxSignalements,
      gamme: nouvelleGamme,
      gammeValidee: nouvelleGamme == "Confort" ? gammeValidee : true,
    );'''
content = re.sub(r'    if \(nouveauxSignalements >= 2 && nouvelleGamme == "Confort"\) \{[\s\S]*?\);', sig_logic, content)

with open('lib/modeles/transporteur.dart', 'w', encoding='utf-8') as f:
    f.write(content)
