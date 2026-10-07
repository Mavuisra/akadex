---
name: admin-qa-structure
description: >-
  Audits AdminAkadex structure (universities/faculties) and settings buttons,
  plus shell nav/menu/logout. Use when testing admin structure or settings.
---

# Admin QA — Structure & shell

## Scope

`renderStructure`, `renderSettings` in `pages/resources.js`, `app.js` shell (nav groups, menu mobile, Site public).

## Checklist

- [ ] Universités / facultés : dialogs Ajouter / Modifier / Supprimer → academic APIs
- [ ] Paramètres : affiche compte ; lien `/django-admin/` ; mention `/adminakadex/`
- [ ] Nav groups all hash routes resolve (no dead links)
- [ ] Menu mobile toggle + overlay close
- [ ] « Site public » → landing `/` (noopener)
- [ ] Déconnexion in foot works

## Report format

| Bouton | Action attendue | Cible | Verdict |
|--------|-----------------|-------|---------|

Return table + bugs only.
