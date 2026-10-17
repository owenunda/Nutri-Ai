# Límite diario de mensajes del Chef IA (FREE / PRO)

Fecha: 2026-10-17
Parte 1 de la separación FREE / PRO. Las siguientes partes (recetas guardadas, historial de progreso, planes semanales, pagos) tienen su propio spec.

## Objetivo

Separar FREE de PRO en el Chef IA y proteger la cuota compartida de la suscripción de MiniMax (plan Plus: 300 prompts cada 5 horas para todos los usuarios juntos).

- FREE: **3 mensajes al día**.
- PRO: "sin límite" para el usuario, con un tope de uso justo de **50 mensajes al día** que no se anuncia.
- ADMIN: sin límite.
- El contador se reinicia a la **medianoche de Colombia** (America/Bogota, UTC-5, sin horario de verano).

Mientras no haya pagos, el PRO se asigna desde el panel de admin (`PATCH /api/v1/admin/users/:userId/plan`), que ya existe.

## Qué cuenta como mensaje

Cuenta cada `POST /api/v1/n8n/chat` que termina con una respuesta de n8n. **No** cuentan:

- Las peticiones que rechaza el rate limit por minuto (10/min), que va antes.
- Las que fallan en n8n o MiniMax: el mensaje se devuelve.
- Las que no pasan la validación (`message` vacío).

## Backend

### `src/config/plan_limits.js` (nuevo)

Es la única fuente de los límites por plan. Las partes siguientes agregan aquí sus propios límites.

```js
export const CHAT_DAILY_LIMITS = { FREE: 3, PRO: 50 };
// ADMIN (rol) no tiene límite. Un plan desconocido usa el límite FREE.
```

Los valores se pueden sobreescribir con variables de entorno (`CHAT_DAILY_LIMIT_FREE`, `CHAT_DAILY_LIMIT_PRO`) en `env_config.js`, siguiendo el patrón de `rateLimit`. Así se ajustan sin desplegar código mientras se mide el consumo real.

### `src/middleware/chatQuota.middleware.js` (nuevo)

Se monta en `POST /api/v1/n8n/chat` después de `chatRateLimit`.

1. Si `req.user.role === 'ADMIN'` → `next()` sin contar. `req.chatQuota = { unlimited: true }`.
2. Lee el plan del usuario de la base de datos (`users` ⨝ `plans`), no del JWT. Así, un cambio de plan desde el admin aplica en el siguiente mensaje.
3. Clave Redis: `quota:chat:{userId}:{YYYY-MM-DD}`, con la fecha calculada en America/Bogota.
4. `INCR` atómico. Si es el primer incremento, `EXPIREAT` a la próxima medianoche de Bogotá + 1 hora de margen.
5. Si el valor pasa el límite → `DECR` (para no inflar el contador) y responde **429**:
   - `code: 'CHAT_DAILY_LIMIT'` (FREE) o `'CHAT_FAIR_USE_LIMIT'` (PRO)
   - mensaje localizado (es/en) vía `localizeError`
   - `data: { quota }` con la misma forma del punto 6 (`remaining: 0`, `exhausted: true`); `resetAt` es el ISO de la próxima medianoche de Bogotá.
6. Si no pasa el límite → deja en `req.chatQuota` `{ quota, refund }`, donde `quota` es `{ plan, unlimited, limit, used, remaining, resetAt, exhausted }` y `refund()` hace `DECR`. `exhausted` es true cuando ya no quedan mensajes (también para PRO en su tope), y la app lo usa para bloquear el input.
7. **Redis caído**: deja pasar el mensaje, registra en el log y deja `req.chatQuota = { quota: null, refund: noop }`. Es el mismo criterio fail-open que `rateLimit.middleware.js`.

Si el usuario del token ya no existe en la base de datos, responde 401, igual que cualquier petición sin usuario válido.

### `POST /api/v1/n8n/chat` (cambio en `app.js`)

- Si `sendChatN8n` lanza error → `req.chatQuota?.refund()` antes de responder.
- El error `N8N_ERROR` pasa a mostrar un mensaje amigable localizado: es: "El Chef está descansando un momento. Intenta de nuevo en un rato." / en: "The Chef is taking a short break. Try again in a little while." El status pasa de 500 a 503 y no consume mensaje.
- La respuesta exitosa agrega `quota` junto a los datos de n8n:
  `data: { ...respuestaN8n, quota: { plan, unlimited, limit, used, remaining, resetAt, exhausted } }`.
  Si Redis estaba caído, `quota` es `null`.

### `GET /api/v1/chat/quota` (nuevo, en `chat.routes.js`)

Devuelve la cuota de hoy sin consumir: `{ plan, unlimited, limit, used, remaining, resetAt, exhausted }`. Usa el mismo helper que el middleware (lee con `GET`, sin `INCR`). Los roles `ADMIN` y `USER` pueden llamarlo.

