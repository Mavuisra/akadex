/**
 * Auth modal Akadex — login Coursera-like + inscription complète (étudiant).
 * Sécurité : validation serveur (Django), throttle API, JWT Bearer,
 * pas de stockage du mot de passe, double-submit lock, messages d’erreur génériques login.
 */
const AUTH_KEYS = {
  access: 'akadex_web_access',
  refresh: 'akadex_web_refresh',
  user: 'akadex_web_user',
  learnAccess: 'akadex_learn_access',
  learnRefresh: 'akadex_learn_refresh',
  learnUser: 'akadex_learn_user',
  teacherAccess: 'akadex_teacher_access',
  teacherRefresh: 'akadex_teacher_refresh',
  teacherUser: 'akadex_teacher_user',
};

const API = '/api/';

function $(id) {
  return document.getElementById(id);
}

function normalizeEmail(v) {
  return String(v || '').trim().toLowerCase();
}

function safeUsername(email) {
  const base = email.split('@')[0] || 'user';
  return base.replace(/[^a-zA-Z0-9_]/g, '_').slice(0, 40) || 'user';
}

function flattenErrors(data) {
  if (!data || typeof data !== 'object') return 'Une erreur est survenue.';
  if (typeof data.detail === 'string') return data.detail;
  const parts = [];
  Object.keys(data).forEach((k) => {
    const v = data[k];
    if (Array.isArray(v)) parts.push(`${k}: ${v.join(' ')}`);
    else if (typeof v === 'string') parts.push(v);
    else if (v && typeof v === 'object') parts.push(flattenErrors(v));
  });
  return parts.filter(Boolean).join(' · ') || 'Une erreur est survenue.';
}

function passwordScore(pwd) {
  let s = 0;
  if (pwd.length >= 8) s += 1;
  if (pwd.length >= 12) s += 1;
  if (/[A-Z]/.test(pwd) && /[a-z]/.test(pwd)) s += 1;
  if (/\d/.test(pwd)) s += 1;
  if (/[^A-Za-z0-9]/.test(pwd)) s += 1;
  return Math.min(s, 4);
}

async function apiJson(path, options = {}) {
  const headers = { ...(options.headers || {}) };
  if (!(options.body instanceof FormData)) {
    headers['Content-Type'] = headers['Content-Type'] || 'application/json';
  }
  const res = await fetch(`${API}${path.replace(/^\//, '')}`, {
    ...options,
    headers,
    credentials: 'same-origin',
  });
  const text = await res.text();
  let data = null;
  try {
    data = text ? JSON.parse(text) : null;
  } catch {
    data = text;
  }
  if (!res.ok) {
    const err = new Error(flattenErrors(data));
    err.status = res.status;
    err.data = data;
    throw err;
  }
  return data;
}

function saveSession({ access, refresh, user }) {
  try {
    if (access) {
      localStorage.setItem(AUTH_KEYS.access, access);
      localStorage.setItem(AUTH_KEYS.learnAccess, access);
    }
    if (refresh) {
      localStorage.setItem(AUTH_KEYS.refresh, refresh);
      localStorage.setItem(AUTH_KEYS.learnRefresh, refresh);
    }
    if (user) {
      const raw = JSON.stringify(user);
      localStorage.setItem(AUTH_KEYS.user, raw);
      localStorage.setItem(AUTH_KEYS.learnUser, raw);
    }
    if (user && (user.role === 'teacher' || user.role === 'admin')) {
      if (access) localStorage.setItem(AUTH_KEYS.teacherAccess, access);
      if (refresh) localStorage.setItem(AUTH_KEYS.teacherRefresh, refresh);
      localStorage.setItem(AUTH_KEYS.teacherUser, JSON.stringify(user));
    }
  } catch (_) {
    /* private mode */
  }
}

function clearSensitiveInputs(root) {
  root.querySelectorAll('input[type="password"]').forEach((el) => {
    el.value = '';
  });
}

function redirectAfterLogin(_user) {
  // Espace étudiant : profil (suivi d’apprentissage).
  // Enseignant / admin : accès invitation uniquement via /enseignant/.
  if (typeof window.__akadexSyncAuthChrome === 'function') {
    window.__akadexSyncAuthChrome();
  }
  location.href = '/profil/';
}

