# Suscripciones PRO con RevenueCat

Fecha: 2026-10-17
Parte 5 de la separación FREE / PRO (pagos reales). Las partes 2 a 4 (recetas guardadas, historial de progreso, planes semanales) tienen su propio spec.

## Objetivo

Cobrar el PRO desde la app en Android y iOS con RevenueCat, y que el backend se entere solo de compras, renovaciones, cancelaciones y vencimientos para que `users.plan` refleje lo que el usuario pagó.

- Plataformas: Google Play y App Store. Mientras no haya cuenta de Apple Developer ni productos en Play Console, todo se prueba con la **Test Store** de RevenueCat (key `test_…`).
- Entitlement: `nutrilife_pro`.
- Productos: `monthly` (mensual) y `yearly` (anual). **Sin prueba gratis.**
- Pantalla de compra: la `premium_screen.dart` actual, conectada a RevenueCat. No se usa el Paywall de RevenueCat.
- El PRO regalado desde el panel admin sigue existiendo y convive con el pagado.

## Fuera de alcance

- Customer Center de RevenueCat (`purchases_ui_flutter`).
- Prueba gratis.
- Pago por web (Wompi, Mercado Pago, Stripe).
- Las partes 2 a 4 de los límites FREE / PRO.

## Datos

### `users`: plan efectivo y regalo aparte

- `users.plan_id` y `users.pro_until` pasan a ser el **plan efectivo**, ya calculado. Todo lo que hoy los lee (cuota del Chef IA, perfil, panel, `proExpiry.job.js`) sigue igual.
- Columnas nuevas para el regalo:
  - `gift_pro BOOLEAN NOT NULL DEFAULT FALSE`
  - `gift_pro_until TIMESTAMPTZ NULL`. Con `gift_pro = TRUE`, `NULL` = regalo para siempre.
- Migración (`src/database/backups/update_<fecha>_store_subscriptions.sql`): a todo usuario con plan PRO hoy le pone `gift_pro = TRUE` y `gift_pro_until = pro_until`. Nadie pierde su PRO.

### Tabla nueva `store_subscriptions`

Una fila por usuario con el estado del entitlement `nutrilife_pro` según RevenueCat.

| Columna | Tipo | Nota |
|---|---|---|
| `user_id` | PK, FK a `users` | `ON DELETE CASCADE` |
| `product_id` | TEXT | `monthly` / `yearly`, o el id de la tienda (Play usa `suscripcion:plan_base`) |
| `store` | TEXT | `play_store` / `app_store` / `test_store` / el que mande RevenueCat |
| `expires_at` | TIMESTAMPTZ NULL | El mayor entre `expires_date` y `grace_period_expires_date` |
| `will_renew` | BOOLEAN | `FALSE` si RevenueCat marca `unsubscribe_detected_at` |
| `billing_issue` | BOOLEAN | `TRUE` si marca `billing_issues_detected_at` |
| `environment` | TEXT | `sandbox` / `production` |
| `updated_at` | TIMESTAMPTZ | |

Si RevenueCat dice que el usuario no tiene el entitlement, la fila queda con `expires_at = NULL`. No se borra: así queda constancia de que alguna vez pagó.

### La regla del plan

Una sola función pura (`src/modules/subscription/effectivePlan.js`) la usan el webhook, el sync y el panel admin:

```
regaloVigente = gift_pro && (gift_pro_until == null || gift_pro_until > ahora)
finTienda     = store.expires_at + 1 hora   (si hay expires_at)
tiendaVigente = finTienda > ahora

plan     = PRO si regaloVigente || tiendaVigente, si no FREE
pro_until:
  - regalo vigente para siempre  -> NULL
  - si no, la fecha más lejana entre gift_pro_until (si vigente) y finTienda (si vigente)
  - FREE                         -> NULL
proSource = 'gift' | 'store' | 'both' | null
```

La **hora de margen** cubre el caso en que la tienda renueva y el webhook llega unos minutos tarde. Sin ella, el job de vencimiento pasaría al usuario a FREE y el webhook lo devolvería a PRO.

`proExpiry.job.js` no cambia: cuando el `pro_until` efectivo pasa, el usuario vuelve a FREE. `expireGiftedPro` sigue limpiando `pro_until` y plan; las columnas `gift_*` se pueden quedar como están, porque la regla ya las da por vencidas.

### Panel admin

- `PATCH /api/v1/admin/users/:userId/plan` (regalar o quitar PRO) ahora escribe `gift_pro` / `gift_pro_until` y después recalcula el plan con la regla. `computeProUntil` de `proGift.js` trabaja sobre el regalo, no sobre el plan efectivo.
- Quitar el PRO a alguien que paga solo le quita el regalo: sigue PRO por la tienda.
- El detalle de usuario del panel muestra `proSource` y, si hay suscripción, producto, tienda, vencimiento y si renueva.

## Backend

