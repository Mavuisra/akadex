/**
 * Ressources admin : domaines, modules, leçons, documents, paiements,
 * inscriptions, notifications, structure académique.
 */
import { api, unwrapList } from '../api.js';
import { confirmDelete, esc, formatDateTime, personCell, toast } from '../utils.js';

export async function renderDomains(root) {
  root.innerHTML = `
    <div class="page-head">
      <div><h1>Domaines (catégories)</h1></div>
      <div class="page-actions"><button class="btn btn-primary" type="button" id="add">+ Ajouter</button></div>
    </div>
    <div class="panel"><div class="panel-b table-wrap" id="table"></div></div>
  `;
  const load = async () => {
    try {
      const rows = unwrapList(await api('learning-domains/?page_size=100'));
      document.getElementById('table').innerHTML = rows.length
        ? `<table class="data"><thead><tr><th>Nom</th><th>Slug</th><th>Actif</th><th></th></tr></thead><tbody>${rows
            .map(
              (d) => `<tr>
              <td><strong>${esc(d.name)}</strong></td>
              <td>${esc(d.slug)}</td>
              <td>${d.is_active ? 'Oui' : 'Non'}</td>
              <td>
                <button class="btn btn-ghost btn-ed" data-id="${d.id}" type="button">Modifier</button>
                <button class="btn btn-ghost btn-del" data-id="${d.id}" data-name="${esc(d.name)}" type="button">Supprimer</button>
              </td></tr>`,
            )
            .join('')}</tbody></table>`
        : '<div class="empty">Aucun domaine</div>';
      root.querySelectorAll('.btn-ed').forEach((b) =>
        b.addEventListener('click', async () => {
          const name = window.prompt('Nouveau nom ?');
          if (!name) return;
          await api(`learning-domains/${b.dataset.id}/`, {
            method: 'PATCH',
            body: JSON.stringify({ name }),
          });
          toast('Mis à jour');
          load();
        }),
      );
      root.querySelectorAll('.btn-del').forEach((b) =>
        b.addEventListener('click', async () => {
          if (!(await confirmDelete(b.dataset.name))) return;
          await api(`learning-domains/${b.dataset.id}/`, { method: 'DELETE' });
          toast('Supprimé');
          load();
        }),
      );
    } catch (e) {
      document.getElementById('table').innerHTML =
        `<div class="alert alert-error">${esc(e.message)}</div>`;
    }
  };
  document.getElementById('add').addEventListener('click', async () => {
    const name = window.prompt('Nom du domaine ?');
    if (!name) return;
    const slug = name
      .toLowerCase()
      .normalize('NFD')
      .replace(/[\u0300-\u036f]/g, '')
      .replace(/[^a-z0-9]+/g, '-')
      .replace(/^-|-$/g, '');
    try {
      await api('learning-domains/', {
        method: 'POST',
        body: JSON.stringify({ name, slug, is_active: true }),
      });
      toast('Domaine créé');
      load();
    } catch (e) {
      toast(e.message, 'error');
    }
  });
  load();
}

export async function renderModules(root) {
  root.innerHTML = `
    <div class="page-head"><div><h1>Modules</h1></div>
      <div class="page-actions"><button class="btn btn-primary" type="button" id="add">+ Ajouter</button></div></div>
    <div class="toolbar"><input type="search" id="q" placeholder="Recherche…" style="flex:1"></div>
    <div class="panel"><div class="panel-b table-wrap" id="table"></div></div>
  `;
  const load = async () => {
    const q = document.getElementById('q').value.trim();
    const params = new URLSearchParams({ page_size: '50' });
    if (q) params.set('search', q);
    try {
      const rows = unwrapList(await api(`course-modules/?${params}`));
      document.getElementById('table').innerHTML = rows.length
        ? `<table class="data"><thead><tr><th>Titre</th><th>Cours</th><th>Ordre</th><th>Leçons</th><th></th></tr></thead><tbody>${rows
            .map(
              (m) => `<tr>
              <td><strong>${esc(m.title)}</strong></td>
              <td>${esc(m.course_title || m.course)}</td>
              <td>${m.order ?? 0}</td>
              <td>${m.lessons_count ?? (m.lessons || []).length}</td>
              <td>
                <button class="btn btn-ghost btn-ed" data-id="${m.id}" type="button">Modifier</button>
                <button class="btn btn-ghost btn-del" data-id="${m.id}" type="button">Supprimer</button>
              </td></tr>`,
            )
            .join('')}</tbody></table>`
        : '<div class="empty">Aucun module</div>';
      root.querySelectorAll('.btn-ed').forEach((b) =>
        b.addEventListener('click', async () => {
          const title = window.prompt('Nouveau titre ?');
          if (!title) return;
          await api(`course-modules/${b.dataset.id}/`, {
            method: 'PATCH',
            body: JSON.stringify({ title }),
          });
          toast('Mis à jour');
          load();
        }),
      );
      root.querySelectorAll('.btn-del').forEach((b) =>
        b.addEventListener('click', async () => {
          if (!(await confirmDelete('ce module'))) return;
          await api(`course-modules/${b.dataset.id}/`, { method: 'DELETE' });
          toast('Supprimé');
          load();
        }),
      );
    } catch (e) {
      document.getElementById('table').innerHTML =
        `<div class="alert alert-error">${esc(e.message)}</div>`;
    }
  };
  document.getElementById('add').addEventListener('click', async () => {
    const course = window.prompt('ID du cours ?');
    const title = window.prompt('Titre du module ?');
    if (!course || !title) return;
    try {
      await api('course-modules/', {
        method: 'POST',
        body: JSON.stringify({ course: Number(course), title, order: 0 }),
      });
      toast('Module créé');
      load();
    } catch (e) {
      toast(e.message, 'error');
    }
  });
  document.getElementById('q').addEventListener('input', () => {
    clearTimeout(window.__mTimer);
    window.__mTimer = setTimeout(load, 300);
  });
  load();
}

