# Rapport QA AdminAkadex (7 agents)

Date : 2026-10-07

| Agent | Skill | Verdict |
|-------|-------|---------|
| [Auth](6c96c407-01d2-4648-b235-9c8d9920c66b) | admin-qa-auth | PASS |
| [Dashboard](03b58a95-2bb8-4e62-8f93-8c7f2a805e99) | admin-qa-dashboard | FAIL → corrigé (docs + 401) |
| [Users](11d19ccf-49a6-4c10-9855-7f270608d913) | admin-qa-users | PASS |
| [Catalog](0723e180-8a2d-4824-ba14-03ffe228c6a9) | admin-qa-catalog | FAIL → corrigé (publish domaines, order modules, edit leçon) |
| [Documents](18a17486-8d74-45aa-a9c1-37b8079aa63c) | admin-qa-documents | FAIL → corrigé (toast erreurs) |
| [Ops](266cddee-d159-473e-ae6b-de787dc8c6dc) | admin-qa-ops | FAIL partiel (Modifier post absent — non bloquant) |
| [Structure](52b7c3c7-61c0-4dc9-aca4-dd2a3dc3b1a3) | admin-qa-structure | PASS (+ menu mobile fermé au clic) |

## Correctifs appliqués après audit

- Dashboard : carte docs en attente ; 401/403 remontés
- Cours : Publier envoie `domain_ids`
- Modules : `order` auto-incrémenté
- Leçons : Modifier titre + `video_url`
- Documents : try/catch + toast
- Shell : fermeture sidebar après navigation
