import { api, getStoredUser } from '../api.js';
import { esc } from '../utils.js';

const CONTENT_TYPES = [
  { value: 'video', label: 'Vidéo' },
  { value: 'pdf', label: 'PDF' },
  { value: 'slides', label: 'Diapositives' },
  { value: 'tp', label: 'TP' },
  { value: 'td', label: 'TD' },
  { value: 'exercise', label: 'Exercice' },
  { value: 'exam', label: 'Examen' },
  { value: 'solution', label: 'Corrigé' },
  { value: 'book', label: 'Livre / support' },
  { value: 'quiz', label: 'Quiz' },
  { value: 'assignment', label: 'Devoir' },
  { value: 'text', label: 'Texte' },
  { value: 'link', label: 'Lien' },
  { value: 'live', label: 'Live' },
];

const DIFFICULTIES = ['Débutant', 'Intermédiaire', 'Avancé'];

const FALLBACK_DOMAINS = [
  { slug: 'informatique', name: 'Informatique' },
  { slug: 'droit', name: 'Droit' },
  { slug: 'medecine', name: 'Médecine' },
  { slug: 'economie', name: 'Économie & Gestion' },
  { slug: 'comptabilite', name: 'Comptabilité' },
  { slug: 'marketing', name: 'Marketing' },
  { slug: 'sciences', name: 'Sciences' },
  { slug: 'lettres', name: 'Lettres & SHS' },
  { slug: 'ingenierie', name: 'Ingénierie' },
  { slug: 'agronomie', name: 'Agronomie' },
];

function newLesson() {
  return {
    title: '',
    content_type: 'video',
    description: '',
    video_url: '',
    external_url: '',
    duration_seconds: 0,
    file: null,
  };
}

function newModule() {
  return {
    title: '',
    description: '',
    lessons: [newLesson()],
  };
}

function tagFieldHtml({ id, selected, placeholder }) {
  const chips = selected
    .map(
      (t) => `
    <span class="tag-chip" data-kind="${esc(t.kind)}" data-value="${esc(t.value)}">
      <span class="tag-kind">${t.kind === 'promo' ? 'Promo' : 'Domaine'}</span>
      ${esc(t.label)}
      <button type="button" class="tag-x" aria-label="Retirer">×</button>
    </span>`,
    )
    .join('');
  return `
    <div class="tag-field" id="${id}">
      <div class="tag-chips" id="${id}-chips">${chips}</div>
      <input
        type="text"
        class="tag-input"
        id="${id}-input"
        autocomplete="off"
        placeholder="${esc(placeholder)}"
      >
      <div class="tag-suggest" id="${id}-suggest" hidden></div>
    </div>
  `;
}

function slugifyLabel(label) {
  return String(label || '')
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-+|-+$/g, '')
    .slice(0, 64);
}

