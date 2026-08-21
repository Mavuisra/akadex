import { api } from '../api.js';
import { esc, formatDateTime, initials, loadTeacherCourses } from '../utils.js';

export async function renderStudents(root) {
  root.innerHTML = `
    <div class="page-head">
      <div>
        <h1>Étudiants</h1>
        <p>Apprenants inscrits à vos cours (via progression)</p>
      </div>
    </div>
    <div class="toolbar">
      <input type="search" id="stu-q" placeholder="Rechercher nom, e-mail, cours…" style="flex:1;min-width:180px">
      <select id="stu-course"><option value="">Tous les cours</option></select>
    </div>
    <div class="panel"><div class="panel-b table-wrap" id="stu-table"><div class="skeleton" style="height:120px"></div></div></div>
  `;

  try {
    const courses = await loadTeacherCourses();
    const sel = document.getElementById('stu-course');
    courses.forEach((c) => {
      const opt = document.createElement('option');
      opt.value = c.id;
      opt.textContent = c.title;
      sel.appendChild(opt);
    });
  } catch {
    /* ignore */
  }

  const load = async () => {
    const q = document.getElementById('stu-q').value.trim();
    const course = document.getElementById('stu-course').value;
    const params = new URLSearchParams();
    if (q) params.set('search', q);
    if (course) params.set('course', course);
    try {
      const data = await api(`courses/teacher_students/?${params}`);
      const rows = data.results || [];
      if (!rows.length) {
        document.getElementById('stu-table').innerHTML =
          '<div class="empty"><strong>Aucun étudiant inscrit</strong>Les apprenants ayant consulté vos leçons apparaîtront dans ce tableau.</div>';
        return;
      }
      document.getElementById('stu-table').innerHTML = `
        <table class="data">
          <thead>
            <tr>
              <th>Étudiant</th>
              <th>Cours</th>
              <th>Progression</th>
              <th>Statut</th>
              <th>Dernière activité</th>
            </tr>
          </thead>
          <tbody>
            ${rows
              .map((r) => {
                const st =
                  r.status === 'completed'
                    ? '<span class="chip chip-ok">Terminé</span>'
                    : r.status === 'active'
                      ? '<span class="chip chip-info">En cours</span>'
                      : '<span class="chip chip-draft">Nouveau</span>';
                return `
              <tr>
                <td>
                  <a href="#/etudiants/${r.user_id}" class="course-cell" style="text-decoration:none;color:inherit">
                    <div class="user-chip" style="border:none;padding:0">
                      <div class="av">${esc(initials(r.name))}</div>
                    </div>
                    <div>
                      <strong>${esc(r.name)}</strong>
                      <div style="color:var(--ink-soft);font-size:0.8rem">${esc(r.email)}</div>
                    </div>
                  </a>
                </td>
                <td>${esc(r.course_title)}</td>
                <td style="min-width:140px">
                  <div style="font-weight:700;font-size:0.85rem;margin-bottom:4px">${r.progress_pct}%</div>
                  <div class="progress-bar"><i style="width:${r.progress_pct}%"></i></div>
                  <div style="font-size:0.75rem;color:var(--ink-soft);margin-top:4px">${r.lessons_completed}/${r.lessons_touched} leçons</div>
                </td>
                <td>${st}</td>
                <td>${esc(formatDateTime(r.last_activity))}</td>
              </tr>`;
              })
              .join('')}
          </tbody>
        </table>`;
    } catch (e) {
      document.getElementById('stu-table').innerHTML =
        `<div class="alert alert-error">${esc(e.message)}</div>`;
    }
  };

  document.getElementById('stu-q').addEventListener('input', () => {
    clearTimeout(window.__stuTimer);
    window.__stuTimer = setTimeout(load, 300);
  });
  document.getElementById('stu-course').addEventListener('change', load);
  load();
}

export async function renderAnalytics(root) {
  root.innerHTML = `
    <div class="page-head">
      <div>
        <h1>Analytics</h1>
        <p>Indicateurs de performance de vos cours</p>
      </div>
    </div>
    <div id="an-body"><div class="skeleton" style="height:180px"></div></div>
  `;
  try {
    const d = await api('courses/teacher_dashboard/');
    const { barsHtml, esc: e, statusChip } = await import('../utils.js');
    document.getElementById('an-body').innerHTML = `
      <div class="grid-stats">
        <div class="stat-card"><div class="label">Étudiants</div><div class="value">${d.students ?? 0}</div><div class="trend trend-up">${d.students_active ?? 0} actifs</div></div>
        <div class="stat-card"><div class="label">Taux complétion</div><div class="value">${d.students ? Math.round((100 * (d.students_completed || 0)) / d.students) : 0}%</div><div class="trend trend-flat">${d.students_completed ?? 0} terminés</div></div>
        <div class="stat-card"><div class="label">Visites</div><div class="value">${d.views ?? 0}</div><div class="trend trend-flat">${d.unique_visitors ?? 0} uniques (HLL)</div></div>
        <div class="stat-card"><div class="label">Contenus</div><div class="value">${d.lessons ?? 0}</div><div class="trend trend-flat">${d.modules ?? 0} modules</div></div>
      </div>
      <div class="grid-2">
        <div class="panel"><div class="panel-h"><h2>Engagement 7 jours</h2></div><div class="panel-b">${barsHtml(d.activity_7d)}</div></div>
        <div class="panel"><div class="panel-h"><h2>Cours populaires</h2></div><div class="panel-b table-wrap">
          <table class="data"><thead><tr><th>Cours</th><th>Étudiants</th><th>Visites</th><th>Uniques</th></tr></thead>
          <tbody>${(d.top_courses || [])
            .map(
              (c) =>
                `<tr><td>${e(c.title)} ${statusChip(c)}</td><td>${c.students ?? 0}</td><td>${c.views ?? 0}</td><td>${c.unique_visitors ?? 0}</td></tr>`,
            )
            .join('') || '<tr><td colspan="4">Aucune donnée</td></tr>'}</tbody></table>
        </div></div>
      </div>
      <div class="alert alert-info">Période affichée : 7 derniers jours. D’autres plages temporelles seront proposées prochainement.</div>
    `;
  } catch (e) {
    document.getElementById('an-body').innerHTML =
      `<div class="alert alert-error">${esc(e.message)}</div>`;
  }
}

