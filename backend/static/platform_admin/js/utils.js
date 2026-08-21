export function esc(s) {
  return String(s ?? '')
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;');
}

export function initials(name) {
  const p = String(name || '?')
    .trim()
    .split(/\s+/)
    .filter(Boolean);
  if (!p.length) return '?';
  if (p.length === 1) return p[0].slice(0, 2).toUpperCase();
  return (p[0][0] + p[1][0]).toUpperCase();
}

export function formatDate(iso) {
  if (!iso) return '—';
  try {
    return new Date(iso).toLocaleDateString('fr-FR');
  } catch {
    return '—';
  }
}

export function formatDateTime(iso) {
  if (!iso) return '—';
  try {
    return new Date(iso).toLocaleString('fr-FR');
  } catch {
    return '—';
  }
}

export function toast(msg, kind = 'ok') {
  let el = document.getElementById('admin-toast');
  if (!el) {
    el = document.createElement('div');
    el.id = 'admin-toast';
    el.style.cssText =
      'position:fixed;right:16px;bottom:16px;z-index:9999;padding:12px 16px;border-radius:10px;font-weight:600;box-shadow:0 8px 24px rgba(0,0,0,.12);max-width:360px';
    document.body.appendChild(el);
  }
  el.style.background = kind === 'error' ? '#fdecec' : '#e6f7ef';
  el.style.color = kind === 'error' ? '#e5484d' : '#1fa971';
  el.textContent = msg;
  el.hidden = false;
  clearTimeout(window.__toastT);
  window.__toastT = setTimeout(() => {
    el.hidden = true;
  }, 2800);
}

export function barsHtml(rows, key = 'users') {
  const list = rows || [];
  if (!list.length) return '<div class="empty">Pas de données</div>';
  const max = Math.max(1, ...list.map((r) => Number(r[key] || r.value || 0)));
  return `<div style="display:flex;align-items:flex-end;gap:8px;height:140px">${list
    .map((r) => {
      const v = Number(r[key] || r.value || 0);
      const h = Math.round((100 * v) / max);
      return `<div style="flex:1;text-align:center"><div style="height:${h}%;min-height:4px;background:var(--blue);border-radius:6px 6px 0 0;margin:0 auto;width:70%"></div><div style="font-size:0.7rem;color:var(--ink-soft);margin-top:6px">${esc(r.label || '')}</div></div>`;
    })
    .join('')}</div>`;
}

export function roleChip(role) {
  const map = {
    student: 'chip-info',
    teacher: 'chip-ok',
    alumni: 'chip-wait',
    admin: 'chip-draft',
  };
  return `<span class="chip ${map[role] || 'chip-draft'}">${esc(role || '—')}</span>`;
}

export function statusActive(active) {
  return active
    ? '<span class="chip chip-ok">Actif</span>'
    : '<span class="chip chip-draft">Inactif</span>';
}

export async function confirmDelete(label = 'cet élément') {
  return window.confirm(`Supprimer définitivement ${label} ?`);
}
