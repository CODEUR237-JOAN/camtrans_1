import re
import os
import glob

def apply_pure_white(path):
    if not os.path.exists(path):
        return

    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()

    # If this is creer_demande or ecran_evaluation, we first need to convert from dark to light
    if 'creer_demande.dart' in path or 'ecran_evaluation.dart' in path:
        content = re.sub(r'backgroundColor:\s*const\s*Color\(0xFF08111F\)', 'backgroundColor: Colors.white', content)
        content = re.sub(r'backgroundColor:\s*const\s*Color\(0xFF0F172A\).*', 'backgroundColor: Colors.white,', content)
        content = re.sub(r'color:\s*Colors\.white54', 'color: Colors.black54', content)
        content = re.sub(r'color:\s*Colors\.white70', 'color: Colors.black87', content)
        content = re.sub(r'color:\s*Colors\.white38', 'color: Colors.black38', content)
        content = re.sub(r'color:\s*Colors\.white24', 'color: Colors.black26', content)
        content = re.sub(r'color:\s*Colors\.white12', 'color: Colors.black12', content)
        content = re.sub(r'color:\s*Colors\.white\)', 'color: Colors.black)', content)
        content = re.sub(r'color:\s*Colors\.white,', 'color: Colors.black,', content)
        content = re.sub(r'Icon\(\s*Icons\.close,\s*color:\s*Colors\.black', 'Icon(Icons.close, color: CouleursApp.primaire', content)
        content = re.sub(r'Colors\.white\.withValues\(alpha:\s*0\.05\)', 'Colors.black.withValues(alpha: 0.05)', content)
        content = re.sub(r'Colors\.white\.withValues\(alpha:\s*0\.1\)', 'Colors.black.withValues(alpha: 0.05)', content)
        content = re.sub(r'Colors\.white\.withValues\(alpha:\s*0\.15\)', 'Colors.black.withValues(alpha: 0.1)', content)
        content = re.sub(r'Colors\.white\.withValues\(alpha:\s*0\.2\)', 'Colors.black.withValues(alpha: 0.1)', content)
        content = re.sub(r'backgroundColor:\s*const\s*Color\(0xFF162032\)', 'backgroundColor: Colors.white', content)
        content = re.sub(r'foregroundColor:\s*Colors\.black', 'foregroundColor: Colors.white', content)
        content = re.sub(r'SystemUiOverlayStyle\.light', 'SystemUiOverlayStyle.dark', content)
        # Specific fixes
        content = re.sub(r'CouleursApp\.textePrincipal', 'Colors.black', content)
        content = re.sub(r'CouleursApp\.texteSecondaire', 'Colors.black87', content)

    # General replacements for ALL files to enforce pure white and black text
    content = re.sub(r'backgroundColor:\s*CouleursApp\.fond(?!Sombre)', 'backgroundColor: Colors.white', content)
    content = re.sub(r'backgroundColor:\s*const\s*Color\(0xFFF8FAFC\)', 'backgroundColor: Colors.white', content)
    content = re.sub(r'backgroundColor:\s*const\s*Color\(0xFFF4F7FB\)', 'backgroundColor: Colors.white', content)
    
    # Enforce text color variables to pure black
    content = re.sub(r'color:\s*CouleursApp\.textePrincipal', 'color: Colors.black', content)
    content = re.sub(r'color:\s*CouleursApp\.texteSecondaire', 'color: Colors.black87', content)
    
    # Let's ensure Scaffold doesn't have Color(0xFF0F172A)
    content = re.sub(r'backgroundColor:\s*const\s*Color\(0xFF0F172A\).*', 'backgroundColor: Colors.white,', content)

    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)
    print(f"Applied pure white theme: {path}")

files = glob.glob('lib/fonctionnalites/client/*.dart')
for f in files:
    apply_pure_white(f)
