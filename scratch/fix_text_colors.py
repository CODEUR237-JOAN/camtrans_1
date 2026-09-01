import re
import glob

files = glob.glob(r'lib/**/*.dart', recursive=True)
count = 0

for file in files:
    try:
        with open(file, 'r', encoding='utf-8') as f:
            content = f.read()
        
        original = content

        # Fix TextStyle
        # We find 'color: const Color(0xFF08111F)' and replace with 'color: Colors.white'
        # But we only want to do it inside text styles, icons, etc.
        # Actually, let's just do a negative lookbehind for Container/Card? No, too complex.
        
        # Let's replace specifically in TextStyle
        content = re.sub(
            r'(TextStyle\([^)]*?)color:\s*(?:const\s*)?Color\(0xFF08111F\)',
            r'\1color: Colors.white',
            content,
            flags=re.DOTALL
        )
        content = re.sub(
            r'(GoogleFonts\.\w+\([^)]*?)color:\s*(?:const\s*)?Color\(0xFF08111F\)',
            r'\1color: Colors.white',
            content,
            flags=re.DOTALL
        )
        
        # Fix Icon
        content = re.sub(
            r'(Icon\([^)]*?)color:\s*(?:const\s*)?Color\(0xFF08111F\)',
            r'\1color: Colors.white',
            content,
            flags=re.DOTALL
        )
        
        # Fix generic color: const Color(0xFF08111F) if it's near 'fontSize' or 'fontWeight'
        content = re.sub(
            r'(fontSize:\s*[\d.]+,[^}]*?)color:\s*(?:const\s*)?Color\(0xFF08111F\)',
            r'\1color: Colors.white',
            content,
            flags=re.DOTALL
        )
        content = re.sub(
            r'color:\s*(?:const\s*)?Color\(0xFF08111F\)([^}]*?fontSize:\s*[\d.]+)',
            r'color: Colors.white\1',
            content,
            flags=re.DOTALL
        )

        if content != original:
            with open(file, 'w', encoding='utf-8') as f:
                f.write(content)
            print(f'Fixed {file}')
            count += 1
    except Exception as e:
        print(f"Error on {file}: {e}")

print(f"Done. Fixed {count} files.")
