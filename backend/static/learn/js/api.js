const TOKEN_KEY = 'akadex_learn_access';
const REFRESH_KEY = 'akadex_learn_refresh';
const USER_KEY = 'akadex_learn_user';
const WEB_TOKEN_KEY = 'akadex_web_access';
const WEB_REFRESH_KEY = 'akadex_web_refresh';
const WEB_USER_KEY = 'akadex_web_user';

function apiBase() {
  return (window.AKADEX_LEARN?.apiBase || '/api/').replace(/\/?$/, '/');
}

export function getAccessToken() {
  return (
    localStorage.getItem(TOKEN_KEY) ||
    localStorage.getItem(WEB_TOKEN_KEY) ||
    ''
  );
}

export function isLoggedIn() {
  return Boolean(getAccessToken());
}

export function openLoginModal() {
  document.querySelector('[data-auth-open="login"]')?.click();
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
  if (access) {
    localStorage.setItem(TOKEN_KEY, access);
    localStorage.setItem(WEB_TOKEN_KEY, access);
  }
  if (refresh) {
    localStorage.setItem(REFRESH_KEY, refresh);
    localStorage.setItem(WEB_REFRESH_KEY, refresh);
  }
  if (user) {
    const raw = JSON.stringify(user);
    localStorage.setItem(USER_KEY, raw);
    localStorage.setItem(WEB_USER_KEY, raw);
  }
}

async function refreshAccess() {
  const refresh =
    localStorage.getItem(REFRESH_KEY) ||
    localStorage.getItem(WEB_REFRESH_KEY);
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
    localStorage.setItem(WEB_TOKEN_KEY, data.access);
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
  saveSession({ user });
  return user;
}

export async function fetchPricing() {
  try {
    const data = await api('payments/pricing/');
    return {
      sale: Number(data.sale_price_usd) || 15,
      list: Number(data.list_price_usd) || 29,
      currency: data.currency || 'USD',
    };
  } catch {
    return { sale: 15, list: 29, currency: 'USD' };
  }
}

/** Opérateurs Mobile Money (mêmes clés que l’app / PawaPay). */
export const MOMO_PROVIDERS = [
  { key: 'vodacom_mpesa', label: 'M-Pesa', brand: 'Vodacom' },
  { key: 'airtel', label: 'Airtel Money', brand: 'Airtel' },
  { key: 'orange', label: 'Orange Money', brand: 'Orange' },
];

export async function initiateDeposit({ phone, provider, amount, courseIds }) {
  return api('payments/deposits/', {
    method: 'POST',
    body: JSON.stringify({
      phone,
      provider,
      amount,
      course_ids: courseIds,
      statement: 'Akadex cours',
    }),
  });
}

export async function getDepositStatus(depositId) {
  return api(`payments/deposits/${depositId}/`);
}

export async function fetchCourses(params = {}) {
  const q = new URLSearchParams();
  q.set('page_size', params.pageSize || '100');
  if (params.search) q.set('search', params.search);
  if (params.domain) q.set('domains__slug', params.domain);
  return unwrapList(await api(`courses/?${q}`));
}

export async function fetchDomains() {
  return unwrapList(await api('learning-domains/?page_size=50'));
}

export async function fetchCourseOutline(id) {
  return api(`course-outlines/${id}/`);
}

export async function fetchPurchasedIds() {
  if (!getAccessToken()) return [];
  try {
    const data = await api('payments/my-courses/');
    return (data.course_ids || []).map(String);
  } catch {
    return [];
  }
}

export async function fetchDocuments(params = {}) {
  const q = new URLSearchParams();
  q.set('page_size', params.pageSize || '48');
  q.set('is_approved', 'true');
  if (params.search) q.set('search', params.search);
  if (params.docType) q.set('doc_type', params.docType);
  if (params.isFree !== undefined && params.isFree !== null && params.isFree !== '') {
    q.set('is_free', params.isFree ? 'true' : 'false');
  }
  return unwrapList(await api(`documents/?${q}`));
}

export async function fetchDocument(id) {
  return api(`documents/${id}/`);
}

export async function purchaseDocument(id) {
  return api(`documents/${id}/purchase/`, { method: 'POST', body: '{}' });
}

export async function downloadDocument(id) {
  return api(`documents/${id}/download/`, { method: 'POST', body: '{}' });
}
