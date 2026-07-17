# Akadex API (Django REST Framework)

API REST de la plateforme académique **Akadex**.

## Démarrage rapide

```bash
cd backend
python -m venv .venv

# Windows
.venv\Scripts\activate

# macOS / Linux
source .venv/bin/activate

pip install -r requirements.txt
python manage.py migrate
python manage.py seed_demo
python manage.py runserver
```

- API : http://127.0.0.1:8000/api/
- Docs Swagger : http://127.0.0.1:8000/api/docs/
- Admin : http://127.0.0.1:8000/admin/

## Comptes démo

| Email | Mot de passe | Rôle |
|-------|--------------|------|
| `admin@akadex.app` | `akadex2026` | Admin |
| `aicha.mbemba@unikin.ac.cd` | `akadex2026` | Étudiante |
| `samuel.okito@unikin.ac.cd` | `akadex2026` | Étudiant |
| `kabongo@unikin.ac.cd` | `akadex2026` | Enseignant |

## Auth JWT

```http
POST /api/auth/token/
Content-Type: application/json

{"email": "aicha.mbemba@unikin.ac.cd", "password": "akadex2026"}
```

> SimpleJWT utilise le `USERNAME_FIELD` du modèle User (`email`).

```http
Authorization: Bearer <access_token>
```

Inscription : `POST /api/auth/register/`  
Profil courant : `GET /api/auth/me/`

## Endpoints principaux

| Ressource | URL |
|-----------|-----|
| Universités | `/api/universities/` |
| Facultés | `/api/faculties/` |
| Départements | `/api/departments/` |
| Promotions | `/api/promotions/` |
| Cours | `/api/courses/` |
| Documents | `/api/documents/` |
| Favoris | `/api/favorites/` |
| Annonces | `/api/announcements/` |
| Événements | `/api/events/` |
| Posts communauté | `/api/posts/` |
| Conversations | `/api/conversations/` |
| Messages | `/api/messages/` |

### Actions documents

- `POST /api/documents/{id}/view/` — incrémenter les vues
- `POST /api/documents/{id}/download/` — incrémenter les téléchargements
- `POST /api/documents/{id}/favorite/` — toggle favori

### Actions communauté

- `POST /api/posts/{id}/like/` — toggle like

## Architecture

```
backend/
  config/          # settings, urls
  accounts/        # User custom, auth
  academic/        # uni → docs, annonces, calendrier
  community/       # posts, likes, commentaires
  messaging/       # chat privé / groupes
```

## Flutter

Émulateur Android : `http://10.0.2.2:8000/api/`  
iOS / desktop : `http://127.0.0.1:8000/api/`
