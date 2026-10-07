import { escapeHtml } from './utils.js';

function formatClock(seconds) {
  const s = Math.max(0, Math.floor(Number(seconds) || 0));
  const m = Math.floor(s / 60);
  const r = s % 60;
  return `${m}:${String(r).padStart(2, '0')}`;
}

function youtubeId(url) {
  if (!url) return '';
  const u = String(url);
  const m =
    u.match(/[?&]v=([\w-]{6,})/) ||
    u.match(/youtu\.be\/([\w-]{6,})/) ||
    u.match(/youtube\.com\/embed\/([\w-]{6,})/) ||
    u.match(/youtube\.com\/shorts\/([\w-]{6,})/);
  return m ? m[1] : '';
}

function isDirectVideo(url) {
  return /\.(mp4|webm|ogg|m3u8)(\?|$)/i.test(url || '');
}

function fallbackYoutube(course) {
  const hay = [
    course.code,
    course.title,
    course.faculty_name,
    course.department_name,
  ]
    .join(' ')
    .toLowerCase();
  if (/droit|jurid/.test(hay)) return 'https://www.youtube.com/watch?v=lrk4oY7UxpQ';
  if (/info|python|algo/.test(hay)) return 'https://www.youtube.com/watch?v=kqtD5dpn9C8';
  if (/méd|med|santé|sante/.test(hay)) return 'https://www.youtube.com/watch?v=j8zy-YZSDc8';
  if (/écon|econ|gestion/.test(hay)) return 'https://www.youtube.com/watch?v=g9aDizJpdIk';
  if (/\bia\b|intel/.test(hay)) return 'https://www.youtube.com/watch?v=aircAruvnKk';
  return 'https://www.youtube.com/watch?v=8mAITcNT3bM';
}

/** Échantillons gratuits : leçons vidéo publiées, sinon aperçu YouTube. */
export function buildPreviewSamples(course, modules = []) {
  const lessons = modules.flatMap((m) =>
    (Array.isArray(m.lessons) ? m.lessons : []).map((l) => ({
      ...l,
      moduleTitle: m.title || '',
    }))
  );
  const withVideo = lessons.filter((l) => (l.video_url || '').trim());
  const pool = (withVideo.length ? withVideo : lessons).slice(0, 8);

  if (!pool.length) {
    return [
      {
        id: `preview-${course.id}`,
        title: `Aperçu — ${course.title}`,
        video_url: fallbackYoutube(course),
        duration_seconds: 600,
        cover: course.cover_url || '',
      },
    ];
  }

  return pool.map((l, i) => ({
    id: String(l.id ?? `sample-${i}`),
    title: l.title || `Leçon ${i + 1}`,
    video_url: (l.video_url || '').trim() || fallbackYoutube(course),
    duration_seconds: Number(l.duration_seconds) || 0,
    cover: course.cover_url || '',
  }));
}

function playerHtml(sample, cover) {
  const url = sample.video_url || '';
  const yt = youtubeId(url);
  if (yt) {
    return `
      <iframe
        class="pv-frame"
        src="https://www.youtube.com/embed/${escapeHtml(yt)}?autoplay=1&rel=0"
        title="${escapeHtml(sample.title)}"
        allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share"
        allowfullscreen
      ></iframe>`;
  }
  if (isDirectVideo(url)) {
    return `
      <video class="pv-video" controls autoplay playsinline src="${escapeHtml(url)}">
        Votre navigateur ne prend pas en charge la vidéo.
      </video>`;
  }
  // Lien externe / pas de lecteur natif : poster + ouverture
  const poster = cover || sample.cover || '';
  return `
    <div class="pv-fallback">
      ${poster ? `<img src="${escapeHtml(poster)}" alt="">` : ''}
      <div class="pv-fallback-ui">
        <p>${escapeHtml(sample.title)}</p>
        ${
          url
            ? `<a class="btn btn-primary" href="${escapeHtml(url)}" target="_blank" rel="noopener">Ouvrir la vidéo</a>`
            : `<p class="pv-muted">Aperçu bientôt disponible</p>`
        }
      </div>
    </div>`;
}

function listHtml(samples, activeId, cover) {
  return samples
    .map((s) => {
      const active = String(s.id) === String(activeId);
      const thumb = cover || s.cover || '';
      return `
      <button type="button" class="pv-sample ${active ? 'active' : ''}" data-id="${escapeHtml(s.id)}">
        <span class="pv-thumb">
          ${thumb ? `<img src="${escapeHtml(thumb)}" alt="">` : ''}
          ${active ? `<span class="pv-playing">▶</span>` : ''}
        </span>
        <span class="pv-sample-title">${escapeHtml(s.title)}</span>
        <span class="pv-sample-dur">${formatClock(s.duration_seconds)}</span>
      </button>`;
    })
    .join('');
}

let escHandler = null;

export function openPreviewModal({ course, samples, startIndex = 0 }) {
  if (!samples?.length) return;
  closePreviewModal();

  let index = Math.max(0, Math.min(startIndex, samples.length - 1));
  const cover = course.cover_url || '';

  const overlay = document.createElement('div');
  overlay.className = 'pv-overlay';
  overlay.id = 'pv-overlay';
  overlay.setAttribute('role', 'dialog');
  overlay.setAttribute('aria-modal', 'true');
  overlay.setAttribute('aria-label', 'Aperçu du cours');

  const render = () => {
    const sample = samples[index];
    overlay.innerHTML = `
      <div class="pv-modal">
        <header class="pv-head">
          <div>
            <p class="pv-kicker">Aperçu du cours</p>
            <h2>${escapeHtml(course.title || '')}</h2>
          </div>
          <button type="button" class="pv-close" aria-label="Fermer">×</button>
        </header>
        <div class="pv-player" id="pv-player">
          ${playerHtml(sample, cover)}
        </div>
        <div class="pv-samples">
          <p class="pv-samples-label">Échantillons vidéo gratuits :</p>
          <div class="pv-sample-list" id="pv-sample-list">
            ${listHtml(samples, sample.id, cover)}
          </div>
        </div>
      </div>
    `;

    overlay.querySelector('.pv-close')?.addEventListener('click', closePreviewModal);
    overlay.querySelectorAll('.pv-sample').forEach((btn) => {
      btn.addEventListener('click', () => {
        const id = btn.dataset.id;
        const next = samples.findIndex((s) => String(s.id) === String(id));
        if (next < 0 || next === index) return;
        index = next;
        render();
      });
    });
  };

  overlay.addEventListener('click', (e) => {
    if (e.target === overlay) closePreviewModal();
  });

  escHandler = (e) => {
    if (e.key === 'Escape') closePreviewModal();
  };
  document.addEventListener('keydown', escHandler);
  document.body.classList.add('pv-open');
  document.body.appendChild(overlay);
  render();
}

export function closePreviewModal() {
  const el = document.getElementById('pv-overlay');
  if (el) el.remove();
  document.body.classList.remove('pv-open');
  if (escHandler) {
    document.removeEventListener('keydown', escHandler);
    escHandler = null;
  }
}