Módulo nuevo `src/modules/subscription/` con la forma de `hydration`: `subscription.routes.js`, `subscription.controller.js`, `subscription.service.js`, `subscription.repository.js`, más `revenuecat.client.js` (la llamada HTTP) y `effectivePlan.js`. Se monta en `app.js` como `/api/v1/subscription`.

### `POST /api/v1/subscription/webhook`

La llama RevenueCat.

- Sin JWT. El header `Authorization` tiene que ser igual a `REVENUECAT_WEBHOOK_AUTH`. Comparación en tiempo constante. Si no coincide, o la variable no está configurada: **401**.
- Evento `TEST`: responde **200** y no hace nada más.
- Usuarios a sincronizar: `event.app_user_id`, y en un `TRANSFER` también los de `event.transferred_from` y `event.transferred_to`. Se descartan los ids anónimos (`$RCAnonymousID:…`), los que no son un `user_id` válido y los que no existen en `users`.
- A cada usuario que queda le hace el **sync**. El contenido del evento no se usa para decidir el plan.
- Respuesta: **200** si todos los sync salieron bien (también si no quedó ningún usuario). Un error **5xx** si alguno falló (502 si fue RevenueCat, 500 si fue la base), para que RevenueCat reintente.
- Queda fuera de `activityLogger`: no aparece en eventos ni cuenta como bot.

### `POST /api/v1/subscription/sync`

La llama la app después de comprar o restaurar.

- Con JWT (`auth.middleware.js`) y un rate limit propio (unas 10 por minuto por usuario).
- Hace el sync del usuario logueado.
- Responde **200** con `{ plan, proUntil, proSource }`.
- **502** si RevenueCat falla o no responde (mensaje por `messages.js`).

### El sync

`syncUser(userId)` en el service:

1. `GET https://api.revenuecat.com/v1/subscribers/{userId}` con `Authorization: Bearer REVENUECAT_SECRET_KEY`. Timeout de 10 segundos.
2. Lee `subscriber.entitlements.nutrilife_pro`. Si existe, toma su `product_identifier` y busca ese producto en `subscriber.subscriptions` para sacar `store`, `is_sandbox`, `unsubscribe_detected_at` y `billing_issues_detected_at`. `expires_at` es el mayor entre `expires_date` y `grace_period_expires_date` del entitlement.
3. Si la suscripción es sandbox y `REVENUECAT_ALLOW_SANDBOX` no es `true`, cuenta como si no tuviera el entitlement.
4. En una transacción: upsert en `store_subscriptions`, lee `gift_pro` / `gift_pro_until`, aplica la regla y actualiza `plan_id` y `pro_until`.
5. Si el plan cambió, lo registra en consola como hace `proExpiry`.

Como el sync siempre lee el estado real, los eventos repetidos o en desorden no hacen daño.

### Perfil

`user.repository.js` agrega `proSource` (calculado con la regla) a la respuesta del perfil, junto a `plan` y `proUntil`. Se actualizan los schemas de Swagger.

### Variables de entorno (Dokploy)

| Variable | Valor |
|---|---|
| `REVENUECAT_SECRET_KEY` | Secret API key v1 del proyecto en RevenueCat |
| `REVENUECAT_WEBHOOK_AUTH` | Un valor largo al azar; el mismo va en el dashboard de RevenueCat |
| `REVENUECAT_ALLOW_SANDBOX` | `true` mientras se prueba con la Test Store. **Pasar a `false` cuando salgan las tiendas reales.** |

Se leen en `env_config.js`. Si falta `REVENUECAT_SECRET_KEY`, el sync y el webhook responden 502. El servidor arranca igual.

## App (Flutter)

### Dependencias y plataforma

- `flutter pub add purchases_flutter`. Si no está, también `url_launcher`.
- Android: confirmar `minSdk` compatible con `purchases_flutter`, y que la `MainActivity` use `launchMode` `standard` o `singleTop`, como pide RevenueCat. El permiso de billing lo agrega el SDK.
- iOS: nada extra para la Test Store. In-App Purchase se activa cuando exista la cuenta de Apple.

### `lib/core/services/purchase_service.dart`

Es el único archivo que importa `purchases_flutter`. Expone una interfaz pequeña para poder usar un servicio falso en las pruebas:

- `isEnabled`: `false` si no hay key.
- `init()`: `Purchases.configure` con la key de la plataforma. Se llama en `main`.
- `logIn(userId)` / `logOut()`.
- `loadPlans()`: offering `current` → paquetes mensual y anual, con `priceString` y el paquete para comprar.
- `purchase(plan)`: devuelve un resultado (éxito, cancelado, pendiente o error con tipo).
- `restore()`: devuelve si quedó activo `nutrilife_pro`.
- `managementUrl()`: la `managementURL` del `CustomerInfo`.

