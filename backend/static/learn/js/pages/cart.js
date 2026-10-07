import {
  clearCart,
  formatPrice,
  getCart,
  removeCourse,
} from '../cart.js';
import {
  getDepositStatus,
  initiateDeposit,
  isLoggedIn,
  MOMO_PROVIDERS,
  openLoginModal,
} from '../api.js';
import { escapeHtml, showToast } from '../utils.js';

const POLL_MS = 3000;
const MAX_POLLS = 80;

let pollTimer = null;
let pollTicks = 0;
let checkoutState = {
  step: 'form', // form | awaiting | done | failed
  provider: 'vodacom_mpesa',
  phone: '',
  depositId: '',
  message: '',
};

function stopPolling() {
  if (pollTimer) {
    clearInterval(pollTimer);
    pollTimer = null;
  }
  pollTicks = 0;
}

function depositStatusOk(data) {
  const st = String(data?.status || '').toUpperCase();
  const pw = String(data?.pawapay_status || '').toUpperCase();
  return (
    st === 'COMPLETED' ||
    pw === 'COMPLETED' ||
    pw === 'COMPLETE'
  );
}

function depositFailed(data) {
  const st = String(data?.status || '').toUpperCase();
  const pw = String(data?.pawapay_status || '').toUpperCase();
  return (
    st === 'FAILED' ||
    st === 'REJECTED' ||
    pw === 'FAILED' ||
    pw === 'REJECTED'
  );
}

function providerPickerHtml() {
  return `
    <div class="momo-providers" role="radiogroup" aria-label="Opérateur Mobile Money">
      ${MOMO_PROVIDERS.map(
        (p) => `
        <button type="button"
          class="momo-provider ${checkoutState.provider === p.key ? 'is-selected' : ''}"
          data-provider="${p.key}"
          aria-pressed="${checkoutState.provider === p.key}">
          <strong>${escapeHtml(p.label)}</strong>
          <span>${escapeHtml(p.brand)}</span>
        </button>`,
      ).join('')}
    </div>`;
}

function checkoutPanelHtml(total, count) {
  if (checkoutState.step === 'awaiting') {
    return `
      <div class="momo-status momo-awaiting">
        <div class="momo-spinner" aria-hidden="true"></div>
        <h3>Validez sur votre téléphone</h3>
        <p>${escapeHtml(checkoutState.message || 'Demande envoyée. Entrez votre PIN Mobile Money.')}</p>
        <p class="hint">Ne fermez pas cette page — confirmation automatique…</p>
        <button type="button" class="btn btn-ghost btn-block" id="momo-cancel">Annuler l’attente</button>
      </div>`;
  }

  if (checkoutState.step === 'done') {
    return `
      <div class="momo-status momo-done">
        <h3>Paiement confirmé</h3>
        <p>${escapeHtml(checkoutState.message || 'Accès aux cours débloqué.')}</p>
        <a class="btn btn-primary btn-block" href="#/">Continuer à apprendre</a>
      </div>`;
  }

  if (checkoutState.step === 'failed') {
    return `
      <div class="momo-status momo-failed">
        <h3>Paiement non abouti</h3>
        <p>${escapeHtml(checkoutState.message || 'Réessayez avec un autre numéro ou opérateur.')}</p>
        <button type="button" class="btn btn-primary btn-block" id="momo-retry">Réessayer</button>
      </div>`;
  }

  return `
    <div class="momo-checkout" id="momo-checkout">
      <h3>Payer avec Mobile Money</h3>
      <p class="momo-sub">Même système que l’app · PawaPay (RDC)</p>
      ${providerPickerHtml()}
      <label class="momo-field" for="momo-phone">Numéro de téléphone</label>
      <input id="momo-phone" class="momo-input" type="tel" inputmode="tel"
        placeholder="ex. 097xxxxxxx" autocomplete="tel"
        value="${escapeHtml(checkoutState.phone)}">
      <p class="hint" style="margin-top:6px">Vodacom, Airtel ou Orange · format local ou +243</p>
      <button type="button" class="btn btn-primary btn-block" id="checkout-btn" style="margin-top:14px">
        Payer ${formatPrice(total)} · ${count} cours
      </button>
      <div class="momo-error" id="momo-error" hidden></div>
    </div>`;
}

