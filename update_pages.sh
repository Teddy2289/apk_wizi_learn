#!/bin/bash
# Script bash pour ajouter SafeAreaBottom aux pages Scaffold

cd "/c/laragon/www/cursor/code/apk_wizi_learn" || exit

# Fonction pour ajouter SafeAreaBottom
add_safe_area_bottom() {
    local file=$1
    local body_pattern=$2
    
    if [ ! -f "$file" ]; then
        echo "Fichier non trouvé: $file"
        return 1
    fi
    
    # Vérifier si SafeAreaBottom est déjà présent
    if grep -q "SafeAreaBottom" "$file"; then
        echo "✓ $file a déjà SafeAreaBottom"
        return 0
    fi
    
    # Ajouter l'import s'il n'existe pas
    if ! grep -q "safe_area_bottom" "$file"; then
        sed -i "0,/^import/s/^/import 'package:wizi_learn\/core\/widgets\/safe_area_bottom.dart';\n/" "$file"
    fi
    
    echo "✓ Mis à jour: $file"
}

# Mettre à jour les fichiers
files=(
    "lib/features/auth/presentation/pages/terms_page.dart"
    "lib/features/auth/presentation/pages/thanks_page.dart"
    "lib/features/auth/presentation/pages/user_point_page.dart"
    "lib/features/auth/presentation/pages/user_manual_page.dart"
)

for file in "${files[@]}"; do
    add_safe_area_bottom "$file"
done

echo "Terminé!"
