# Modo invitado para la beta

Fecha: 2026-10-18

## Problema

Los testers de la beta no quieren crear una cuenta solo para probar la app ("the app requires login and I did not want to create an account just for testing"). Sin cuenta no pasan del login, así que no prueban nada.

## Decisión

Un botón "Entrar como invitado" en el login que crea una **cuenta real y temporal** en el backend, ya cargada con datos de ejemplo. La app funciona igual que con cualquier cuenta: no hay datos falsos del lado de la app. La cuenta dura **24 horas** y después se borra con todo lo que tenga. El invitado está en plan **FREE** y no puede comprar.

Es solo para la beta: se apaga con una variable de entorno en Dokploy, sin sacar versión nueva de la app.

## Backend

### Interruptor

`GUEST_MODE_ENABLED=true` lo enciende. Apagado o sin definir:

- `POST /auth/guest` responde 404.
- `GET /auth/health` devuelve `guestModeEnabled: false`.
- Los invitados que ya existen siguen hasta que vencen y la limpieza los borra igual (la limpieza no depende del interruptor).

### Base de datos

Migración `update_18_10_2026_guest_mode.sql`:

```sql
ALTER TABLE users ADD COLUMN guest_expires_at TIMESTAMPTZ NULL;
CREATE INDEX idx_users_guest_expires_at ON users (guest_expires_at) WHERE guest_expires_at IS NOT NULL;
```

Una cuenta es de invitado si y solo si `guest_expires_at IS NOT NULL`.

### `POST /auth/guest`

Sin cuerpo. Con un rate limit propio y estricto por IP (5 por hora), para que nadie llene la base.

1. Crea el usuario en una transacción:
   - `name`: "Invitado" (o "Guest" según `req.lang`).
   - `email`: `guest-<uuid>@guest.nutrilife.invalid` (la columna es `UNIQUE NOT NULL`; `.invalid` nunca es un dominio real y no se le envía correo).
   - `password`: NULL. `email_verified_at`: ahora (no debe pedir verificación).
   - Rol USER, plan FREE.
   - `guest_expires_at`: ahora + 24 h.
2. En la misma transacción le carga datos de ejemplo:
   - Perfil completo (edad, altura, sexo, peso, objetivo), para que la app no lo mande al setup.
   - Los últimos 7 días de comidas (desayuno, almuerzo y cena con alimentos del catálogo común), agua y unos registros de peso, para que el dashboard y el progreso no salgan vacíos.
3. Responde lo mismo que el login normal (token y usuario), más `guestExpiresAt`. El usuario también lleva `isGuest: true` y `guestExpiresAt` en cada respuesta de perfil.

### Lo que un invitado no puede hacer

403 con un mensaje traducido ("Crea una cuenta para hacer esto"):

- Comprar o sincronizar suscripciones (rutas de `subscription` que vienen de la app).
- Cambiar correo o contraseña.
- Vincular Google (`/auth/google/link`).

Todo lo demás funciona igual, con los límites FREE de siempre (incluido el Chef IA). Borrar su propia cuenta sí puede.

### Vencimiento

- `authenticateToken` rechaza con 401 a un invitado cuyo `guest_expires_at` ya pasó, aunque el token siga siendo válido.
- `guestCleanup.job.js` (mismo patrón que `proExpiry.job.js`): barre al arrancar y después cada hora; borra cada invitado vencido con `deleteUserAccountData`. Nunca lanza: un fallo solo se registra y el resto sigue.

### Panel y estadísticas

- El overview y `stats` no cuentan invitados como usuarios.
- La lista de usuarios del panel los muestra con una etiqueta "Invitado".

## App

### Botón

En el login, debajo del botón de Google: "Entrar como invitado". Solo aparece si `GET /auth/health` responde `guestModeEnabled: true`. Si la consulta falla o tarda, no aparece (el login nunca espera por él).

### Alerta antes de entrar

Al tocar el botón, antes de crear nada:

> **Entrar como invitado**
> - Es una cuenta de prueba con datos de ejemplo.
> - Se borra en 24 horas, junto con todo lo que registres.
> - Tiene el plan FREE y no puedes comprar PRO.
> - Si quieres guardar tu progreso, crea una cuenta.
>
> [Cancelar] [Entrar]

"Entrar" llama a `POST /auth/guest`, guarda la sesión como un login normal y va directo al dashboard (sin onboarding ni setup). Si falla, sale el error de siempre.

### Mientras es invitado

- **Inicio:** una franja fija "Modo invitado · se borra en Xh" con un botón "Crear cuenta" (cierra la sesión y abre el registro).
- **Premium:** el botón de compra aparece desactivado, con el texto "Crea una cuenta para suscribirte".
- **Perfil:** se ocultan cambiar correo, cambiar contraseña y vincular Google.
- **RevenueCat:** no se hace `logIn` con un invitado.

### Al vencer

El manejo de 401 que ya existe en `dio_client.dart` lo manda al login. Si la sesión era de invitado, el login muestra "Tu cuenta de invitado venció".

### Textos

Todos por ARB, en español e inglés.

## Fuera del alcance

- Convertir la cuenta de invitado en una cuenta real. "Crear cuenta" registra una cuenta nueva y vacía; los datos de prueba no se pasan.
- Modo sin conexión o datos falsos dentro de la app.

## Tests

- **Backend:** `POST /auth/guest` crea usuario, perfil y datos de ejemplo, y responde 404 con el interruptor apagado; el rate limit; `authenticateToken` rechaza invitados vencidos; las rutas bloqueadas dan 403; `runGuestCleanup` borra solo los vencidos y no lanza si falla la base; overview y stats excluyen invitados.
- **App:** el botón aparece o no según `guestModeEnabled` (y no aparece si falla la consulta); la alerta muestra los cuatro puntos y "Cancelar" no crea nada; la franja del inicio solo sale para invitados; Premium bloquea la compra; textos en inglés sin desbordes a 375x812.

## Al terminar la beta

Poner `GUEST_MODE_ENABLED=false` en Dokploy. El botón desaparece en todas las versiones instaladas y en 24 horas no queda ningún invitado. Quitar el código es opcional y puede hacerse en otra versión.
