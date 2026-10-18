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
// subscriptions solo con la suscripción, o al revés.
const findSubscription = (subscriptions = {}, productId) => {
  if (!productId) return {};
  if (subscriptions[productId]) return subscriptions[productId];
  const base = productId.split(':')[0];
  const key = Object.keys(subscriptions).find((k) => k.split(':')[0] === base);
  return key ? subscriptions[key] : {};
};

/**
 * @param {Object|undefined} subscriber `subscriber` de la respuesta de RevenueCat.
 * @param {{allowSandbox: boolean}} options
 */
export const readStoreSubscription = (subscriber, { allowSandbox }) => {
  const entitlement = subscriber?.entitlements?.[ENTITLEMENT_ID];
  if (!entitlement) return { ...EMPTY };

  const productId = entitlement.product_identifier ?? null;
  const subscription = findSubscription(subscriber.subscriptions, productId);
  const sandbox = subscription.is_sandbox === true;
  const state = {
    productId,
    store: subscription.store ?? null,
    willRenew: !subscription.unsubscribe_detected_at,
    billingIssue: Boolean(subscription.billing_issues_detected_at),
    environment: sandbox ? 'sandbox' : 'production',
  };

  if (sandbox && !allowSandbox) return { ...state, expiresAt: null };
  return {
    ...state,
    expiresAt: later(toDate(entitlement.expires_date), toDate(entitlement.grace_period_expires_date)),
  };
};