export async function renderLessons(root) {
  root.innerHTML = `
    <div class="page-head"><div><h1>Leçons</h1></div>
      <div class="page-actions"><button class="btn btn-primary" type="button" id="add">+ Ajouter</button></div></div>
    <div class="toolbar"><input type="search" id="q" placeholder="Recherche…" style="flex:1"></div>
    <div class="panel"><div class="panel-b table-wrap" id="table"></div></div>
  `;
  const load = async () => {
    const q = document.getElementById('q').value.trim();
    const params = new URLSearchParams({ page_size: '50' });
    if (q) params.set('search', q);
    try {
      const rows = unwrapList(await api(`course-lessons/?${params}`));
      document.getElementById('table').innerHTML = rows.length
        ? `<table class="data"><thead><tr><th>Titre</th><th>Type</th><th>Module</th><th>Publié</th><th></th></tr></thead><tbody>${rows
            .map(
              (l) => `<tr>
              <td><strong>${esc(l.title)}</strong>
                ${l.video_url ? `<div style="font-size:0.75rem;color:var(--ink-soft);max-width:280px;overflow:hidden;text-overflow:ellipsis">${esc(l.video_url)}</div>` : ''}
              </td>
              <td>${esc(l.content_type)}</td>
              <td>${esc(l.module)}</td>
              <td>${l.is_published ? 'Oui' : 'Non'}</td>
              <td>
                <button class="btn btn-ghost btn-ed" data-id="${l.id}" type="button">Modifier</button>
                <button class="btn btn-ghost btn-del" data-id="${l.id}" type="button">Supprimer</button>
              </td></tr>`,
            )
            .join('')}</tbody></table>`
        : '<div class="empty">Aucune leçon</div>';
      root.querySelectorAll('.btn-ed').forEach((b) =>
        b.addEventListener('click', async () => {
          const title = window.prompt('Nouveau titre ?');
          if (!title) return;
          await api(`course-lessons/${b.dataset.id}/`, {
            method: 'PATCH',
            body: JSON.stringify({ title }),
          });
          toast('Mis à jour');
          load();
        }),
      );
      root.querySelectorAll('.btn-del').forEach((b) =>
        b.addEventListener('click', async () => {
          if (!(await confirmDelete('cette leçon'))) return;
          await api(`course-lessons/${b.dataset.id}/`, { method: 'DELETE' });
          toast('Supprimée');
          load();
        }),
      );
    } catch (e) {
      document.getElementById('table').innerHTML =
        `<div class="alert alert-error">${esc(e.message)}</div>`;
    }
  };
  document.getElementById('add').addEventListener('click', async () => {
    const moduleId = window.prompt('ID du module ?');
    const title = window.prompt('Titre de la leçon ?');
    const video = window.prompt('Lien vidéo (optionnel) ?') || '';
    if (!moduleId || !title) return;
    try {
      await api('course-lessons/', {
        method: 'POST',
        body: JSON.stringify({
          module: Number(moduleId),
          title,
          content_type: 'video',
          video_url: video,
          order: 0,
          is_published: true,
        }),
      });
      toast('Leçon créée');
      load();
    } catch (e) {
      toast(e.message, 'error');
    }
  });
  document.getElementById('q').addEventListener('input', () => {
    clearTimeout(window.__lTimer);
    window.__lTimer = setTimeout(load, 300);
  });
  load();
}

export async function renderDocuments(root) {
  root.innerHTML = `
    <div class="page-head"><div><h1>Documents</h1></div></div>
    <div class="toolbar">
      <input type="search" id="q" placeholder="Titre…" style="flex:1">
      <select id="st"><option value="">Tous</option><option value="pending_admin">En attente admin</option><option value="pending_peers">Pairs</option><option value="approved">Approuvés</option></select>
    </div>
    <div class="panel"><div class="panel-b table-wrap" id="table"></div></div>
  `;
  const load = async () => {
    const params = new URLSearchParams({ page_size: '40' });
    const q = document.getElementById('q').value.trim();
    const st = document.getElementById('st').value;
    if (q) params.set('search', q);
    if (st) params.set('moderation_status', st);
    try {
      const rows = unwrapList(await api(`documents/?${params}`));
      document.getElementById('table').innerHTML = rows.length
        ? `<table class="data"><thead><tr><th>Titre</th><th>Statut</th><th>Vues</th><th></th></tr></thead><tbody>${rows
            .map(
              (d) => `<tr>
              <td><strong>${esc(d.title)}</strong></td>
              <td>${esc(d.moderation_status || '—')}</td>
              <td>${d.views ?? 0}</td>
              <td>
                ${d.moderation_status === 'pending_admin' || d.moderation_status === 'pending' ? `<button class="btn btn-ghost btn-ok" data-id="${d.id}" type="button">Approuver</button>` : ''}
                <button class="btn btn-ghost btn-del" data-id="${d.id}" type="button">Supprimer</button>
              </td></tr>`,
            )
            .join('')}</tbody></table>`
        : '<div class="empty">Aucun document</div>';
      root.querySelectorAll('.btn-ok').forEach((b) =>
        b.addEventListener('click', async () => {
          await api(`documents/${b.dataset.id}/approve/`, {
            method: 'POST',
            body: '{}',
          });
          toast('Approuvé');
          load();
        }),
      );
      root.querySelectorAll('.btn-del').forEach((b) =>
        b.addEventListener('click', async () => {
          if (!(await confirmDelete('ce document'))) return;
          await api(`documents/${b.dataset.id}/`, { method: 'DELETE' });
          toast('Supprimé');
          load();
        }),
      );
    } catch (e) {
      document.getElementById('table').innerHTML =
        `<div class="alert alert-error">${esc(e.message)}</div>`;
    }
  };
  document.getElementById('q').addEventListener('input', () => {
    clearTimeout(window.__dTimer);
    window.__dTimer = setTimeout(load, 300);
  });
  document.getElementById('st').addEventListener('change', load);
  load();
}

