---
name: admin-qa-documents
description: >-
  Audits AdminAkadex document moderation buttons (approve, delete, filters).
  Use when testing admin document actions.
---

# Admin QA — Documents

## Scope

`renderDocuments` in `pages/resources.js`, route `#/documents`.

## Checklist

- [ ] Liste `GET documents/?…` with filters (status)
- [ ] Approuver → `POST documents/:id/approve/` only when pending
- [ ] Supprimer → confirm → `DELETE documents/:id/`
- [ ] Filtres pending_admin / approved change query params
- [ ] Errors surface in UI (toast / alert)

## Report format

| Bouton | Action attendue | Endpoint | Verdict |
|--------|-----------------|----------|---------|

Return table + bugs only.
