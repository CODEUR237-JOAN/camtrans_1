import re
import sys

def patch_file(filepath):
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.read()

        # Find the line with estEnLigne: map["estEnLigne"] ?? false,
        
        replacement_logic = """
      // LOGIQUE DE PRESENCE : Si pas de signal depuis 5 minutes, on force a hors ligne
      estEnLigne: (map["estEnLigne"] ?? false) && 
                  (map["derniereConnexion"] != null && 
                   DateTime.now().difference(Parseur.toDateTime(map["derniereConnexion"])).inMinutes <= 5),
"""

        if 'estEnLigne: map["estEnLigne"] ?? false' in content:
            content = content.replace(
                'estEnLigne: map["estEnLigne"] ?? false,', 
                replacement_logic
            )
            with open(filepath, 'w', encoding='utf-8') as f:
                f.write(content)
            print(f"Patched {filepath}")
        else:
            print(f"Could not find exact estEnLigne match in {filepath}")
            
    except Exception as e:
        print(f"Error processing {filepath}: {e}")

files_to_patch = [
    r'lib\modeles\utilisateur.dart',
    r'lib\modeles\transporteur.dart',
    r'lib\modeles\client.dart',
]

for f in files_to_patch:
    patch_file(f)
