import re

def reverse_dark_to_light(path):
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()

    # Scaffold and general background
    content = re.sub(r'backgroundColor:\s*CouleursApp\.fond', 'backgroundColor: const Color(0xFF08111F)', content)

    # Text Colors
    content = re.sub(r'color:\s*CouleursApp\.texteSecondaire', 'color: Colors.white54', content)
    content = re.sub(r'color:\s*CouleursApp\.texteTertiaire', 'color: Colors.white38', content)
    content = re.sub(r'color:\s*Colors\.black26', 'color: Colors.white24', content)
    content = re.sub(r'color:\s*Colors\.black12', 'color: Colors.white12', content)

    # Replace CouleursApp.textePrincipal with Colors.white
    content = re.sub(r'color:\s*CouleursApp\.textePrincipal\)', 'color: Colors.white)', content)
    content = re.sub(r'color:\s*CouleursApp\.textePrincipal,', 'color: Colors.white,', content)

    # Backgrounds of containers / textfields
    content = re.sub(r'Colors\.black\.withValues\(alpha:\s*0\.05\)', 'Colors.white.withValues(alpha: 0.1)', content)
    content = re.sub(r'Colors\.black\.withValues\(alpha:\s*0\.1\)', 'Colors.white.withValues(alpha: 0.15)', content)
    
    # Bottom Sheet in creer_demande
    content = re.sub(r'backgroundColor:\s*Colors\.white', 'backgroundColor: const Color(0xFF162032)', content)
    
    # SystemUiOverlayStyle
    content = re.sub(r'SystemUiOverlayStyle\.dark', 'SystemUiOverlayStyle.light', content)

    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)
    print(f"Reverted colors for: {path}")

reverse_dark_to_light('lib/fonctionnalites/client/creer_demande.dart')
