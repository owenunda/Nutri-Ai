# Renovaciones aunque no llegue el webhook

Fecha: 2026-10-18
Sigue a `2026-10-17-suscripciones-revenuecat-design.md`. Cambia lo que ese spec decía de `proExpiry.job.js` ("no cambia").

## Problema

Para un suscriptor de tienda, `users.pro_until` = `store_subscriptions.expires_at` + 1 h, y solo avanza cuando corre `syncUser` (webhook de RevenueCat o `POST /subscription/sync` desde la app). Si los webhooks de renovación fallan, el job de vencimiento pasa a FREE a alguien que sí pagó, y queda así hasta que toque "Restaurar compras".

## Decisión

El job de vencimiento le pregunta a RevenueCat antes de bajar a un suscriptor que tenía la renovación automática activa. Solo backend: la app no cambia.

## Comportamiento

En cada barrido (cada 10 min), **antes** de vencer:

1. **Quién se revisa.** Usuarios con fila en `store_subscriptions` donde:
   - `will_renew = TRUE`,
   - `expires_at` no es NULL y venció hace menos de **3 días** (`STORE_RENEWAL_WAIT_MS`),
   - `users.pro_until` no es NULL y vence en los próximos **15 minutos** o ya venció.

   Ordenados por `pro_until` (el más próximo primero), **máximo 100** por barrido.

   Los 15 minutos (más que el intervalo del job) hacen que la consulta llegue antes de que pase `pro_until`, cuando la cuota del Chef IA ya lo trataría como FREE.

2. **Qué se hace.** `syncUser(userId)` a cada uno, en serie. Lo que pase lo decide la regla de siempre:
   - renovó → `pro_until` avanza;
   - venció de verdad → FREE;
   - RevenueCat falla → `syncUser` lanza antes de escribir; se registra y el usuario queda como estaba.

   Con **3 fallos seguidos** se dejan los demás para el próximo barrido (RevenueCat probablemente está caído). Un éxito reinicia la cuenta. Nunca lanza.

3. **Vencer.** `expireGiftedPro` ya no baja a quien tiene `will_renew = TRUE` y `expires_at` vencido hace menos de 3 días: si su sync salió bien, su plan ya es el correcto; si falló, sigue en PRO hasta que RevenueCat responda. Pasados los 3 días vence como siempre (y deja de consultarse). Quien canceló (`will_renew = FALSE`) vence igual que hoy, sin llamar a RevenueCat.

Un fallo de la revisión nunca impide el vencimiento.

## Límites

- Durante una caída de RevenueCat, en cuanto pasa `pro_until` el plan sigue en PRO pero la cuota del Chef IA y el `proSource` del perfil lo tratan como FREE hasta que el sync salga bien. Cubrirlo exigiría cambiar la regla del plan.
- Llamadas a RevenueCat: como máximo 100 por barrido; en una caída, unas 3 por barrido.

## Código

- `effectivePlan.js`: constante `STORE_RENEWAL_WAIT_MS` (3 días) junto a `STORE_GRACE_MS`.
- `subscription.repository.js`: `findStoreRenewalsDue({ lookaheadMs, waitMs, limit })`.
- `subscription.service.js`: `renewDueStoreSubscriptions()` → `{ checked, failed, stopped }`.
- `admin.repository.js`: `expireGiftedPro` recibe la ventana y excluye a esos usuarios.
- `proExpiry.job.js`: `runProExpiry(expire, renew)` corre `renew` y después `expire`.

## Tests

- Job: la revisión corre antes del vencimiento; si la revisión falla, el vencimiento corre igual.
- Service: sincroniza a cada pendiente; sigue tras un fallo suelto; se detiene tras 3 seguidos; un éxito reinicia la cuenta; nunca lanza (tampoco si falla la consulta de pendientes).
- El SQL no tiene tests de base (el repo no los tiene); se revisa leyéndolo.
