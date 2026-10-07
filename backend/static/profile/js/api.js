const TOKEN_KEY = 'akadex_web_access';
const REFRESH_KEY = 'akadex_web_refresh';
const USER_KEY = 'akadex_web_user';

function apiBase() {
  return (window.AKADEX_PROFILE?.apiBase || '/api/').replace(/\/?$/, '/');
}

export function getAccessToken() {
  return (
    localStorage.getItem(TOKEN_KEY) ||
    localStorage.getItem('akadex_learn_access') ||
    ''
  );
}

export function isLoggedIn() {
  return Boolean(getAccessToken());
}

export function getStoredUser() {
  try {
    return (
      JSON.parse(localStorage.getItem(USER_KEY) || 'null') ||
      JSON.parse(localStorage.getItem('akadex_learn_user') || 'null')
    );
  } catch {
    return null;
  }
}

async function refreshAccess() {
  const refresh =
    localStorage.getItem(REFRESH_KEY) ||
    localStorage.getItem('akadex_learn_refresh');
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
    localStorage.setItem('akadex_learn_access', data.access);
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
      (data && (data.detail || data.message)) ||
      `Erreur ${res.status}`;
    const err = new Error(typeof msg === 'string' ? msg : JSON.stringify(msg));
    err.status = res.status;
    throw err;
  }
  return data;
}

export async function fetchStudentDashboard() {
  return api('student-dashboard/');
}
