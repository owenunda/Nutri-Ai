# Diseño: Pedir la contraseña al vincular Google

Continúa `2026-10-14-google-auth-design.md`. Reemplaza la "opción (a)" de ese spec
(borrar la contraseña al vincular).

## Contexto

Hoy, si alguien entra con Google y su correo ya tiene una cuenta con contraseña, el
backend vincula automáticamente y **borra la contraseña** (salvo cuentas ADMIN). Así se
evita que alguien que registró el correo de otra persona (el registro con email no
verifica el correo) conserve acceso. El costo: el usuario legítimo pierde su contraseña.

## Objetivo

Que el usuario legítimo conserve las dos formas de entrar, sin abrir la puerta a quien
registró un correo ajeno: para vincular, hay que demostrar que se es dueño **del correo**
(Google) **y de la cuenta** (su contraseña).

## Decisiones

| Tema | Decisión |
|---|---|
| Cómo se vincula | La app reenvía el `idToken` de Google junto con la contraseña a `POST /auth/google/link`. Sin tokens propios ni estado en el servidor. |
| Contraseña olvidada | "Cancelar" vuelve a la pantalla anterior. No se agrega recuperación (eso llega con la verificación por correo). |
| Opción (a) | Se elimina: ya no se borra ninguna contraseña. La excepción de ADMIN deja de hacer falta. |
| Términos en el login | Línea legal bajo el botón de Google del login: "Al continuar con Google aceptas los Términos del Servicio y la Política de Privacidad". |

## Backend

### `POST /auth/google` (cambio)

En `resolveGoogleUser`, si no hay vínculo por `sub` y existe un usuario con ese email:

- Si ya tiene otra cuenta de Google → 409 `GOOGLE_ACCOUNT_CONFLICT` (sin cambios).
- Si **tiene contraseña** → 409 `GOOGLE_LINK_REQUIRES_PASSWORD`, mensaje
  "Ya tienes una cuenta con este correo. Escribe tu contraseña para vincularla con Google."
  No se vincula nada.
- Si **no tiene contraseña** (caso raro) → se vincula directo, sin borrar nada.

`linkProviderToExistingUser` deja de recibir `clearPassword` y nunca toca `users.password`.

### `POST /auth/google/link` (nuevo)

Body `{ idToken, password }` (ambos string no vacío), con `strictAuthRateLimit`.

1. `verifyGoogleIdToken`; si `emailVerified` no es true → 403 `GOOGLE_EMAIL_NOT_VERIFIED`.
2. Si el `sub` ya está vinculado → inicia sesión con ese usuario (reintento idempotente).
3. Busca el usuario por email: no existe → 404 `USER_NOT_FOUND`; tiene otra cuenta de
   Google → 409 `GOOGLE_ACCOUNT_CONFLICT`.
4. Si tiene contraseña y `bcrypt.compare` falla → 401 `INVALID_PASSWORD` y evento
   `LOGIN_FAILED` con `{ reason: 'INVALID_PASSWORD', method: 'google-link' }`.
5. Vincula (sin tocar la contraseña), eventos `ACCOUNT_LINKED` y `LOGIN`
   (`method: 'google'`), y responde `{ token, user, needsProfileSetup, offerPasswordSetup: false }`.

El 401 no cierra la sesión en la app: `DioClient` no redirige en rutas `/auth/*`.

## App

- `AuthRepository.loginWithGoogle`: ante `GOOGLE_LINK_REQUIRES_PASSWORD` lanza
  `GoogleLinkRequiredException` (subclase de `AuthException`).
- `AuthRepository.linkGoogle(idToken, password)` → `GoogleLoginResult`.
- `signInWithGoogle`: ante esa excepción abre **encima** `LinkGoogleAccountScreen(idToken)`
  y devuelve null (el login o registro de abajo quita su carga).
- `LinkGoogleAccountScreen`: estilo de "Crea tu contraseña". Título "Vincula tu cuenta";
  texto "Ya tienes una cuenta de NutriLife con este correo. Escribe tu contraseña para
  vincularla con Google; después podrás entrar de las dos formas."; campo de contraseña;
  botones "Vincular" y "Cancelar" (vuelve atrás); error dentro de la pantalla. Al vincular,
  guarda la sesión y sigue con `openAppAfterLogin`.
- Login: línea legal bajo el botón de Google con enlaces a los documentos de
  `LegalDocuments`.

## Plan

1. Backend, TDD: tests de servicio (requiere contraseña, vincula conservándola,
   contraseña incorrecta, `sub` ya vinculado, conflicto, usuario inexistente) y de
   validación; quitar `clearPassword` y ajustar los tests de la opción (a); ruta,
   controlador y doc OpenAPI. Commit.
2. App, TDD: `GoogleLinkRequiredException` y `linkGoogle` en el repositorio. Commit junto
   con el paso 3.
3. App: `LinkGoogleAccountScreen` con widget tests (vincular, contraseña incorrecta,
   cancelar) y su uso en `signInWithGoogle`.
4. App: línea legal en el login.
5. `npm test`, `flutter analyze`, `flutter test`; actualizar el spec original; commit y push.

## Fuera de alcance

- Recuperar contraseña y verificar el correo al registrarse (parte 4).
- Cambiar una contraseña existente desde la app.