Las keys llegan por `--dart-define`: `REVENUECAT_ANDROID_KEY` y `REVENUECAT_IOS_KEY` (hoy las dos son la `test_…`). No se escriben en el código. **Una build de producción nunca debe llevar la key `test_…`.**

### Sesión

- Después de `SessionService.save` y de `SessionService.restore` con éxito: `PurchaseService.logIn(user_id)`.
- En `SessionService.clear`: `PurchaseService.logOut()`. Si falla, se ignora: el SDK lanza error al cerrar la sesión de un usuario anónimo.

### Pantalla premium

Se conserva el diseño de `premium_screen.dart`.

- Se borran `kPremiumMonthlyPrice` y `kPremiumYearlyPrice`. Al abrir carga `loadPlans()`; el precio de cada tarjeta es el `priceString` de la tienda.
- **Cargando:** las tarjetas muestran un indicador y el botón queda deshabilitado.
- **Error al cargar:** mensaje con "Reintentar".
- **Sin key** (`isEnabled == false`): el comportamiento de hoy ("pagos pronto").
- **Comprar:**
  - Éxito → `POST /subscription/sync` → se cierra la pantalla con "¡Ya eres PRO!" y quien la abrió recarga el perfil.
  - Cancelado → nada.
  - Pendiente → "tu pago está pendiente, te avisaremos cuando se confirme".
  - Otros errores (pago rechazado, tienda no disponible, ya comprado) → mensaje traducido.
  - Compra bien pero sync con error → "tu compra se registró, el PRO puede tardar unos minutos", y se cierra la pantalla igual.
- **Restaurar compras:** `restore()` y luego el sync. Sin compras → "no encontramos compras para restaurar".
- **Texto legal** debajo del botón: se renueva automáticamente, se cancela cuando quieras desde la tienda, junto a los enlaces a términos y privacidad que ya existen.

### Perfil

- `profile_repository.dart` lee `proSource`.
- Fila PRO:
  - Si `proSource` es `store` o `both`: subtítulo "Activo hasta X" y al tocarla abre la `managementURL` (Administrar suscripción).
  - Si es `gift`: como hoy.
  - Si es FREE: abre la pantalla premium, como hoy.

### Textos

Todo texto nuevo va por ARB (`es` y `en`). En el backend, por `messages.js`.

## Pruebas

### Backend (`node --test`, carpeta `test/subscription/`)

- `effectivePlan`: solo regalo con fecha, solo regalo para siempre, solo tienda, regalo + tienda (gana la fecha más lejana), regalo para siempre + tienda (`NULL`), los dos vencidos (FREE), y el margen de 1 hora.
- Lectura de la respuesta de RevenueCat: entitlement activo, vencido o ausente; período de gracia; sandbox con `REVENUECAT_ALLOW_SANDBOX` en `true` y `false`; renovación cancelada; problema de cobro.
- Webhook: token incorrecto o sin configurar (401), `TEST` (200), ids anónimos o inexistentes que se ignoran, `TRANSFER` que sincroniza a los dos usuarios, falla de RevenueCat (500).
- Sync: sin JWT (401), éxito (200 con `proSource`), falla de RevenueCat (502).
- Panel: regalar y quitar PRO a quien también tiene suscripción recalcula sin tocar `store_subscriptions`. Se ajustan `proGift.test.js` y `admin.service.test.js`.
- La API de RevenueCat siempre va simulada: ninguna prueba sale a internet.

### App (`flutter test`)

Pantalla premium con un `PurchaseService` falso: precios del offering, carga, error con reintento, compra cancelada sin efecto, compra exitosa que llama al sync, restaurar sin compras, sin key ("pagos pronto"). Fila PRO del perfil según `proSource`.

### Manual (la hace el usuario; Claude solo lanza la app en el emulador)

1. Con la Test Store: comprar el mensual, ver el PRO en el perfil y que el Chef IA tenga el límite PRO.
2. Cancelar o expirar desde el dashboard de RevenueCat y ver que vuelve a FREE al vencer.
3. Cerrar sesión, entrar de nuevo, restaurar y ver que vuelve el PRO.
4. Botón "Send test event" del webhook en el dashboard: el backend responde 200.

## Configuración en RevenueCat (la hace el usuario)

1. **Entitlement** `nutrilife_pro` con los productos `monthly` y `yearly` de la Test Store.
2. **Offering** `default`, marcado como *current*, con los paquetes Monthly y Annual.
3. **Webhook** a `https://<backend>/api/v1/subscription/webhook`, con el header de autorización igual a `REVENUECAT_WEBHOOK_AUTH`.
4. **Secret API key (v1)** en Dokploy como `REVENUECAT_SECRET_KEY`.
5. Cuando estén las cuentas de las tiendas: crear los productos en Play Console y App Store Connect, asociarlos a los mismos paquetes, cambiar las keys de `--dart-define` por las públicas de cada tienda y poner `REVENUECAT_ALLOW_SANDBOX=false`.