export async function renderPayments(root) {
  root.innerHTML = `
    <div class="page-head"><div><h1>Paiements</h1></div></div>
    <div class="toolbar">
      <select id="st"><option value="">Tous</option><option value="COMPLETED">Terminés</option><option value="PENDING">En attente</option><option value="FAILED">Échoués</option></select>
    </div>
    <div class="panel"><div class="panel-b table-wrap" id="table"></div></div>
  `;
  const load = async () => {
    const params = new URLSearchParams({ page_size: '50' });
    const st = document.getElementById('st').value;
    if (st) params.set('status', st);
    try {
      const rows = unwrapList(await api(`auth/admin/deposits/?${params}`));
      document.getElementById('table').innerHTML = rows.length
        ? `<table class="data"><thead><tr><th>ID</th><th>Étudiant</th><th>Montant</th><th>Statut</th><th>Date</th></tr></thead><tbody>${rows
            .map(
              (p) => `<tr>
              <td style="font-size:0.75rem">${esc(String(p.deposit_id).slice(0, 8))}…</td>
              <td>${esc(p.user_name || p.user_email || '—')}</td>
              <td>${esc(p.amount)} ${esc(p.currency)}</td>
              <td>${esc(p.status)}</td>
              <td>${esc(formatDateTime(p.created_at))}</td>
            </tr>`,
            )
            .join('')}</tbody></table>`
        : '<div class="empty">Aucun paiement</div>';
    } catch (e) {
      document.getElementById('table').innerHTML =
        `<div class="alert alert-error">${esc(e.message)}</div>`;
    }
  };
  document.getElementById('st').addEventListener('change', load);
  load();
}

export async function renderEnrollments(root) {
  root.innerHTML = `
    <div class="page-head"><div><h1>Inscriptions</h1></div></div>
    <div class="toolbar"><input type="search" id="q" placeholder="Étudiant ou cours…" style="flex:1"></div>
    <div class="panel"><div class="panel-b table-wrap" id="table"></div></div>
  `;
  const load = async () => {
    const q = document.getElementById('q').value.trim();
    const params = new URLSearchParams();
    if (q) params.set('search', q);
    try {
      const data = await api(`auth/admin/enrollments/?${params}`);
      const rows = data.results || [];
      document.getElementById('table').innerHTML = rows.length
        ? `<table class="data"><thead><tr><th>Étudiant</th><th>Cours</th><th>Progression</th><th>Dernière activité</th></tr></thead><tbody>${rows
            .map(
              (r) => `<tr>
              <td><strong>${esc(r.student_name)}</strong><div style="font-size:0.8rem;color:var(--ink-soft)">${esc(r.student_email)}</div></td>
              <td>${esc(r.course_title)}</td>
              <td>${r.progress_pct}% (${r.lessons_completed}/${r.lessons_touched})</td>
              <td>${esc(formatDateTime(r.last_activity))}</td>
            </tr>`,
            )
            .join('')}</tbody></table>`
        : '<div class="empty">Aucune inscription détectée</div>';
    } catch (e) {
      document.getElementById('table').innerHTML =
        `<div class="alert alert-error">${esc(e.message)}</div>`;
    }
  };
  document.getElementById('q').addEventListener('input', () => {
    clearTimeout(window.__eTimer);
    window.__eTimer = setTimeout(load, 300);
  });
  load();
}

