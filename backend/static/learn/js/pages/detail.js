import { fetchCourseOutline, fetchPurchasedIds } from '../api.js';
import {
  addCourse,
  formatPrice,
  hasCourse,
  teacherName,
} from '../cart.js';
import { buildPreviewSamples, openPreviewModal } from '../preview-modal.js';
import {
  escapeHtml,
  formatViews,
  hashRating,
  showToast,
  splitLines,
} from '../utils.js';

function discountPct(sale, list) {
  if (!list || list <= sale) return 0;
  return Math.round(((list - sale) / list) * 100);
}

function headline(course) {
  const raw = (course.description || '').trim();
  if (!raw) return course.teacher_headline || '';
  const first = raw.split(/\n+/)[0].trim();
  return first.length > 180 ? `${first.slice(0, 177)}…` : first;
}

function totalCurriculum(modules) {
  let lessons = 0;
  let seconds = 0;
  for (const m of modules) {
    const ls = Array.isArray(m.lessons) ? m.lessons : [];
    lessons += ls.length;
    for (const l of ls) seconds += Number(l.duration_seconds) || 0;
  }
  const hours = Math.floor(seconds / 3600);
  const mins = Math.round((seconds % 3600) / 60);
  let dur = '';
  if (hours > 0) dur = `${hours} h ${mins ? `${mins} min` : ''}`.trim();
  else if (mins > 0) dur = `${mins} min`;
  return { lessons, dur, sections: modules.length };
}

function formatLessonClock(seconds) {
  const s = Number(seconds) || 0;
  if (!s) return '';
  const m = Math.floor(s / 60);
  const r = s % 60;
  return `${m}:${String(r).padStart(2, '0')}`;
}

function learnItems(course) {
  const fromObj = splitLines(course.objectives);
  const fromSkills = splitLines(course.skills);
  const merged = [...fromObj, ...fromSkills];
  if (merged.length) return merged;
  if (course.description) {
    return splitLines(course.description).slice(0, 8);
  }
  return [];
}

function buyCardHtml(course, pricing, { owned, inCart, stickyClass = 'ud-buy' }) {
  const pct = discountPct(pricing.sale, pricing.list);
  const cover = course.cover_url
    ? `<img src="${escapeHtml(course.cover_url)}" alt="">`
    : '';
  const hours = course.estimated_hours
    ? `${course.estimated_hours} h de contenu`
    : null;
  const includes = [
    hours,
    course.document_count ? `${course.document_count} ressources` : null,
    'Accès sur mobile',
    'Accès à vie après achat',
  ].filter(Boolean);

  const ctaLabel = owned
    ? 'Déjà acheté'
    : inCart
      ? 'Dans le panier'
      : 'Ajouter au panier';

  return `
    <aside class="${stickyClass} glass-strong">
      <button type="button" class="ud-buy-preview preview-open" aria-label="Aperçu du cours">
        ${cover}
        <div class="play">
          <div class="play-btn" aria-hidden="true">▶</div>
        </div>
        <div class="preview-label">Aperçu du cours</div>
      </button>
      <div class="ud-buy-body">
        <div class="price-stack">
          <span class="price-sale">${formatPrice(pricing.sale)}</span>
          <span class="price-list">${formatPrice(pricing.list)}</span>
          ${pct ? `<span class="discount">${pct} % de réduction</span>` : ''}
        </div>
        ${
          pct
            ? `<div class="deal-hint">⏱ Prix promo catalogue</div>`
            : ''
        }
        <button type="button" class="btn btn-primary btn-block buy-btn"
          ${owned || inCart ? 'disabled' : ''}>${ctaLabel}</button>
        <button type="button" class="btn btn-outline-blue btn-block buy-now-btn"
          ${owned ? 'disabled' : ''}>
          ${owned ? 'Accès déjà activé' : 'Acheter maintenant'}
        </button>
        <p class="ud-guarantee">Accès après paiement · Mobile Money</p>
        <div class="ud-includes">
          <h3>Ce cours comprend :</h3>
          <ul>
            ${includes
              .map((i) => `<li><span class="ico">✓</span><span>${escapeHtml(i)}</span></li>`)
              .join('')}
          </ul>
        </div>
      </div>
    </aside>
  `;
}

function bindBuyActions(root, course, pricing, { owned, onCartChange }) {
  const syncButtons = () => {
    const inCart = hasCourse(course.id);
    root.querySelectorAll('.buy-btn').forEach((btn) => {
      if (owned) {
        btn.disabled = true;
        btn.textContent = 'Déjà acheté';
      } else if (inCart) {
        btn.disabled = true;
        btn.textContent = 'Dans le panier';
      }
    });
  };

  root.querySelectorAll('.buy-btn').forEach((btn) => {
    btn.addEventListener('click', () => {
      if (owned) return;
      const added = addCourse(course, pricing.sale);
      if (added) {
        showToast('Ajouté au panier');
        onCartChange?.();
        syncButtons();
      } else {
        location.hash = '#/panier';
      }
    });
  });

  root.querySelectorAll('.buy-now-btn').forEach((btn) => {
    btn.addEventListener('click', () => {
      if (owned) return;
      if (!hasCourse(course.id)) {
        addCourse(course, pricing.sale);
        onCartChange?.();
      }
      location.hash = '#/panier';
    });
  });
}

