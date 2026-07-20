# Akadex

Plateforme académique et communautaire multiplateforme (Flutter + Django REST).

## Télécharger (GitHub Releases)

Les builds sont publiés **automatiquement à chaque push sur `main`**
(version bump + APK + ZIP web) :

**https://github.com/Mavuisra/akadex/releases**

| Artifact | Usage |
|----------|--------|
| `akadex-android-vX.Y.Z.apk` | Installer sur Android |
| `akadex-web-vX.Y.Z.zip` | Build web à héberger |

La version dans `pubspec.yaml` est incrémentée à chaque release
(ex. `1.1.0+2` → `1.1.1+3`).

Pour sauter une release sur un commit : ajoute `[skip release]` dans le message.

## Applications

| Dossier | Stack |
|---------|-------|
| `lib/` | App Flutter (look iOS / Cupertino, Riverpod, GoRouter) |
| `backend/` | API Django REST Framework + JWT |
| `.github/workflows/` | CI (tests) + Release (APK + Web) |

## Flutter

```bash
flutter pub get
flutter run -d chrome
```

## Backend API

```bash
cd backend
python -m venv .venv
.venv\Scripts\activate
pip install -r requirements.txt
python manage.py migrate
python manage.py seed_demo
python manage.py runserver
```

Docs : http://127.0.0.1:8000/api/docs/  
Détails : [backend/README.md](backend/README.md)

## Déployer l’API sur Render

1. [dashboard.render.com](https://dashboard.render.com) → **New** → **Blueprint**
2. Repo `Mavuisra/akadex` (fichier `render.yaml`)
3. Apply → l’API est sur **https://akadex.onrender.com/api/**

```bash
# Flutter pointe déjà vers Render par défaut.
# Backend local :
flutter run --dart-define=API_BASE_URL=http://127.0.0.1:8000/api/
```

