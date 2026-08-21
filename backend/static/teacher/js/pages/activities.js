/**
 * Activités des étudiants — données réelles depuis Apprendre (mobile).
 * API : GET courses/teacher_activities/ + teacher_students/:id/
 */
import { api } from '../api.js';
import { esc, formatDateTime, initials, loadTeacherCourses } from '../utils.js';

const POLL_MS = 25000;

function eventChip(type) {
  const map = {
    course_opened: ['chip-info', 'Cours'],
    content_opened: ['chip-info', 'Contenu'],
    video_started: ['chip-info', 'Vidéo'],
    video_progress: ['chip-wait', 'Progression'],
    video_completed: ['chip-ok', 'Vidéo OK'],
    lesson_completed: ['chip-ok', 'Leçon OK'],
    document_opened: ['chip-info', 'Document'],
    course_commented: ['chip-draft', 'Commentaire'],
  };
  const [cls, label] = map[type] || ['chip-draft', type || '—'];
  return `<span class="chip ${cls}">${esc(label)}</span>`;
}

function timelineHtml(rows) {
  if (!rows.length) {
    return `<div class="empty">
      <strong>Aucune activité étudiante pour l’instant</strong>
      Les lignes ici viennent uniquement de l’app mobile <em>Apprendre</em>
      (ouverture de cours, vidéo, leçon terminée…).<br>
      Dès qu’un vrai étudiant consulte un de vos cours, l’activité apparaît ici automatiquement.
    </div>`;
  }
  return `<div class="timeline">${rows
    .map(
      (a) => `
    <div class="timeline-item" data-student="${esc(a.student_id)}" data-course="${esc(a.course_id)}">
      <div><div class="timeline-dot"></div></div>
      <div>
        <div style="display:flex;gap:8px;align-items:center;flex-wrap:wrap;margin-bottom:4px">
          ${eventChip(a.event_type)}
          <strong>${esc(a.title || '')}</strong>
        </div>
        <p>${esc(a.message || '')}</p>
        <time>${esc(formatDateTime(a.created_at))}</time>
        <div style="margin-top:8px;display:flex;gap:8px;flex-wrap:wrap">
          <a class="btn btn-ghost" href="#/etudiants/${a.student_id}">Voir l’étudiant</a>
          ${a.course_id ? `<a class="btn btn-ghost" href="#/cours/${a.course_id}">Cours</a>` : ''}
        </div>
      </div>
    </div>`,
    )
    .join('')}</div>`;
}

function tableHtml(rows) {
  if (!rows.length) {
    return `<div class="empty">
      <strong>Tableau vide</strong>
      Pas encore d’action réelle enregistrée sur vos cours.
    </div>`;
  }
  return `
    <table class="data">
      <thead>
        <tr>
          <th>Étudiant</th>
          <th>Activité</th>
          <th>Cours</th>
          <th>Contenu</th>
          <th>Date</th>
        </tr>
      </thead>
      <tbody>
        ${rows
          .map(
            (a) => `
          <tr>
            <td>
              <a href="#/etudiants/${a.student_id}" style="display:flex;gap:10px;align-items:center;text-decoration:none;color:inherit">
                <div class="av" style="width:32px;height:32px;font-size:0.75rem">${esc(initials(a.student_name))}</div>
                <div>
                  <strong>${esc(a.student_name)}</strong>
                  <div style="color:var(--ink-soft);font-size:0.8rem">${esc(a.student_email || '')}</div>
                </div>
              </a>
            </td>
            <td>${eventChip(a.event_type)}</td>
            <td>${esc(a.course_title || '—')}</td>
            <td>${esc(a.content_label || a.lesson_title || '—')}</td>
            <td>${esc(formatDateTime(a.created_at))}</td>
          </tr>`,
          )
          .join('')}
      </tbody>
    </table>`;
}

