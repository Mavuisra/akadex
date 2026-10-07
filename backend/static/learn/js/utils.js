import { teacherName } from './cart.js';

/** Catalogue Apprendre = AKX-* (vitrine) + ENS-* (enseignants). */
export function isLearnCatalog(course) {
  const code = String(course.code || '').trim().toUpperCase();
  return code.startsWith('AKX-') || code.startsWith('ENS-');
}

export function formatViews(n) {
  const v = Number(n) || 0;
  if (v >= 1000) return `${(v / 1000).toFixed(v >= 10000 ? 0 : 1)} k`;
  return String(v);
}

export function hashRating(id) {
  const h = Math.abs(hashCode(String(id)));
  return {
    rating: (4.5 + (h % 5) / 10).toFixed(1),
    count: 80 + (h % 900),
  };
}

function hashCode(s) {
  let h = 0;
  for (let i = 0; i < s.length; i++) h = (Math.imul(31, h) + s.charCodeAt(i)) | 0;
  return h;
}

export function escapeHtml(str) {
  return String(str ?? '')
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;');
}

export function coverHtml(course, className = '') {
  const url = course.cover_url || '';
  const code = escapeHtml(course.code || '');
  if (url) {
    return `<div class="${className}"><img src="${escapeHtml(url)}" alt="" loading="lazy" onerror="this.remove()"><span class="code-tag">${code}</span></div>`;
  }
  return `<div class="${className}"><span class="code-tag">${code}</span></div>`;
}

export function courseCardHtml(course, pricing) {
  const { rating, count } = hashRating(course.id);
  const teacher = escapeHtml(teacherName(course));
  const title = escapeHtml(course.title || '');
  const sale = pricing.sale;
  const list = pricing.list;
  const views = formatViews(course.views);
  const level = course.level_label
    ? `<span class="badge-level">${escapeHtml(course.level_label)}</span>`
    : '';

  return `
    <article class="course-card glass" data-id="${escapeHtml(course.id)}" role="link" tabindex="0">
      ${coverHtml(course, 'course-thumb')}
      <div class="course-body">
        <h3 class="course-title">${title}</h3>
        <p class="course-teacher">${teacher}</p>
        <div class="course-stats">
          <span class="rating"><span class="star">★</span> ${rating} <span style="color:var(--muted);font-weight:600">(${count})</span></span>
          <span>${views} vues</span>
        </div>
        ${level}
        <div class="price-row">
          <span class="price-sale">${sale}$</span>
          <span class="price-list">${list}$</span>
        </div>
      </div>
    </article>
  `;
}

export function showToast(message) {
  const el = document.getElementById('toast');
  if (!el) return;
  el.textContent = message;
  el.hidden = false;
  el.classList.add('show');
  clearTimeout(showToast._t);
  showToast._t = setTimeout(() => {
    el.classList.remove('show');
    setTimeout(() => {
      el.hidden = true;
    }, 200);
  }, 2200);
}

export function splitLines(text) {
  if (!text) return [];
  return String(text)
    .split(/\n|•|;/)
    .map((s) => s.trim())
    .filter(Boolean);
}
