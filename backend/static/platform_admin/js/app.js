import {
  clearSession,
  fetchMe,
  getStoredUser,
  isAdminUser,
  login,
} from './api.js';
import { esc, initials } from './utils.js';
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

const NAV = [
  { href: '#/dashboard', label: 'Dashboard', icon: '▣' },
  { href: '#/utilisateurs', label: 'Utilisateurs', icon: '◎' },
  { href: '#/etudiants', label: 'Étudiants', icon: '◉' },
  { href: '#/enseignants', label: 'Enseignants', icon: '◈' },
  { href: '#/cours', label: 'Cours', icon: '▶' },
  { href: '#/domaines', label: 'Catégories', icon: '◇' },
  { href: '#/modules', label: 'Modules', icon: '▦' },
  { href: '#/lecons', label: 'Leçons', icon: '☰' },
  { href: '#/documents', label: 'Documents', icon: '▤' },
  { href: '#/inscriptions', label: 'Inscriptions', icon: '⇢' },
  { href: '#/paiements', label: 'Paiements', icon: '¤' },
  { href: '#/notifications', label: 'Notifications', icon: '◉' },
  { href: '#/communaute', label: 'Communauté', icon: '💬' },
  { href: '#/structure', label: 'Universités', icon: '⌂' },
  { href: '#/parametres', label: 'Paramètres', icon: '⚙' },
];

let state = { user: null };

function parseRoute() {
  const hash = (location.hash || '#/dashboard').replace(/^#\/?/, '');
  const [page, id] = hash.split('/');
  return { page: page || 'dashboard', id: id || null };
}

function renderLogin(root, err = '') {
  root.innerHTML = `
    <div class="login-wrap">
      <div class="login-card">
        <img src="${window.AKADEX_ADMIN.logoUrl}" alt="Akadex" class="login-logo">
        <h1>Administration</h1>
        <p>Centre de contrôle Akadex</p>
        ${err ? `<div class="alert alert-error">${esc(err)}</div>` : ''}
        <form id="login-form">
          <div class="field"><label>E-mail</label><input name="email" type="email" required autocomplete="username"></div>
          <div class="field"><label>Mot de passe</label><input name="password" type="password" required autocomplete="current-password"></div>
          <button class="btn btn-primary" type="submit" style="width:100%">Se connecter</button>
        </form>
        <p class="login-note">Accès réservé aux administrateurs (rôle admin ou staff).</p>
      </div>
    </div>`;
  document.getElementById('login-form').addEventListener('submit', async (ev) => {
    ev.preventDefault();
    const fd = new FormData(ev.target);
    try {
      const user = await login(fd.get('email'), fd.get('password'));
      if (!isAdminUser(user)) {
        clearSession();
        renderLogin(root, 'Ce compte n’a pas les droits administrateur.');
        return;
      }
      state.user = user;
      renderShell(root);
    } catch (e) {
      renderLogin(root, e.message);
    }
  });
}

function renderShell(root) {
  const user = state.user;
  const name = user.full_name || user.email || 'Admin';
  root.innerHTML = `
    <div class="shell">
      <div class="sidebar-overlay" id="sidebar-overlay"></div>
      <aside class="sidebar">
        <div class="sidebar-brand">
          <img src="${window.AKADEX_ADMIN.logoUrl}" alt="">
          <div><strong>Akadex</strong><span>Admin</span></div>
        </div>
        <nav class="sidebar-nav">
          ${NAV.map((n) => `<a href="${n.href}" data-nav="${n.href}"><span>${n.icon}</span> ${n.label}</a>`).join('')}
        </nav>
        <div class="sidebar-foot">
          <div class="user-chip">
            <div class="avatar">${esc(initials(name))}</div>
            <div><strong>${esc(name)}</strong><span>${esc(user.role)}</span></div>
          </div>
          <button class="btn btn-ghost" type="button" id="logout">Déconnexion</button>
        </div>
      </aside>
      <div class="main">
        <header class="topbar">
          <button class="menu-btn" type="button" id="menu-toggle" aria-label="Menu">☰</button>
          <div class="breadcrumbs" id="crumbs">Admin</div>
          <div class="topbar-actions"><a class="btn btn-secondary" href="/" target="_blank">Site</a></div>
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
  route();
}

async function route() {
  const content = document.getElementById('content');
  if (!content || !state.user) return;
  const { page, id } = parseRoute();
  document.querySelectorAll('[data-nav]').forEach((a) => {
    const href = a.getAttribute('href');
    a.classList.toggle(
      'active',
      href === `#/${page}` || (page.startsWith('cours') && href === '#/cours'),
    );
  });
  document.getElementById('crumbs').textContent =
    NAV.find((n) => n.href === `#/${page}`)?.label || page;

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
  } catch (e) {
    content.innerHTML = `<div class="alert alert-error">${esc(e.message)}</div>`;
  }
}

async function boot() {
  const root = document.getElementById('app');
  const stored = getStoredUser();
  if (stored && isAdminUser(stored)) {
    try {
      state.user = await fetchMe();
      if (!isAdminUser(state.user)) throw new Error('forbidden');
      renderShell(root);
      return;
    } catch {
      clearSession();
    }
  }
  renderLogin(root);
}

window.addEventListener('hashchange', () => {
  if (state.user) route();
});

boot();
