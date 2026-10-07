---
name: admin-qa-catalog
description: >-
  Audits AdminAkadex catalog buttons for courses, categories, modules, lessons.
  Use when testing admin catalog CRUD actions.
---

# Admin QA — Catalogue

## Scope

`pages/courses.js`, `pages/resources.js` (domains, modules, lessons), routes `#/cours`, `#/domaines`, `#/modules`, `#/lecons`.

## Checklist

- [ ] Cours : list / create / edit / delete / validate actions match API
- [ ] Catégories : + Ajouter / Modifier / Supprimer → `learning-domains/`
- [ ] Modules : CRUD → `course-modules/`
- [ ] Leçons : CRUD → `course-lessons/` (incl. video_url / file if present)
- [ ] Chaque bouton a un listener ; pas de bouton mort

## Report format

| Page | Bouton | Endpoint | Verdict |
|------|--------|----------|---------|

Return table + bugs only.
