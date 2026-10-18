// Plan efectivo de un usuario a partir del PRO regalado y de la suscripción de
// tienda. Es la única regla: la usan el webhook, el sync, el panel y el perfil.

// Si la tienda renueva y el webhook llega tarde, el job de vencimiento no debe
// pasar al usuario a FREE unos minutos.
export const STORE_GRACE_MS = 60 * 60 * 1000;

const toDate = (value) => (value ? new Date(value) : null);

/**
 * @param {{giftPro: boolean, giftProUntil: Date|string|null, storeExpiresAt: Date|string|null}} inputs
 * @returns {{plan: 'FREE'|'PRO', proUntil: Date|null, proSource: 'gift'|'store'|'both'|null}}
 *   proUntil null con PRO = sin vencimiento.
 */
export const computeEffectivePlan = ({ giftPro, giftProUntil, storeExpiresAt }, now = new Date()) => {
  const giftEnd = toDate(giftProUntil);
  const giftActive = Boolean(giftPro) && (giftEnd === null || giftEnd > now);

  const storeExpiry = toDate(storeExpiresAt);
  const storeEnd = storeExpiry ? new Date(storeExpiry.getTime() + STORE_GRACE_MS) : null;
  const storeActive = storeEnd !== null && storeEnd > now;

  if (!giftActive && !storeActive) return { plan: 'FREE', proUntil: null, proSource: null };

  const proSource = giftActive && storeActive ? 'both' : giftActive ? 'gift' : 'store';
  if (giftActive && giftEnd === null) return { plan: 'PRO', proUntil: null, proSource };

  const ends = [giftActive ? giftEnd : null, storeActive ? storeEnd : null].filter(Boolean);
  return { plan: 'PRO', proUntil: new Date(Math.max(...ends.map((d) => d.getTime()))), proSource };
};
