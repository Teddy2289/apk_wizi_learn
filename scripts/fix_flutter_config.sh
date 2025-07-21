#!/bin/bash

# Crée le dossier Flutter s'il n'existe pas
mkdir -p ios/Flutter

# Génère les fichiers manquants
flutter precache
flutter pub get
flutter gen-l10n