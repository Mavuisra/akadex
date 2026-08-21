import {
  clearSession,
  fetchMe,
  getAccessToken,
  getStoredUser,
  login,
  api,
  unwrapList,
} from './api.js';
import { initials } from './utils.js';
import { renderDashboard } from './pages/dashboard.js';
import { renderCourses } from './pages/courses.js';
import { renderCreate, renderCourseManage } from './pages/create.js';
import {
  renderStudents,
  renderAnalytics,
  renderRevenue,
  renderNotifications,
  renderProfile,
} from './pages/more.js';
import { renderActivities, renderStudentDetail } from './pages/activities.js';

const NAV = [
  { hash: '#/dashboard', label: 'Dashboard', icon: '◈' },
  { hash: '#/activites', label: 'Activités', icon: '⚡' },
  { hash: '#/cours', label: 'Mes cours', icon: '☰' },
  { hash: '#/creer', label: 'Créer un cours', icon: '+' },
  { hash: '#/etudiants', label: 'Étudiants', icon: '◎' },
  { hash: '#/analytics', label: 'Analytics', icon: '▦' },
  { hash: '#/revenus', label: 'Revenus', icon: '₿' },
  { hash: '#/notifications', label: 'Notifications', icon: '◉' },
  { hash: '#/profil', label: 'Profil', icon: '☺' },
];

const app = document.getElementById('app');
let currentUser = getStoredUser();

