# Akadex

Plateforme académique et communautaire multiplateforme (Flutter + Django REST).

## Télécharger (GitHub Releases)

Les builds sont publiés automatiquement à chaque tag `v*` :

**https://github.com/Mavuisra/akadex/releases**

| Artifact | Usage |
|----------|--------|
| `akadex-android-vX.Y.Z.apk` | Installer sur Android |
| `akadex-web-vX.Y.Z.zip` | Build web à héberger |

Créer une nouvelle release :

```bash
git tag v1.0.1
git push origin v1.0.1
```

Ou : Actions → **Release** → *Run workflow*.

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
3. Apply → l’API sera sur `https://akadex-api.onrender.com`

