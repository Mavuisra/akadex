---
name: admin-qa-users
description: >-
  Audits AdminAkadex user management buttons (CRUD, activate/deactivate) for
  utilisateurs, étudiants, enseignants. Use when testing admin user actions.
---

# Admin QA — Utilisateurs

## Scope

`pages/users.js`, routes `#/utilisateurs`, `#/etudiants`, `#/enseignants`.

## Checklist

- [ ] + Ajouter → dialog → `POST auth/admin/users/`
- [ ] Modifier → load `GET …/users/:id/` → `PATCH …/users/:id/`
- [ ] Activer / Désactiver → `POST …/users/:id/activate|deactivate/`
- [ ] Supprimer → confirm → `DELETE …/users/:id/`
- [ ] Filtres étudiants (`role=student`) / enseignants (`role=teacher`)
- [ ] Annuler ferme le dialog sans appel API

## Report format

| Bouton | Action attendue | Endpoint | Verdict |
|--------|-----------------|----------|---------|

Return table + bugs only.
