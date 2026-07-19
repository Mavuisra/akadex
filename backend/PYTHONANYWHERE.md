# Déploiement Akadex sur PythonAnywhere

Guide pour héberger l’**API Django** sur un compte **gratuit** PythonAnywhere avec **SQLite**.

Flutter reste en local / mobile et pointe vers l’API via `--dart-define=API_BASE_URL=...`.

URL typique : `https://<username>.pythonanywhere.com`

- Docs API : `https://<username>.pythonanywhere.com/api/docs/`
- Admin : `https://<username>.pythonanywhere.com/admin/`

> Remplace partout `<username>` par ton identifiant PythonAnywhere.

---

## 1. Compte et clone

1. Crée un compte sur [https://www.pythonanywhere.com](https://www.pythonanywhere.com)
2. Ouvre **Consoles** → **Bash**

```bash
cd ~
git clone https://github.com/Mavuisra/akadex.git
cd akadex/backend
```

Pour une branche feature :

```bash
git clone -b feature/premium-ux-messaging-register https://github.com/Mavuisra/akadex.git
cd akadex/backend
```

---

## 2. Virtualenv et dépendances

Utilise une version Python **3.10+** disponible sur PA (ex. 3.10) :

```bash
# Adapte 3.10 si une autre version est proposée dans l’onglet Web
mkvirtualenv --python=/usr/bin/python3.10 akadex-venv
workon akadex-venv

cd ~/akadex/backend
pip install -r requirements.txt
```

Si `mkvirtualenv` n’est pas dispo :

```bash
python3.10 -m venv ~/venvs/akadex-venv
source ~/venvs/akadex-venv/bin/activate
cd ~/akadex/backend
pip install -r requirements.txt
```

---

## 3. Fichier `.env`

```bash
cd ~/akadex/backend
nano .env
```

Contenu (adapte `<username>` et génère un `SECRET_KEY` fort) :

```env
DEBUG=False
SECRET_KEY=change-me-to-a-long-random-string
ALLOWED_HOSTS=<username>.pythonanywhere.com
PYTHONANYWHERE_DOMAIN=<username>.pythonanywhere.com
CSRF_TRUSTED_ORIGINS=https://<username>.pythonanywhere.com
CORS_ALLOW_ALL_ORIGINS=True
SECURE_SSL_REDIRECT=True
```

**Ne définis pas** `DATABASE_URL` : Django utilisera SQLite (`db.sqlite3`).

---

## 4. Migrations, static, seed

Toujours avec le venv activé :

```bash
cd ~/akadex/backend
python manage.py migrate
python manage.py collectstatic --noinput
python manage.py seed_demo
```

Comptes démo après seed : mot de passe `akadex2026` (voir README).

---

## 5. Web app (onglet Web)

1. **Web** → **Add a new web app**
2. **Manual configuration** → Python **3.10** (même version que le venv)
3. **Source code** : `/home/<username>/akadex/backend`
4. **Working directory** : `/home/<username>/akadex/backend`
5. **Virtualenv** : chemin du venv, par ex.  
   `/home/<username>/.virtualenvs/akadex-venv`  
   ou `/home/<username>/venvs/akadex-venv`

### WSGI

Ouvre le fichier WSGI (lien dans l’onglet Web) et **remplace tout** par :

```python
import os
import sys

# Projet Django (dossier qui contient manage.py et config/)
project_home = '/home/<username>/akadex/backend'
if project_home not in sys.path:
    sys.path.insert(0, project_home)

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings')

# Charge le .env avant Django
from dotenv import load_dotenv
load_dotenv(os.path.join(project_home, '.env'))

from django.core.wsgi import get_wsgi_application
application = get_wsgi_application()
```

### Fichiers statiques et médias

Dans **Static files** (onglet Web) :

| URL | Directory |
|-----|-----------|
| `/static/` | `/home/<username>/akadex/backend/staticfiles` |
| `/media/` | `/home/<username>/akadex/backend/media` |

Crée le dossier médias si besoin :

```bash
mkdir -p ~/akadex/backend/media
```

Clique **Reload** sur l’onglet Web.

---

## 6. Vérification

Ouvre dans le navigateur :

- `https://<username>.pythonanywhere.com/api/docs/`
- `https://<username>.pythonanywhere.com/api/universities/`

Si erreur 500 : **Web** → **Log files** → `error.log`.

---

## 7. Flutter → API PythonAnywhere

```bash
flutter run --dart-define=API_BASE_URL=https://<username>.pythonanywhere.com/api/
```

Build web / release :

```bash
flutter build apk --dart-define=API_BASE_URL=https://<username>.pythonanywhere.com/api/
```

La constante est définie dans `lib/core/constants/app_constants.dart` (`API_BASE_URL`).

---

## 8. Mises à jour du code

```bash
cd ~/akadex
git pull
workon akadex-venv   # ou source ~/venvs/akadex-venv/bin/activate
cd backend
pip install -r requirements.txt
python manage.py migrate
python manage.py collectstatic --noinput
```

Puis **Reload** dans l’onglet Web.

---

## Limites du compte gratuit

- CPU / bande passante limités ; reload **manuel** après chaque `git pull`
- Pas de Postgres : SQLite (sauvegarde régulière de `db.sqlite3` recommandée)
- Sorties HTTP externes restreintes (whitelist) — OK pour une API JWT classique
- Pour MySQL PythonAnywhere plus tard : configurer `DATABASES` sans toucher Flutter

---

## Dépannage rapide

| Symptôme | Piste |
|----------|--------|
| `DisallowedHost` | `ALLOWED_HOSTS` + `PYTHONANYWHERE_DOMAIN` dans `.env` |
| Static / admin sans CSS | `collectstatic` + mapping `/static/` → `staticfiles` |
| Avatars / uploads 404 | mapping `/media/` → `media` |
| Module not found | Virtualenv mal renseigné dans l’onglet Web |
| CORS depuis Flutter web | `CORS_ALLOW_ALL_ORIGINS=True` |
