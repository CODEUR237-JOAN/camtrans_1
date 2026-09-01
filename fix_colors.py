import re
import os

FILES_TO_PATCH = [
    'lib/fonctionnalites/client/profil.dart',
    'lib/fonctionnalites/client/historique.dart',
    'lib/fonctionnalites/client/ecran_chat.dart',
    'lib/fonctionnalites/client/adresses_favorites.dart',
    'lib/fonctionnalites/client/suivi_transport.dart',
    'lib/fonctionnalites/client/facture.dart'
]

def patch_file(path):
    if not os.path.exists(path):
        return

    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()

    # Fix invalid shade properties on Colors.white54
    content = re.sub(r'Colors\.white54\.shade50', 'Colors.white12', content)
    content = re.sub(r'Colors\.white54\.shade100', 'Colors.white12', content)
    content = re.sub(r'Colors\.white54\.shade200', 'Colors.white24', content)
    content = re.sub(r'Colors\.white54\.shade300', 'Colors.white38', content)
    
    # Fix Colors.white45
    content = re.sub(r'Colors\.white45', 'Colors.white54', content)
    
    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)
    print(f"Fixed colors in: {path}")

for f in FILES_TO_PATCH:
    patch_file(f)
