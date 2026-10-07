---
name: admin-qa-ops
description: >-
  Audits AdminAkadex operations buttons for payments, enrollments, notifications,
  and community posts. Use when testing admin ops actions.
---

# Admin QA — Opérations

## Scope

`pages/resources.js` : payments, enrollments, notifications, posts. Routes `#/paiements`, `#/inscriptions`, `#/notifications`, `#/communaute`.

## Checklist

- [ ] Paiements : list `auth/admin/deposits/`, filters work
- [ ] Inscriptions : list `auth/admin/enrollments/`
- [ ] Notifications : list + form Envoyer → `POST auth/admin/notifications/`
- [ ] Publications : list / edit / delete / moderate match community API
- [ ] No button without handler

## Report format

| Page | Bouton | Endpoint | Verdict |
|------|--------|----------|---------|

Return table + bugs only.
