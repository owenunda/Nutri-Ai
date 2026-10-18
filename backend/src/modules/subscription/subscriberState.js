// Convierte la respuesta de GET /v1/subscribers/{id} de RevenueCat en la fila
// de store_subscriptions.

export const ENTITLEMENT_ID = 'nutrilife_pro';

const EMPTY = Object.freeze({
  productId: null,
  store: null,
  expiresAt: null,
  willRenew: false,
  billingIssue: false,
  environment: null,
});

const toDate = (value) => (value ? new Date(value) : null);
const later = (a, b) => (!a ? b : !b ? a : a > b ? a : b);

// En Play el producto puede venir como "suscripcion:plan_base" y la clave de
// subscriptions solo con la suscripción, o al revés. Null si no aparece.
const findSubscription = (subscriptions, productId) => {
  const map = subscriptions ?? {};
  if (!productId) return null;
  if (map[productId]) return map[productId];
  const base = productId.split(':')[0];
  const key = Object.keys(map).find((k) => k.split(':')[0] === base);
  return key ? map[key] : null;
};

// La Test Store de RevenueCat es de pruebas aunque marque is_sandbox: false.
const isSandbox = (subscription) => subscription.is_sandbox === true || subscription.store === 'test_store';

/**
 * @param {Object|undefined} subscriber `subscriber` de la respuesta de RevenueCat.
 * @param {{allowSandbox: boolean}} options
 */
export const readStoreSubscription = (subscriber, { allowSandbox }) => {
  const entitlement = subscriber?.entitlements?.[ENTITLEMENT_ID];
  if (!entitlement) return { ...EMPTY };

  const productId = entitlement.product_identifier ?? null;
  const found = findSubscription(subscriber.subscriptions, productId);
  const subscription = found ?? {};
  const sandbox = isSandbox(subscription);
  const state = {
    productId,
    store: subscription.store ?? null,
    willRenew: !subscription.unsubscribe_detected_at,
    billingIssue: Boolean(subscription.billing_issues_detected_at),
    environment: sandbox ? 'sandbox' : 'production',
  };

  // En producción solo cuenta una suscripción real de la tienda: si no aparece
  // en subscriptions no se puede saber si es de pruebas, así que no da PRO.
  if (!allowSandbox && (!found || sandbox)) return { ...state, expiresAt: null };
  return {
    ...state,
    expiresAt: later(toDate(entitlement.expires_date), toDate(entitlement.grace_period_expires_date)),
  };
};
