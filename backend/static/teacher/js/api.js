const TOKEN_KEY = 'akadex_teacher_access';
const REFRESH_KEY = 'akadex_teacher_refresh';
const USER_KEY = 'akadex_teacher_user';

function apiBase() {
  return (window.AKADEX_TEACHER?.apiBase || '/api/').replace(/\/?$/, '/');
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
}

export function saveSession({ access, refresh, user }) {
  if (access) localStorage.setItem(TOKEN_KEY, access);
  if (refresh) localStorage.setItem(REFRESH_KEY, refresh);
  if (user) localStorage.setItem(USER_KEY, JSON.stringify(user));
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
    return true;
  }
  return false;
}

export async function api(path, options = {}) {
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
  return data;
}

export function unwrapList(data) {
  if (Array.isArray(data)) return data;
  if (data && Array.isArray(data.results)) return data.results;
  return [];
}

export async function login(email, password) {
  const tokens = await api('auth/token/', {
    method: 'POST',
    body: JSON.stringify({ email, password }),
  });
  saveSession({ access: tokens.access, refresh: tokens.refresh });
  const user = await api('auth/me/');
  if (user.role !== 'teacher' && user.role !== 'admin') {
    clearSession();
    throw new Error('Cet espace est réservé aux enseignants.');
  }
  saveSession({ user });
  return user;
}

export async function fetchMe() {
  const user = await api('auth/me/');
  saveSession({ user });
  return user;
}
