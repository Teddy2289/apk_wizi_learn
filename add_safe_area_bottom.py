#!/usr/bin/env python3
"""
Script Python pour ajouter SafeAreaBottom à toutes les pages Scaffold
"""

import re
import os
from pathlib import Path

PROJECT_ROOT = Path("/c/laragon/www/cursor/code/apk_wizi_learn")
IMPORT_STATEMENT = "import 'package:wizi_learn/core/widgets/safe_area_bottom.dart';\n"

PAGES_TO_UPDATE = [
    "lib/features/auth/presentation/pages/terms_page.dart",
    "lib/features/auth/presentation/pages/thanks_page.dart",
    "lib/features/auth/presentation/pages/user_point_page.dart",
    "lib/features/auth/presentation/pages/user_manual_page.dart",
    "lib/features/auth/presentation/pages/contact_faq_page.dart",
    "lib/features/auth/presentation/pages/quiz_detail_page.dart",
    "lib/features/auth/presentation/pages/splash_page.dart",
    "lib/features/auth/presentation/pages/auth/login_page.dart",
]

def has_safe_area_bottom(content):
    """Vérifie si SafeAreaBottom est déjà présent"""
    return "SafeAreaBottom" in content or "safe_area_bottom" in content

def add_import_if_missing(content):
    """Ajoute l'import SafeAreaBottom s'il n'existe pas"""
    if has_safe_area_bottom(content):
        return content
    
    # Trouver la première ligne d'import et l'ajouter après
    import_match = re.search(r"^(import .*?;\n)", content, re.MULTILINE)
    if import_match:
        insert_pos = import_match.end()
        return content[:insert_pos] + IMPORT_STATEMENT + content[insert_pos:]
    
    return content

def wrap_body_with_safe_area(content):
    """Enveloppe le body Scaffold avec SafeAreaBottom"""
    if has_safe_area_bottom(content):
        return content
    
    # Pattern pour SingleChildScrollView
    pattern = r"(\s+body:\s+)SingleChildScrollView\("
    replacement = r"\1SafeAreaBottom(\n        child: SingleChildScrollView("
    new_content = re.sub(pattern, replacement, content, count=1)
    
    # Si le remplacement a eu lieu, ajouter la fermeture
    if new_content != content:
        # Trouver la fermeture de Scaffold et ajouter la fermeture de SafeAreaBottom
        # Pattern: ),\n      ), au lieu de ),\n      ),
        new_content = re.sub(r"(\s+\),\n\s+),\s*$", r"\1,\n    )),", new_content, flags=re.MULTILINE)
        return new_content
    
    # Pattern pour Center
    pattern = r"(\s+body:\s+)Center\("
    replacement = r"\1SafeAreaBottom(\n        child: Center("
    new_content = re.sub(pattern, replacement, content, count=1)
    
    if new_content != content:
        new_content = re.sub(r"(\s+\),\n\s+),\s*$", r"\1,\n    )),", new_content, flags=re.MULTILINE)
        return new_content
    
    # Pattern pour Padding
    pattern = r"(\s+body:\s+)Padding\("
    replacement = r"\1SafeAreaBottom(\n        child: Padding("
    new_content = re.sub(pattern, replacement, content, count=1)
    
    if new_content != content:
        new_content = re.sub(r"(\s+\),\n\s+),\s*$", r"\1,\n    )),", new_content, flags=re.MULTILINE)
        return new_content
    
    # Pattern pour ListView
    pattern = r"(\s+body:\s+)ListView\("
    replacement = r"\1SafeAreaBottom(\n        child: ListView("
    new_content = re.sub(pattern, replacement, content, count=1)
    
    if new_content != content:
        new_content = re.sub(r"(\s+\),\n\s+),\s*$", r"\1,\n    )),", new_content, flags=re.MULTILINE)
        return new_content
    
    # Pattern pour Column
    pattern = r"(\s+body:\s+)Column\("
    replacement = r"\1SafeAreaBottom(\n        child: Column("
    new_content = re.sub(pattern, replacement, content, count=1)
    
    if new_content != content:
        new_content = re.sub(r"(\s+\),\n\s+),\s*$", r"\1,\n    )),", new_content, flags=re.MULTILINE)
        return new_content
    
    return content

def process_file(file_path):
    """Traite un fichier pour ajouter SafeAreaBottom"""
    file_path = PROJECT_ROOT / file_path
    
    if not file_path.exists():
        print(f"❌ Fichier non trouvé: {file_path}")
        return False
    
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        if has_safe_area_bottom(content):
            print(f"✓ {file_path.name} a déjà SafeAreaBottom")
            return True
        
        # Ajouter l'import
        content = add_import_if_missing(content)
        
        # Envelopper le body
        new_content = wrap_body_with_safe_area(content)
        
        if new_content != content:
            with open(file_path, 'w', encoding='utf-8') as f:
                f.write(new_content)
            print(f"✓ Mis à jour: {file_path.name}")
            return True
        else:
            print(f"⚠ Pas de changement pour: {file_path.name}")
            return False
    
    except Exception as e:
        print(f"❌ Erreur lors du traitement de {file_path.name}: {e}")
        return False

if __name__ == "__main__":
    print("🔄 Ajout de SafeAreaBottom à toutes les pages...\n")
    
    updated = 0
    for page in PAGES_TO_UPDATE:
        if process_file(page):
            updated += 1
    
    print(f"\n✨ Traitement terminé! {updated} fichier(s) mis à jour.")
