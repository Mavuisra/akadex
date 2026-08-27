import { api, unwrapList } from '../api.js';
import { confirmDelete, esc, formatDateTime, toast } from '../utils.js';

function modChip(c) {
  const st = c.moderation_status || (c.is_approved ? 'approved' : 'pending');
  const map = {
    approved: ['chip-ok', 'Publié'],
    pending: ['chip-wait', 'En attente'],
    changes_requested: ['chip-draft', 'Brouillon'],
    rejected: ['chip-draft', 'Refusé'],
  };
  const [cls, label] = map[st] || ['chip-draft', st];
  return `<span class="chip ${cls}">${esc(label)}</span>`;
}

export async function renderCourses(root, courseId = null) {
  if (courseId) return renderCourseDetail(root, courseId);

  root.innerHTML = `
    <div class="page-head">
      <div><h1>Cours</h1></div>
      <div class="page-actions"><button class="btn btn-primary" type="button" id="btn-add">+ Ajouter</button></div>
    </div>
    <div class="toolbar">
      <input type="search" id="q" placeholder="Titre, code…" style="flex:1;min-width:160px">
      <select id="status">
        <option value="">Tous</option>
        <option value="approved">Publiés</option>
        <option value="pending">En attente</option>
        <option value="changes_requested">Brouillon</option>
        <option value="rejected">Refusés</option>
      </select>
    </div>
    <div class="panel"><div class="panel-b table-wrap" id="table"><div class="skeleton" style="height:120px"></div></div></div>
    <dialog class="admin-dialog" id="dlg" style="width:min(560px,94vw)">
      <form method="dialog" id="form">
        <h2>Cours</h2>
        <input type="hidden" name="id">
        <div class="form-grid">
          <div class="field full"><label>Titre</label><input name="title" required></div>
          <div class="field"><label>Code</label><input name="code"></div>
          <div class="field"><label>Enseignant (nom)</label><input name="teacher_name"></div>
          <div class="field full"><label>Description</label><textarea name="description" rows="3"></textarea></div>
        </div>
        <div id="form-err"></div>
        <div class="admin-dialog-actions">
          <button class="btn btn-secondary" value="cancel" type="submit">Annuler</button>
          <button class="btn btn-primary" value="default" type="submit">Enregistrer</button>
        </div>
      </form>
    </dialog>
  `;

  const load = async () => {
    const q = document.getElementById('q').value.trim();
    const st = document.getElementById('status').value;
    const params = new URLSearchParams({ page_size: '50' });
    if (q) params.set('search', q);
    if (st) params.set('moderation_status', st);
    try {
      const data = await api(`courses/?${params}`);
      const rows = unwrapList(data);
      if (!rows.length) {
        document.getElementById('table').innerHTML =
          '<div class="empty"><strong>Aucun cours</strong></div>';
        return;
      }
      document.getElementById('table').innerHTML = `
        <table class="data">
          <thead><tr><th>Cours</th><th>Statut</th><th>Vues</th><th>Modifié</th><th></th></tr></thead>
          <tbody>${rows
            .map(
              (c) => `
            <tr>
              <td><a href="#/cours/${c.id}"><strong>${esc(c.title)}</strong></a><div style="color:var(--ink-soft);font-size:0.8rem">${esc(c.code || '')}</div></td>
              <td>${modChip(c)}</td>
              <td>${c.views ?? 0}</td>
              <td>${esc(formatDateTime(c.updated_at))}</td>
              <td>
                <div class="row-actions">
                  <button class="btn btn-ghost btn-edit" data-id="${c.id}" type="button">Modifier</button>
                  ${
                    c.moderation_status === 'pending'
                      ? `<button class="btn btn-ghost btn-ok" data-id="${c.id}" type="button">Publier</button>`
                      : ''
                  }
                  <button class="btn btn-ghost btn-del" data-id="${c.id}" data-name="${esc(c.title)}" type="button">Supprimer</button>
                </div>
              </td>
            </tr>`,
            )
            .join('')}</tbody></table>`;

      root.querySelectorAll('.btn-edit').forEach((b) =>
        b.addEventListener('click', () => openForm(b.dataset.id)),
      );
      root.querySelectorAll('.btn-ok').forEach((b) =>
        b.addEventListener('click', async () => {
          try {
            await api(`courses/${b.dataset.id}/approve/`, { method: 'POST', body: '{}' });
            toast('Cours publié');
            load();
          } catch (e) {
            toast(e.message, 'error');
          }
        }),
      );
      root.querySelectorAll('.btn-del').forEach((b) =>
        b.addEventListener('click', async () => {
          if (!(await confirmDelete(b.dataset.name))) return;
          try {
            await api(`courses/${b.dataset.id}/`, { method: 'DELETE' });
            toast('Cours supprimé');
            load();
          } catch (e) {
            toast(e.message, 'error');
          }
        }),
      );
    } catch (e) {
      document.getElementById('table').innerHTML =
        `<div class="alert alert-error">${esc(e.message)}</div>`;
    }
  };

  async function openForm(id) {
    const form = document.getElementById('form');
    form.reset();
    form.id.value = id || '';
    if (id) {
      const c = await api(`courses/${id}/`);
      form.title.value = c.title || '';
      form.code.value = c.code || '';
      form.teacher_name.value = c.teacher_name || '';
      form.description.value = c.description || '';
    }
    document.getElementById('dlg').showModal();
  }

  document.getElementById('form').addEventListener('submit', async (ev) => {
    if (ev.submitter?.value === 'cancel') return;
    ev.preventDefault();
    const form = ev.target;
    const id = form.id.value;
    const body = {
      title: form.title.value.trim(),
      code: form.code.value.trim(),
      teacher_name: form.teacher_name.value.trim(),
      description: form.description.value.trim(),
    };
    try {
      if (id) {
        await api(`courses/${id}/`, { method: 'PATCH', body: JSON.stringify(body) });
        toast('Cours mis à jour');
      } else {
        await api('courses/', { method: 'POST', body: JSON.stringify(body) });
        toast('Cours créé');
      }
      document.getElementById('dlg').close();
      load();
    } catch (e) {
      document.getElementById('form-err').innerHTML =
        `<div class="alert alert-error">${esc(e.message)}</div>`;
    }
  });

  document.getElementById('btn-add').addEventListener('click', () => openForm());
  document.getElementById('q').addEventListener('input', () => {
    clearTimeout(window.__cTimer);
    window.__cTimer = setTimeout(load, 300);
  });
  document.getElementById('status').addEventListener('change', load);
  load();
}