export function renderCart(container, { pricing, onCartChange }) {
  const items = getCart();

  if (!items.length && checkoutState.step !== 'done') {
    stopPolling();
    checkoutState = {
      step: 'form',
      provider: 'vodacom_mpesa',
      phone: '',
      depositId: '',
      message: '',
    };
    container.innerHTML = `
      <a class="back-link" href="#/">← Catalogue</a>
      <h1 class="page-title">Panier</h1>
      <div class="empty glass-strong">Votre panier est vide.</div>
    `;
    return;
  }

  const total = items.reduce(
    (s, i) => s + (Number(i.priceUsd) || pricing.sale),
    0,
  );
  const count = items.length || 0;

  container.innerHTML = `
    <a class="back-link" href="#/">← Catalogue</a>
    <h1 class="page-title">Panier ${
      count
        ? `<span style="color:var(--muted);font-size:1rem;font-weight:700">(${count})</span>`
        : ''
    }</h1>
    <div class="cart-layout">
      <div class="cart-panel glass">
        ${
          items.length
            ? items
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
              <button type="button" class="btn btn-danger remove-btn" ${
                checkoutState.step === 'awaiting' ? 'disabled' : ''
              }>Retirer</button>
            </div>
          </div>`,
                )
                .join('')
            : `<div class="empty glass-strong">Cours achetés — panier vidé.</div>`
        }
      </div>
      <aside class="cart-summary glass-strong">
        <h2>Récapitulatif</h2>
        <div class="summary-row"><span>Cours</span><span>${count || '—'}</span></div>
        <div class="summary-row"><span>Prix unitaire</span><span>${formatPrice(pricing.sale)}</span></div>
        <div class="summary-row total"><span>Total</span><span>${formatPrice(total)}</span></div>
        ${checkoutPanelHtml(total, count)}
        ${
          checkoutState.step === 'form' && items.length
            ? `<button type="button" class="btn btn-ghost btn-block" id="clear-btn" style="margin-top:8px">Vider</button>`
            : ''
        }
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

  container.querySelector('#clear-btn')?.addEventListener('click', () => {
    clearCart();
    onCartChange?.();
    renderCart(container, { pricing, onCartChange });
  });

  container.querySelectorAll('[data-provider]').forEach((btn) => {
    btn.addEventListener('click', () => {
      checkoutState.provider = btn.dataset.provider;
      checkoutState.phone =
        container.querySelector('#momo-phone')?.value?.trim() ||
        checkoutState.phone;
      renderCart(container, { pricing, onCartChange });
    });
  });

  container.querySelector('#momo-retry')?.addEventListener('click', () => {
    checkoutState.step = 'form';
    checkoutState.message = '';
    checkoutState.depositId = '';
    renderCart(container, { pricing, onCartChange });
  });

  container.querySelector('#momo-cancel')?.addEventListener('click', () => {
    stopPolling();
    checkoutState.step = 'form';
    checkoutState.message = '';
    renderCart(container, { pricing, onCartChange });
    showToast('Attente annulée — panier conservé');
  });

  container.querySelector('#checkout-btn')?.addEventListener('click', async () => {
    const phoneEl = container.querySelector('#momo-phone');
    const errEl = container.querySelector('#momo-error');
    const phone = (phoneEl?.value || '').trim();
    checkoutState.phone = phone;

    const showErr = (msg) => {
      if (!errEl) return;
      errEl.hidden = false;
      errEl.textContent = msg;
    };

    if (!isLoggedIn()) {
      showErr('Connectez-vous pour payer.');
      openLoginModal();
      showToast('Connexion requise pour payer');
      return;
    }

    if (phone.replace(/\D/g, '').length < 9) {
      showErr('Entrez un numéro Mobile Money valide.');
      phoneEl?.focus();
      return;
    }

    const courseIds = getCart().map((i) => String(i.courseId));
    if (!courseIds.length) {
      showErr('Panier vide.');
      return;
    }

    const btn = container.querySelector('#checkout-btn');
    if (btn) {
      btn.disabled = true;
      btn.textContent = 'Envoi…';
    }
    if (errEl) errEl.hidden = true;

    try {
      const amount = courseIds.length * (Number(pricing.sale) || 15);
      const result = await initiateDeposit({
        phone,
        provider: checkoutState.provider,
        amount,
        courseIds,
      });

      if (depositStatusOk(result)) {
        stopPolling();
        clearCart();
        onCartChange?.();
        checkoutState.step = 'done';
        checkoutState.message =
          result.message || 'Paiement confirmé. Accès débloqué.';
        renderCart(container, { pricing, onCartChange });
        showToast('Paiement confirmé');
        return;
      }

      if (depositFailed(result)) {
        checkoutState.step = 'failed';
        checkoutState.message =
          result.message ||
          result.detail ||
          `Paiement refusé (${result.status || 'FAILED'}).`;
        renderCart(container, { pricing, onCartChange });
        return;
      }

      checkoutState.step = 'awaiting';
      checkoutState.depositId = result.deposit_id || '';
      checkoutState.message =
        result.message ||
        'Demande envoyée. Validez le PIN sur votre téléphone.';
      renderCart(container, { pricing, onCartChange });
      startPolling(container, { pricing, onCartChange });
    } catch (e) {
      if (e.status === 401) {
        showErr('Session expirée — reconnectez-vous.');
        openLoginModal();
      } else {
        showErr(e.message || 'Paiement indisponible.');
      }
      if (btn) {
        btn.disabled = false;
        btn.textContent = `Payer ${formatPrice(total)} · ${count} cours`;
      }
    }
  });
}

function startPolling(container, ctx) {
  stopPolling();
  const depositId = checkoutState.depositId;
  if (!depositId) return;

  const tick = async () => {
    if (checkoutState.step !== 'awaiting') {
      stopPolling();
      return;
    }
    pollTicks += 1;
    if (pollTicks > MAX_POLLS) {
      stopPolling();
      checkoutState.step = 'failed';
      checkoutState.message =
        'Confirmation trop longue. Le panier est conservé. Réessayez ou validez sur le téléphone — l’accès sera crédité dès validation.';
      renderCart(container, ctx);
      return;
    }
    try {
      const result = await getDepositStatus(depositId);
      if (depositStatusOk(result)) {
        stopPolling();
        clearCart();
        ctx.onCartChange?.();
        checkoutState.step = 'done';
        checkoutState.message =
          result.message || 'Paiement confirmé. Accès débloqué.';
        renderCart(container, ctx);
        showToast('Paiement confirmé');
        return;
      }
      if (depositFailed(result)) {
        stopPolling();
        checkoutState.step = 'failed';
        checkoutState.message =
          result.message ||
          result.detail ||
          'Paiement refusé.';
        renderCart(container, ctx);
      }
    } catch {
      /* réseau — on continue à poller */
    }
  };

  pollTimer = setInterval(tick, POLL_MS);
  tick();
}
