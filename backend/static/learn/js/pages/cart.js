import {
  clearCart,
  formatPrice,
  getCart,
  removeCourse,
} from '../cart.js';
import { escapeHtml, showToast } from '../utils.js';

export function renderCart(container, { pricing, onCartChange }) {
  const items = getCart();

  if (!items.length) {
    container.innerHTML = `
      <a class="back-link" href="#/">← Catalogue</a>
      <h1 class="page-title">Panier</h1>
      <div class="empty glass-strong">Votre panier est vide.</div>
    `;
    return;
  }

  const total = items.reduce((s, i) => s + (Number(i.priceUsd) || pricing.sale), 0);

  container.innerHTML = `
    <a class="back-link" href="#/">← Catalogue</a>
    <h1 class="page-title">Panier <span style="color:var(--muted);font-size:1rem;font-weight:700">(${items.length})</span></h1>
    <div class="cart-layout">
      <div class="cart-panel glass">
        ${items
          .map(
            (i) => `
          <div class="cart-item glass-strong" data-id="${escapeHtml(i.courseId)}">
            ${
              i.coverUrl
                ? `<img src="${escapeHtml(i.coverUrl)}" alt="">`
                : `<div class="cart-thumb"></div>`
            }
            <div>
              <h3>${escapeHtml(i.title)}</h3>
              <p class="sub">${escapeHtml(i.teacher)}${i.code ? ` · ${escapeHtml(i.code)}` : ''}</p>
              <p class="sub" style="margin-top:8px;font-weight:800;color:var(--ink)">${formatPrice(i.priceUsd || pricing.sale)}</p>
            </div>
            <div class="cart-actions">
              <button type="button" class="btn btn-danger remove-btn">Retirer</button>
            </div>
          </div>`
          )
          .join('')}
      </div>
      <aside class="cart-summary glass-strong">
        <h2>Récapitulatif</h2>
        <div class="summary-row"><span>Cours</span><span>${items.length}</span></div>
        <div class="summary-row"><span>Prix unitaire</span><span>${formatPrice(pricing.sale)}</span></div>
        <div class="summary-row total"><span>Total</span><span>${formatPrice(total)}</span></div>
        <button type="button" class="btn btn-primary btn-block" id="checkout-btn" style="margin-top:14px">
          Payer
        </button>
        <button type="button" class="btn btn-ghost btn-block" id="clear-btn" style="margin-top:8px">
          Vider
        </button>
        <p class="hint">Paiement Mobile Money dans l’app Akadex.</p>
      </aside>
    </div>
  `;

  container.querySelectorAll('.remove-btn').forEach((btn) => {
    btn.addEventListener('click', () => {
      const id = btn.closest('[data-id]')?.dataset.id;
      if (!id) return;
      removeCourse(id);
      onCartChange?.();
      renderCart(container, { pricing, onCartChange });
      showToast('Retiré du panier');
    });
  });

  container.querySelector('#clear-btn').addEventListener('click', () => {
    clearCart();
    onCartChange?.();
    renderCart(container, { pricing, onCartChange });
  });

  container.querySelector('#checkout-btn').addEventListener('click', () => {
    const store = window.AKADEX_LEARN?.playStoreUrl;
    if (store) {
      window.open(store, '_blank', 'noopener');
      showToast('Finalisez le paiement dans l’app');
      return;
    }
    showToast('Ouvrez l’app Akadex pour payer');
  });
}
