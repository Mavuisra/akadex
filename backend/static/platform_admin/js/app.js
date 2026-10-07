import {
  clearSession,
  ensureFreshSession,
  fetchMe,
  getStoredUser,
  isAdminUser,
  login,
} from './api.js';
import { attachDialogClose, esc, initials } from './utils.js';
import { renderDashboard } from './pages/dashboard.js';
import { renderUsers } from './pages/users.js';
import { renderCourses } from './pages/courses.js';
import {
  renderDocuments,
  renderDomains,
  renderEnrollments,
  renderLessons,
  renderModules,
  renderNotifications,
  renderPayments,
  renderPosts,
  renderSettings,
  renderStructure,
} from './pages/resources.js';

/** Navigation groupée — un rôle clair par section. */
const NAV_GROUPS = [
  {
    title: 'Vue d’ensemble',
    items: [{ href: '#/dashboard', label: 'Dashboard', icon: '▣' }],
  },
  {
    title: 'Communauté',
    items: [
      { href: '#/utilisateurs', label: 'Utilisateurs', icon: '◎' },
      { href: '#/etudiants', label: 'Étudiants', icon: '◉' },
      { href: '#/enseignants', label: 'Enseignants', icon: '◈' },
      { href: '#/communaute', label: 'Publications', icon: '◇' },
      { href: '#/notifications', label: 'Notifications', icon: '◎' },
    ],
  },
  {
    title: 'Catalogue',
    items: [
      { href: '#/cours', label: 'Cours', icon: '▶' },
      { href: '#/domaines', label: 'Catégories', icon: '◇' },
      { href: '#/modules', label: 'Modules', icon: '▦' },
      { href: '#/lecons', label: 'Leçons', icon: '☰' },
      { href: '#/documents', label: 'Documents', icon: '▤' },
    ],
  },
  {
    title: 'Opérations',
    items: [
      { href: '#/inscriptions', label: 'Inscriptions', icon: '⇢' },
      { href: '#/paiements', label: 'Paiements', icon: '¤' },
      { href: '#/structure', label: 'Universités', icon: '⌂' },
      { href: '#/parametres', label: 'Paramètres', icon: '⚙' },
    ],
  },
];

const NAV_FLAT = NAV_GROUPS.flatMap((g) => g.items);

let state = { user: null };