export async function renderNotifications(root) {
  root.innerHTML = `
    <div class="page-head">
      <div><h1>Notifications</h1></div>
    </div>
    <div class="panel"><div class="panel-h"><h2>Envoyer</h2></div><div class="panel-b">
      <form id="form" class="form-grid">
        <div class="field full"><label>Titre</label><input name="title" required></div>
        <div class="field full"><label>Message</label><textarea name="message" rows="3" required></textarea></div>
        <div class="field"><label>Cible</label>
          <select name="role">
            <option value="">Tous les actifs</option>
            <option value="student">Étudiants</option>
            <option value="teacher">Enseignants</option>
            <option value="alumni">Alumni</option>
          </select>
        </div>
        <div class="full" style="text-align:right"><button class="btn btn-primary" type="submit">Envoyer</button></div>
      </form>
    </div></div>
    <div class="panel"><div class="panel-h"><h2>Récentes</h2></div><div class="panel-b" id="list"></div></div>
  `;
  const load = async () => {
    try {
      const data = await api('auth/admin/notifications/?page_size=30');
      const rows = unwrapList(data);
      document.getElementById('list').innerHTML = rows.length
        ? `<div class="timeline">${rows
            .map(
              (n) => `<div class="timeline-item"><div><div class="timeline-dot"></div></div><div>
              <strong>${esc(n.title)}</strong>
              <p>${esc(n.message)}</p>
              <time>${esc(n.user_name || n.user_email)} · ${esc(formatDateTime(n.created_at))}</time>
            </div></div>`,
            )
            .join('')}</div>`
        : '<div class="empty">Aucune notification</div>';
    } catch (e) {
      document.getElementById('list').innerHTML =
        `<div class="alert alert-error">${esc(e.message)}</div>`;
    }
  };
  document.getElementById('form').addEventListener('submit', async (ev) => {
    ev.preventDefault();
    const fd = new FormData(ev.target);
    try {
      const res = await api('auth/admin/notifications/', {
        method: 'POST',
        body: JSON.stringify({
          title: fd.get('title'),
          message: fd.get('message'),
          role: fd.get('role') || '',
        }),
      });
      toast(`${res.created} notification(s) créée(s)`);
      ev.target.reset();
      load();
    } catch (e) {
      toast(e.message, 'error');
    }
  });
  load();
}

function toSlug(name) {
  return String(name || '')
    .toLowerCase()
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-|-$/g, '')
    .slice(0, 80);
}

