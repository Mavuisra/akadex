# Akadex API (Django REST Framework)

API REST de la plateforme académique **Akadex**.

## Déploiement PythonAnywhere (recommandé, gratuit)

Guide complet : **[PYTHONANYWHERE.md](PYTHONANYWHERE.md)**

Résumé :

1. Clone le repo sur PythonAnywhere, crée un virtualenv, `pip install -r requirements.txt`
2. Crée un `.env` (voir [.env.example](.env.example)) avec ton `<username>.pythonanywhere.com`
3. `migrate` → `collectstatic` → `seed_demo`
4. Web app manuelle + WSGI (détails dans le guide) + mappings `/static/` et `/media/`
5. Vérifie : `https://<username>.pythonanywhere.com/api/docs/`

Compte gratuit = **SQLite** (ne pas définir `DATABASE_URL`).

---

## Déploiement Render

Le fichier `render.yaml` à la racine du repo configure automatiquement :

- Web Service `akadex-api`
- PostgreSQL `akadex-db`

### Étapes

1. Va sur [https://dashboard.render.com](https://dashboard.render.com)
2. **New** → **Blueprint**
3. Connecte le repo `Mavuisra/akadex`
4. Applique le blueprint (`render.yaml`)
5. Attends le premier deploy (~5–10 min)

URL production : **https://akadex.onrender.com**

- Docs : `https://akadex.onrender.com/api/docs/`
- Health : `https://akadex.onrender.com/api/universities/`

### Déploiement manuel (sans blueprint)

1. Crée une **PostgreSQL** (free)
2. Crée un **Web Service** :
   - Root Directory : `backend`
   - Build : `chmod +x build.sh && ./build.sh`
   - Start : `gunicorn config.wsgi:application --bind 0.0.0.0:$PORT`
3. Variables d’environnement :

| Clé | Valeur |
|-----|--------|
| `PYTHON_VERSION` | `3.13.4` |
| `DEBUG` | `False` |
| `SECRET_KEY` | (Generate) |
| `DATABASE_URL` | Internal Database URL |
| `ALLOWED_HOSTS` | `.onrender.com` |
| `CORS_ALLOW_ALL_ORIGINS` | `True` |

> Le plan free s’endort après inactivité (~50 s au réveil).

---

## Démarrage rapide (local)

```bash
cd backend
python -m venv .venv
.venv\Scripts\activate
pip install -r requirements.txt
python manage.py migrate
python manage.py seed_demo
python manage.py runserver
```

- API : http://127.0.0.1:8000/api/
- Docs : http://127.0.0.1:8000/api/docs/
- Admin : http://127.0.0.1:8000/admin/

## Comptes démo

| Email | Mot de passe |
|-------|--------------|
| `admin@akadex.app` | `akadex2026` |
| `aicha.mbemba@unikin.ac.cd` | `akadex2026` |

## Flutter → API

La base URL se configure avec `--dart-define` (voir `lib/core/constants/app_constants.dart`) :

```bash
# Production (défaut) → https://akadex.onrender.com/api/
flutter run

# Backend local
flutter run --dart-define=API_BASE_URL=http://127.0.0.1:8000/api/

# PythonAnywhere
flutter run --dart-define=API_BASE_URL=https://<username>.pythonanywhere.com/api/
```
