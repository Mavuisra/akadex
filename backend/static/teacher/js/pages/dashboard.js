import { api } from '../api.js';
import { barsHtml, esc, formatDateTime, statusChip } from '../utils.js';

export async function renderDashboard(root) {
  root.innerHTML = `
    <div class="page-head">
      <div>
        <h1>Tableau de bord</h1>
        <p>Vue d’ensemble de votre activité pédagogique</p>
      </div>
      <div class="page-actions">
        <a class="btn btn-primary" href="#/creer">+ Créer un cours</a>
      </div>
    </div>
    <div class="grid-stats" id="dash-stats">
      ${[1, 2, 3, 4].map(() => `<div class="stat-card"><div class="skeleton"></div><div class="skeleton" style="margin-top:12px;width:40%"></div></div>`).join('')}
    </div>
    <div class="grid-2">
      <div class="panel"><div class="panel-h"><h2>Activité 7 derniers jours</h2></div><div class="panel-b" id="dash-chart"><div class="skeleton" style="height:140px"></div></div></div>
      <div class="panel"><div class="panel-h"><h2>Activité récente</h2><a href="#/activites">Tout voir</a></div><div class="panel-b" id="dash-recent"><div class="skeleton"></div></div></div>
    </div>
    <div class="panel"><div class="panel-h"><h2>Cours les plus consultés</h2><a href="#/cours">Voir tout</a></div><div class="panel-b table-wrap" id="dash-top"></div></div>
  `;

  try {
    const d = await api('courses/teacher_dashboard/');
    const stats = [
      { label: 'Cours', value: d.courses_count ?? 0, trend: `${d.courses_published ?? 0} publiés`, cls: 'trend-flat' },
      { label: 'Étudiants', value: d.students ?? 0, trend: `${d.students_active ?? 0} en cours`, cls: 'trend-up' },
      { label: 'Visites', value: d.views ?? 0, trend: `${d.unique_visitors ?? 0} uniques`, cls: 'trend-flat' },
      { label: 'Leçons', value: d.lessons ?? 0, trend: `${d.modules ?? 0} modules`, cls: 'trend-flat' },
      { label: 'Publiés', value: d.courses_published ?? 0, trend: 'validés', cls: 'trend-up' },
      { label: 'En attente', value: d.courses_pending ?? 0, trend: 'modération', cls: 'trend-flat' },
      { label: 'Terminés', value: d.students_completed ?? 0, trend: 'étudiants', cls: 'trend-up' },
      { label: 'Revenus', value: d.revenue_available ? `${d.revenue_month} $` : '—', trend: d.revenue_available ? 'ce mois' : 'non activé', cls: 'trend-flat' },
    ];
    document.getElementById('dash-stats').innerHTML = stats
      .map(
        (s) => `
      <div class="stat-card">
        <div class="label">${esc(s.label)}</div>
        <div class="value">${esc(s.value)}</div>
        <div class="trend ${s.cls}">${esc(s.trend)}</div>
      </div>`,
      )
      .join('');

    document.getElementById('dash-chart').innerHTML = barsHtml(d.activity_7d);

    const recent = d.recent_activity || [];
    document.getElementById('dash-recent').innerHTML = recent.length
      ? `<div class="timeline">${recent
          .map(
            (a) => `
        <div class="timeline-item">
          <div><div class="timeline-dot"></div></div>
          <div>
            <strong>${esc(a.title)}</strong>
            <p>${esc(a.message)}</p>
            <time>${esc(formatDateTime(a.created_at))}</time>
          </div>
        </div>`,
          )
          .join('')}</div>`
      : '<div class="empty"><strong>Aucune activité récente</strong>Les inscriptions et progressions s’afficheront ici.</div>';

    const top = d.top_courses || [];
    document.getElementById('dash-top').innerHTML = top.length
      ? `<table class="data">
          <thead><tr><th>Cours</th><th>Statut</th><th>Étudiants</th><th>Visites</th><th>Uniques</th><th></th></tr></thead>
          <tbody>${top
            .map(
              (c) => `
            <tr>
              <td><strong>${esc(c.title)}</strong><div style="color:var(--ink-soft);font-size:0.8rem">${esc(c.code || '')}</div></td>
              <td>${statusChip(c)}</td>
              <td>${c.students ?? 0}</td>
              <td>${c.views ?? 0}</td>
              <td>${c.unique_visitors ?? 0}</td>
              <td><a class="btn btn-ghost" href="#/cours/${c.id}">Gérer</a></td>
            </tr>`,
            )
            .join('')}</tbody>
        </table>`
      : '<div class="empty"><strong>Aucun cours</strong><a class="btn btn-primary" href="#/creer" style="margin-top:12px">Créer votre premier cours</a></div>';
  } catch (e) {
    root.innerHTML = `<div class="alert alert-error">${esc(e.message)}</div>`;
  }
}
