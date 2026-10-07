# AdminAkadex — agents QA

Sept agents (skills) pour vérifier que chaque bouton AdminAkadex (`/adminakadex/`) fait exactement l’action attendue.

| # | Skill | Zone |
|---|-------|------|
| 1 | `admin-qa-auth` | Login, logout, session, headers |
| 2 | `admin-qa-dashboard` | Dashboard, stats, navigation |
| 3 | `admin-qa-users` | Utilisateurs / étudiants / enseignants |
| 4 | `admin-qa-catalog` | Cours, catégories, modules, leçons |
| 5 | `admin-qa-documents` | Documents (approuver / supprimer) |
| 6 | `admin-qa-ops` | Paiements, inscriptions, notifications, publications |
| 7 | `admin-qa-structure` | Universités, paramètres, shell |

## Mode d’emploi

1. Lire le skill correspondant dans `.cursor/skills/<name>/SKILL.md`
2. Auditer le JS admin (`backend/static/platform_admin/js/`) + API (`backend/accounts/admin_api.py`, views liées)
3. Produire un rapport : bouton → handler → endpoint → verdict OK / BUG / PARTIEL
4. Ne pas inventer de boutons absents du code

## URL

- SPA : `/adminakadex/`
- Login API : `POST /api/auth/admin/token/`
- APIs admin : `/api/auth/admin/*` (+ ressources academic/learning)
