# VazoAntso

Application iOS / Android (Flutter) pour organiser des chansons en dossiers.

## Fonctionnalités

- Dossiers nommés par titre de chanson (renommables : le dossier ET tous ses fichiers sont renommés).
- 7 emplacements par chanson : `titre_lyrics` (PDF), `titre_instrum`, `titre_vocal_ensemble`, `titre_vocal_1` à `titre_vocal_4` (audio MP3/WAV/M4A/AAC/OGG/FLAC ou PDF).
- Ajouter / supprimer des dossiers, recherche par nom.
- Lecture des lyrics en PDF.
- Édition du PDF : annotations (surligner, souligner, barrer, gribouillis), modification du texte avec régénération du PDF, remplacement du fichier.
- Lecteur audio intégré (lecture/pause, ±10 s, barre de progression).
- Stockage 100 % local, fonctionne hors ligne.
- Fonctionne sur iOS, Android **et le web (PWA)** — voir INSTALLATION.md pour le déploiement GitHub Pages.

## Installation

Prérequis : [Flutter SDK](https://docs.flutter.dev/get-started/install) (3.24+). Pour iOS : un Mac avec Xcode. Pour Android : Android Studio.

```bash
cd vazoantso
flutter create . --org com.vazoantso --project-name vazoantso
flutter pub get
flutter run          # lance sur l'appareil/émulateur connecté
```

`flutter create .` génère les dossiers `android/` et `ios/` autour du code fourni (`lib/`, `pubspec.yaml`).

## Icône de l'application

1. Placez votre logo (PNG carré, 1024×1024 conseillé) dans `assets/icon/app_icon.png`.
2. Lancez : `dart run flutter_launcher_icons`

Les icônes iOS et Android sont générées automatiquement.

## Compilation release

```bash
flutter build apk --release      # Android (APK)
flutter build appbundle          # Android (Play Store)
flutter build ipa                # iOS (App Store, nécessite un compte développeur Apple)
```

## Structure du code

- `lib/main.dart` — point d'entrée, thème.
- `lib/models/song_folder.dart` — modèle dossier + les 7 emplacements.
- `lib/services/storage_service.dart` — création/suppression/renommage/import (stockage local dans les documents de l'app).
- `lib/screens/home_screen.dart` — liste, recherche, ajout, suppression.
- `lib/screens/folder_screen.dart` — détail d'une chanson, import/ouverture des fichiers.
- `lib/screens/pdf_viewer_screen.dart` — lecture + annotation PDF.
- `lib/screens/pdf_text_edit_screen.dart` — édition texte → régénération PDF.
- `lib/screens/audio_player_screen.dart` — lecteur audio.

## Notes

- PDF : Syncfusion Flutter (licence communautaire gratuite pour les particuliers et petites entreprises — voir syncfusion.com/products/communitylicense).
- « Modifier le texte » extrait le texte du PDF et régénère un nouveau PDF : la mise en page d'origine n'est pas conservée.
