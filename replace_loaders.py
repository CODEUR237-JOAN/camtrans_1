import os
import re

import_loader = "import 'package:update_camtrans/coeur/widgets/loader_premium.dart';"
import_skeleton = "import 'package:update_camtrans/coeur/widgets/skeleton_shimmer.dart';"

def process_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    original = content
    modified = False

    # Replacements for CircularProgressIndicator
    if 'CircularProgressIndicator' in content:
        # Check if import exists
        if import_loader not in content:
            # Add import after last import
            imports_end = content.rfind("import '")
            if imports_end != -1:
                end_line = content.find('\n', imports_end)
                content = content[:end_line] + f"\n{import_loader}" + content[end_line:]
        
        # Replace const Center(child: CircularProgressIndicator(...))
        content = re.sub(r'const\s+Center\(\s*child:\s*CircularProgressIndicator\([^)]*\)\s*\)', 'Center(child: LoaderPremium())', content)
        content = re.sub(r'const\s+Center\(\s*child:\s*CircularProgressIndicator\(\)\s*\)', 'Center(child: LoaderPremium())', content)
        
        # Replace CircularProgressIndicator with specific parameters
        content = re.sub(r'CircularProgressIndicator\(\s*color:[^)]*\)', 'LoaderPremium(size: 24)', content)
        content = re.sub(r'CircularProgressIndicator\(\s*strokeWidth:[^)]*\)', 'LoaderPremium(size: 20)', content)
        
        # Replace remaining generic ones
        content = re.sub(r'CircularProgressIndicator\(\)', 'LoaderPremium()', content)
        
        modified = True

    if modified:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"Updated: {filepath}")

for root, _, files in os.walk('lib'):
    for file in files:
        if file.endswith('.dart') and file not in ['loader_premium.dart', 'skeleton_shimmer.dart']:
            process_file(os.path.join(root, file))
