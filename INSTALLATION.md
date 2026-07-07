# Installer VazoAntso depuis votre compte GitHub

## 1. Mettre le projet sur GitHub (une seule fois)

Créez un dépôt `vazoantso` sur github.com (bouton « New repository »), puis depuis le dossier `vazoantso` sur votre ordinateur :

```bash
git init
git add .
git commit -m "VazoAntso v1.0.0"
git branch -M main
git remote add origin https://github.com/VOTRE_COMPTE/vazoantso.git
git push -u origin main
```

## 2. Générer l'APK Android automatiquement

Deux façons :

- **Manuelle** : sur GitHub → onglet **Actions** → « Build APK Android » → **Run workflow**.
- **Par version** : poussez un tag, une Release est créée avec l'APK attaché :

```bash
git tag v1.0.0
git push origin v1.0.0
```

GitHub compile l'APK gratuitement (aucune installation de Flutter nécessaire sur votre machine).

## 3. Installer sur un téléphone Android

1. Sur le téléphone, ouvrez la page **Releases** du dépôt : `https://github.com/VOTRE_COMPTE/vazoantso/releases`
2. Téléchargez `VazoAntso.apk`.
3. Ouvrez le fichier et autorisez « Installer des applications inconnues » si demandé.

## 4. Version web installable (PWA) — iOS ET Android

Le dépôt contient un workflow qui publie automatiquement l'appli en version web sur GitHub Pages.

Une seule configuration (une fois) : sur GitHub → **Settings** → **Pages** → Source : **GitHub Actions**.

Ensuite, à chaque push sur `main`, l'appli est publiée à :
`https://VOTRE_COMPTE.github.io/vazoantso/`

Partagez ce lien (WhatsApp, Facebook…). Sur le téléphone :

- **Android (Chrome)** : menu ⋮ → « Ajouter à l'écran d'accueil » / « Installer l'application ».
- **iPhone (Safari)** : bouton Partager → « Sur l'écran d'accueil ».

L'appli s'installe avec son icône et s'ouvre en plein écran comme une appli native. Les données sont stockées dans le navigateur du téléphone : ne pas effacer les données du site, sinon les chansons sont perdues.

## iPhone (iOS) — appli native

Apple n'autorise pas l'installation d'un fichier depuis GitHub. Options :

- **Test personnel** : brancher l'iPhone à un Mac avec Xcode et lancer `flutter run --release` (gratuit, à renouveler tous les 7 jours sans compte développeur payant).
- **Distribution** : compte Apple Developer (99 $/an) + TestFlight ou App Store (`flutter build ipa`).