export async function renderStructure(root) {
  let unis = [];
  let facs = [];
  let selectedUniId = null;
  let uniQuery = '';
  let facQuery = '';

  root.innerHTML = `
    <div class="page-head">
      <div>
        <h1>Structure académique</h1>
      </div>
    </div>
    <div class="struct-stats" id="struct-stats">
      <div class="struct-stat"><div class="k">Universités</div><div class="v">—</div></div>
      <div class="struct-stat"><div class="k">Facultés</div><div class="v">—</div></div>
      <div class="struct-stat"><div class="k">Suggestions</div><div class="v">—</div></div>
    </div>
    <div class="struct-grid">
      <section class="struct-panel">
        <div class="panel-h">
          <h2>Universités</h2>
          <button class="btn btn-primary btn-icon" type="button" id="add-uni" title="Ajouter">+</button>
        </div>
        <div class="struct-toolbar">
          <input type="search" id="uni-q" placeholder="Rechercher une université…">
        </div>
        <div class="struct-list" id="unis"><div class="skeleton" style="height:80px;margin:8px"></div></div>
      </section>
      <section class="struct-panel">
        <div class="panel-h">
          <h2 id="fac-title">Facultés</h2>
          <button class="btn btn-primary btn-icon" type="button" id="add-fac" title="Ajouter" disabled>+</button>
        </div>
        <div class="struct-toolbar">
          <input type="search" id="fac-q" placeholder="Filtrer les facultés…" disabled>
        </div>
        <div class="struct-list" id="facs">
          <div class="struct-hint"><strong>Sélectionnez une université</strong>Les facultés s’affichent ici.</div>
        </div>
      </section>
    </div>

    <dialog class="admin-dialog" id="dlg-uni">
      <form method="dialog" id="form-uni">
        <h2 id="dlg-uni-title">Université</h2>
        <input type="hidden" name="id">
        <div class="form-grid">
          <div class="field full"><label>Nom</label><input name="name" required maxlength="255"></div>
          <div class="field"><label>Slug</label><input name="slug" maxlength="80" placeholder="auto"></div>
          <div class="field"><label>Ville</label><input name="city" maxlength="100"></div>
          <div class="field"><label>Pays</label><input name="country" value="RD Congo" maxlength="100"></div>
          <div class="field"><label>Couleur</label><input name="primary_color" type="color" value="#1a47b8"></div>
          <div class="field full"><label>Description</label><textarea name="description" rows="3"></textarea></div>
          <div class="field"><label><input type="checkbox" name="is_active" checked> Active</label></div>
          <div class="field"><label><input type="checkbox" name="is_verified" checked> Vérifiée</label></div>
        </div>
        <div id="uni-err"></div>
        <div class="admin-dialog-actions">
          <button class="btn btn-secondary" value="cancel" type="submit">Annuler</button>
          <button class="btn btn-primary" value="default" type="submit">Enregistrer</button>
        </div>
      </form>
    </dialog>

    <dialog class="admin-dialog" id="dlg-fac">
      <form method="dialog" id="form-fac">
        <h2 id="dlg-fac-title">Faculté</h2>
        <input type="hidden" name="id">
        <div class="form-grid">
          <div class="field full"><label>Université</label>
            <select name="university" id="fac-uni" required></select>
          </div>
          <div class="field full"><label>Nom</label><input name="name" required maxlength="255"></div>
          <div class="field"><label>Slug</label><input name="slug" maxlength="80" placeholder="auto"></div>
          <div class="field"><label><input type="checkbox" name="is_verified" checked> Vérifiée</label></div>
          <div class="field full"><label>Description</label><textarea name="description" rows="3"></textarea></div>
        </div>
        <div id="fac-err"></div>
        <div class="admin-dialog-actions">
          <button class="btn btn-secondary" value="cancel" type="submit">Annuler</button>
          <button class="btn btn-primary" value="default" type="submit">Enregistrer</button>
        </div>
      </form>
    </dialog>
  `;

  const dlgUni = document.getElementById('dlg-uni');
  const formUni = document.getElementById('form-uni');
  const dlgFac = document.getElementById('dlg-fac');
  const formFac = document.getElementById('form-fac');

  const selectedUni = () => unis.find((u) => String(u.id) === String(selectedUniId)) || null;

  const updateStats = () => {
    const pending =
      unis.filter((u) => !u.is_verified).length + facs.filter((f) => !f.is_verified).length;
    document.getElementById('struct-stats').innerHTML = `
      <div class="struct-stat"><div class="k">Universités</div><div class="v">${unis.length}</div></div>
      <div class="struct-stat"><div class="k">Facultés</div><div class="v">${facs.length}</div></div>
      <div class="struct-stat"><div class="k">Suggestions</div><div class="v">${pending}</div></div>`;
  };

  const fillFacUniSelect = (preferId) => {
    const sel = document.getElementById('fac-uni');
    sel.innerHTML = unis
      .map(
        (u) =>
          `<option value="${u.id}" ${String(u.id) === String(preferId) ? 'selected' : ''}>${esc(u.name)}</option>`,
      )
      .join('');
  };

  const renderUnis = () => {
    const q = uniQuery.trim().toLowerCase();
    const rows = unis.filter(
      (u) =>
        !q ||
        (u.name || '').toLowerCase().includes(q) ||
        (u.city || '').toLowerCase().includes(q) ||
        (u.slug || '').toLowerCase().includes(q),
    );
    const box = document.getElementById('unis');
    if (!rows.length) {
      box.innerHTML = `<div class="struct-hint"><strong>Aucune université</strong>${
        uniQuery ? 'Aucun résultat pour cette recherche.' : 'Ajoutez la première avec +.'
      }</div>`;
      return;
    }
    box.innerHTML = rows
      .map((u) => {
        const sel = String(u.id) === String(selectedUniId);
        const color = u.primary_color || '#1a47b8';
        return `<div class="struct-item ${sel ? 'is-selected' : ''}" data-id="${u.id}" role="button" tabindex="0">
          <div class="meta">
            <strong><span class="struct-dot" style="background:${esc(color)}"></span>${esc(u.name)}</strong>
            <div class="sub">
              ${u.city ? `<span>${esc(u.city)}</span>` : ''}
              ${u.is_verified ? '<span class="chip chip-ok">Vérifiée</span>' : '<span class="chip chip-wait">Suggestion</span>'}
              ${u.is_active === false ? '<span class="chip chip-draft">Inactive</span>' : ''}
            </div>
          </div>
          <div class="actions">
            <button class="btn btn-ghost btn-ed-uni" data-id="${u.id}" type="button">Modifier</button>
            <button class="btn btn-ghost btn-del-uni" data-id="${u.id}" data-name="${esc(u.name)}" type="button">Supprimer</button>
          </div>
        </div>`;
      })
      .join('');

    box.querySelectorAll('.struct-item').forEach((el) => {
      el.addEventListener('click', (ev) => {
        if (ev.target.closest('.actions')) return;
        selectedUniId = el.dataset.id;
        renderUnis();
        renderFacs();
      });
      el.addEventListener('keydown', (ev) => {
        if (ev.key === 'Enter' || ev.key === ' ') {
          ev.preventDefault();
          selectedUniId = el.dataset.id;
          renderUnis();
          renderFacs();
        }
      });
    });
    box.querySelectorAll('.btn-ed-uni').forEach((b) =>
      b.addEventListener('click', (ev) => {
        ev.stopPropagation();
        openUniForm(b.dataset.id);
      }),
    );
    box.querySelectorAll('.btn-del-uni').forEach((b) =>
      b.addEventListener('click', async (ev) => {
        ev.stopPropagation();
        if (!(await confirmDelete(b.dataset.name))) return;
        try {
          await api(`universities/${b.dataset.id}/`, { method: 'DELETE' });
          toast('Université supprimée');
          if (String(selectedUniId) === String(b.dataset.id)) selectedUniId = null;
          await load();
        } catch (e) {
          toast(e.message, 'error');
        }
      }),
    );
  };

  const renderFacs = () => {
    const uni = selectedUni();
    const addBtn = document.getElementById('add-fac');
    const facQ = document.getElementById('fac-q');
    const title = document.getElementById('fac-title');
    addBtn.disabled = !uni;
    facQ.disabled = !uni;

    if (!uni) {
      title.textContent = 'Facultés';
      document.getElementById('facs').innerHTML =
        '<div class="struct-hint"><strong>Sélectionnez une université</strong>Les facultés s’affichent ici.</div>';
      return;
    }

    title.textContent = `Facultés — ${uni.name}`;
    const q = facQuery.trim().toLowerCase();
    const rows = facs.filter(
      (f) =>
        String(f.university) === String(uni.id) &&
        (!q || (f.name || '').toLowerCase().includes(q) || (f.slug || '').toLowerCase().includes(q)),
    );
    const box = document.getElementById('facs');
    if (!rows.length) {
      box.innerHTML = `<div class="struct-hint"><strong>Aucune faculté</strong>${
        facQuery ? 'Aucun résultat.' : 'Ajoutez une faculté avec +.'
      }</div>`;
      return;
    }
    box.innerHTML = rows
      .map(
        (f) => `<div class="struct-item" data-id="${f.id}">
          <div class="meta">
            <strong>${esc(f.name)}</strong>
            <div class="sub">
              <span>${esc(f.slug || '')}</span>
              ${f.is_verified ? '<span class="chip chip-ok">Vérifiée</span>' : '<span class="chip chip-wait">Suggestion</span>'}
            </div>
          </div>
          <div class="actions">
            <button class="btn btn-ghost btn-ed-fac" data-id="${f.id}" type="button">Modifier</button>
            <button class="btn btn-ghost btn-del-fac" data-id="${f.id}" data-name="${esc(f.name)}" type="button">Supprimer</button>
          </div>
        </div>`,
      )
      .join('');

    box.querySelectorAll('.btn-ed-fac').forEach((b) =>
      b.addEventListener('click', () => openFacForm(b.dataset.id)),
    );
    box.querySelectorAll('.btn-del-fac').forEach((b) =>
      b.addEventListener('click', async () => {
        if (!(await confirmDelete(b.dataset.name))) return;
        try {
          await api(`faculties/${b.dataset.id}/`, { method: 'DELETE' });
          toast('Faculté supprimée');
          await load();
        } catch (e) {
          toast(e.message, 'error');
        }
      }),
    );
  };

  const openUniForm = (id = null) => {
    formUni.reset();
    document.getElementById('uni-err').innerHTML = '';
    const u = id ? unis.find((x) => String(x.id) === String(id)) : null;
    document.getElementById('dlg-uni-title').textContent = u
      ? 'Modifier l’université'
      : 'Nouvelle université';
    formUni.id.value = u?.id || '';
    formUni.name.value = u?.name || '';
    formUni.slug.value = u?.slug || '';
    formUni.city.value = u?.city || '';
    formUni.country.value = u?.country || 'RD Congo';
    formUni.primary_color.value = u?.primary_color || '#1a47b8';
    formUni.description.value = u?.description || '';
    formUni.is_active.checked = u ? u.is_active !== false : true;
    formUni.is_verified.checked = u ? u.is_verified !== false : true;
    dlgUni.showModal();
    formUni.name.focus();
  };

  const openFacForm = (id = null) => {
    formFac.reset();
    document.getElementById('fac-err').innerHTML = '';
    const f = id ? facs.find((x) => String(x.id) === String(id)) : null;
    const prefer = f?.university || selectedUniId;
    fillFacUniSelect(prefer);
    document.getElementById('dlg-fac-title').textContent = f
      ? 'Modifier la faculté'
      : 'Nouvelle faculté';
    formFac.id.value = f?.id || '';
    formFac.name.value = f?.name || '';
    formFac.slug.value = f?.slug || '';
    formFac.description.value = f?.description || '';
    formFac.is_verified.checked = f ? f.is_verified !== false : true;
    dlgFac.showModal();
    formFac.name.focus();
  };

  formUni.addEventListener('submit', async (ev) => {
    if (ev.submitter?.value === 'cancel') return;
    ev.preventDefault();
    const name = formUni.name.value.trim();
    if (!name) return;
    const payload = {
      name,
      slug: formUni.slug.value.trim() || toSlug(name),
      city: formUni.city.value.trim(),
      country: formUni.country.value.trim() || 'RD Congo',
      primary_color: formUni.primary_color.value || '#1a47b8',
      description: formUni.description.value.trim(),
      is_active: formUni.is_active.checked,
      is_verified: formUni.is_verified.checked,
      is_user_suggested: false,
    };
    const id = formUni.id.value;
    try {
      if (id) {
        await api(`universities/${id}/`, { method: 'PATCH', body: JSON.stringify(payload) });
        toast('Université mise à jour');
      } else {
        const created = await api('universities/', {
          method: 'POST',
          body: JSON.stringify(payload),
        });
        selectedUniId = created.id;
        toast('Université créée');
      }
      dlgUni.close();
      await load();
    } catch (e) {
      document.getElementById('uni-err').innerHTML =
        `<div class="alert alert-error">${esc(e.message)}</div>`;
    }
  });

  formFac.addEventListener('submit', async (ev) => {
    if (ev.submitter?.value === 'cancel') return;
    ev.preventDefault();
    const name = formFac.name.value.trim();
    if (!name) return;
    const university = Number(formFac.university.value);
    const payload = {
      name,
      slug: formFac.slug.value.trim() || toSlug(name),
      university,
      description: formFac.description.value.trim(),
      is_verified: formFac.is_verified.checked,
      is_user_suggested: false,
    };
    const id = formFac.id.value;
    try {
      if (id) {
        await api(`faculties/${id}/`, { method: 'PATCH', body: JSON.stringify(payload) });
        toast('Faculté mise à jour');
      } else {
        await api('faculties/', { method: 'POST', body: JSON.stringify(payload) });
        toast('Faculté créée');
      }
      selectedUniId = university;
      dlgFac.close();
      await load();
    } catch (e) {
      document.getElementById('fac-err').innerHTML =
        `<div class="alert alert-error">${esc(e.message)}</div>`;
    }
  });

  document.getElementById('add-uni').addEventListener('click', () => openUniForm());
  document.getElementById('add-fac').addEventListener('click', () => {
    if (!selectedUniId) return;
    openFacForm();
  });
  document.getElementById('uni-q').addEventListener('input', (ev) => {
    uniQuery = ev.target.value;
    renderUnis();
  });
  document.getElementById('fac-q').addEventListener('input', (ev) => {
    facQuery = ev.target.value;
    renderFacs();
  });

  const load = async () => {
    try {
      const [uData, fData] = await Promise.all([
        api('universities/'),
        api('faculties/'),
      ]);
      unis = unwrapList(uData);
      facs = unwrapList(fData);
      if (selectedUniId && !unis.some((u) => String(u.id) === String(selectedUniId))) {
        selectedUniId = null;
      }
      if (!selectedUniId && unis.length) selectedUniId = unis[0].id;
      updateStats();
      renderUnis();
      renderFacs();
    } catch (e) {
      document.getElementById('unis').innerHTML =
        `<div class="alert alert-error">${esc(e.message)}</div>`;
    }
  };

  await load();
}