function modulesHtml(modules) {
  if (!modules.length) {
    return '<div class="empty"><strong>Aucun module</strong>Ajoutez au moins un module avec ses leçons.</div>';
  }
  return modules
    .map(
      (m, mi) => `
    <div class="module-card" data-mi="${mi}">
      <div class="module-h">
        <span>☰</span>
        <strong style="flex:1">Module ${mi + 1}</strong>
        <button type="button" class="btn btn-ghost btn-rm-module" data-mi="${mi}">Supprimer</button>
      </div>
      <div style="padding:12px 14px;display:grid;gap:10px">
        <div class="field" style="margin:0">
          <label>Titre du module *</label>
          <input class="mod-title" data-mi="${mi}" value="${esc(m.title)}" placeholder="Ex. Introduction" required>
        </div>
        <div class="field" style="margin:0">
          <label>Description du module</label>
          <textarea class="mod-desc" data-mi="${mi}" rows="2" placeholder="Objectifs de ce module">${esc(m.description)}</textarea>
        </div>
        ${(m.lessons || [])
          .map(
            (l, li) => `
          <div class="lesson-editor" data-mi="${mi}" data-li="${li}" style="border:1px solid var(--border);border-radius:8px;padding:12px;background:#fafbff">
            <div style="display:flex;align-items:center;gap:8px;margin-bottom:8px">
              <strong style="flex:1">Leçon ${li + 1}</strong>
              <button type="button" class="btn btn-ghost btn-rm-lesson" data-mi="${mi}" data-li="${li}">Retirer</button>
            </div>
            <div class="form-grid">
              <div class="field full" style="margin:0">
                <label>Titre de la leçon *</label>
                <input class="les-title" data-mi="${mi}" data-li="${li}" value="${esc(l.title)}" placeholder="Ex. Notion de variable" required>
              </div>
              <div class="field" style="margin:0">
                <label>Type de contenu *</label>
                <select class="les-type" data-mi="${mi}" data-li="${li}">
                  ${CONTENT_TYPES.map(
                    (t) =>
                      `<option value="${t.value}" ${l.content_type === t.value ? 'selected' : ''}>${t.label}</option>`,
                  ).join('')}
                </select>
              </div>
              <div class="field" style="margin:0">
                <label>Durée (secondes)</label>
                <input class="les-duration" type="number" min="0" data-mi="${mi}" data-li="${li}" value="${esc(l.duration_seconds || 0)}">
              </div>
              <div class="field full les-file-wrap" style="margin:0">
                <label class="les-file-label">${
                  l.content_type === 'video' || l.content_type === 'live'
                    ? 'Vidéo depuis l’ordinateur'
                    : 'Fichier (PDF, diapos, TP…)'
                }</label>
                <input class="les-file" type="file" data-mi="${mi}" data-li="${li}" accept="${
                  l.content_type === 'video' || l.content_type === 'live'
                    ? 'video/mp4,video/webm,video/quicktime,video/x-msvideo,.mp4,.webm,.mov,.avi,.mkv'
                    : '.pdf,.ppt,.pptx,.doc,.docx,.xls,.xlsx,image/*,audio/*,video/*'
                }">
                <small class="les-file-hint" style="color:var(--ink-soft)">${
                  l.file
                    ? esc(l.file.name)
                    : l.content_type === 'video' || l.content_type === 'live'
                      ? 'Formats : MP4, WebM, MOV — choisissez un fichier sur votre ordinateur'
                      : 'Parcourir un fichier sur votre ordinateur'
                }</small>
              </div>
              <div class="field full les-video-wrap" style="margin:0;${l.content_type === 'video' || l.content_type === 'live' || l.content_type === 'link' ? '' : 'display:none'}">
                <label>${l.content_type === 'link' ? 'URL du lien' : 'Lien vidéo (optionnel)'}</label>
                <input class="les-video" data-mi="${mi}" data-li="${li}" value="${esc(l.video_url)}" placeholder="https://… — si vous n’uploadez pas de fichier">
              </div>
              <div class="field full les-ext-wrap" style="margin:0">
                <label>URL externe (optionnel)</label>
                <input class="les-ext" data-mi="${mi}" data-li="${li}" value="${esc(l.external_url)}" placeholder="https://…">
              </div>
              <div class="field full" style="margin:0">
                <label>Description de la leçon</label>
                <textarea class="les-desc" data-mi="${mi}" data-li="${li}" rows="2">${esc(l.description)}</textarea>
              </div>
            </div>
          </div>`,
          )
          .join('')}
        <button type="button" class="btn btn-secondary btn-add-lesson" data-mi="${mi}">+ Ajouter une leçon</button>
      </div>
    </div>`,
    )
    .join('');
}

