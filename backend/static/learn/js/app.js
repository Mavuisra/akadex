import { fetchPricing } from './api.js';
import { cartCount, onCartChange } from './cart.js';
import { closePreviewModal } from './preview-modal.js';
import { renderCatalog } from './pages/catalog.js';
import { renderDetail } from './pages/detail.js';
import { renderCart } from './pages/cart.js';

const app = document.getElementById('app');
let pricing = { sale: 15, list: 29, currency: 'USD' };

function parseRoute() {
  const raw = (location.hash || '#/').replace(/^#/, '') || '/';
  const [pathPart, queryPart = ''] = raw.split('?');
  const parts = pathPart.split('/').filter(Boolean);
  const params = new URLSearchParams(queryPart);
  return {
    path: parts[0] || '',
    id: parts[1] || null,
    query: params.get('q') || '',
    domain: params.get('domain') || '',
  };
}

function updateCartBadge() {
  const badge = document.getElementById('cart-badge');
  if (!badge) return;
  const n = cartCount();
  badge.hidden = n === 0;
  badge.textContent = String(n);
}

function shellHtml() {
  const n = cartCount();
  return `
    <div class="shell">
      <div class="learn-toolbar">
        <button type="button" class="cart-chip" id="cart-btn" title="Panier" aria-label="Panier">
          Panier
          <span class="cart-badge" id="cart-badge" ${n ? '' : 'hidden'}>${n || ''}</span>
        </button>
      </div>
      <main class="main" id="page"></main>
    </div>
  `;
}

function bindChrome() {
  document.getElementById('cart-btn')?.addEventListener('click', () => {
    location.hash = '#/panier';
  });
}

function syncNavSearch() {
  const input = document.getElementById('nav-q');
  if (!input || input.dataset.learnBound) return;
  input.dataset.learnBound = '1';
  const route = parseRoute();
  if (route.query) input.value = route.query;
}

async function render() {
  closePreviewModal();
  if (!app.querySelector('.shell')) {
    app.innerHTML = shellHtml();
    bindChrome();
  }
  syncNavSearch();
  updateCartBadge();

  const page = document.getElementById('page');
  const route = parseRoute();
  const isDetail = route.path === 'cours' && !!route.id;
  page.classList.toggle('is-detail', isDetail);

  if (route.path === 'panier') {
    renderCart(page, { pricing, onCartChange: updateCartBadge });
    return;
  }

  if (isDetail) {
    await renderDetail(page, {
      courseId: route.id,
      pricing,
      onCartChange: updateCartBadge,
    });
    return;
  }

  await renderCatalog(page, {
    pricing,
    query: route.query,
    domain: route.domain,
  });
}

async function boot() {
  pricing = await fetchPricing();
  onCartChange(updateCartBadge);
  await render();
  window.addEventListener('hashchange', () => {
    render();
  });
}

boot().catch((e) => {
  app.innerHTML = `<div class="error-box glass" style="margin:40px auto;max-width:480px">${e.message}</div>`;
});