Para PRO, el endpoint devuelve `unlimited: true` y no expone `limit` ni `used` (el tope de 50 es interno). Si un PRO llega a 50, recibe un 429 con el código `CHAT_FAIR_USE_LIMIT` y el mensaje "Llegaste al límite de uso justo de hoy. Vuelve mañana."

### Helper de fecha

`src/utils/bogotaDay.js`: `bogotaDayKey(now)` → `'2026-10-17'` y `nextBogotaMidnight(now)` → `Date`. Bogotá no tiene horario de verano, así que basta con un desplazamiento fijo de -5 h, sin librerías.

### i18n

Se agregan a `CODE_MESSAGES` en `src/i18n/messages.js`:
- `CHAT_DAILY_LIMIT` (FREE): es "Usaste tus 3 mensajes de hoy con el Chef IA." / en "You've used your 3 Chef AI messages for today." El número sale de `params.limit`.
- `CHAT_FAIR_USE_LIMIT` (PRO): es/en del mensaje de uso justo.
- `N8N_ERROR`: el mensaje amigable de arriba.

## App (Flutter)

### Datos

- `ChatQuota` (modelo): `limit`, `used`, `remaining`, `resetAt`, `unlimited`.
- `ChatRepository.getQuota()` → `GET /chat/quota`.
- `ChatRepository.sendMessage` lee `data.quota` de la respuesta y la expone en `ChatResponse.quota`.
- Un 429 con `code == 'CHAT_DAILY_LIMIT'` o `'CHAT_FAIR_USE_LIMIT'` se convierte en una `ChatQuotaExceededException(quota)`, distinta de la `RateLimitException` por minuto que ya existe.

### `ChatViewModel`

- Al abrir el chat llama a `getQuota()`. Si falla, el chat funciona igual, sin chip.
- Guarda la cuota actual y la actualiza con cada respuesta y con la excepción de límite.
- Expone `isQuotaExhausted`.

### UI

- **`ChatQuotaChip`** (nuevo, junto a `RateLimitChip`): "2 de 3 mensajes hoy". Siempre visible para FREE y oculto si `unlimited`. Usa el mismo estilo que `RateLimitChip`: ámbar cuando queda 1 y rojo en 0.
- **Estado agotado**: el `ChatInputField` se deshabilita. En su lugar aparece una tarjeta con la nutria (`nutria_atenta.png`), el texto "Usaste tus 3 mensajes de hoy", "Se reinician a las 12:00 a. m." (hora local del teléfono a partir de `resetAt`) y el botón **Hazte Premium**, que abre la `PremiumScreen` existente.
- Para un PRO que llega al tope: la misma tarjeta con el texto de uso justo y sin botón a Premium.
- Los textos nuevos van en `app_es.arb` y `app_en.arb`.

## Medición de consumo

Ya se registran los eventos `POST /api/v1/n8n/chat` (`events.repository.js`). Con eso el admin puede contar mensajes por día. En esta parte no se agrega nada más. Después de unos días de uso real se comparan esos números con el consumo que muestra el panel de MiniMax y se ajustan los límites con las variables de entorno.

## Pruebas

Backend (`node --test`, con mocks de Redis y del repositorio):
- `bogotaDay`: el cambio de día a las 05:00 UTC y `nextBogotaMidnight` justo antes y justo después de medianoche.
- `chatQuota.middleware`: FREE pasa 3 y rechaza el 4.º con 429 `CHAT_DAILY_LIMIT` y `resetAt`; PRO pasa 50 y rechaza el 51.º con `CHAT_FAIR_USE_LIMIT`; ADMIN nunca cuenta; Redis caído deja pasar; `refund()` hace DECR; el rechazo no infla el contador.
- La ruta del chat devuelve el mensaje cuando n8n falla y agrega `quota` en la respuesta exitosa.
- `GET /chat/quota` no consume mensajes y oculta el límite para PRO.
- i18n: los mensajes nuevos en es y en.

App (`flutter test`):
- `ChatQuotaChip`: el texto según la cuota y oculto si es ilimitado.
- El estado agotado deshabilita el input y muestra el botón Premium (FREE) o no lo muestra (PRO).
- El repositorio convierte el 429 `CHAT_DAILY_LIMIT` en `ChatQuotaExceededException`.

Manual: se abre la app en el emulador y el usuario prueba. Para probar FREE→PRO se cambia el plan desde el admin.

## Fuera de alcance

- Límites de recetas guardadas, historial de progreso y planes semanales.
- Pagos reales y restaurar compras.
- Mensajes extra por ver un anuncio.
- Cambios en el flujo de n8n.
- Revisar los términos de uso del Coding Plan de MiniMax para producción. Queda pendiente del dueño, fuera del código.
