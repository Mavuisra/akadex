import { esc, formatDate, loadTeacherCourses, statusChip } from '../utils.js';

export async function renderCourses(root) {
  root.innerHTML = `
    <div class="page-head">
      <div>
        <h1>Mes cours</h1>
        <p>Gérez, publiez et suivez vos parcours</p>
      </div>
      <div class="page-actions">
        <a class="btn btn-primary" href="#/creer">+ Créer un cours</a>
      </div>
    </div>
    <div class="toolbar">
      <input type="search" id="course-q" placeholder="Rechercher un cours…" style="flex:1;min-width:180px">
      <select id="course-status">
        <option value="">Tous les statuts</option>
        <option value="published">Publié</option>
        <option value="pending">En attente</option>
        <option value="draft">Brouillon</option>
      </select>
    </div>
    <div class="panel"><div class="panel-b table-wrap" id="courses-table"><div class="skeleton" style="height:120px"></div></div></div>
  `;

  let courses = [];
  try {
    courses = await loadTeacherCourses();
  } catch (e) {
    document.getElementById('courses-table').innerHTML =
      `<div class="alert alert-error">${esc(e.message)}</div>`;
    return;
  }

  const paint = () => {
    const q = (document.getElementById('course-q').value || '').toLowerCase();
    const st = document.getElementById('course-status').value;
    const filtered = courses.filter((c) => {
      const hay = `${c.title} ${c.code} ${c.description || ''}`.toLowerCase();
      if (q && !hay.includes(q)) return false;
      const pub = c.is_approved || c.moderation_status === 'approved';
      const pend =
        c.moderation_status === 'pending' ||
        c.moderation_status === 'changes_requested';
      if (st === 'published' && !pub) return false;
      if (st === 'pending' && !pend) return false;
      if (st === 'draft' && (pub || pend)) return false;
      return true;
    });

    if (!filtered.length) {
      document.getElementById('courses-table').innerHTML =
        '<div class="empty"><strong>Aucun cours trouvé</strong>Ajustez les filtres ou créez un nouveau cours.</div>';
      return;
    }

    document.getElementById('courses-table').innerHTML = `
      <table class="data">
        <thead>
          <tr>
            <th>Cours</th>
            <th>Niveau</th>
            <th>Statut</th>
            <th>Visites</th>
            <th>Uniques</th>
            <th>Modifié</th>
            <th>Actions</th>
          </tr>
        </thead>
        <tbody>
          ${filtered
            .map((c) => {
              const thumb = c.cover_url
                ? `<img class="course-thumb" src="${esc(c.cover_url)}" alt="">`
                : `<div class="course-thumb ph">${esc((c.title || '?')[0])}</div>`;
              return `
              <tr>
                <td>
                  <div class="course-cell">
                    ${thumb}
                    <div>
                      <strong>${esc(c.title)}</strong>
                      <div style="color:var(--ink-soft);font-size:0.8rem">${esc(c.code || '')} · ${esc((c.domain_names || []).join(', ') || c.department_name || '')}</div>
                    </div>
                  </div>
                </td>
                <td>${esc(c.semester || c.level_label || '—')}</td>
                <td>${statusChip(c)}</td>
                <td>${c.views ?? 0}</td>
                <td>${c.unique_visitors ?? 0}</td>
                <td>${esc(formatDate(c.updated_at))}</td>
                <td>
                  <div class="row-actions">
                    <a class="btn btn-secondary" href="#/cours/${c.id}">Gérer</a>
                    <a class="btn btn-ghost" href="/api/course-outlines/${c.id}/" target="_blank" rel="noopener">Aperçu</a>
                  </div>
                </td>
              </tr>`;
            })
            .join('')}
        </tbody>
      </table>`;
  };

  document.getElementById('course-q').addEventListener('input', paint);
  document.getElementById('course-status').addEventListener('change', paint);
  paint();
}
