import re
import os
import glob

def clean_creer_demande(path):
    if not os.path.exists(path):
        return
        
    if 'creer_demande.dart' not in path and 'ecran_evaluation.dart' not in path:
        return

    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()

    # Replace dark container colors with light colors
    content = re.sub(r'const\s*Color\(0xFF1E293B\)', 'Colors.white', content)
    content = re.sub(r'const\s*Color\(0xFF0F172A\)', 'Colors.white', content)
    content = re.sub(r'color:\s*Colors\.black\)', 'color: Colors.white)', content) # For buttons foreground that might have been broken

    # Text style adjustments inside containers
    # We replaced text with black, which is good on a white container.
    
    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)
    print(f"Cleaned containers: {path}")

files = glob.glob('lib/fonctionnalites/client/*.dart')
for f in files:
    clean_creer_demande(f)
