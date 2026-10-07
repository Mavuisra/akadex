---
name: admin-qa-auth
description: >-
  Audits AdminAkadex login, logout, session isolation, and admin-only token.
  Use when testing /adminakadex/ auth buttons or admin JWT security.
---

# Admin QA — Auth

## Scope

`backend/static/platform_admin/js/app.js`, `api.js`, `backend/accounts/auth.py`, `config/views.py` (`admin_app`).

## Checklist

- [ ] Login form submit → `POST /api/auth/admin/token/` (not public `/auth/token/`)
- [ ] Non-admin credentials rejected (no session saved)
- [ ] Admin credentials → shell rendered, nav visible
- [ ] Déconnexion clears `akadex_admin_*` keys and returns to login
- [ ] Idle timeout (~2h) clears session
- [ ] Page headers: noindex, X-Frame-Options DENY, no-store
- [ ] Route is `/adminakadex/` (not `/admin/`)

## Report format

| Contrôle | Attendu | Observé | Verdict |
|----------|---------|---------|---------|
| … | … | … | OK / BUG |

Return only the table + short list of bugs.
