-- Suscripciones de tienda (RevenueCat) y PRO regalado por separado
-- (spec 2026-10-17, suscripciones PRO con RevenueCat).
--
-- users.plan_id / users.pro_until pasan a ser el plan efectivo, calculado por
-- el backend a partir de:
--   gift_pro / gift_pro_until: el PRO regalado desde el panel. Con gift_pro,
--     gift_pro_until NULL = regalo sin vencimiento.
--   store_subscriptions: el estado del entitlement nutrilife_pro en RevenueCat.

ALTER TABLE users ADD COLUMN IF NOT EXISTS gift_pro BOOLEAN NOT NULL DEFAULT FALSE;
ALTER TABLE users ADD COLUMN IF NOT EXISTS gift_pro_until TIMESTAMPTZ;

-- Todo PRO de hoy es regalado: se copia al regalo para que nadie lo pierda.
-- Correr UNA sola vez, antes de que la app pueda vender suscripciones: si se
-- vuelve a correr cuando ya hay suscriptores de la tienda, los marcaría como
-- regalo.
UPDATE users u
   SET gift_pro = TRUE,
       gift_pro_until = u.pro_until
  FROM plans p
 WHERE p.plan_id = u.plan_id
   AND p.name = 'PRO'
   AND u.gift_pro = FALSE;

CREATE TABLE IF NOT EXISTS store_subscriptions (
    user_id INTEGER PRIMARY KEY REFERENCES users(user_id) ON DELETE CASCADE,
    product_id TEXT,
    store TEXT,
    expires_at TIMESTAMPTZ,
    will_renew BOOLEAN NOT NULL DEFAULT FALSE,
    billing_issue BOOLEAN NOT NULL DEFAULT FALSE,
    environment TEXT,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);
