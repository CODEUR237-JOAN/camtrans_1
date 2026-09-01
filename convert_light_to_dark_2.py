import re
import os

FILES_TO_PATCH = [
    'lib/fonctionnalites/client/adresses_favorites.dart',
    'lib/fonctionnalites/client/facture.dart',
    'lib/fonctionnalites/client/ecran_chat.dart',
    'lib/fonctionnalites/client/parametres.dart',
    'lib/fonctionnalites/client/suivi_transport.dart'
]

def patch_file(path):
    if not os.path.exists(path):
        return

    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()

    # Scaffold and App backgrounds
    content = re.sub(r'backgroundColor:\s*CouleursApp\.fond(?!Sombre)', 'backgroundColor: const Color(0xFF08111F)', content)
    content = re.sub(r'backgroundColor:\s*const\s*Color\(0xFFF8FAFC\)', 'backgroundColor: const Color(0xFF08111F)', content)
    content = re.sub(r'backgroundColor:\s*const\s*Color\(0xFFF4F7FB\)', 'backgroundColor: const Color(0xFF08111F)', content)
    content = re.sub(r'backgroundColor:\s*Colors\.white', 'backgroundColor: const Color(0xFF08111F)', content)
    
    # AppBars overlay style
    content = re.sub(r'SystemUiOverlayStyle\.dark', 'SystemUiOverlayStyle.light', content)

    # Text and Icon Colors (Light mode text -> Dark mode text)
    content = re.sub(r'color:\s*Colors\.black87', 'color: Colors.white', content)
    content = re.sub(r'color:\s*Colors\.black54', 'color: Colors.white70', content)
    content = re.sub(r'color:\s*Colors\.black(?!12|24|38|54|70)', 'color: Colors.white', content)
    content = re.sub(r'color:\s*CouleursApp\.textePrincipal', 'color: Colors.white', content)
    content = re.sub(r'color:\s*CouleursApp\.texteSecondaire', 'color: Colors.white70', content)
    content = re.sub(r'color:\s*CouleursApp\.texteTertiaire', 'color: Colors.white54', content)

    # Cards / Containers (White backgrounds -> Dark Glass/Surface)
    content = re.sub(r'color:\s*Colors\.white,\s*//\s*fond carte', 'color: const Color(0xFF1E293B),', content)
    content = re.sub(r'Decoration\(color:\s*Colors\.white', 'Decoration(color: const Color(0xFF1E293B)', content)
    content = re.sub(r'BoxDecoration\(color:\s*Colors\.white', 'BoxDecoration(color: const Color(0xFF1E293B)', content)
    content = re.sub(r'Card\(.*?color:\s*Colors\.white', 'Card(color: const Color(0xFF1E293B)', content)
    content = content.replace("color: Colors.white, // fond blanc", "color: const Color(0xFF1E293B),")

    # AppBar icons and text
    content = re.sub(r'iconTheme:\s*const\s*IconThemeData\(color:\s*CouleursApp\.primaire\)', 'iconTheme: const IconThemeData(color: Colors.white)', content)

    # Divider colors
    content = re.sub(r'color:\s*const Color\(0xFFEEEEEE\)', 'color: Colors.white12', content)

    # Some specific fixes
    content = re.sub(r'Colors\.grey\.shade400', 'Colors.white38', content)
    content = re.sub(r'Colors\.grey', 'Colors.white54', content)
    
    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)
    print(f"Patched to dark theme: {path}")

for f in FILES_TO_PATCH:
    patch_file(f)
