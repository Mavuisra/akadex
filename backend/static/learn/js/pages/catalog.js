import { fetchCourses, fetchDomains } from '../api.js';
import { courseCardHtml, escapeHtml, isLearnCatalog, showToast } from '../utils.js';

export async function renderCatalog(container, { pricing, query = '', domain = '' }) {
  container.innerHTML = `
    <section class="hero-strip glass-strong">
      <div>
        <h1>Apprendre</h1>
        <p>Cours campus · professeurs · prix catalogue</p>
      </div>
      <div class="meta-count" id="catalog-count">…</div>
    </section>
    <div class="domains" id="domain-row"></div>
    <div class="course-grid" id="course-grid">
      <div class="empty glass" style="grid-column:1/-1">Chargement des cours…</div>
    </div>
  `;

  const grid = container.querySelector('#course-grid');
  const countEl = container.querySelector('#catalog-count');
  const domainRow = container.querySelector('#domain-row');

  let domains = [];
  try {
    domains = await fetchDomains();
  } catch {
    domains = [];
  }

  domainRow.innerHTML = `
    <button type="button" class="domain-chip ${!domain ? 'active' : ''}" data-domain="">Tous</button>
    ${domains
      .map(
        (d) => `
      <button type="button" class="domain-chip ${domain === d.slug ? 'active' : ''}" data-domain="${escapeHtml(d.slug)}">
        ${escapeHtml(d.name || d.slug)}
      </button>`
      )
      .join('')}
  `;

  domainRow.querySelectorAll('.domain-chip').forEach((btn) => {
    btn.addEventListener('click', () => {
      const slug = btn.dataset.domain || '';
      const q = new URLSearchParams();
      if (query) q.set('q', query);
      if (slug) q.set('domain', slug);
      const qs = q.toString();
      location.hash = qs ? `#/?${qs}` : '#/';
    });
  });

  try {
    const raw = await fetchCourses({ search: query, domain });
    let courses = raw.filter(isLearnCatalog);
    if (!courses.length && raw.length) {
      // Fallback si le seed n’utilise pas encore les préfixes AKX/ENS
      courses = raw.filter((c) => c.is_approved !== false);
    }
    if (query) {
      const q = query.toLowerCase();
      courses = courses.filter((c) =>
        [c.title, c.code, c.teacher_name, c.teacher_full_name, c.faculty_name]
          .filter(Boolean)
          .join(' ')
          .toLowerCase()
          .includes(q)
      );
    }

    countEl.textContent = `${courses.length} cours`;
    if (!courses.length) {
      grid.innerHTML = `<div class="empty glass" style="grid-column:1/-1">Aucun cours pour ce filtre.</div>`;
      return;
    }

    grid.innerHTML = courses.map((c) => courseCardHtml(c, pricing)).join('');
    grid.querySelectorAll('.course-card').forEach((card) => {
      const go = () => {
        location.hash = `#/cours/${card.dataset.id}`;
      };
      card.addEventListener('click', go);
      card.addEventListener('keydown', (e) => {
        if (e.key === 'Enter' || e.key === ' ') {
          e.preventDefault();
          go();
        }
      });
    });
  } catch (e) {
    countEl.textContent = '';
    grid.innerHTML = `<div class="error-box glass" style="grid-column:1/-1">${escapeHtml(e.message)}</div>`;
    showToast('Impossible de charger le catalogue');
  }
}
