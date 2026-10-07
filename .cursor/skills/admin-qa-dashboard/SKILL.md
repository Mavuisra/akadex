---
name: admin-qa-dashboard
description: >-
  Audits AdminAkadex dashboard page: stats load, nav links, and dashboard API.
  Use when testing dashboard buttons or auth/admin/dashboard.
---

# Admin QA — Dashboard

## Scope

`pages/dashboard.js`, `app.js` route `dashboard`, `AdminDashboardView`.

## Checklist

- [ ] Nav « Dashboard » → `#/dashboard`, `renderDashboard`
- [ ] Loads `GET auth/admin/dashboard/`
- [ ] Stats/cards match API fields (users, courses, payments, pending docs…)
- [ ] Any CTA on dashboard links to the correct hash route
- [ ] 401/403 → login, not blank page

## Report format

| Bouton / élément | Action attendue | Endpoint / route | Verdict |
|------------------|-----------------|------------------|---------|

Return table + bugs only.
