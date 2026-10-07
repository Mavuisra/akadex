import { fetchStudentDashboard, getStoredUser, isLoggedIn } from './api.js';
import { escapeHtml, formatRelative, initials } from './utils.js';

const app = document.getElementById('app');
const learnUrl = () => window.AKADEX_PROFILE?.learnUrl || '/apprendre/';

function gateHtml() {
  return `
    <div class="pf-gate">
      <h1>Ton espace d’apprentissage</h1>
      <p>Connecte-toi pour suivre ta progression, ta série et tes cours en cours.</p>
      <button type="button" class="pf-btn" data-auth-open="login">Connexion</button>
    </div>
  `;
}

function renderDashboard(data) {
  const user = data.user || getStoredUser() || {};
  const s = data.stats || {};
  const rate = Number(s.learning_rate_pct) || 0;
  const name =
    user.full_name ||
    [user.first_name, user.last_name].filter(Boolean).join(' ') ||
    user.email ||
    'Étudiant';
  const avatar = user.avatar
    ? `<img src="${escapeHtml(user.avatar)}" alt="">`
    : escapeHtml(initials(user));

  const week = data.weekly_activity || [];
  const maxMin = Math.max(1, ...week.map((d) => d.minutes || 0));

  const courses = data.courses || [];
  const achievements = data.achievements || [];
  const recent = data.recent_activity || [];
  const next = data.next_up;

  return `
    <div class="profile-wrap">
      <section class="pf-hero">
        <div class="pf-avatar">${avatar}</div>
        <div>
          <h1>${escapeHtml(name)}</h1>
          <p class="sub">${escapeHtml(user.email || '')}${
            user.headline ? ` · ${escapeHtml(user.headline)}` : ''
          }</p>
        </div>
        <div class="pf-rate" style="--pct:${rate}" title="Taux d’apprentissage moyen">
          <div>
            <strong>${rate}%</strong>
            <span>Taux</span>
          </div>
        </div>
      </section>

      <section class="pf-stats" aria-label="Indicateurs">
        <div class="pf-stat">
          <div class="label">Série</div>
          <div class="value">${s.streak_days || 0}</div>
          <div class="hint">jours d’affilée</div>
        </div>
        <div class="pf-stat">
          <div class="label">Leçons</div>
          <div class="value">${s.lessons_completed || 0}</div>
          <div class="hint">+${s.lessons_this_week || 0} cette semaine</div>
        </div>
        <div class="pf-stat">
          <div class="label">Temps</div>
          <div class="value">${s.learning_minutes || 0}</div>
          <div class="hint">minutes suivies</div>
        </div>
        <div class="pf-stat">
          <div class="label">Cours</div>
          <div class="value">${s.courses_completed || 0}/${s.courses_started || 0}</div>
          <div class="hint">terminés / commencés</div>
        </div>
      </section>

      ${
        next
          ? `<section class="pf-card">
              <h2>Prochaine étape</h2>
              <div class="pf-next">
                <div>
                  <strong>${escapeHtml(next.course_title || '')}</strong>
                  <p class="meta">${escapeHtml(
                    next.lesson?.module_title || ''
                  )} · ${escapeHtml(next.lesson?.title || '')} · ${
                    next.progress_pct || 0
                  }%</p>
                </div>
                <a class="pf-btn" href="${escapeHtml(next.continue_url || learnUrl())}">Continuer</a>
              </div>
            </section>`
          : ''
      }

      <div class="pf-grid">
        <div>
          <section class="pf-card">
            <h2>Activité de la semaine</h2>
            <div class="week-bars" aria-hidden="true">
              ${week
                .map((d) => {
                  const h = Math.round(((d.minutes || 0) / maxMin) * 100);
                  return `<div class="day">
                    <div class="bar-wrap"><div class="bar" style="height:${Math.max(
                      4,
                      h
                    )}%"></div></div>
                    <span class="lbl">${escapeHtml(d.label || '')}</span>
                  </div>`;
                })
                .join('')}
            </div>
          </section>

          <section class="pf-card">
            <h2>Mes cours</h2>
            ${
              courses.length
                ? courses
                    .map(
                      (c) => `
                <a class="course-row" href="${escapeHtml(c.continue_url || learnUrl())}">
                  ${
                    c.cover_url
                      ? `<img class="course-thumb" src="${escapeHtml(
                          c.cover_url
                        )}" alt="" loading="lazy">`
                      : `<div class="course-thumb"></div>`
                  }
                  <div>
                    <h3>${escapeHtml(c.title || '')}</h3>
                    <div class="prog"><i style="width:${c.progress_pct || 0}%"></i></div>
                    <p class="meta" style="margin-top:0.3rem;font-size:0.8rem;color:var(--muted)">
                      ${c.lessons_completed || 0}/${c.lessons_total || 0} leçons
                      · ${
                        c.status === 'completed' ? 'Terminé' : 'En cours'
                      }
                    </p>
                  </div>
                  <div class="pct">${c.progress_pct || 0}%</div>
                </a>`
                    )
                    .join('')
                : `<div class="pf-empty">
                    <p>Aucun cours commencé.</p>
                    <a class="pf-btn" href="${learnUrl()}">Explorer le catalogue</a>
                  </div>`
            }
          </section>
        </div>

        <div>
          <section class="pf-card">
            <h2>Succès</h2>
            <div class="ach-grid">
              ${achievements
                .map(
                  (a) => `
                <div class="ach ${a.earned ? 'earned' : ''}">
                  <strong>${a.earned ? '✓ ' : ''}${escapeHtml(a.label)}</strong>
                  <span>${escapeHtml(a.hint || '')}</span>
                </div>`
                )
                .join('')}
            </div>
          </section>

          <section class="pf-card">
            <h2>Activité récente</h2>
            ${
              recent.length
                ? `<ul class="activity-list">
                    ${recent
                      .map(
                        (e) => `
                      <li>
                        <div>
                          <strong>${escapeHtml(e.type_label || e.type)}</strong>
                          <div style="color:var(--muted);font-size:0.82rem">${escapeHtml(
                            e.course_title || ''
                          )}${
                          e.lesson_title
                            ? ` · ${escapeHtml(e.lesson_title)}`
                            : ''
                        }</div>
                        </div>
                        <span class="when">${escapeHtml(
                          formatRelative(e.created_at)
                        )}</span>
                      </li>`
                      )
                      .join('')}
                  </ul>`
                : `<p class="pf-empty">Pas encore d’activité.</p>`
            }
          </section>
        </div>
      </div>
    </div>
  `;
}

async function boot() {
  if (!isLoggedIn()) {
    app.innerHTML = gateHtml();
    app.querySelectorAll('[data-auth-open]').forEach((el) => {
      el.addEventListener('click', () => {
        document.querySelector('[data-auth-open="login"]')?.click();
      });
    });
    // Prefer opening via auth modal buttons already in nav
    const navLogin = document.querySelector('.nav-right [data-auth-open="login"]');
    app.querySelector('.pf-btn')?.addEventListener('click', (e) => {
      e.preventDefault();
      navLogin?.click();
    });
    return;
  }

  try {
    const data = await fetchStudentDashboard();
    app.innerHTML = renderDashboard(data);
  } catch (e) {
    if (e.status === 401) {
      app.innerHTML = gateHtml();
      return;
    }
    app.innerHTML = `<div class="pf-gate"><h1>Profil</h1><p>${escapeHtml(
      e.message || 'Impossible de charger'
    )}</p><a class="pf-btn" href="${learnUrl()}">Catalogue</a></div>`;
  }
}

boot();