export async function renderActivities(root) {
  let pollTimer = null;
  let eventTypes = [];

  root.innerHTML = `
    <div class="page-head">
      <div>
        <h1>Activités des étudiants</h1>
        <p>Données réelles uniquement — actions effectuées dans Apprendre (mobile)</p>
      </div>
      <div class="page-actions">
        <button type="button" class="btn btn-secondary" id="act-refresh">Actualiser</button>
      </div>
    </div>
    <div class="toolbar" id="act-filters">
      <input type="search" id="act-q" placeholder="Rechercher étudiant, cours, leçon…" style="flex:1;min-width:160px">
      <select id="act-course"><option value="">Tous les cours</option></select>
      <select id="act-type"><option value="">Tous les types</option></select>
      <select id="act-period">
        <option value="">Toute période</option>
        <option value="1">Dernières 24 h</option>
        <option value="7" selected>7 derniers jours</option>
        <option value="30">30 derniers jours</option>
      </select>
    </div>
    <div class="grid-2">
      <div class="panel">
        <div class="panel-h"><h2>Timeline</h2></div>
        <div class="panel-b" id="act-timeline"><div class="skeleton" style="height:160px"></div></div>
      </div>
      <div class="panel">
        <div class="panel-h"><h2>Tableau</h2></div>
        <div class="panel-b table-wrap" id="act-table"><div class="skeleton" style="height:160px"></div></div>
      </div>
    </div>
  `;

  try {
    const courses = await loadTeacherCourses();
    const sel = document.getElementById('act-course');
    courses.forEach((c) => {
      const opt = document.createElement('option');
      opt.value = c.id;
      opt.textContent = c.title;
      sel.appendChild(opt);
    });
  } catch {
    /* ignore */
  }

  const sinceIso = (days) => {
    if (!days) return '';
    const d = new Date(Date.now() - Number(days) * 86400000);
    return d.toISOString();
  };

  const load = async ({ silent = false } = {}) => {
    const q = document.getElementById('act-q')?.value.trim() || '';
    const course = document.getElementById('act-course')?.value || '';
    const type = document.getElementById('act-type')?.value || '';
    const period = document.getElementById('act-period')?.value || '';
    const params = new URLSearchParams({ limit: '80' });
    if (q) params.set('search', q);
    if (course) params.set('course', course);
    if (type) params.set('event_type', type);
    const since = sinceIso(period);
    if (since) params.set('since', since);

    if (!silent) {
      document.getElementById('act-timeline').innerHTML =
        '<div class="skeleton" style="height:120px"></div>';
    }

    try {
      const data = await api(`courses/teacher_activities/?${params}`);
      const rows = data.results || [];
      if (Array.isArray(data.event_types) && data.event_types.length) {
        eventTypes = data.event_types;
        const typeSel = document.getElementById('act-type');
        if (typeSel && typeSel.options.length <= 1) {
          eventTypes.forEach((t) => {
            const opt = document.createElement('option');
            opt.value = t.value;
            opt.textContent = t.label;
            typeSel.appendChild(opt);
          });
        }
      }
      document.getElementById('act-timeline').innerHTML = timelineHtml(rows.slice(0, 25));
      document.getElementById('act-table').innerHTML = tableHtml(rows);
    } catch (e) {
      const msg = `<div class="alert alert-error">${esc(e.message)}</div>`;
      document.getElementById('act-timeline').innerHTML = msg;
      document.getElementById('act-table').innerHTML = msg;
    }
  };

  const bind = () => {
    document.getElementById('act-refresh')?.addEventListener('click', () => load());
    document.getElementById('act-course')?.addEventListener('change', () => load());
    document.getElementById('act-type')?.addEventListener('change', () => load());
    document.getElementById('act-period')?.addEventListener('change', () => load());
    document.getElementById('act-q')?.addEventListener('input', () => {
      clearTimeout(window.__actTimer);
      window.__actTimer = setTimeout(() => load(), 320);
    });
  };

  bind();
  await load();

  pollTimer = setInterval(() => load({ silent: true }), POLL_MS);
  root._teardown = () => {
    if (pollTimer) clearInterval(pollTimer);
  };
}

export async function renderStudentDetail(root, studentId) {
  root.innerHTML = `
    <div class="page-head">
      <div>
        <h1>Étudiant</h1>
        <p>Activité réelle sur vos cours Apprendre</p>
      </div>
      <div class="page-actions">
        <a class="btn btn-secondary" href="#/etudiants">← Roster</a>
        <a class="btn btn-secondary" href="#/activites">Activités</a>
      </div>
    </div>
    <div id="stu-detail"><div class="skeleton" style="height:200px"></div></div>
  `;

  try {
    const data = await api(`courses/teacher_students/${studentId}/`);
    const s = data.student || {};
    const stats = data.stats || {};
    const courses = data.courses || [];
    const activities = data.activities || [];

    document.getElementById('stu-detail').innerHTML = `
      <div class="grid-stats" style="grid-template-columns:repeat(4,1fr)">
        <div class="stat-card"><div class="label">Étudiant</div><div class="value" style="font-size:1.1rem">${esc(s.name || '')}</div><div class="trend trend-flat">${esc(s.email || '')}</div></div>
        <div class="stat-card"><div class="label">Cours commencés</div><div class="value">${stats.courses_started ?? 0}</div></div>
        <div class="stat-card"><div class="label">Cours terminés</div><div class="value">${stats.courses_completed ?? 0}</div></div>
        <div class="stat-card"><div class="label">Leçons terminées</div><div class="value">${stats.lessons_completed ?? 0}</div></div>
      </div>
      <div class="grid-2">
        <div class="panel">
          <div class="panel-h"><h2>Cours suivis</h2></div>
          <div class="panel-b table-wrap">
            ${
              courses.length
                ? `<table class="data"><thead><tr><th>Cours</th><th>Progression</th><th>Statut</th><th>Dernière activité</th></tr></thead><tbody>
                ${courses
                  .map(
                    (c) => `
                  <tr>
                    <td><a href="#/cours/${c.course_id}">${esc(c.course_title)}</a></td>
                    <td>
                      <div style="font-weight:700">${c.progress_pct}%</div>
                      <div class="progress-bar"><i style="width:${c.progress_pct}%"></i></div>
                      <div style="font-size:0.75rem;color:var(--ink-soft)">${c.lessons_completed}/${c.lessons_total} leçons</div>
                    </td>
                    <td>${
                      c.status === 'completed'
                        ? '<span class="chip chip-ok">Terminé</span>'
                        : '<span class="chip chip-info">En cours</span>'
                    }</td>
                    <td>${esc(formatDateTime(c.last_activity))}</td>
                  </tr>`,
                  )
                  .join('')}
                </tbody></table>`
                : '<div class="empty"><strong>Aucun cours</strong></div>'
            }
          </div>
        </div>
        <div class="panel">
          <div class="panel-h"><h2>Derniers événements</h2></div>
          <div class="panel-b">${timelineHtml(activities)}</div>
        </div>
      </div>
    `;
  } catch (e) {
    document.getElementById('stu-detail').innerHTML =
      `<div class="alert alert-error">${esc(e.message)}</div>`;
  }
}
