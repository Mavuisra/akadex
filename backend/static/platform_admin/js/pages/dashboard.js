import { api } from '../api.js';
import { barsHtml, esc, formatDateTime, personCell } from '../utils.js';

export async function renderDashboard(root) {
  root.innerHTML = `
    <div class="page-head">
      <div>
        <h1>Dashboard</h1>
      </div>
    </div>
    <div class="grid-stats" id="stats">${[1, 2, 3, 4, 5, 6, 7, 8]
      .map(
        () =>
          `<div class="stat-card"><div class="skeleton"></div><div class="skeleton" style="margin-top:12px;width:40%"></div></div>`,
      )
      .join('')}</div>
    <div class="grid-2">
      <div class="panel"><div class="panel-h"><h2>Nouveaux utilisateurs (7 j)</h2></div><div class="panel-b" id="chart"></div></div>
      <div class="panel"><div class="panel-h"><h2>Derniers utilisateurs</h2></div><div class="panel-b" id="recent-users"></div></div>
    </div>
    <div class="panel">
      <div class="panel-h">
        <h2>Publications (page d’accueil)</h2>
        <a class="btn btn-ghost" href="#/communaute">Tout voir</a>
      </div>
      <div class="panel-b table-wrap" id="recent-posts"></div>
    </div>
    <div class="panel"><div class="panel-h"><h2>Derniers cours</h2></div><div class="panel-b table-wrap" id="recent-courses"></div></div>
  `;

  try {
    const d = await api('auth/admin/dashboard/');
    const cards = [
      ['Utilisateurs', d.users_total, `${d.users_week || 0} cette semaine`],
      ['Étudiants', d.students, ''],
      ['Enseignants', d.teachers, ''],
      ['Cours', d.courses_total, `${d.courses_published || 0} publiés`],
      ['Publications', d.posts ?? 0, 'page d’accueil'],
      ['Pubs. en attente', d.posts_pending ?? 0, 'modération'],
      ['Inscriptions', d.enrollments, 'via progression'],
      ['Paiements', d.payments_completed, `${d.payments_total || 0} total`],
    ];
    document.getElementById('stats').innerHTML = cards
      .map(
        ([label, value, trend]) => `
      <div class="stat-card">
        <div class="label">${esc(label)}</div>
        <div class="value">${esc(value)}</div>
        <div class="trend trend-flat">${esc(trend)}</div>
      </div>`,
      )
      .join('');

    document.getElementById('chart').innerHTML = barsHtml(d.activity_7d, 'users');

    const users = d.recent_users || [];
    document.getElementById('recent-users').innerHTML = users.length
      ? `<div class="timeline">${users
          .map(
            (u) => `
        <div class="timeline-item">
          <div><div class="timeline-dot"></div></div>
          <div>
            <strong>${esc(u.name)}</strong>
            <p>${esc(u.email)} · ${esc(u.role)}</p>
            <time>${esc(formatDateTime(u.created_at))}</time>
          </div>
        </div>`,
          )
          .join('')}</div>`
      : '<div class="empty">Aucun utilisateur</div>';

    const posts = d.recent_posts || [];
    document.getElementById('recent-posts').innerHTML = posts.length
      ? `<table class="data"><thead><tr><th>Auteur</th><th>Publication</th><th>Type</th><th>Statut</th><th>Date</th></tr></thead><tbody>${posts
          .map((p) => {
            const st = p.status || 'approved';
            const chip =
              st === 'approved'
                ? '<span class="chip chip-ok">Validée</span>'
                : st === 'pending'
                  ? '<span class="chip chip-wait">En examen</span>'
                  : '<span class="chip chip-draft">Refusée</span>';
            const body = (p.title || p.content || 'Sans titre').slice(0, 90);
            return `<tr>
              <td>${personCell({
                id: p.author_id,
                name: p.author,
                email: p.author_email,
                role: p.author_role,
                university: p.author_university,
                faculty: p.author_faculty,
              })}</td>
              <td>${esc(body)}</td>
              <td>${esc(p.kind_display || p.kind || '—')}</td>
              <td>${chip}</td>
              <td>${esc(formatDateTime(p.created_at))}</td>
            </tr>`;
          })
          .join('')}</tbody></table>`
      : '<div class="empty">Aucune publication</div>';

    const courses = d.recent_courses || [];
    document.getElementById('recent-courses').innerHTML = courses.length
      ? `<table class="data"><thead><tr><th>Cours</th><th>Statut</th><th>Créé</th></tr></thead><tbody>${courses
          .map(
            (c) =>
              `<tr><td><a href="#/cours/${c.id}"><strong>${esc(c.title)}</strong></a><div style="color:var(--ink-soft);font-size:0.8rem">${esc(c.code || '')}</div></td><td>${esc(c.status)}</td><td>${esc(formatDateTime(c.created_at))}</td></tr>`,
          )
          .join('')}</tbody></table>`
      : '<div class="empty">Aucun cours</div>';
  } catch (e) {
    root.innerHTML = `<div class="alert alert-error">${esc(e.message)}</div>`;
  }
}
