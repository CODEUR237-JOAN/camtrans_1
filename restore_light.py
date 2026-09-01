import re
import os

FILES_TO_PATCH = [
    'lib/fonctionnalites/client/tableau_de_bord_client.dart',
    'lib/fonctionnalites/client/historique.dart',
    'lib/fonctionnalites/client/profil.dart',
    'lib/fonctionnalites/client/adresses_favorites.dart',
    'lib/fonctionnalites/client/facture.dart',
    'lib/fonctionnalites/client/ecran_chat.dart',
    'lib/fonctionnalites/client/parametres.dart',
    'lib/fonctionnalites/client/suivi_transport.dart'
]

def restore_file(path):
    if not os.path.exists(path):
        return

    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()

    # Scaffold and App backgrounds
    content = re.sub(r'backgroundColor:\s*const\s*Color\(0xFF08111F\)', 'backgroundColor: CouleursApp.fond', content)
    
    # AppBars overlay style
    content = re.sub(r'SystemUiOverlayStyle\.light', 'SystemUiOverlayStyle.dark', content)

    # Text and Icon Colors (Dark mode text -> Light mode text)
    # Caution: only replace colors where they were changed.
    # In my previous script, I replaced CouleursApp.textePrincipal with Colors.white
    content = re.sub(r'color:\s*Colors\.white(?!12|24|38|54|70)', 'color: CouleursApp.textePrincipal', content)
    content = re.sub(r'color:\s*Colors\.white70', 'color: CouleursApp.texteSecondaire', content)
    content = re.sub(r'color:\s*Colors\.white54', 'color: Colors.grey', content)
    content = re.sub(r'color:\s*Colors\.white38', 'color: Colors.grey.shade400', content)

    # Fix buttons foreground: ElevatedButtons might have had foregroundColor: Colors.white, which is now CouleursApp.textePrincipal
    # Actually, in the previous script I didn't touch ElevatedButton colors because they weren't matched if they didn't have `color:`
    # Wait, `foregroundColor: Colors.white` would NOT be matched by `color: Colors.white` because of the `foreground` prefix!
    # Ah! `re.sub(r'color:\s*Colors\.white'` matches `color: Colors.white`, it DOES NOT match `foregroundColor: Colors.white`
    # So `color: Colors.white` is mostly safe to revert to `color: CouleursApp.textePrincipal`.

    # Cards / Containers (Dark Glass/Surface -> White backgrounds)
    content = re.sub(r'color:\s*const\s*Color\(0xFF1E293B\)', 'color: Colors.white', content)
    
    # But wait, Decoration(color: const Color(0xFF1E293B) became color: Colors.white
    # Let's fix some specific backgrounds that need CouleursApp.fond instead of white? 
    # Adresses_favorites Scaffold was originally Color(0xFFF8FAFC). CouleursApp.fond is fine (it's the same color practically).
    # Facture Scaffold was Color(0xFFF4F7FB). CouleursApp.fond is fine too.

    # AppBar icons and text
    content = re.sub(r'iconTheme:\s*const\s*IconThemeData\(color:\s*Colors\.white\)', 'iconTheme: const IconThemeData(color: CouleursApp.primaire)', content)

    # Divider colors
    content = re.sub(r'color:\s*Colors\.white12', 'color: const Color(0xFFEEEEEE)', content)
    content = re.sub(r'color:\s*Colors\.white24', 'color: Colors.grey.shade200', content)
    
    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)
    print(f"Restored to light theme: {path}")

for f in FILES_TO_PATCH:
    restore_file(f)
