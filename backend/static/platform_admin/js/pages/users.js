import { api, unwrapList } from '../api.js';
import {
  confirmDelete,
  esc,
  formatDateTime,
  roleChip,
  statusActive,
  toast,
} from '../utils.js';

const ROLES = [
  'student',
  'teacher',
  'alumni',
  'admin',
  'assistant',
  'rep',
  'association',
  'library',
];

export async function renderUsers(root, { roleFilter = '' } = {}) {
  const title =
    roleFilter === 'student'
      ? 'Étudiants'
      : roleFilter === 'teacher'
        ? 'Enseignants'
        : 'Utilisateurs';

  root.innerHTML = `
    <div class="page-head">
      <div>
        <h1>${esc(title)}</h1>
      </div>
      <div class="page-actions">
        <button class="btn btn-primary" type="button" id="btn-add">+ Ajouter</button>
      </div>
    </div>
    <div class="toolbar">
      <input type="search" id="q" placeholder="Nom, e-mail, téléphone…" style="flex:1;min-width:180px">
      ${
        roleFilter
          ? ''
          : `<select id="role"><option value="">Tous les rôles</option>${ROLES.map((r) => `<option value="${r}">${r}</option>`).join('')}</select>`
      }
      <select id="active">
        <option value="">Tous</option>
        <option value="true">Actifs</option>
        <option value="false">Inactifs</option>
      </select>
    </div>
    <div class="panel"><div class="panel-b table-wrap" id="table"><div class="skeleton" style="height:120px"></div></div></div>
    <dialog class="admin-dialog" id="dlg" style="width:min(520px,94vw)">
      <form method="dialog" id="form">
        <h2 id="dlg-title">Utilisateur</h2>
        <input type="hidden" name="id">
        <div class="form-grid">
          <div class="field"><label>Prénom</label><input name="first_name" required></div>
          <div class="field"><label>Nom</label><input name="last_name" required></div>
          <div class="field full"><label>E-mail</label><input name="email" type="email" required></div>
          <div class="field"><label>Téléphone</label><input name="phone"></div>
          <div class="field"><label>Rôle</label>
            <select name="role">${ROLES.map((r) => `<option value="${r}">${r}</option>`).join('')}</select>
          </div>
          <div class="field full"><label>Mot de passe ${roleFilter ? '' : '(création / reset)'}</label><input name="password" type="password" autocomplete="new-password"></div>
          <div class="field"><label><input type="checkbox" name="is_active" checked> Actif</label></div>
          <div class="field"><label><input type="checkbox" name="is_staff"> Staff Django</label></div>
        </div>
        <div id="form-err"></div>
        <div class="admin-dialog-actions">
          <button class="btn btn-secondary" value="cancel" type="submit">Annuler</button>
          <button class="btn btn-primary" id="form-save" value="default" type="submit">Enregistrer</button>
        </div>
      </form>
    </dialog>
  `;

  const dlg = document.getElementById('dlg');
  const form = document.getElementById('form');

  const load = async () => {
    const q = document.getElementById('q').value.trim();
    const role = roleFilter || document.getElementById('role')?.value || '';
    const active = document.getElementById('active').value;
    const params = new URLSearchParams({ page_size: '50' });
    if (q) params.set('search', q);
    if (role) params.set('role', role);
    if (active) params.set('is_active', active);
    try {
      const data = await api(`auth/admin/users/?${params}`);
      const rows = unwrapList(data);
      if (!rows.length) {
        document.getElementById('table').innerHTML =
          '<div class="empty"><strong>Aucun utilisateur</strong><button class="btn btn-primary" style="margin-top:12px" type="button" id="empty-add">+ Ajouter</button></div>';
        document.getElementById('empty-add')?.addEventListener('click', () => openForm());
        return;
      }
      document.getElementById('table').innerHTML = `
        <table class="data">
          <thead><tr><th>ID</th><th>Nom</th><th>E-mail</th><th>Tél.</th><th>Rôle</th><th>Statut</th><th>Créé</th><th></th></tr></thead>
          <tbody>
            ${rows
              .map(
                (u) => `
              <tr>
                <td>${u.id}</td>
                <td><strong>${esc(u.full_name || `${u.first_name || ''} ${u.last_name || ''}`)}</strong></td>
                <td>${esc(u.email)}</td>
                <td>${esc(u.phone || '—')}</td>
                <td>${roleChip(u.role)}</td>
                <td>${statusActive(u.is_active !== false)}</td>
                <td>${esc(formatDateTime(u.date_joined))}</td>
                <td>
                  <div class="row-actions">
                    <button class="btn btn-ghost btn-edit" data-id="${u.id}" type="button">Modifier</button>
                    <button class="btn btn-ghost btn-tog" data-id="${u.id}" data-active="${u.is_active !== false}" type="button">${u.is_active === false ? 'Activer' : 'Désactiver'}</button>
                    <button class="btn btn-ghost btn-del" data-id="${u.id}" data-name="${esc(u.email)}" type="button">Supprimer</button>
                  </div>
                </td>
              </tr>`,
              )
              .join('')}
          </tbody>
        </table>`;

      root.querySelectorAll('.btn-edit').forEach((b) =>
        b.addEventListener('click', () => openForm(b.dataset.id)),
      );
      root.querySelectorAll('.btn-del').forEach((b) =>
        b.addEventListener('click', async () => {
          if (!(await confirmDelete(b.dataset.name))) return;
          try {
            await api(`auth/admin/users/${b.dataset.id}/`, { method: 'DELETE' });
            toast('Utilisateur supprimé');
            load();
          } catch (e) {
            toast(e.message, 'error');
          }
        }),
      );
      root.querySelectorAll('.btn-tog').forEach((b) =>
        b.addEventListener('click', async () => {
          const active = b.dataset.active === 'true';
          const action = active ? 'deactivate' : 'activate';
          try {
            await api(`auth/admin/users/${b.dataset.id}/${action}/`, {
              method: 'POST',
              body: '{}',
            });
            toast(active ? 'Désactivé' : 'Activé');
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
    form.reset();
    form.id.value = id || '';
    document.getElementById('dlg-title').textContent = id
      ? 'Modifier l’utilisateur'
      : 'Nouvel utilisateur';
    form.is_active.checked = true;
    if (roleFilter) form.role.value = roleFilter;
    if (id) {
      try {
        const u = await api(`auth/admin/users/${id}/`);
        form.first_name.value = u.first_name || '';
        form.last_name.value = u.last_name || '';
        form.email.value = u.email || '';
        form.phone.value = u.phone || '';
        form.role.value = u.role || 'student';
        form.is_active.checked = u.is_active !== false;
        form.is_staff.checked = !!u.is_staff;
      } catch (e) {
        toast(e.message, 'error');
        return;
      }
    }
    dlg.showModal();
  }

  form.addEventListener('submit', async (ev) => {
    if (ev.submitter?.value === 'cancel') return;
    ev.preventDefault();
    const err = document.getElementById('form-err');
    err.innerHTML = '';
    const id = form.id.value;
    const body = {
      first_name: form.first_name.value.trim(),
      last_name: form.last_name.value.trim(),
      email: form.email.value.trim(),
      phone: form.phone.value.trim(),
      role: form.role.value,
      is_active: form.is_active.checked,
      is_staff: form.is_staff.checked,
      username: form.email.value.trim().split('@')[0].replace(/[^a-zA-Z0-9_]/g, '_'),
    };
    if (form.password.value) body.password = form.password.value;
    if (!id && !body.password) {
      err.innerHTML = '<div class="alert alert-error">Mot de passe obligatoire à la création.</div>';
      return;
    }
    const saveBtn = document.getElementById('form-save');
    saveBtn.disabled = true;
    try {
      if (id) {
        await api(`auth/admin/users/${id}/`, {
          method: 'PATCH',
          body: JSON.stringify(body),
        });
        toast('Utilisateur mis à jour');
      } else {
        await api('auth/admin/users/', {
          method: 'POST',
          body: JSON.stringify(body),
        });
        toast('Utilisateur créé');
      }
      dlg.close();
      load();
    } catch (e) {
      err.innerHTML = `<div class="alert alert-error">${esc(e.message)}</div>`;
    } finally {
      saveBtn.disabled = false;
    }
  });

  document.getElementById('btn-add').addEventListener('click', () => openForm());
  document.getElementById('q').addEventListener('input', () => {
    clearTimeout(window.__uTimer);
    window.__uTimer = setTimeout(load, 300);
  });
  document.getElementById('role')?.addEventListener('change', load);
  document.getElementById('active').addEventListener('change', load);
  load();
}