export function initAuthModal({ onMenuClose } = {}) {
  const overlay = $('auth-overlay');
  if (!overlay) return;

  const titleEl = $('auth-title');
  const subEl = $('auth-sub');
  const errEl = $('auth-error');
  const backBtn = $('auth-back');
  const stepsEl = $('auth-signup-steps');
  const formEmail = $('auth-form-email');
  const formPass = $('auth-form-password');
  const formSignup = $('auth-form-signup');
  const orEl = $('auth-or');
  const googleBtn = $('auth-google');
  const switchEl = $('auth-switch');
  const emailInput = $('auth-email');
  const passInput = $('auth-password');
  const strengthBar = $('auth-strength-bar');
  const strengthLabel = $('auth-strength-label');

  let authMode = 'login';
  let authStep = 'email';
  let signupStep = 0;
  let pendingEmail = '';
  let busy = false;

  const signupData = {
    first_name: '',
    last_name: '',
    postnom: '',
    gender: '',
    birth_date: '',
    email: '',
    phone: '',
    password: '',
    password_confirm: '',
    terms: false,
  };

  function showError(msg) {
    if (!errEl) return;
    if (!msg) {
      errEl.textContent = '';
      errEl.setAttribute('data-show', 'false');
      return;
    }
    errEl.textContent = msg;
    errEl.setAttribute('data-show', 'true');
  }

  function setBusy(on, btn, labelIdle) {
    busy = on;
    if (!btn) return;
    btn.disabled = on;
    if (on) btn.dataset.label = btn.textContent;
    btn.textContent = on ? 'Patiente…' : labelIdle || btn.dataset.label || btn.textContent;
  }

  function updateStrength() {
    const pwd = $('su-password')?.value || '';
    const score = passwordScore(pwd);
    if (strengthBar) {
      strengthBar.dataset.score = String(score);
      strengthBar.style.width = `${(score / 4) * 100}%`;
    }
    if (strengthLabel) {
      const labels = ['Trop court', 'Faible', 'Moyen', 'Bon', 'Fort'];
      strengthLabel.textContent = pwd ? labels[score] : '';
    }
  }

  function paintSignupStep() {
    const panes = formSignup?.querySelectorAll('[data-signup-step]');
    panes?.forEach((p) => {
      p.hidden = Number(p.dataset.signupStep) !== signupStep;
    });
    if (stepsEl) {
      stepsEl.querySelectorAll('[data-step]').forEach((el) => {
        const n = Number(el.dataset.step);
        el.classList.toggle('active', n === signupStep);
        el.classList.toggle('done', n < signupStep);
      });
    }
    if (titleEl) {
      titleEl.textContent = signupStep === 0 ? 'Qui es-tu ?' : 'Ton compte';
    }
    if (subEl) {
      subEl.textContent =
        signupStep === 0
          ? 'Profil et identité'
          : 'E-mail, mot de passe et conditions';
    }
    if (backBtn) backBtn.hidden = false;
  }

  function setAuthStep(step) {
    authStep = step;
    showError('');
    overlay.classList.toggle('is-signup', authMode === 'signup' || step === 'signup');
    if (formEmail) formEmail.hidden = step !== 'email';
    if (formPass) formPass.hidden = step !== 'password';
    if (formSignup) formSignup.hidden = step !== 'signup';
    if (stepsEl) stepsEl.hidden = step !== 'signup';
    if (orEl) orEl.hidden = step !== 'email';
    if (googleBtn) googleBtn.hidden = step !== 'email';
    if (backBtn) backBtn.hidden = step === 'email' && authMode === 'login';

    if (step === 'signup') {
      paintSignupStep();
    } else if (step === 'password') {
      if (titleEl) titleEl.textContent = 'Bienvenue';
      if (subEl) subEl.textContent = `Connexion pour ${pendingEmail}`;
      if (backBtn) backBtn.hidden = false;
    } else {
      if (titleEl) titleEl.textContent = 'Se connecter ou créer un compte';
      if (subEl) {
        subEl.textContent = 'Apprends à ton rythme avec Akadex.';
      }
      if (backBtn) backBtn.hidden = true;
    }

    if (switchEl) {
      if (step === 'email') {
        switchEl.innerHTML =
          authMode === 'signup'
            ? 'Déjà un compte ? <button type="button" data-auth-mode="login">Se connecter</button>'
            : 'Nouveau sur Akadex ? <button type="button" data-auth-mode="signup">Créer un compte</button>';
      } else if (step === 'password') {
        switchEl.innerHTML =
          'Pas encore de compte ? <button type="button" data-auth-mode="signup">Créer un compte</button>';
      } else {
        switchEl.innerHTML =
          'Déjà inscrit ? <button type="button" data-auth-mode="login">Se connecter</button>';
      }
      switchEl.querySelectorAll('[data-auth-mode]').forEach((b) => {
        b.addEventListener('click', () => openAuth(b.getAttribute('data-auth-mode')));
      });
    }

    if (step === 'email') setTimeout(() => emailInput?.focus(), 40);
    if (step === 'password') setTimeout(() => passInput?.focus(), 40);
  }

  function openAuth(mode) {
    authMode = mode === 'signup' ? 'signup' : 'login';
    signupStep = 0;
    overlay.hidden = false;
    overlay.setAttribute('data-open', 'true');
    document.body.classList.add('auth-open');
    onMenuClose?.();
    if (authMode === 'signup') {
      setAuthStep('signup');
    } else {
      setAuthStep('email');
    }
    try {
      history.replaceState(null, '', `#authMode=${authMode}`);
    } catch (_) {}
  }

  function closeAuth() {
    overlay.setAttribute('data-open', 'false');
    overlay.hidden = true;
    document.body.classList.remove('auth-open');
    clearSensitiveInputs(overlay);
    setAuthStep('email');
    if (location.hash.includes('authMode')) {
      try {
        history.replaceState(null, '', location.pathname + location.search);
      } catch (_) {}
    }
  }

  function readSignupIdentity() {
    signupData.first_name = ($('su-first')?.value || '').trim();
    signupData.last_name = ($('su-last')?.value || '').trim();
    signupData.postnom = ($('su-postnom')?.value || '').trim();
    signupData.gender = $('su-gender')?.value || '';
    signupData.birth_date = $('su-birth')?.value || '';
    if (!signupData.last_name) return 'Le nom est obligatoire.';
    if (!signupData.postnom) return 'Le postnom est obligatoire.';
    if (!signupData.first_name) return 'Le prénom est obligatoire.';
    if (!signupData.gender) return 'Le sexe est obligatoire.';
    if (!signupData.birth_date) return 'La date de naissance est obligatoire.';
    const birth = new Date(signupData.birth_date);
    const now = new Date();
    if (Number.isNaN(birth.getTime()) || birth >= now) {
      return 'Date de naissance invalide.';
    }
    return null;
  }

  function readSignupAccount() {
    signupData.email = normalizeEmail($('su-email')?.value || pendingEmail);
    signupData.phone = ($('su-phone')?.value || '').trim();
    signupData.password = $('su-password')?.value || '';
    signupData.password_confirm = $('su-password2')?.value || '';
    if (!signupData.email || !signupData.email.includes('@')) {
      return 'Indique une adresse e-mail valide.';
    }
    if (!signupData.phone) return 'Le téléphone est obligatoire.';
    if (signupData.password.length < 8) {
      return 'Le mot de passe doit contenir au moins 8 caractères.';
    }
    if (passwordScore(signupData.password) < 2) {
      return 'Mot de passe trop faible (maj/min, chiffre recommandé).';
    }
    if (signupData.password !== signupData.password_confirm) {
      return 'Les mots de passe ne correspondent pas.';
    }
    return null;
  }

  function readSignupAccountFinal() {
    const err = readSignupAccount();
    if (err) return err;
    signupData.terms = Boolean($('su-terms')?.checked);
    if (!signupData.terms) return 'Tu dois accepter les conditions d’utilisation.';
    return null;
  }

  async function submitRegister() {
    const btn = $('su-submit');
    setBusy(true, btn, 'Créer mon compte');
    showError('');
    try {
      const payload = {
        email: signupData.email,
        username: safeUsername(signupData.email),
        password: signupData.password,
        password_confirm: signupData.password_confirm,
        first_name: signupData.first_name,
        last_name: signupData.last_name,
        postnom: signupData.postnom,
        phone: signupData.phone,
        role: 'student',
        gender: signupData.gender,
        birth_date: signupData.birth_date,
      };
      const data = await apiJson('auth/register/', {
        method: 'POST',
        body: JSON.stringify(payload),
      });
      saveSession({
        access: data.access,
        refresh: data.refresh,
        user: data.user,
      });
      clearSensitiveInputs(overlay);
      closeAuth();
      redirectAfterLogin(data.user || { role: 'student' });
    } catch (e) {
      showError(e.message || 'Inscription impossible.');
    } finally {
      setBusy(false, btn, 'Créer mon compte');
    }
  }

  async function loginWithPassword(email, password) {
    const data = await apiJson('auth/token/', {
      method: 'POST',
      body: JSON.stringify({ email: normalizeEmail(email), password }),
    });
    saveSession({
      access: data.access,
      refresh: data.refresh,
      user: data.user,
    });
    return data.user || {};
  }

  document.querySelectorAll('[data-auth-open]').forEach((el) => {
    el.addEventListener('click', (ev) => {
      ev.preventDefault();
      openAuth(el.getAttribute('data-auth-open') || 'login');
    });
  });

  $('auth-close')?.addEventListener('click', closeAuth);
  overlay.addEventListener('click', (ev) => {
    if (ev.target === overlay) closeAuth();
  });
  document.addEventListener('keydown', (ev) => {
    if (ev.key === 'Escape' && overlay.getAttribute('data-open') === 'true') {
      closeAuth();
    }
  });

  backBtn?.addEventListener('click', () => {
    if (authStep === 'password') {
      setAuthStep('email');
      return;
    }
    if (authStep === 'signup') {
      if (signupStep > 0) {
        signupStep -= 1;
        paintSignupStep();
        showError('');
        return;
      }
      openAuth('login');
    }
  });

  formEmail?.addEventListener('submit', (ev) => {
    ev.preventDefault();
    if (busy) return;
    pendingEmail = normalizeEmail(emailInput?.value);
    if (!pendingEmail || !pendingEmail.includes('@')) {
      showError('Indique une adresse e-mail valide.');
      return;
    }
    if (authMode === 'signup') {
      if ($('su-email')) $('su-email').value = pendingEmail;
      signupStep = 0;
      setAuthStep('signup');
      return;
    }
    setAuthStep('password');
  });

  formPass?.addEventListener('submit', async (ev) => {
    ev.preventDefault();
    if (busy) return;
    const pwd = passInput?.value || '';
    const btn = $('auth-login-btn');
    setBusy(true, btn, 'Se connecter');
    showError('');
    try {
      const user = await loginWithPassword(pendingEmail || emailInput?.value, pwd);
      clearSensitiveInputs(overlay);
      closeAuth();
      redirectAfterLogin(user);
    } catch (e) {
      // Message générique : évite d’indiquer si l’e-mail existe.
      showError(
        e.status === 429
          ? 'Trop de tentatives. Réessaie dans quelques minutes.'
          : 'E-mail ou mot de passe incorrect.'
      );
    } finally {
      setBusy(false, btn, 'Se connecter');
    }
  });

  formSignup?.addEventListener('submit', async (ev) => {
    ev.preventDefault();
    if (busy) return;
    if (signupStep === 0) {
      const err = readSignupIdentity();
      if (err) return showError(err);
      showError('');
      signupStep = 1;
      if ($('su-email') && !$('su-email').value) {
        $('su-email').value = pendingEmail || '';
      }
      paintSignupStep();
      return;
    }
    if (signupStep === 1) {
      const err = readSignupAccountFinal();
      if (err) return showError(err);
      await submitRegister();
    }
  });

  $('su-password')?.addEventListener('input', updateStrength);

  googleBtn?.addEventListener('click', () => {
    showError('Google arrive bientôt. Utilise e-mail + mot de passe.');
  });

  if (/authMode=login/i.test(location.hash)) openAuth('login');
  else if (/authMode=signup/i.test(location.hash)) openAuth('signup');

  return { openAuth, closeAuth };
}
