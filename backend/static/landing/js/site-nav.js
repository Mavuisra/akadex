/**
 * Navbar partagée : thème + menu mobile + recherche.
 */
export function initSiteNav() {
  const root = document.documentElement;
  const btn = document.getElementById('theme-toggle');
  const meta = document.getElementById('meta-theme-color');

  function applyTheme(theme) {
    root.setAttribute('data-theme', theme);
    try {
      localStorage.setItem('akadex-theme', theme);
    } catch {
      /* ignore */
    }
    if (meta) {
      meta.setAttribute('content', theme === 'dark' ? '#121212' : '#0056d2');
    }
    if (btn) {
      btn.setAttribute(
        'aria-label',
        theme === 'dark' ? 'Passer en thème clair' : 'Passer en thème sombre'
      );
    }
  }

  if (btn) {
    btn.addEventListener('click', () => {
      applyTheme(root.getAttribute('data-theme') === 'dark' ? 'light' : 'dark');
    });
  }

  const menuBtn = document.getElementById('nav-menu-btn');
  const drawer = document.getElementById('nav-drawer');

  function setMenuOpen(open) {
    if (!drawer || !menuBtn) return;
    drawer.hidden = !open;
    drawer.setAttribute('data-open', open ? 'true' : 'false');
    menuBtn.setAttribute('aria-expanded', open ? 'true' : 'false');
  }

  if (menuBtn && drawer) {
    menuBtn.addEventListener('click', (e) => {
      e.stopPropagation();
      setMenuOpen(drawer.getAttribute('data-open') !== 'true');
    });
    document.addEventListener('keydown', (e) => {
      if (e.key === 'Escape') setMenuOpen(false);
    });
    document.addEventListener('click', (e) => {
      if (
        drawer.getAttribute('data-open') === 'true' &&
        !drawer.contains(e.target) &&
        !menuBtn.contains(e.target)
      ) {
        setMenuOpen(false);
      }
    });
  }

  const navForm = document.getElementById('nav-search');
  if (navForm) {
    navForm.addEventListener('submit', (e) => {
      e.preventDefault();
      const q = (document.getElementById('nav-q') || {}).value || '';
      const trimmed = String(q).trim();
      location.href = trimmed
        ? `/apprendre/#/?q=${encodeURIComponent(trimmed)}`
        : '/apprendre/';
    });
  }

  const AUTH_KEYS = [
    'akadex_web_access',
    'akadex_web_refresh',
    'akadex_web_user',
    'akadex_learn_access',
    'akadex_learn_refresh',
    'akadex_learn_user',
    'akadex_teacher_access',
    'akadex_teacher_refresh',
    'akadex_teacher_user',
  ];

  function isLoggedIn() {
    return Boolean(
      localStorage.getItem('akadex_web_access') ||
        localStorage.getItem('akadex_learn_access')
    );
  }

  function logout() {
    AUTH_KEYS.forEach((k) => {
      try {
        localStorage.removeItem(k);
      } catch {
        /* ignore */
      }
    });
    syncAuthChrome();
    setMenuOpen(false);
    const path = location.pathname || '/';
    if (path.startsWith('/profil')) {
      location.href = '/';
      return;
    }
    location.reload();
  }

  function syncAuthChrome() {
    const logged = isLoggedIn();
    document.querySelectorAll('[data-guest-only]').forEach((el) => {
      el.hidden = logged;
      el.classList.toggle('is-auth-hidden', logged);
    });
    document.querySelectorAll('[data-auth-only]').forEach((el) => {
      el.hidden = !logged;
      el.classList.toggle('is-auth-hidden', !logged);
    });
  }
  syncAuthChrome();
  window.addEventListener('storage', syncAuthChrome);
  window.__akadexSyncAuthChrome = syncAuthChrome;

  document.getElementById('nav-logout')?.addEventListener('click', logout);
  document.querySelectorAll('[data-logout]').forEach((el) => {
    el.addEventListener('click', logout);
  });

  window.__akadexCloseMenu = () => setMenuOpen(false);
  return { applyTheme, setMenuOpen, syncAuthChrome, logout };
}
