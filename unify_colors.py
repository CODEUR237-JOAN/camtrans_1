"""
Script to uniformize colors across all client pages.
Target design system:
  - Scaffold backgroundColor: CouleursApp.fond (#F8FAFC)
  - AppBar backgroundColor: CouleursApp.fond (#F8FAFC) 
  - AppBar elevation: 0
  - AppBar title text: CouleursApp.textePrincipal
  - AppBar leading/icons: CouleursApp.primaire
"""

import re

def patch_file(path, replacements):
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()
    for old, new in replacements:
        content = content.replace(old, new)
    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)
    print(f"  OK Patched: {path}")

# ----------------------------------------------------------------
# adresses_favorites.dart
# ----------------------------------------------------------------
patch_file(
    'lib/fonctionnalites/client/adresses_favorites.dart',
    [
        ("backgroundColor: const Color(0xFFF8FAFC), // Fond clair premium",
         "backgroundColor: CouleursApp.fond,"),
        ("backgroundColor: Colors.white,\n        elevation: 0,\n        systemOverlayStyle: SystemUiOverlayStyle.dark,\n        centerTitle: true,\n        leading: IconButton(\n          icon: const Icon(Iconsax.arrow_left_2_copy, color: Colors.black87),",
         "backgroundColor: CouleursApp.fond,\n        elevation: 0,\n        systemOverlayStyle: SystemUiOverlayStyle.dark,\n        centerTitle: true,\n        leading: IconButton(\n          icon: const Icon(Iconsax.arrow_left_2_copy, color: CouleursApp.primaire),"),
        ("style: GoogleFonts.inter(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 18),\n        ),\n      ),\n      body: SafeArea(\n        child: Padding(\n          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20),",
         "style: GoogleFonts.inter(color: CouleursApp.textePrincipal, fontWeight: FontWeight.bold, fontSize: 18),\n        ),\n      ),\n      body: SafeArea(\n        child: Padding(\n          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20),"),
    ]
)

# ----------------------------------------------------------------
# facture.dart
# ----------------------------------------------------------------
patch_file(
    'lib/fonctionnalites/client/facture.dart',
    [
        ("backgroundColor: const Color(0xFFF4F7FB),",
         "backgroundColor: CouleursApp.fond,"),
        ("title: const Text(\"Mes Transactions\", style: TextStyle(fontWeight: FontWeight.bold)),\n        backgroundColor: Colors.white,\n        elevation: 0,\n        foregroundColor: Colors.black87,",
         "title: const Text(\"Mes Transactions\", style: TextStyle(fontWeight: FontWeight.bold, color: CouleursApp.textePrincipal)),\n        backgroundColor: CouleursApp.fond,\n        elevation: 0,\n        foregroundColor: CouleursApp.textePrincipal,"),
    ]
)

# ----------------------------------------------------------------
# ecran_chat.dart
# ----------------------------------------------------------------
patch_file(
    'lib/fonctionnalites/client/ecran_chat.dart',
    [
        ("backgroundColor: const Color(0xFFF8FAFC),\n      appBar: AppBar(\n        backgroundColor: Colors.white,",
         "backgroundColor: CouleursApp.fond,\n      appBar: AppBar(\n        backgroundColor: CouleursApp.fond,"),
        ("icon: const Icon(Iconsax.arrow_left_2_copy, color: Colors.black87),",
         "icon: const Icon(Iconsax.arrow_left_2_copy, color: CouleursApp.primaire),"),
        ("style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),",
         "style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16, color: CouleursApp.textePrincipal),"),
    ]
)

# ----------------------------------------------------------------
# parametres.dart — AppBar has no custom background set, just add styling
# ----------------------------------------------------------------
patch_file(
    'lib/fonctionnalites/client/parametres.dart',
    [
        ("appBar: AppBar(\n        title: const Text(\"Paramètres\"),\n      ),",
         "appBar: AppBar(\n        title: const Text(\"Paramètres\", style: TextStyle(fontWeight: FontWeight.bold, color: CouleursApp.textePrincipal)),\n        backgroundColor: CouleursApp.fond,\n        elevation: 0,\n        iconTheme: const IconThemeData(color: CouleursApp.primaire),\n      ),"),
    ]
)

# ----------------------------------------------------------------
# suivi_transport.dart
# ----------------------------------------------------------------
patch_file(
    'lib/fonctionnalites/client/suivi_transport.dart',
    [
        ("backgroundColor: Colors.white,\n        appBar: AppBar(title: const Text('Suivi')),",
         "backgroundColor: CouleursApp.fond,\n        appBar: AppBar(\n          title: const Text('Suivi', style: TextStyle(fontWeight: FontWeight.bold, color: CouleursApp.textePrincipal)),\n          backgroundColor: CouleursApp.fond,\n          elevation: 0,\n          iconTheme: const IconThemeData(color: CouleursApp.primaire),\n        ),"),
    ]
)

print("\nDone! All client pages now use a uniform color palette.")
