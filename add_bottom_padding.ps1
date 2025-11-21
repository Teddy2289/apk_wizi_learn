# Script pour ajouter SafeAreaBottom à toutes les pages

$projectRoot = "c:\laragon\www\cursor\code\apk_wizi_learn"
$filesToUpdate = @(
    "lib/features/auth/presentation/pages/terms_page.dart",
    "lib/features/auth/presentation/pages/thanks_page.dart", 
    "lib/features/auth/presentation/pages/user_point_page.dart",
    "lib/features/auth/presentation/pages/user_manual_page.dart"
)

# Fonction pour ajouter SafeAreaBottom
function Add-SafeAreaBottom {
    param([string]$filePath)
    
    $content = Get-Content $filePath -Raw
    
    # Vérifier si SafeAreaBottom est déjà importé
    if ($content -match "import.*safe_area_bottom") {
        Write-Host "✓ $filePath a déjà SafeAreaBottom" -ForegroundColor Green
        return
    }
    
    # Ajouter l'import
    $content = $content -replace '(import [''"]package:)', "import 'package:wizi_learn/core/widgets/safe_area_bottom.dart';`n`$1"
    
    # Envelopper le body avec SafeAreaBottom
    if ($content -match "body:\s+SingleChildScrollView\(") {
        $content = $content -replace "(body:\s+)SingleChildScrollView\(", "`$1SafeAreaBottom(`n        child: SingleChildScrollView(`n"
        $content = $content -replace "(body.*?child:.*?\),\s+),\s+bottomNavigationBar)", "`$1),`n      ),`n    )),$0"
    }
    elseif ($content -match "body:\s+Center\(") {
        $content = $content -replace "(body:\s+)Center\(", "`$1SafeAreaBottom(`n        child: Center(`n"
        $content = $content -replace "(body.*?child:.*?\),\s+),\s+bottomNavigationBar)", "`$1),`n      ),`n    )),$0"
    }
    elseif ($content -match "body:\s+Padding\(") {
        $content = $content -replace "(body:\s+)Padding\(", "`$1SafeAreaBottom(`n        child: Padding(`n"
        $content = $content -replace "(body.*?child:.*?\),\s+),\s+bottomNavigationBar)", "`$1),`n      ),`n    )),$0"
    }
    
    Set-Content $filePath $content
    Write-Host "✓ Mis à jour: $filePath" -ForegroundColor Green
}

foreach ($file in $filesToUpdate) {
    $fullPath = Join-Path $projectRoot $file
    if (Test-Path $fullPath) {
        Add-SafeAreaBottom -filePath $fullPath
    }
    else {
        Write-Host "✗ Fichier non trouvé: $fullPath" -ForegroundColor Red
    }
}

Write-Host "`nTerminé !" -ForegroundColor Cyan