export async function renderRevenue(root) {
  root.innerHTML = `
    <div class="page-head">
      <div>
        <h1>Revenus</h1>
        <p>Monétisation de vos cours</p>
      </div>
    </div>
    <div class="grid-stats">
      <div class="stat-card"><div class="label">Total</div><div class="value">—</div></div>
      <div class="stat-card"><div class="label">Ce mois</div><div class="value">—</div></div>
      <div class="stat-card"><div class="label">Ventes</div><div class="value">—</div></div>
      <div class="stat-card"><div class="label">Disponible</div><div class="value">—</div></div>
    </div>
    <div class="panel">
      <div class="panel-b">
        <div class="alert alert-warn">
          <strong>Module en cours de déploiement.</strong><br>
          Les revenus, ventes et retraits seront disponibles dès l’activation de la monétisation des cours.
        </div>
        <table class="data">
          <thead><tr><th>Date</th><th>Cours</th><th>Étudiant</th><th>Montant</th><th>Statut</th></tr></thead>
          <tbody><tr><td colspan="5" style="text-align:center;color:var(--ink-soft)">Aucune transaction</td></tr></tbody>
        </table>
      </div>
    </div>
  `;
}

export async function renderNotifications(root) {
  let pollTimer = null;
  root.innerHTML = `
    <div class="page-head">
      <div>
        <h1>Notifications</h1>
        <p>Alertes pédagogiques (nouveaux étudiants, leçons terminées, commentaires)</p>
      </div>
      <div class="page-actions">
        <button class="btn btn-secondary" type="button" id="notif-refresh">Actualiser</button>
        <button class="btn btn-secondary" type="button" id="mark-all">Tout marquer lu</button>
        <a class="btn btn-primary" href="#/activites">Voir les activités</a>
      </div>
    </div>
    <div class="panel"><div class="panel-b" id="notif-list"><div class="skeleton"></div></div></div>
  `;

  const load = async ({ silent = false } = {}) => {
    if (!silent) {
      document.getElementById('notif-list').innerHTML =
        '<div class="skeleton" style="height:100px"></div>';
    }
    try {
      const data = await api('auth/notifications/');
      const { unwrapList } = await import('../api.js');
      const list = unwrapList(data);
      if (!list.length) {
        document.getElementById('notif-list').innerHTML =
          '<div class="empty"><strong>Aucune notification</strong>Les jalons étudiants (ouverture de cours, leçon terminée, commentaire) apparaîtront ici.</div>';
        return;
      }
      document.getElementById('notif-list').innerHTML = `
        <div class="timeline">
          ${list
            .map(
              (n) => `
            <div class="timeline-item" style="${n.is_read ? '' : 'background:var(--blue-mist);margin:0 -8px;padding:12px 8px;border-radius:8px'}">
              <div><div class="timeline-dot" style="${n.is_read ? 'background:var(--ink-soft);box-shadow:none' : ''}"></div></div>
              <div>
                <strong>${esc(n.title)}</strong>
                <p>${esc(n.message)}</p>
                <time>${esc(formatDateTime(n.created_at))}</time>
              </div>
            </div>`,
            )
            .join('')}
        </div>`;
    } catch (e) {
      document.getElementById('notif-list').innerHTML =
        `<div class="alert alert-error">${esc(e.message)}</div>`;
    }
  };

  document.getElementById('mark-all').addEventListener('click', async () => {
    try {
      await api('auth/notifications/mark_all_read/', { method: 'POST', body: '{}' });
      load();
    } catch (e) {
      alert(e.message);
    }
  });
  document.getElementById('notif-refresh').addEventListener('click', () => load());
  await load();
  pollTimer = setInterval(() => load({ silent: true }), 20000);
  root._teardown = () => {
    if (pollTimer) clearInterval(pollTimer);
  };
}

export async function renderProfile(root, user, onLogout) {
  root.innerHTML = `
    <div class="page-head">
      <div>
        <h1>Profil enseignant</h1>
        <p>Informations de compte</p>
      </div>
      <div class="page-actions">
        <button class="btn btn-danger" type="button" id="logout-btn">Se déconnecter</button>
      </div>
    </div>
    <div class="panel">
      <div class="panel-b form-grid">
        <div class="field"><label>Nom complet</label><input readonly value="${esc(user.full_name || user.name || `${user.first_name || ''} ${user.last_name || ''}`.trim())}"></div>
        <div class="field"><label>E-mail</label><input readonly value="${esc(user.email || '')}"></div>
        <div class="field"><label>Rôle</label><input readonly value="${esc(user.role || '')}"></div>
        <div class="field"><label>Spécialité / domaine</label><input readonly value="${esc(user.professional_domain || user.headline || '—')}"></div>
        <div class="field full"><label>Bio</label><textarea readonly>${esc(user.bio || '')}</textarea></div>
        <div class="full alert alert-info">Pour modifier votre profil, utilisez le menu Paramètres du compte.</div>
      </div>
    </div>
  `;
  document.getElementById('logout-btn').addEventListener('click', onLogout);
}