export async function renderDetail(container, { courseId, pricing, onCartChange }) {
  container.innerHTML = `
    <div class="ud-page">
      <div class="ud-wrap" style="padding-top:18px">
        <a class="back-link" href="#/">← Catalogue</a>
        <div class="empty glass">Chargement…</div>
      </div>
    </div>
  `;

  try {
    const [course, purchased] = await Promise.all([
      fetchCourseOutline(courseId),
      fetchPurchasedIds(),
    ]);
    const owned = purchased.includes(String(course.id));
    const inCart = hasCourse(course.id);
    const { rating, count } = hashRating(course.id);
    const teacher = teacherName(course);
    const teachers = Array.isArray(course.teacher_names) && course.teacher_names.length
      ? course.teacher_names
      : [teacher];
    const objectives = learnItems(course);
    const prereqs = splitLines(course.prerequisites);
    const modules = Array.isArray(course.modules) ? course.modules : [];
    const curr = totalCurriculum(modules);
    const sub = headline(course);
    const students = formatViews(course.unique_visitors || course.views);
    const domains = Array.isArray(course.domains) ? course.domains : [];
    const faculty = course.faculty_name || 'Campus';
    const department = course.department_name || course.code || 'Cours';

    const learnHtml = objectives.length
      ? `
      <section class="ud-learn glass collapsed" id="learn-box">
        <h2>Ce que vous apprendrez</h2>
        <div class="ud-learn-grid">
          ${objectives
            .map(
              (o) => `
            <div class="ud-learn-item">
              <span class="check">✓</span>
              <span>${escapeHtml(o)}</span>
            </div>`
            )
            .join('')}
        </div>
        ${
          objectives.length > 8
            ? `<button type="button" class="ud-show-more" id="learn-more">Afficher plus ▾</button>`
            : ''
        }
      </section>`
      : '';

    const topicsHtml = domains.length
      ? `
      <section class="ud-topics">
        <h2>Explorer les thèmes liés</h2>
        <div class="ud-topic-chips">
          ${domains
            .map(
              (d) =>
                `<a href="#/?domain=${escapeHtml(d.slug)}">${escapeHtml(d.name || d.slug)}</a>`
            )
            .join('')}
          ${course.level_label ? `<span>${escapeHtml(course.level_label)}</span>` : ''}
        </div>
      </section>`
      : '';

    const curriculumHtml = `
      <section class="ud-section" id="curriculum">
        <div class="ud-curriculum-head">
          <h2>Contenu du cours</h2>
          <button type="button" class="ud-expand-all" id="expand-all">Tout développer</button>
        </div>
        <p class="ud-curriculum-meta">
          ${curr.sections} section${curr.sections > 1 ? 's' : ''}
          · ${curr.lessons} leçon${curr.lessons > 1 ? 's' : ''}
          ${curr.dur ? `· ${curr.dur}` : course.estimated_hours ? `· ${course.estimated_hours} h` : ''}
        </p>
        ${
          modules.length
            ? modules
                .map((m, idx) => {
                  const lessons = Array.isArray(m.lessons) ? m.lessons : [];
                  let sec = 0;
                  lessons.forEach((l) => {
                    sec += Number(l.duration_seconds) || 0;
                  });
                  const mMin = sec ? Math.max(1, Math.round(sec / 60)) : 0;
                  return `
                  <details class="module" ${idx === 0 ? 'open' : ''}>
                    <summary>
                      <span>${escapeHtml(m.title || `Section ${idx + 1}`)}</span>
                      <span class="mod-meta">${lessons.length} leçons${mMin ? ` · ${mMin} min` : ''}</span>
                    </summary>
                    ${lessons
                      .map(
                        (l) => `
                      <div class="lesson" data-lesson-id="${escapeHtml(l.id)}">
                        <span>▶ ${escapeHtml(l.title || 'Leçon')}</span>
                        <span>${formatLessonClock(l.duration_seconds)}</span>
                      </div>`
                      )
                      .join('')}
                  </details>`;
                })
                .join('')
            : `<p class="ud-curriculum-meta">Programme bientôt disponible.</p>`
        }
      </section>`;

    container.innerHTML = `
      <div class="ud-page">
        <section class="ud-hero">
          <div class="ud-wrap ud-hero-grid">
            <div class="ud-lede">
              <nav class="ud-crumbs" aria-label="Fil d'Ariane">
                <a href="#/">Apprendre</a>
                <span class="sep">›</span>
                <a href="#/">${escapeHtml(faculty)}</a>
                <span class="sep">›</span>
                <span>${escapeHtml(department)}</span>
              </nav>
              <h1>${escapeHtml(course.title)}</h1>
              ${sub ? `<p class="ud-subtitle">${escapeHtml(sub)}</p>` : ''}
              <div class="ud-badges">
                ${Number(course.views) > 100 ? `<span class="ud-badge best">Populaire</span>` : ''}
                <span class="ud-badge rated">Bien noté</span>
                ${course.level_label ? `<span class="ud-badge best">${escapeHtml(course.level_label)}</span>` : ''}
              </div>
              <p class="ud-created">
                Créé par
                ${teachers
                  .map((t) => `<span class="linkish">${escapeHtml(t)}</span>`)
                  .join(', ')}
              </p>
              <div class="ud-stats-row">
                <span class="rating"><span class="star">★</span> ${rating}</span>
                <span class="ratings-link">(${count} notes)</span>
                <span>${students} étudiants</span>
              </div>
              <div class="ud-meta-row">
                ${course.estimated_hours ? `<span>⏱ ${course.estimated_hours} heures</span>` : ''}
                <span>👁 ${formatViews(course.views)} vues</span>
                ${course.code ? `<span>${escapeHtml(course.code)}</span>` : ''}
                ${course.university_name ? `<span>${escapeHtml(course.university_name)}</span>` : ''}
              </div>
            </div>
            <div class="ud-buy-slot" aria-hidden="true"></div>
          </div>
        </section>

        <div class="ud-mobile-buy">
          ${buyCardHtml(course, pricing, { owned, inCart, stickyClass: 'ud-buy' })}
        </div>

        <div class="ud-body">
          <div class="ud-wrap ud-body-grid">
            <div class="ud-main">
              ${learnHtml}
              ${topicsHtml}
              ${curriculumHtml}

              ${
                prereqs.length
                  ? `<section class="ud-section">
                      <h2>Prérequis</h2>
                      <ul class="ud-req-list">${prereqs
                        .map((p) => `<li>${escapeHtml(p)}</li>`)
                        .join('')}</ul>
                    </section>`
                  : ''
              }

              ${
                course.description
                  ? `<section class="ud-section">
                      <h2>Description</h2>
                      <div class="ud-desc">${escapeHtml(course.description)}</div>
                    </section>`
                  : ''
              }

              <section class="ud-section">
                <h2>Formateur</h2>
                <div class="ud-instructor glass-strong">
                  ${
                    course.teacher_avatar_url
                      ? `<img class="avatar" src="${escapeHtml(course.teacher_avatar_url)}" alt="">`
                      : `<div class="avatar">${escapeHtml(teacher.slice(0, 1).toUpperCase())}</div>`
                  }
                  <div>
                    <h3>${escapeHtml(teacher)}</h3>
                    <p class="role">${escapeHtml(
                      course.teacher_specialty ||
                        course.teacher_title ||
                        course.faculty_name ||
                        'Professeur'
                    )}</p>
                    ${
                      course.teacher_bio
                        ? `<p>${escapeHtml(course.teacher_bio)}</p>`
                        : course.teacher_headline
                          ? `<p>${escapeHtml(course.teacher_headline)}</p>`
                          : ''
                    }
                  </div>
                </div>
              </section>
            </div>

            <div class="ud-sidebar-col">
              ${buyCardHtml(course, pricing, { owned, inCart })}
            </div>
          </div>
        </div>
      </div>
    `;

    bindBuyActions(container, course, pricing, { owned, onCartChange });

    const samples = buildPreviewSamples(course, modules);
    const openPreview = (startId) => {
      let startIndex = 0;
      if (startId != null) {
        const i = samples.findIndex((s) => String(s.id) === String(startId));
        if (i >= 0) startIndex = i;
      }
      openPreviewModal({ course, samples, startIndex });
    };

    container.querySelectorAll('.preview-open').forEach((btn) => {
      btn.addEventListener('click', () => openPreview());
    });

    // Leçons présentes dans les échantillons → ouvrir la modale
    const sampleIds = new Set(samples.map((s) => String(s.id)));
    container.querySelectorAll('.lesson[data-lesson-id]').forEach((row) => {
      const id = row.dataset.lessonId;
      if (!sampleIds.has(String(id))) return;
      row.classList.add('lesson-preview');
      row.addEventListener('click', () => openPreview(id));
    });

    const more = container.querySelector('#learn-more');
    more?.addEventListener('click', () => {
      const box = container.querySelector('#learn-box');
      box.classList.remove('collapsed');
      more.remove();
    });

    const expand = container.querySelector('#expand-all');
    expand?.addEventListener('click', () => {
      const open = expand.dataset.open === '1';
      container.querySelectorAll('.module').forEach((d) => {
        d.open = !open;
      });
      expand.dataset.open = open ? '0' : '1';
      expand.textContent = open ? 'Tout développer' : 'Tout réduire';
    });
  } catch (e) {
    container.innerHTML = `
      <div class="ud-wrap" style="padding-top:18px">
        <a class="back-link" href="#/">← Catalogue</a>
        <div class="error-box glass">${escapeHtml(e.message)}</div>
      </div>
    `;
  }
}