function parseRoute() {
  const hash = (location.hash || '#/dashboard').replace(/^#\/?/, '');
  const [page, id] = hash.split('/');
  return { page: page || 'dashboard', id: id || null };
}

function renderLogin(root, err = '') {
  root.innerHTML = `
    <div class="login-page">
      <div class="login-card" role="form">
        <div class="login-brand">
          <img src="${window.AKADEX_ADMIN.logoUrl}" alt="Akadex" width="40" height="40">
          <strong>AdminAkadex</strong>
        </div>
        <h1>Connexion sécurisée</h1>
        <p class="sub">Centre de contrôle — accès administrateurs uniquement.</p>
        ${err ? `<div class="alert alert-error" role="alert">${esc(err)}</div>` : ''}
        <form id="login-form" autocomplete="on">
          <div class="field">
            <label for="admin-email">E-mail</label>
            <input id="admin-email" name="email" type="email" required autocomplete="username" autofocus>
          </div>
          <div class="field">
            <label for="admin-password">Mot de passe</label>
            <input id="admin-password" name="password" type="password" required autocomplete="current-password">
          </div>
          <button class="btn btn-primary" type="submit" style="width:100%">Se connecter</button>
        </form>
        <p class="login-note">Session isolée · expiration après inactivité · API réservée IsAkadexAdmin.</p>
        <p class="login-note" style="margin-top:8px"><a href="${window.AKADEX_ADMIN.landingUrl || '/'}">← Retour au site</a></p>
      </div>
    </div>`;
  document.getElementById('login-form').addEventListener('submit', async (ev) => {
    ev.preventDefault();
    const btn = ev.target.querySelector('button[type="submit"]');
    if (btn) btn.disabled = true;
    const fd = new FormData(ev.target);
    try {
      const user = await login(fd.get('email'), fd.get('password'));
      if (!isAdminUser(user)) {
        clearSession();
        renderLogin(root, 'Ce compte n’a pas les droits administrateur.');
        return;
      }
      state.user = user;
      location.hash = '#/dashboard';
      renderShell(root);
    } catch (e) {
      renderLogin(root, e.message || 'Identifiants invalides.');
    }
  });
}

function navMarkup() {
  return NAV_GROUPS.map(
    (g) => `
      <div class="nav-group">
        <div class="nav-group-title">${esc(g.title)}</div>
        ${g.items
          .map(
            (n) =>
              `<a href="${n.href}" data-nav="${n.href}"><span aria-hidden="true">${n.icon}</span> ${esc(n.label)}</a>`,
          )
          .join('')}
      </div>`,
  ).join('');
}

function renderShell(root) {
  const user = state.user;
  const name = user.full_name || user.email || 'Admin';
  root.innerHTML = `
    <div class="shell">
      <div class="sidebar-overlay" id="sidebar-overlay"></div>
      <aside class="sidebar" aria-label="Navigation AdminAkadex">
        <div class="sidebar-brand">
          <img src="${window.AKADEX_ADMIN.logoUrl}" alt="">
          <div><strong>AdminAkadex</strong><span>Contrôle plateforme</span></div>
        </div>
        <nav class="sidebar-nav">${navMarkup()}</nav>
        <div class="sidebar-foot">
          <div class="user-chip">
            <div class="avatar">${esc(initials(name))}</div>
            <div><strong>${esc(name)}</strong><span>${esc(user.role || 'admin')}</span></div>
          </div>
          <button class="btn btn-ghost" type="button" id="logout">Déconnexion</button>
        </div>
      </aside>
      <div class="main">
        <header class="topbar">
          <button class="menu-btn" type="button" id="menu-toggle" aria-label="Menu">☰</button>
          <div class="breadcrumbs" id="crumbs">AdminAkadex</div>
          <div class="topbar-actions">
            <a class="btn btn-secondary" href="${window.AKADEX_ADMIN.landingUrl || '/'}" target="_blank" rel="noopener">Site public</a>
          </div>
        </header>
        <main class="content" id="content"></main>
      </div>
    </div>`;

  document.getElementById('logout').addEventListener('click', () => {
    clearSession();
    state.user = null;
    location.hash = '#/login';
    renderLogin(root);
  });
  const shell = document.querySelector('.shell');
  document.getElementById('menu-toggle')?.addEventListener('click', () => {
    shell?.classList.toggle('sidebar-open');
  });
  document.getElementById('sidebar-overlay')?.addEventListener('click', () => {
    shell?.classList.remove('sidebar-open');
  });
  document.querySelectorAll('[data-nav]').forEach((a) => {
    a.addEventListener('click', () => shell?.classList.remove('sidebar-open'));
  });
  route();
}

async function route() {
  const content = document.getElementById('content');
  if (!content || !state.user) return;
  if (!ensureFreshSession()) {
    clearSession();
    state.user = null;
    renderLogin(document.getElementById('app'), 'Session expirée. Reconnectez-vous.');
    return;
  }
  const { page, id } = parseRoute();
  document.querySelectorAll('[data-nav]').forEach((a) => {
    const href = a.getAttribute('href');
    a.classList.toggle(
      'active',
      href === `#/${page}` || (page.startsWith('cours') && href === '#/cours'),
    );
  });
  document.getElementById('crumbs').textContent =
    NAV_FLAT.find((n) => n.href === `#/${page}`)?.label || page;

  try {
    switch (page) {
      case 'dashboard':
        await renderDashboard(content);
        break;
      case 'utilisateurs':
        await renderUsers(content);
        break;
      case 'etudiants':
        await renderUsers(content, { roleFilter: 'student' });
        break;
      case 'enseignants':
        await renderUsers(content, { roleFilter: 'teacher' });
        break;
      case 'cours':
        await renderCourses(content, id);
        break;
      case 'domaines':
        await renderDomains(content);
        break;
      case 'modules':
        await renderModules(content);
        break;
      case 'lecons':
        await renderLessons(content);
        break;
      case 'documents':
        await renderDocuments(content);
        break;
      case 'inscriptions':
        await renderEnrollments(content);
        break;
      case 'paiements':
        await renderPayments(content);
        break;
      case 'notifications':
        await renderNotifications(content);
        break;
      case 'communaute':
        await renderPosts(content);
        break;
      case 'structure':
        await renderStructure(content);
        break;
      case 'parametres':
        await renderSettings(content, state.user);
        break;
      default:
        location.hash = '#/dashboard';
    }
    attachDialogClose(content);
  } catch (e) {
    if (e.status === 401 || e.status === 403) {
      clearSession();
      state.user = null;
      renderLogin(document.getElementById('app'), e.message || 'Accès refusé.');
      return;
    }
    content.innerHTML = `<div class="alert alert-error">${esc(e.message)}</div>`;
  }
}

async function boot() {
  const root = document.getElementById('app');
  const stored = getStoredUser();
  if (stored && isAdminUser(stored) && ensureFreshSession()) {
    try {
      state.user = await fetchMe();
      if (!isAdminUser(state.user)) throw new Error('forbidden');
      renderShell(root);
      return;
    } catch {
      clearSession();
    }
  } else {
    clearSession();
  }
  renderLogin(root);
}

window.addEventListener('hashchange', () => {
  if (state.user) route();
});

document.addEventListener('visibilitychange', () => {
  if (document.visibilityState === 'visible' && state.user && !ensureFreshSession()) {
    clearSession();
    state.user = null;
    renderLogin(document.getElementById('app'), 'Session expirée. Reconnectez-vous.');
  }
});

boot();