async function renderCourseDetail(root, id) {
  root.innerHTML = `<div class="page-head"><div><h1>Cours</h1></div><div class="page-actions"><a class="btn btn-secondary" href="#/cours">← Liste</a></div></div><div id="body"><div class="skeleton" style="height:160px"></div></div>`;
  try {
    const [c, outline] = await Promise.all([
      api(`courses/${id}/`),
      api(`course-outlines/${id}/`).catch(() => null),
    ]);
    const modules = outline?.modules || [];
    document.getElementById('body').innerHTML = `
      <div class="grid-stats">
        <div class="stat-card"><div class="label">Statut</div><div class="value" style="font-size:1rem">${modChip(c)}</div></div>
        <div class="stat-card"><div class="label">Vues</div><div class="value">${c.views ?? 0}</div></div>
        <div class="stat-card"><div class="label">Uniques</div><div class="value">${c.unique_visitors ?? 0}</div></div>
        <div class="stat-card"><div class="label">Modules</div><div class="value">${modules.length}</div></div>
      </div>
      <div class="panel"><div class="panel-h"><h2>${esc(c.title)}</h2>
        <div>
          ${c.moderation_status === 'pending' ? `<button class="btn btn-primary" id="approve" type="button">Publier</button>` : ''}
          <button class="btn btn-secondary" id="reject" type="button">Refuser</button>
        </div>
      </div>
      <div class="panel-b">
        <p>${esc(c.description || 'Pas de description')}</p>
        <p style="color:var(--ink-soft)">Code ${esc(c.code || '—')} · ${esc(c.teacher_name || '')}</p>
      </div></div>
      <div class="panel"><div class="panel-h"><h2>Structure</h2></div><div class="panel-b">
        ${
          modules.length
            ? modules
                .map(
                  (m, i) => `
          <div style="margin-bottom:12px">
            <strong>Module ${i + 1} — ${esc(m.title)}</strong>
            <ul>${(m.lessons || []).map((l) => `<li>${esc(l.title)} <span style="color:var(--ink-soft)">(${esc(l.content_type)})</span></li>`).join('') || '<li>Aucune leçon</li>'}</ul>
          </div>`,
                )
                .join('')
            : '<div class="empty">Aucun module</div>'
        }
      </div></div>`;
    document.getElementById('approve')?.addEventListener('click', async () => {
      await api(`courses/${id}/approve/`, { method: 'POST', body: '{}' });
      toast('Publié');
      renderCourseDetail(root, id);
    });
    document.getElementById('reject')?.addEventListener('click', async () => {
      const note = window.prompt('Motif du refus ?') || '';
      await api(`courses/${id}/reject/`, {
        method: 'POST',
        body: JSON.stringify({ note }),
      });
      toast('Refusé');
      renderCourseDetail(root, id);
    });
  } catch (e) {
    document.getElementById('body').innerHTML =
      `<div class="alert alert-error">${esc(e.message)}</div>`;
  }
}
