import re

def convert_dark_to_light(path):
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()

    # Scaffold and general background
    content = re.sub(r'backgroundColor:\s*const\s*Color\(0xFF08111F\)', 'backgroundColor: CouleursApp.fond', content)
    content = re.sub(r'backgroundColor:\s*const\s*Color\(0xFF0F172A\).*', 'backgroundColor: CouleursApp.fond,', content)

    # Text Colors
    content = re.sub(r'color:\s*Colors\.white54', 'color: CouleursApp.texteSecondaire', content)
    content = re.sub(r'color:\s*Colors\.white70', 'color: CouleursApp.texteSecondaire', content)
    content = re.sub(r'color:\s*Colors\.white38', 'color: CouleursApp.texteTertiaire', content)
    content = re.sub(r'color:\s*Colors\.white24', 'color: Colors.black26', content)
    content = re.sub(r'color:\s*Colors\.white12', 'color: Colors.black12', content)

    # Replace remaining Colors.white in TextStyles with CouleursApp.textePrincipal
    # Careful not to replace Colors.white where it's used for buttons or icons that should stay white if they have a primary background.
    # In ecran_evaluation, icons like Icons.close should be primary or black
    content = re.sub(r'color:\s*Colors\.white\)', 'color: CouleursApp.textePrincipal)', content)
    content = re.sub(r'color:\s*Colors\.white,', 'color: CouleursApp.textePrincipal,', content)

    # Specific fix for Icon(Icons.close, color: Colors.white) -> CouleursApp.primaire
    content = re.sub(r'Icon\(\s*Icons\.close,\s*color:\s*CouleursApp\.textePrincipal', 'Icon(Icons.close, color: CouleursApp.primaire', content)

    # Backgrounds of containers / textfields
    content = re.sub(r'Colors\.white\.withValues\(alpha:\s*0\.05\)', 'Colors.black.withValues(alpha: 0.05)', content)
    content = re.sub(r'Colors\.white\.withValues\(alpha:\s*0\.1\)', 'Colors.black.withValues(alpha: 0.05)', content)
    content = re.sub(r'Colors\.white\.withValues\(alpha:\s*0\.15\)', 'Colors.black.withValues(alpha: 0.1)', content)
    content = re.sub(r'Colors\.white\.withValues\(alpha:\s*0\.2\)', 'Colors.black.withValues(alpha: 0.1)', content)
    
    # Bottom Sheet in creer_demande
    content = re.sub(r'backgroundColor:\s*const\s*Color\(0xFF162032\)', 'backgroundColor: Colors.white', content)
    
    # Specific fix for buttons that need white text (ElevatedButton)
    # We might have broken ElevatedButton text. Let's fix text inside "J'ai compris", "Terminer", etc.
    # Actually, ElevatedButton style foregroundColor: Colors.white should be preserved.
    # I'll fix foregroundColor: CouleursApp.textePrincipal back to foregroundColor: Colors.white
    content = re.sub(r'foregroundColor:\s*CouleursApp\.textePrincipal', 'foregroundColor: Colors.white', content)
    
    # SystemUiOverlayStyle.light -> SystemUiOverlayStyle.dark
    content = re.sub(r'SystemUiOverlayStyle\.light', 'SystemUiOverlayStyle.dark', content)

    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)
    print(f"Patched: {path}")

convert_dark_to_light('lib/fonctionnalites/client/ecran_evaluation.dart')
convert_dark_to_light('lib/fonctionnalites/client/creer_demande.dart')
