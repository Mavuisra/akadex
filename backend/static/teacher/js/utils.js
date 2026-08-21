import { api, unwrapList } from './api.js';

export function esc(s) {
  return String(s ?? '')
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;');
}

export function formatDate(iso) {
  if (!iso) return '—';
  try {
    return new Date(iso).toLocaleDateString('fr-FR', {
      day: 'numeric',
      month: 'short',
      year: 'numeric',
    });
  } catch {
    return '—';
  }
}

export function formatDateTime(iso) {
  if (!iso) return '—';
  try {
    return new Date(iso).toLocaleString('fr-FR', {
      day: 'numeric',
      month: 'short',
      hour: '2-digit',
      minute: '2-digit',
    });
  } catch {
    return '—';
  }
}

export function statusChip(course) {
  if (course.is_approved || course.moderation_status === 'approved') {
    return '<span class="chip chip-ok">Publié</span>';
  }
  if (
    course.moderation_status === 'pending' ||
    course.moderation_status === 'changes_requested'
  ) {
    return '<span class="chip chip-wait">En attente</span>';
  }
  if (course.moderation_status === 'rejected') {
    return '<span class="chip chip-draft">Refusé</span>';
  }
  return '<span class="chip chip-draft">Brouillon</span>';
}

export function initials(name) {
  const p = String(name || '?').trim().split(/\s+/);
  return ((p[0]?.[0] || '?') + (p[1]?.[0] || '')).toUpperCase();
}

export function barsHtml(activity) {
  const items = Array.isArray(activity) ? activity : [];
  const max = Math.max(1, ...items.map((d) => Number(d.value) || 0));
  if (!items.length) {
    return '<div class="empty"><strong>Aucune activité</strong>Sur les 7 derniers jours.</div>';
  }
  return `<div class="bars">${items
    .map((d) => {
      const v = Number(d.value) || 0;
      const h = Math.max(4, Math.round((v / max) * 140));
      return `<div class="bar-col"><div class="bar" style="height:${h}px" title="${v}"></div><span>${esc(d.label || '')}</span></div>`;
    })
    .join('')}</div>`;
}

export async function loadTeacherCourses() {
  const me = JSON.parse(localStorage.getItem('akadex_teacher_user') || '{}');
  const data = await api('courses/?ordering=-updated_at&page_size=100');
  const all = unwrapList(data);
  const uid = String(me.id || '');
  const name = (me.full_name || me.name || me.first_name || '').toLowerCase();
  const first = name.split(/\s+/).filter(Boolean)[0] || '';

  const mine = all.filter((c) => {
    if (uid && String(c.submitted_by) === uid) return true;
    if (Array.isArray(c.teachers) && c.teachers.some((t) => String(t) === uid)) {
      return true;
    }
    const hay = [
      c.teacher_name,
      c.teacher_full_name,
      c.submitted_by_name,
      ...(c.teacher_names || []),
    ]
      .join(' ')
      .toLowerCase();
    if (first && hay.includes(first)) return true;
    if (String(c.code || '').startsWith('ENS-')) return true;
    return false;
  });
  return mine.length ? mine : all.filter((c) => !String(c.code || '').startsWith('AKX-'));
}