export async function renderCreate(root) {
  const user = getStoredUser() || {};
  const teacherDefault =
    user.full_name ||
    user.name ||
    `${user.first_name || ''} ${user.last_name || ''}`.trim() ||
    '';

  let domains = FALLBACK_DOMAINS;
  try {
    const raw = await api('learning-domains/?page_size=50');
    const list = Array.isArray(raw) ? raw : raw.results || [];
    if (list.length) {
      domains = list.map((d) => ({
        slug: d.slug,
        name: d.name,
      }));
    }
  } catch {
    /* fallback */
  }

  let promotions = [];
  const deptId = user.department || user.department_id;
  if (deptId) {
    try {
      const raw = await api(`promotions/?department=${deptId}`);
      const list = Array.isArray(raw) ? raw : raw.results || [];
      promotions = list.map((p) => ({
        id: String(p.id),
        name: p.name || p.level || `Promo ${p.id}`,
        level: p.level || '',
      }));
    } catch {
      /* ignore */
    }
  }

  /** @type {{ kind: 'domain'|'promo', value: string, label: string }[]} */
  let tags = [];
  let modules = [newModule()];

  const paint = () => {
    root.innerHTML = `
    <div class="page-head">
      <div>
        <h1>Créer un cours</h1>
        <p>Renseignez les informations du cours, puis structurez le contenu</p>
      </div>
      <div class="page-actions">
        <a class="btn btn-secondary" href="#/cours">Annuler</a>
      </div>
    </div>

    <form id="create-form">
      <div class="panel">
        <div class="panel-h"><h2>1. Identité du cours</h2></div>
        <div class="panel-b form-grid">
          <div class="field full">
            <label>Titre du cours *</label>
            <input name="title" required minlength="3" placeholder="Ex. Algorithmique et structures de données">
          </div>
          <div class="field full">
            <label>Description</label>
            <textarea name="description" rows="4" placeholder="Décris le cours en quelques lignes…"></textarea>
          </div>
          <div class="field">
            <label>Code UE (optionnel)</label>
            <input name="code" placeholder="Auto (ENS-…) si vide">
          </div>
          <div class="field">
            <label>Nom de l’enseignant *</label>
            <input name="teacher_name" required value="${esc(teacherDefault)}" placeholder="Nom affiché sur le cours">
          </div>
          <div class="field full">
            <label>Image de couverture</label>
            <input name="cover" type="file" id="cover-file" accept="image/jpeg,image/png,image/webp,image/gif,.jpg,.jpeg,.png,.webp,.gif">
            <small id="cover-hint" style="color:var(--ink-soft)">Choisissez une image sur votre ordinateur (JPG, PNG, WebP)</small>
            <div id="cover-preview" style="margin-top:10px;display:none">
              <img alt="Aperçu couverture" style="max-width:240px;max-height:140px;border-radius:8px;object-fit:cover;border:1px solid var(--border)">
            </div>
          </div>
          <div class="field full">
            <label>Lien de couverture (optionnel)</label>
            <input name="cover_url" type="url" placeholder="https://… — si vous n’uploadez pas d’image">
          </div>
        </div>
      </div>

      <div class="panel">
        <div class="panel-h"><h2>2. Paramètres du cours</h2></div>
        <div class="panel-b form-grid">
          <div class="field">
            <label>Niveau de difficulté</label>
            <select name="difficulty_hint">
              ${DIFFICULTIES.map((d) => `<option value="${d}">${d}</option>`).join('')}
            </select>
            <small style="color:var(--ink-soft)">Indiqué aux apprenants sur Apprendre</small>
          </div>
          <div class="field">
            <label>Crédits ECTS</label>
            <input name="credits" type="number" min="0" max="60" value="5">
          </div>
          <div class="field">
            <label>Volume horaire estimé (h)</label>
            <input name="estimated_hours" type="number" min="0" value="24">
          </div>
          <div class="field">
            <label>Département (profil)</label>
            <input readonly value="${esc(user.department_name || 'Depuis votre profil')}">
          </div>
          <div class="field full">
            <label>Faculté / Université</label>
            <input readonly value="${esc([user.faculty_name, user.university_name].filter(Boolean).join(' · ') || 'Depuis votre profil')}">
          </div>
        </div>
      </div>

      <div class="panel">
        <div class="panel-h"><h2>3. Domaines & promotion</h2></div>
        <div class="panel-b">
          <p style="margin:0 0 12px;color:var(--ink-muted);font-size:0.9rem">
            Optionnel. Sélectionnez une suggestion ou tapez un nom puis <strong>Entrée</strong> pour l’ajouter.
            Le cours reste dans <strong>Apprendre</strong> (pas Ma Fac).
          </p>
          ${tagFieldHtml({
            id: 'classif-tags',
            selected: tags,
            placeholder: 'Ex. Informatique, L3, Cybersécurité…',
          })}
        </div>
      </div>

      <div class="panel">
        <div class="panel-h"><h2>4. Pédagogie</h2></div>
        <div class="panel-b form-grid">
          <div class="field full">
            <label>Objectifs pédagogiques</label>
            <textarea name="objectives" rows="3" placeholder="Ce que l’étudiant saura faire à la fin du cours"></textarea>
          </div>
          <div class="field full">
            <label>Compétences visées</label>
            <textarea name="skills" rows="3" placeholder="Compétences acquises"></textarea>
          </div>
          <div class="field full">
            <label>Prérequis</label>
            <textarea name="prerequisites" rows="3" placeholder="Bases attendues avant de suivre ce cours"></textarea>
          </div>
          <div class="field full">
            <label>Bibliographie / ressources</label>
            <textarea name="bibliography" rows="3" placeholder="Ouvrages, liens, références"></textarea>
          </div>
          <div class="field full">
            <label>Public cible</label>
            <textarea name="audience" rows="2" placeholder="Ex. Étudiants en informatique, débutants"></textarea>
          </div>
        </div>
      </div>

      <div class="panel">
        <div class="panel-h">
          <h2>5. Structure — Modules & leçons</h2>
          <button type="button" class="btn btn-primary" id="add-module">+ Module</button>
        </div>
        <div class="panel-b" id="modules-box">${modulesHtml(modules)}</div>
      </div>

      <div class="panel">
        <div class="panel-b">
          <div id="create-error"></div>
          <div style="display:flex;gap:8px;justify-content:flex-end;flex-wrap:wrap">
            <a class="btn btn-secondary" href="#/cours">Annuler</a>
            <button class="btn btn-primary" type="submit" id="create-btn">Publier le cours</button>
          </div>
        </div>
      </div>
    </form>
    `;

    bind();
  };

  const syncFromDom = () => {
    root.querySelectorAll('.mod-title').forEach((el) => {
      const mi = Number(el.dataset.mi);
      if (modules[mi]) modules[mi].title = el.value;
    });
    root.querySelectorAll('.mod-desc').forEach((el) => {
      const mi = Number(el.dataset.mi);
      if (modules[mi]) modules[mi].description = el.value;
    });
    root.querySelectorAll('.les-title').forEach((el) => {
      const mi = Number(el.dataset.mi);
      const li = Number(el.dataset.li);
      if (modules[mi]?.lessons[li]) modules[mi].lessons[li].title = el.value;
    });
    root.querySelectorAll('.les-type').forEach((el) => {
      const mi = Number(el.dataset.mi);
      const li = Number(el.dataset.li);
      if (modules[mi]?.lessons[li]) modules[mi].lessons[li].content_type = el.value;
    });
    root.querySelectorAll('.les-video').forEach((el) => {
      const mi = Number(el.dataset.mi);
      const li = Number(el.dataset.li);
      if (modules[mi]?.lessons[li]) modules[mi].lessons[li].video_url = el.value;
    });
    root.querySelectorAll('.les-ext').forEach((el) => {
      const mi = Number(el.dataset.mi);
      const li = Number(el.dataset.li);
      if (modules[mi]?.lessons[li]) modules[mi].lessons[li].external_url = el.value;
    });
    root.querySelectorAll('.les-desc').forEach((el) => {
      const mi = Number(el.dataset.mi);
      const li = Number(el.dataset.li);
      if (modules[mi]?.lessons[li]) modules[mi].lessons[li].description = el.value;
    });
    root.querySelectorAll('.les-duration').forEach((el) => {
      const mi = Number(el.dataset.mi);
      const li = Number(el.dataset.li);
      if (modules[mi]?.lessons[li]) {
        modules[mi].lessons[li].duration_seconds = Number(el.value || 0);
      }
    });
    root.querySelectorAll('.les-file').forEach((el) => {
      const mi = Number(el.dataset.mi);
      const li = Number(el.dataset.li);
      if (modules[mi]?.lessons[li] && el.files?.[0]) {
        modules[mi].lessons[li].file = el.files[0];
      }
    });
  };

  const addTag = (tag) => {
    if (!tag?.value || !tag?.label) return;
    if (tag.kind === 'promo') {
      tags = tags.filter((t) => t.kind !== 'promo');
    }
    if (tags.some((t) => t.kind === tag.kind && t.value === tag.value)) return;
    tags = [...tags, tag];
    paint();
  };

  const removeTag = (kind, value) => {
    tags = tags.filter((t) => !(t.kind === kind && t.value === value));
    paint();
  };

  const suggestionsFor = (q) => {
    const query = (q || '').trim().toLowerCase();
    const out = [];
    for (const d of domains) {
      const slug = d.slug || d.id;
      const name = d.name || slug;
      if (tags.some((t) => t.kind === 'domain' && t.value === slug)) continue;
      if (!query || name.toLowerCase().includes(query) || slug.includes(query)) {
        out.push({ kind: 'domain', value: slug, label: name });
      }
    }
    for (const p of promotions) {
      if (tags.some((t) => t.kind === 'promo' && t.value === p.id)) continue;
      const label = p.name;
      if (
        !query ||
        label.toLowerCase().includes(query) ||
        (p.level || '').toLowerCase().includes(query)
      ) {
        out.push({ kind: 'promo', value: p.id, label });
      }
    }
    if (query.length >= 2) {
      const slug = slugifyLabel(query);
      const isPromoHint = /^(l[123]|m[12]|master|licence|promo)/i.test(query);
      if (isPromoHint) {
        if (!tags.some((t) => t.kind === 'promo' && t.label.toLowerCase() === query)) {
          out.unshift({
            kind: 'promo',
            value: `new:${query}`,
            label: q.trim(),
            create: true,
          });
        }
      } else if (slug && !tags.some((t) => t.kind === 'domain' && t.value === slug)) {
        out.unshift({
          kind: 'domain',
          value: slug,
          label: q.trim(),
          create: true,
        });
      }
    }
    return out.slice(0, 8);
  };

  const bindTagField = () => {
    const input = document.getElementById('classif-tags-input');
    const suggest = document.getElementById('classif-tags-suggest');
    if (!input || !suggest) return;

    const renderSuggest = () => {
      const items = suggestionsFor(input.value);
      if (!items.length) {
        suggest.hidden = true;
        suggest.innerHTML = '';
        return;
      }
      suggest.hidden = false;
      suggest.innerHTML = items
        .map(
          (it) => `
        <button type="button" class="tag-suggest-item" data-kind="${esc(it.kind)}" data-value="${esc(it.value)}" data-label="${esc(it.label)}">
          <span class="tag-kind">${it.kind === 'promo' ? 'Promo' : 'Domaine'}${it.create ? ' · ajouter' : ''}</span>
          ${esc(it.label)}
        </button>`,
        )
        .join('');
    };

    input.addEventListener('input', renderSuggest);
    input.addEventListener('focus', renderSuggest);
    input.addEventListener('keydown', (ev) => {
      if (ev.key === 'Enter' || ev.key === ',') {
        ev.preventDefault();
        const q = input.value.trim().replace(/,$/, '');
        if (!q) return;
        const items = suggestionsFor(q);
        const isPromo = /^(l[123]|m[12]|master|licence|promo)/i.test(q);
        const pick = items[0] || {
          kind: isPromo ? 'promo' : 'domain',
          value: isPromo ? `new:${q}` : slugifyLabel(q),
          label: q,
        };
        addTag({ kind: pick.kind, value: pick.value, label: pick.label });
      }
      if (ev.key === 'Backspace' && !input.value && tags.length) {
        const last = tags[tags.length - 1];
        removeTag(last.kind, last.value);
      }
    });

    suggest.addEventListener('mousedown', (ev) => {
      const btn = ev.target.closest('.tag-suggest-item');
      if (!btn) return;
      ev.preventDefault();
      addTag({
        kind: btn.dataset.kind,
        value: btn.dataset.value,
        label: btn.dataset.label,
      });
    });

    document.getElementById('classif-tags-chips')?.addEventListener('click', (ev) => {
      const x = ev.target.closest('.tag-x');
      if (!x) return;
      const chip = x.closest('.tag-chip');
      if (!chip) return;
      removeTag(chip.dataset.kind, chip.dataset.value);
    });
  };

  const bind = () => {
    bindTagField();

    document.getElementById('cover-file')?.addEventListener('change', (ev) => {
      const file = ev.target.files?.[0];
      const hint = document.getElementById('cover-hint');
      const preview = document.getElementById('cover-preview');
      const img = preview?.querySelector('img');
      if (!file) {
        if (hint) {
          hint.textContent =
            'Choisissez une image sur votre ordinateur (JPG, PNG, WebP)';
        }
        if (preview) preview.style.display = 'none';
        return;
      }
      const mb = (file.size / (1024 * 1024)).toFixed(1);
      if (hint) hint.textContent = `${file.name} (${mb} Mo)`;
      if (img && preview) {
        img.src = URL.createObjectURL(file);
        preview.style.display = 'block';
      }
    });

    document.getElementById('add-module')?.addEventListener('click', () => {
      syncFromDom();
      modules.push(newModule());
      paint();
    });

    root.querySelectorAll('.btn-rm-module').forEach((btn) => {
      btn.addEventListener('click', () => {
        syncFromDom();
        const mi = Number(btn.dataset.mi);
        modules.splice(mi, 1);
        if (!modules.length) modules.push(newModule());
        paint();
      });
    });

    root.querySelectorAll('.btn-add-lesson').forEach((btn) => {
      btn.addEventListener('click', () => {
        syncFromDom();
        const mi = Number(btn.dataset.mi);
        modules[mi].lessons.push(newLesson());
        paint();
      });
    });

    root.querySelectorAll('.btn-rm-lesson').forEach((btn) => {
      btn.addEventListener('click', () => {
        syncFromDom();
        const mi = Number(btn.dataset.mi);
        const li = Number(btn.dataset.li);
        modules[mi].lessons.splice(li, 1);
        if (!modules[mi].lessons.length) modules[mi].lessons.push(newLesson());
        paint();
      });
    });

    document.getElementById('create-form').addEventListener('submit', onSubmit);
  };

  async function onSubmit(ev) {
    ev.preventDefault();
    syncFromDom();
    const fd = new FormData(ev.target);
    const btn = document.getElementById('create-btn');
    const errBox = document.getElementById('create-error');
    errBox.innerHTML = '';

    const title = (fd.get('title') || '').trim();
    if (title.length < 3) {
      errBox.innerHTML =
        '<div class="alert alert-error">Le titre doit faire au moins 3 caractères.</div>';
      return;
    }

    for (let i = 0; i < modules.length; i++) {
      const m = modules[i];
      if (!m.title.trim()) {
        errBox.innerHTML = `<div class="alert alert-error">Module ${i + 1} : ajoutez un titre.</div>`;
        return;
      }
      for (let j = 0; j < m.lessons.length; j++) {
        const l = m.lessons[j];
        if (!l.title.trim()) {
          errBox.innerHTML = `<div class="alert alert-error">Module ${i + 1}, leçon ${j + 1} : titre requis.</div>`;
          return;
        }
        if (l.content_type === 'video' || l.content_type === 'live') {
          if (!l.file && !l.video_url.trim()) {
            errBox.innerHTML = `<div class="alert alert-error">Module ${i + 1}, leçon ${j + 1} : uploadez une vidéo ou indiquez un lien.</div>`;
            return;
          }
        } else if (l.content_type === 'link') {
          if (!l.video_url.trim() && !l.external_url.trim()) {
            errBox.innerHTML = `<div class="alert alert-error">Module ${i + 1}, leçon ${j + 1} : indiquez une URL.</div>`;
            return;
          }
        } else if (
          l.content_type !== 'text' &&
          l.content_type !== 'quiz' &&
          !l.file
        ) {
          errBox.innerHTML = `<div class="alert alert-error">Module ${i + 1}, leçon ${j + 1} : ajoutez un fichier.</div>`;
          return;
        }
      }
    }

    btn.disabled = true;
    btn.textContent = 'Publication…';

    try {
      const audience = (fd.get('audience') || '').trim();
      const difficulty = (fd.get('difficulty_hint') || '').trim();
      let description = (fd.get('description') || '').trim();
      if (audience) {
        description = description
          ? `${description}\n\nPublic cible : ${audience}`
          : `Public cible : ${audience}`;
      }
      if (difficulty) {
        description = description
          ? `${description}\nDifficulté : ${difficulty}`
          : `Difficulté : ${difficulty}`;
      }

      const domainSlugs = tags
        .filter((t) => t.kind === 'domain')
        .map((t) => t.value);
      const promoTag = tags.find((t) => t.kind === 'promo');

      const payload = {
        title,
        code: (fd.get('code') || '').trim() || undefined,
        description,
        objectives: (fd.get('objectives') || '').trim(),
        skills: (fd.get('skills') || '').trim(),
        prerequisites: (fd.get('prerequisites') || '').trim(),
        bibliography: (fd.get('bibliography') || '').trim(),
        teacher_name: (fd.get('teacher_name') || '').trim(),
        level_label: (fd.get('difficulty_hint') || '').trim(),
        credits: Number(fd.get('credits') || 0),
        estimated_hours: Number(fd.get('estimated_hours') || 0),
        cover_url: (fd.get('cover_url') || '').trim(),
        domain_slugs: domainSlugs,
      };
      if (promoTag) {
        if (String(promoTag.value).startsWith('new:')) {
          payload.promotion_name = promoTag.label;
        } else {
          payload.promotion_id = Number(promoTag.value) || promoTag.value;
        }
      }

      const course = await api('courses/', {
        method: 'POST',
        body: JSON.stringify(payload),
      });

      const coverFile = document.getElementById('cover-file')?.files?.[0];
      if (coverFile) {
        const coverFd = new FormData();
        coverFd.append('cover', coverFile);
        await api(`courses/${course.id}/`, {
          method: 'PATCH',
          body: coverFd,
        });
      }

      for (let i = 0; i < modules.length; i++) {
        const draft = modules[i];
        const module = await api('course-modules/', {
          method: 'POST',
          body: JSON.stringify({
            course: Number(course.id) || course.id,
            title: draft.title.trim(),
            description: draft.description.trim(),
            order: i + 1,
          }),
        });

        for (let j = 0; j < draft.lessons.length; j++) {
          const lesson = draft.lessons[j];
          const body = new FormData();
          body.append('module', module.id);
          body.append('title', lesson.title.trim());
          body.append('content_type', lesson.content_type);
          body.append('description', lesson.description || '');
          body.append('video_url', lesson.video_url || '');
          body.append('external_url', lesson.external_url || '');
          body.append('duration_seconds', String(lesson.duration_seconds || 0));
          body.append('order', String(j + 1));
          body.append('is_published', 'true');
          if (lesson.file) body.append('file', lesson.file);
          await api('course-lessons/', { method: 'POST', body });
        }
      }

      location.hash = `#/cours/${course.id}`;
    } catch (e) {
      errBox.innerHTML = `<div class="alert alert-error">${esc(e.message)}</div>`;
      btn.disabled = false;
      btn.textContent = 'Publier le cours';
    }
  }

  paint();
}