function statusChip(status) {
  if (status === 'approved') return '<span class="chip chip-ok">Validée</span>';
  if (status === 'pending') return '<span class="chip chip-wait">En examen</span>';
  if (status === 'rejected') return '<span class="chip chip-draft">Refusée</span>';
  return `<span class="chip chip-draft">${esc(status || '—')}</span>`;
}

export async function renderPosts(root) {
  root.innerHTML = `
    <div class="page-head">
      <div>
        <h1>Publications</h1>
      </div>
    </div>
    <div class="toolbar">
      <input type="search" id="q" placeholder="Titre, contenu, auteur…" style="flex:1;min-width:180px">
      <select id="status">
        <option value="">Tous les statuts</option>
        <option value="pending">En examen</option>
        <option value="approved">Validées</option>
        <option value="rejected">Refusées</option>
      </select>
      <select id="kind">
        <option value="">Tous les types</option>
        <option value="discussion">Discussions</option>
        <option value="question">Questions</option>
        <option value="exam">Examens</option>
        <option value="tp">TP / TD</option>
        <option value="summary">Résumés</option>
        <option value="notes">Notes</option>
        <option value="support">Supports</option>
        <option value="rapport">Rapports</option>
        <option value="tfc">TFC</option>
        <option value="memoire">Mémoires</option>
      </select>
    </div>
    <div class="panel"><div class="panel-b table-wrap" id="table"><div class="skeleton" style="height:120px"></div></div></div>
    <dialog class="admin-dialog" id="dlg-post" style="width:min(720px,94vw)">
      <form method="dialog" id="form-post">
        <h2 id="post-dlg-title">Publication</h2>
        <div id="post-dlg-body"></div>
        <div class="admin-dialog-actions">
          <button class="btn btn-secondary" value="cancel" type="submit">Fermer</button>
        </div>
      </form>
    </dialog>
  `;

  const dlg = document.getElementById('dlg-post');

  const renderComments = (comments) => {
    if (!comments.length) {
      return '<div class="struct-hint" style="padding:16px 0"><strong>Aucun commentaire</strong></div>';
    }
    return `<div class="comment-list">${comments
      .map(
        (c) => `<div class="comment-row" data-id="${c.id}">
          ${personCell({
            id: c.author_id,
            name: c.author_name,
            email: c.author_email,
            role: c.author_role,
            avatar: c.author_avatar,
          })}
          <div class="comment-body">
            <p>${esc(c.content || '')}</p>
            <time>${esc(formatDateTime(c.created_at))}</time>
          </div>
          <button class="btn btn-ghost btn-del-com" data-id="${c.id}" data-name="${esc((c.content || 'ce commentaire').slice(0, 40))}" type="button">Supprimer</button>
        </div>`,
      )
      .join('')}</div>`;
  };

  const bindCommentDeletes = (postId) => {
    document.querySelectorAll('.btn-del-com').forEach((b) =>
      b.addEventListener('click', async (ev) => {
        ev.preventDefault();
        ev.stopPropagation();
        if (!(await confirmDelete(b.dataset.name))) return;
        try {
          await api(`post-comments/${b.dataset.id}/`, { method: 'DELETE' });
          toast('Commentaire supprimé');
          const p = byIdCache[String(postId)];
          if (p) await openPost(p);
          load();
        } catch (e) {
          toast(e.message, 'error');
        }
      }),
    );
  };

  let byIdCache = {};

  const openPost = async (p) => {
    document.getElementById('post-dlg-title').textContent = p.title || 'Publication';
    const media = p.image_url
      ? `<img src="${esc(p.image_url)}" alt="" style="max-width:100%;border-radius:10px;margin:12px 0">`
      : '';
    const file = p.attachment_url
      ? `<p><a href="${esc(p.attachment_url)}" target="_blank" rel="noopener">Pièce jointe</a></p>`
      : '';
    document.getElementById('post-dlg-body').innerHTML = `
      <div style="margin-bottom:14px">${personCell({
        id: p.author_id,
        name: p.author_name,
        email: p.author_email,
        role: p.author_role,
        avatar: p.author_avatar,
        university: p.author_university,
        faculty: p.author_faculty,
      })}</div>
      <p style="margin:0 0 8px;color:var(--ink-muted)">${esc(p.kind_display || p.kind || '')} · ${statusChip(p.moderation_status)}</p>
      <p style="white-space:pre-wrap;margin:0">${esc(p.content || '—')}</p>
      ${media}${file}
      <h3 class="comment-h">Commentaires</h3>
      <div id="post-comments"><div class="skeleton" style="height:48px"></div></div>
    `;
    if (!dlg.open) dlg.showModal();
    try {
      const comments = unwrapList(
        await api(`post-comments/?post=${p.id}&page_size=100&ordering=created_at`),
      );
      document.getElementById('post-comments').innerHTML = renderComments(comments);
      bindCommentDeletes(p.id);
    } catch (e) {
      document.getElementById('post-comments').innerHTML =
        `<div class="alert alert-error">${esc(e.message)}</div>`;
    }
  };

  const load = async () => {
    const q = document.getElementById('q').value.trim();
    const status = document.getElementById('status').value;
    const kind = document.getElementById('kind').value;
    const params = new URLSearchParams({
      page_size: '50',
      scope: 'timeline',
      ordering: '-created_at',
    });
    if (q) params.set('search', q);
    if (kind) params.set('kind', kind);
    if (status) params.set('moderation_status', status);
    try {
      const rows = unwrapList(await api(`posts/?${params}`));
      const box = document.getElementById('table');
      if (!rows.length) {
        box.innerHTML = '<div class="empty"><strong>Aucune publication</strong>Rien ne correspond à ces filtres.</div>';
        return;
      }
      box.innerHTML = `<table class="data">
        <thead><tr><th>Auteur</th><th>Publication</th><th>Type</th><th>Réactions</th><th>Statut</th><th>Date</th><th></th></tr></thead>
        <tbody>${rows
          .map((p) => {
            const excerpt = (p.title || p.content || 'Sans titre').slice(0, 100);
            return `<tr>
              <td>${personCell({
                id: p.author_id,
                name: p.author_name,
                email: p.author_email,
                role: p.author_role,
                avatar: p.author_avatar,
                university: p.author_university,
                faculty: p.author_faculty,
              })}</td>
              <td>${esc(excerpt)}</td>
              <td>${esc(p.kind_display || p.kind || '—')}</td>
              <td>${p.likes_count || 0} ♥ · <button class="btn btn-ghost btn-view" data-id="${p.id}" type="button">${p.comments_count || 0} com.</button></td>
              <td>${statusChip(p.moderation_status)}</td>
              <td>${esc(formatDateTime(p.created_at))}</td>
              <td>
                <div class="row-actions">
                  <button class="btn btn-ghost btn-view" data-id="${p.id}" type="button">Voir</button>
                  ${p.moderation_status !== 'approved' ? `<button class="btn btn-ghost btn-ok" data-id="${p.id}" type="button">Approuver</button>` : ''}
                  ${p.moderation_status !== 'rejected' ? `<button class="btn btn-ghost btn-no" data-id="${p.id}" type="button">Refuser</button>` : ''}
                  <button class="btn btn-ghost btn-del" data-id="${p.id}" data-name="${esc(p.title || 'cette publication')}" type="button">Supprimer</button>
                </div>
              </td>
            </tr>`;
          })
          .join('')}</tbody></table>`;

      const byId = Object.fromEntries(rows.map((p) => [String(p.id), p]));
      byIdCache = byId;
      root.querySelectorAll('.btn-view').forEach((b) =>
        b.addEventListener('click', () => openPost(byId[b.dataset.id])),
      );
      root.querySelectorAll('.btn-ok').forEach((b) =>
        b.addEventListener('click', async () => {
          try {
            await api(`posts/${b.dataset.id}/approve/`, { method: 'POST', body: '{}' });
            toast('Publication validée');
            load();
          } catch (e) {
            toast(e.message, 'error');
          }
        }),
      );
      root.querySelectorAll('.btn-no').forEach((b) =>
        b.addEventListener('click', async () => {
          const reason = window.prompt('Motif du refus (optionnel)') || '';
          try {
            await api(`posts/${b.dataset.id}/reject/`, {
              method: 'POST',
              body: JSON.stringify({ reason }),
            });
            toast('Publication refusée');
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
            await api(`posts/${b.dataset.id}/`, { method: 'DELETE' });
            toast('Publication supprimée');
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

  document.getElementById('q').addEventListener('input', () => load());
  document.getElementById('status').addEventListener('change', () => load());
  document.getElementById('kind').addEventListener('change', () => load());
  load();
}

export async function renderSettings(root, user) {
  root.innerHTML = `
    <div class="page-head"><div><h1>Paramètres</h1><p>Compte administrateur</p></div></div>
    <div class="panel"><div class="panel-b form-grid">
      <div class="field"><label>Nom</label><input readonly value="${esc(user.full_name || '')}"></div>
      <div class="field"><label>E-mail</label><input readonly value="${esc(user.email || '')}"></div>
      <div class="field"><label>Rôle</label><input readonly value="${esc(user.role || '')}"></div>
      <div class="field full"><p style="color:var(--ink-soft)">Django Admin classique : <a href="/django-admin/" target="_blank">/django-admin/</a></p></div>
    </div></div>
  `;
}
