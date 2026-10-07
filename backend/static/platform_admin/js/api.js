const TOKEN_KEY = 'akadex_admin_access';
const REFRESH_KEY = 'akadex_admin_refresh';
const USER_KEY = 'akadex_admin_user';
const ACTIVITY_KEY = 'akadex_admin_activity';
/** Inactivité max avant déconnexion forcée (2 h). */
const IDLE_MS = 2 * 60 * 60 * 1000;

function apiBase() {
  return (window.AKADEX_ADMIN?.apiBase || '/api/').replace(/\/?$/, '/');
}

export function getAccessToken() {
  return localStorage.getItem(TOKEN_KEY) || '';
}

export function getStoredUser() {
  try {
    return JSON.parse(localStorage.getItem(USER_KEY) || 'null');
  } catch {
    return null;
  }
}

export function clearSession() {
  localStorage.removeItem(TOKEN_KEY);
  localStorage.removeItem(REFRESH_KEY);
  localStorage.removeItem(USER_KEY);
  localStorage.removeItem(ACTIVITY_KEY);
}

function touchActivity() {
  localStorage.setItem(ACTIVITY_KEY, String(Date.now()));
}

/** Expire la session admin après inactivité prolongée. */
export function ensureFreshSession() {
  const raw = localStorage.getItem(ACTIVITY_KEY);
  if (!raw) {
    if (getAccessToken()) touchActivity();
    return true;
  }
  const last = Number(raw);
  if (!Number.isFinite(last) || Date.now() - last > IDLE_MS) {
    clearSession();
    return false;
  }
  touchActivity();
  return true;
}

/** Évite de mélanger tokens étudiant / enseignant avec la session admin. */
function clearOtherAkadexSessions() {
  [
    'akadex_access',
    'akadex_refresh',
    'akadex_user',
    'akadex_teacher_access',
    'akadex_teacher_refresh',
    'akadex_teacher_user',
    'akadex_learn_access',
    'akadex_learn_refresh',
    'akadex_learn_user',
  ].forEach((k) => localStorage.removeItem(k));
}

export function saveSession({ access, refresh, user }) {
  if (access) localStorage.setItem(TOKEN_KEY, access);
  if (refresh) localStorage.setItem(REFRESH_KEY, refresh);
  if (user) localStorage.setItem(USER_KEY, JSON.stringify(user));
  touchActivity();
}

async function refreshAccess() {
  const refresh = localStorage.getItem(REFRESH_KEY);
  if (!refresh) return false;
  const res = await fetch(`${apiBase()}auth/token/refresh/`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ refresh }),
  });
  if (!res.ok) return false;
  const data = await res.json();
  if (data.access) {
    localStorage.setItem(TOKEN_KEY, data.access);
    touchActivity();
    return true;
  }
  return false;
}

export async function api(path, options = {}) {
  const isAdminLogin = String(path).includes('auth/admin/token');
  if (!isAdminLogin) {
    const hadToken = !!getAccessToken();
    if (hadToken && !ensureFreshSession()) {
      const err = new Error('Session expirée. Reconnectez-vous.');
      err.status = 401;
      throw err;
    }
  }

  const url = path.startsWith('http') ? path : `${apiBase()}${path.replace(/^\//, '')}`;
  const headers = { ...(options.headers || {}) };
  if (!(options.body instanceof FormData)) {
    headers['Content-Type'] = headers['Content-Type'] || 'application/json';
  }
  const token = getAccessToken();
  if (token) headers.Authorization = `Bearer ${token}`;

  let res = await fetch(url, { ...options, headers });
  if (res.status === 401 && (await refreshAccess())) {
    headers.Authorization = `Bearer ${getAccessToken()}`;
    res = await fetch(url, { ...options, headers });
  }

  const text = await res.text();
  let data = null;
  try {
    data = text ? JSON.parse(text) : null;
  } catch {
    data = text;
  }

  if (!res.ok) {
    const msg =
      (data && (data.detail || data.message || data.error)) ||
      (typeof data === 'object' && data
        ? Object.values(data).flat().join(' ')
        : null) ||
      `Erreur ${res.status}`;
    const err = new Error(typeof msg === 'string' ? msg : JSON.stringify(msg));
    err.status = res.status;
    err.data = data;
    throw err;
  }
  touchActivity();
  return data;
}

export function unwrapList(data) {
  if (Array.isArray(data)) return data;
  if (data && Array.isArray(data.results)) return data.results;
  return [];
}

export async function login(email, password) {
  clearOtherAkadexSessions();
  const tokens = await api('auth/admin/token/', {
    method: 'POST',
    body: JSON.stringify({ email, password }),
  });
  saveSession({ access: tokens.access, refresh: tokens.refresh });
  const user = tokens.user || (await api('auth/me/'));
  if (!isAdminUser(user)) {
    clearSession();
    throw new Error('Accès réservé aux administrateurs Akadex.');
  }
  saveSession({ user });
  return user;
}

export async function fetchMe() {
  if (!ensureFreshSession()) {
    throw new Error('Session expirée');
  }
  const user = await api('auth/me/');
  if (!isAdminUser(user)) {
    clearSession();
    throw new Error('Accès refusé');
  }
  saveSession({ user });
  return user;
}

export function isAdminUser(user) {
  if (!user) return false;
  return user.role === 'admin' || user.is_staff === true || user.is_superuser === true;
}