function parseRoute() {
  const raw = (location.hash || '#/dashboard').replace(/^#/, '') || '/dashboard';
  const parts = raw.split('/').filter(Boolean);
  return { path: parts[0] || 'dashboard', id: parts[1] || null };
}

function renderLogin() {
  const logo = window.AKADEX_TEACHER?.logoUrl || '';
  app.innerHTML = `
    <div class="login-page">
      <div class="login-card">
        <div class="login-brand">
          ${logo ? `<img src="${logo}" alt="Akadex">` : ''}
          <div>
            <strong>Akadex</strong>
            <small style="display:block;color:var(--ink-soft);font-weight:600">Espace enseignant</small>
          </div>
        </div>
        <h1>Connexion</h1>
        <p class="sub">Accédez à votre tableau de bord professionnel.</p>
        <div id="login-error"></div>
        <form id="login-form">
          <div class="field">
            <label>E-mail</label>
            <input type="email" name="email" required autocomplete="username" placeholder="enseignant@universite.cd">
          </div>
          <div class="field">
            <label>Mot de passe</label>
            <input type="password" name="password" required autocomplete="current-password">
          </div>
          <button class="btn btn-primary btn-block" type="submit" id="login-btn">Se connecter</button>
        </form>
        <p style="margin:18px 0 0;text-align:center;font-size:0.85rem;color:var(--ink-soft)">
          <a href="${window.AKADEX_TEACHER?.landingUrl || '/'}">← Retour au site Akadex</a>
        </p>
      </div>
    </div>
  `;

  document.getElementById('login-form').addEventListener('submit', async (ev) => {
    ev.preventDefault();
    const fd = new FormData(ev.target);
    const btn = document.getElementById('login-btn');
    const err = document.getElementById('login-error');
    err.innerHTML = '';
    btn.disabled = true;
    btn.textContent = 'Connexion…';
    try {
      currentUser = await login(fd.get('email'), fd.get('password'));
      location.hash = '#/dashboard';
      renderShell();
    } catch (e) {
      err.innerHTML = `<div class="alert alert-error">${e.message}</div>`;
      btn.disabled = false;
      btn.textContent = 'Se connecter';
    }
  });
}

function logout() {
  clearSession();
  currentUser = null;
  location.hash = '#/login';
  renderLogin();
}

async function unreadCount() {
  try {
    const data = await api('auth/notifications/unread_count/');
    return Number(data.count || 0);
  } catch {
    try {
      const data = await api('auth/notifications/');
      return unwrapList(data).filter((n) => !n.is_read).length;
    } catch {
      return 0;
    }
  }
}

function updateNotifBadge(n) {
  const badge = document.getElementById('notif-badge');
  if (!badge) return;
  if (n > 0) {
    badge.hidden = false;
    badge.textContent = n > 99 ? '99+' : String(n);
  } else {
    badge.hidden = true;
    badge.textContent = '0';
  }
}

function startNotifPolling() {
  if (window.__notifPoll) clearInterval(window.__notifPoll);
  const tick = () => unreadCount().then(updateNotifBadge);
  tick();
  window.__notifPoll = setInterval(tick, 20000);
}

function renderShell() {
  const logo = window.AKADEX_TEACHER?.logoUrl || '';
  const name =
    currentUser?.full_name ||
    currentUser?.name ||
    `${currentUser?.first_name || ''} ${currentUser?.last_name || ''}`.trim() ||
    'Enseignant';
  const role = currentUser?.role || 'teacher';

  app.innerHTML = `
    <div class="shell" id="shell">
      <div class="sidebar-overlay" id="nav-overlay"></div>
      <aside class="sidebar">
        <div class="sidebar-brand">
          ${logo ? `<img src="${logo}" alt="">` : ''}
          <div>
            <span>Akadex</span>
            <small>Enseignant</small>
          </div>
        </div>
        <nav class="nav" id="side-nav">
          ${NAV.map(
            (n) =>
              `<a href="${n.hash}" data-hash="${n.hash}"><span class="nav-ico">${n.icon}</span>${n.label}</a>`,
          ).join('')}
        </nav>
        <div class="sidebar-foot">
          <a class="btn btn-ghost btn-block" href="${window.AKADEX_TEACHER?.landingUrl || '/'}">Site public</a>
        </div>
      </aside>
      <div class="main">
        <header class="topbar">
          <button class="menu-btn" type="button" id="menu-btn" aria-label="Menu">☰</button>
          <div class="topbar-search">
            <span class="ico">⌕</span>
            <input type="search" id="global-search" placeholder="Rechercher un cours…">
          </div>
          <div class="topbar-actions">
            <button class="icon-btn" type="button" id="notif-btn" title="Notifications">
              🔔<span class="badge-dot" id="notif-badge" hidden>0</span>
            </button>
            <button class="user-chip" type="button" id="user-btn">
              <div class="av">${initials(name)}</div>
              <div class="meta"><strong>${name}</strong><span>${role}</span></div>
            </button>
          </div>
        </header>
        <main class="content" id="page"></main>
      </div>
    </div>
  `;

  document.getElementById('menu-btn').addEventListener('click', () => {
    document.getElementById('shell').classList.toggle('nav-open');
  });
  document.getElementById('nav-overlay').addEventListener('click', () => {
    document.getElementById('shell').classList.remove('nav-open');
  });
  document.getElementById('notif-btn').addEventListener('click', () => {
    location.hash = '#/notifications';
  });
  document.getElementById('user-btn').addEventListener('click', () => {
    location.hash = '#/profil';
  });
  document.getElementById('global-search').addEventListener('keydown', (ev) => {
    if (ev.key === 'Enter') {
      const q = ev.target.value.trim();
      location.hash = q ? `#/cours` : '#/cours';
      sessionStorage.setItem('teacher_course_q', q);
    }
  });

  unreadCount().then(updateNotifBadge);
  startNotifPolling();

  route();
}

async function route() {
  const page = document.getElementById('page');
  if (!page) return;
  const { path, id } = parseRoute();

  document.querySelectorAll('#side-nav a').forEach((a) => {
    const h = a.getAttribute('data-hash');
    const active =
      h === `#/${path}` ||
      (path === 'cours' && id && h === '#/cours') ||
      (path === 'etudiants' && id && h === '#/etudiants') ||
      (path === 'dashboard' && h === '#/dashboard');
    a.classList.toggle('active', active);
  });
  document.getElementById('shell')?.classList.remove('nav-open');

  // Teardown page précédente (ex. poll activités).
  if (typeof page._teardown === 'function') {
    try {
      page._teardown();
    } catch (_) {
      /* ignore */
    }
    page._teardown = null;
  }

  if (path === 'dashboard') return renderDashboard(page);
  if (path === 'activites') return renderActivities(page);
  if (path === 'cours' && id) return renderCourseManage(page, id);
  if (path === 'cours') return renderCourses(page);
  if (path === 'creer') return renderCreate(page);
  if (path === 'etudiants' && id) return renderStudentDetail(page, id);
  if (path === 'etudiants') return renderStudents(page);
  if (path === 'analytics') return renderAnalytics(page);
  if (path === 'revenus') return renderRevenue(page);
  if (path === 'notifications') return renderNotifications(page);
  if (path === 'profil') return renderProfile(page, currentUser, logout);
  location.hash = '#/dashboard';
}

async function boot() {
  window.addEventListener('hashchange', () => {
    if (!getAccessToken()) {
      renderLogin();
      return;
    }
    if (!document.getElementById('page')) renderShell();
    else route();
  });

  if (!getAccessToken()) {
    renderLogin();
    return;
  }

  try {
    currentUser = await fetchMe();
    if (
      currentUser.role !== 'teacher' &&
      currentUser.role !== 'admin'
    ) {
      clearSession();
      renderLogin();
      return;
    }
    if (!location.hash || location.hash === '#/login') {
      location.hash = '#/dashboard';
    }
    renderShell();
  } catch {
    clearSession();
    renderLogin();
  }
}

boot();