export async function renderCourseManage(root, courseId) {
  root.innerHTML = `
    <div class="page-head">
      <div>
        <h1>Gestion du cours</h1>
        <p>Modules, leçons, statistiques et activités étudiants</p>
      </div>
      <div class="page-actions">
        <a class="btn btn-secondary" href="#/activites">Activités</a>
        <a class="btn btn-secondary" href="#/cours">← Retour</a>
      </div>
    </div>
    <div id="manage-body"><div class="skeleton" style="height:200px"></div></div>
  `;

  try {
    const [course, outline, stats] = await Promise.all([
      api(`courses/${courseId}/`),
      api(`course-outlines/${courseId}/`).catch(() => ({ modules: [] })),
      api(`courses/${courseId}/stats/`).catch(() => null),
    ]);

    const modules = outline.modules || outline.course_modules || [];

    document.getElementById('manage-body').innerHTML = `
      <div class="grid-stats" style="grid-template-columns:repeat(4,1fr)">
        <div class="stat-card"><div class="label">Visites</div><div class="value">${stats?.views ?? course.views ?? 0}</div></div>
        <div class="stat-card"><div class="label">Visiteurs uniques</div><div class="value">${stats?.unique_visitors ?? course.unique_visitors ?? 0}</div></div>
        <div class="stat-card"><div class="label">Étudiants</div><div class="value">${stats?.students ?? 0}</div></div>
        <div class="stat-card"><div class="label">Modules</div><div class="value">${stats?.modules ?? modules.length}</div></div>
        <div class="stat-card"><div class="label">Leçons</div><div class="value">${stats?.lessons ?? 0}</div></div>
      </div>

      <div class="panel">
        <div class="panel-h"><h2>Activités étudiants (Apprendre)</h2><a href="#/activites">Voir tout</a></div>
        <div class="panel-b" id="course-activities"><div class="skeleton" style="height:80px"></div></div>
      </div>

      <div class="panel">
        <div class="panel-h"><h2>Métadonnées complètes</h2></div>
        <div class="panel-b">
          <form id="meta-form" class="form-grid">
            <div class="field full"><label>Titre</label><input name="title" value="${esc(course.title)}"></div>
            <div class="field"><label>Code</label><input name="code" value="${esc(course.code || '')}"></div>
            <div class="field"><label>Enseignant</label><input name="teacher_name" value="${esc(course.teacher_name || '')}"></div>
            <div class="field"><label>Niveau de difficulté</label><input name="level_label" value="${esc(course.level_label || '')}" placeholder="Débutant / Intermédiaire / Avancé"></div>
            <div class="field"><label>Crédits</label><input name="credits" type="number" value="${esc(course.credits ?? 0)}"></div>
            <div class="field"><label>Volume (h)</label><input name="estimated_hours" type="number" value="${esc(course.estimated_hours ?? 0)}"></div>
            <div class="field full"><label>Couverture — fichier</label>
              <input name="cover" type="file" id="meta-cover" accept="image/jpeg,image/png,image/webp,image/gif,.jpg,.jpeg,.png,.webp">
              <small style="color:var(--ink-soft)">Remplace l’image actuelle si vous choisissez un fichier</small>
            </div>
            <div class="field full"><label>Couverture — lien (optionnel)</label><input name="cover_url" value="${esc(course.cover_url || '')}"></div>
            <div class="field full"><label>Description</label><textarea name="description">${esc(course.description || '')}</textarea></div>
            <div class="field full"><label>Objectifs</label><textarea name="objectives">${esc(course.objectives || '')}</textarea></div>
            <div class="field full"><label>Compétences</label><textarea name="skills">${esc(course.skills || '')}</textarea></div>
            <div class="field full"><label>Prérequis</label><textarea name="prerequisites">${esc(course.prerequisites || '')}</textarea></div>
            <div class="field full"><label>Bibliographie</label><textarea name="bibliography">${esc(course.bibliography || '')}</textarea></div>
            <div class="full" id="meta-msg"></div>
            <div class="full" style="text-align:right"><button class="btn btn-primary" type="submit">Enregistrer</button></div>
          </form>
        </div>
      </div>

      <div class="panel">
        <div class="panel-h">
          <h2>Structure du cours</h2>
          <button class="btn btn-primary" type="button" id="add-module">+ Module</button>
        </div>
        <div class="panel-b" id="modules-list">
          ${
            modules.length
              ? modules
                  .map(
                    (m, mi) => `
            <div class="module-card" data-module-id="${m.id}">
              <div class="module-h">
                <span>☰</span>
                <strong>Module ${mi + 1} — ${esc(m.title)}</strong>
                <button class="btn btn-ghost add-lesson" type="button" data-module="${m.id}">+ Leçon</button>
              </div>
              ${(m.lessons || [])
                .map(
                  (l) => `
                <div class="lesson-row">
                  <span class="type">${esc(l.content_type_display || l.content_type || '')}</span>
                  <strong style="flex:1">${esc(l.title)}</strong>
                  <span style="color:var(--ink-soft);font-size:0.8rem">${l.is_published === false ? 'Brouillon' : 'Publié'}</span>
                </div>`,
                )
                .join('') || '<div class="lesson-row" style="color:var(--ink-soft)">Aucune leçon</div>'}
            </div>`,
                  )
                  .join('')
              : '<div class="empty"><strong>Aucun module</strong>Ajoutez un premier module.</div>'
          }
        </div>
      </div>

      <dialog id="lesson-dialog" style="border:1px solid var(--border);border-radius:12px;padding:0;width:min(480px,92vw)">
        <form method="dialog" id="lesson-form" style="padding:20px">
          <h3 style="margin:0 0 14px">Nouvelle leçon</h3>
          <input type="hidden" name="module_id">
          <div class="field"><label>Titre</label><input name="title" required></div>
          <div class="field"><label>Type</label>
            <select name="content_type">${CONTENT_TYPES.map((t) => `<option value="${t.value}">${t.label}</option>`).join('')}</select>
          </div>
          <div class="field"><label>Vidéo depuis l’ordinateur</label><input name="file" type="file" accept="video/mp4,video/webm,video/quicktime,.mp4,.webm,.mov,.avi,.mkv,.pdf,.ppt,.pptx,.doc,.docx,image/*"></div>
          <div class="field" id="video-field"><label>Lien vidéo (optionnel)</label><input name="video_url" placeholder="https://…"></div>
          <div class="field"><label>Description</label><textarea name="description"></textarea></div>
          <div id="lesson-err"></div>
          <div style="display:flex;gap:8px;justify-content:flex-end;margin-top:12px">
            <button class="btn btn-secondary" value="cancel" type="submit">Annuler</button>
            <button class="btn btn-primary" id="lesson-save" value="default" type="submit">Ajouter</button>
          </div>
        </form>
      </dialog>
    `;

    api(`courses/teacher_activities/?course=${courseId}&limit=12`)
      .then((data) => {
        const box = document.getElementById('course-activities');
        if (!box) return;
        const rows = data.results || [];
        if (!rows.length) {
          box.innerHTML =
            '<div class="empty"><strong>Pas encore d’activité</strong>Les ouvertures et progressions Apprendre s’afficheront ici.</div>';
          return;
        }
        box.innerHTML = `<div class="timeline">${rows
          .map(
            (a) => `
          <div class="timeline-item">
            <div><div class="timeline-dot"></div></div>
            <div>
              <strong>${esc(a.title || '')}</strong>
              <p>${esc(a.message || '')}</p>
              <time>${esc(a.created_at ? new Date(a.created_at).toLocaleString('fr-FR') : '')}</time>
            </div>
          </div>`,
          )
          .join('')}</div>`;
      })
      .catch((e) => {
        const box = document.getElementById('course-activities');
        if (box) box.innerHTML = `<div class="alert alert-error">${esc(e.message)}</div>`;
      });

    document.getElementById('meta-form').addEventListener('submit', async (ev) => {
      ev.preventDefault();
      const form = new FormData(ev.target);
      const msg = document.getElementById('meta-msg');
      try {
        const coverFile = document.getElementById('meta-cover')?.files?.[0];
        if (coverFile) {
          const fd = new FormData();
          fd.append('cover', coverFile);
          fd.append('title', form.get('title'));
          fd.append('code', form.get('code') || '');
          fd.append('teacher_name', form.get('teacher_name') || '');
          fd.append('level_label', form.get('level_label') || '');
          fd.append('credits', form.get('credits') || '0');
          fd.append('estimated_hours', form.get('estimated_hours') || '0');
          fd.append('cover_url', form.get('cover_url') || '');
          fd.append('description', form.get('description') || '');
          fd.append('objectives', form.get('objectives') || '');
          fd.append('skills', form.get('skills') || '');
          fd.append('prerequisites', form.get('prerequisites') || '');
          fd.append('bibliography', form.get('bibliography') || '');
          await api(`courses/${courseId}/`, { method: 'PATCH', body: fd });
        } else {
          await api(`courses/${courseId}/`, {
            method: 'PATCH',
            body: JSON.stringify({
              title: form.get('title'),
              code: form.get('code'),
              teacher_name: form.get('teacher_name'),
              level_label: form.get('level_label'),
              credits: Number(form.get('credits') || 0),
              estimated_hours: Number(form.get('estimated_hours') || 0),
              cover_url: form.get('cover_url'),
              description: form.get('description'),
              objectives: form.get('objectives'),
              skills: form.get('skills'),
              prerequisites: form.get('prerequisites'),
              bibliography: form.get('bibliography'),
            }),
          });
        }
        msg.innerHTML = '<div class="alert alert-info">Enregistré.</div>';
      } catch (e) {
        msg.innerHTML = `<div class="alert alert-error">${esc(e.message)}</div>`;
      }
    });

    document.getElementById('add-module').addEventListener('click', async () => {
      const title = prompt('Titre du module ?', `Module ${modules.length + 1}`);
      if (!title) return;
      try {
        await api('course-modules/', {
          method: 'POST',
          body: JSON.stringify({
            course: Number(courseId) || courseId,
            title,
            description: '',
            order: modules.length,
          }),
        });
        renderCourseManage(root, courseId);
      } catch (e) {
        alert(e.message);
      }
    });

    const dialog = document.getElementById('lesson-dialog');
    const lessonForm = document.getElementById('lesson-form');

    root.querySelectorAll('.add-lesson').forEach((btn) => {
      btn.addEventListener('click', () => {
        lessonForm.module_id.value = btn.dataset.module;
        lessonForm.title.value = '';
        lessonForm.video_url.value = '';
        lessonForm.description.value = '';
        lessonForm.file.value = '';
        document.getElementById('lesson-err').innerHTML = '';
        dialog.showModal();
      });
    });

    lessonForm.addEventListener('submit', async (ev) => {
      if (ev.submitter?.value === 'cancel') return;
      ev.preventDefault();
      const form = new FormData(lessonForm);
      const moduleId = form.get('module_id');
      const file = lessonForm.file.files[0];
      const err = document.getElementById('lesson-err');
      const saveBtn = document.getElementById('lesson-save');
      saveBtn.disabled = true;
      try {
        const body = new FormData();
        body.append('module', moduleId);
        body.append('title', form.get('title'));
        body.append('content_type', form.get('content_type'));
        body.append('description', form.get('description') || '');
        body.append('video_url', form.get('video_url') || '');
        body.append('order', '0');
        body.append('is_published', 'true');
        if (file) body.append('file', file);
        await api('course-lessons/', { method: 'POST', body });
        dialog.close();
        renderCourseManage(root, courseId);
      } catch (e) {
        err.innerHTML = `<div class="alert alert-error">${esc(e.message)}</div>`;
        saveBtn.disabled = false;
      }
    });
  } catch (e) {
    document.getElementById('manage-body').innerHTML =
      `<div class="alert alert-error">${esc(e.message)}</div>`;
  }
}
