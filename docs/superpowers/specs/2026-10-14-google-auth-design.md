# Diseño: Inicio de sesión con Google

## Contexto

Hoy la autenticación es solo email + contraseña (`backend/src/modules/auth`): bcrypt para
el hash y un JWT propio de 1 h. La app tiene un botón "Google" en `login_screen.dart` que
no hace nada (desde el commit `1638a7a` muestra el wordmark de Google y el botón de Apple
se retiró temporalmente).

Restricciones encontradas en el código:

- `users.password` es `NOT NULL` (`Nutri_Script.sql`).
- `DELETE` de la cuenta exige la contraseña (`user.service.js` → `deleteUserAccount`).
- No existe flujo de cambiar ni recuperar contraseña.
- Tras registrarse con email la app va a `ProfileSetupScreen` (edad, peso, altura) y
  luego a `GoalSetupScreen`; tras el login va al Dashboard.
- El admin-panel solo admite cuentas `ADMIN` con email + contraseña.
- `strictAuthRateLimit` existe en `rateLimit.middleware.js` pero no se usa en ninguna ruta.
- El backend no tiene tests configurados.

## Objetivo

Que un usuario pueda registrarse e iniciar sesión en la app con su cuenta de Google,
recibiendo el mismo JWT propio que el login con email, sin romper a los usuarios actuales.

## Decisiones

| Tema | Decisión |
|---|---|
| Proveedores | Solo Google. Apple queda fuera por ahora, pero el modelo de datos lo admite sin migrar. |
| Email ya registrado con contraseña | Se vincula automáticamente si Google devuelve `email_verified = true`, y la contraseña se borra (la cuenta pasa a ser solo de Google). El registro con email no verifica el correo: así, quien registró antes el correo de otra persona pierde el acceso en cuanto el dueño real entra con Google. Excepción: las cuentas ADMIN conservan la contraseña (el panel de admin solo entra con ella, y el rol ADMIN se asigna a mano, así que no puede ser una cuenta preparada por otra persona). |
| Usuarios sin contraseña | Solo pueden entrar con Google. El login con email les responde `USE_GOOGLE_SIGN_IN`. Crear contraseña queda como trabajo futuro. |
| Borrar cuenta sin contraseña | Se re-autentica con Google; el backend comprueba que el `sub` coincide. |
| Admin-panel | Sigue con email + contraseña. Muestra el método de cada usuario (`EMAIL`, `GOOGLE`, `BOTH`). `BOTH` solo aparecerá cuando exista "crear contraseña desde el perfil". |
| A dónde va el usuario tras entrar | Según `needsProfileSetup` (`age IS NULL`), tanto en Google como en el login con email. |
| Modelo de datos | Tabla `user_auth_providers` (no una columna `google_sub`, no Firebase Auth). |

## Base de datos

Nueva migración `backend/src/database/backups/update_14_10_2026_google_auth.sql`:

```sql
ALTER TABLE users ALTER COLUMN password DROP NOT NULL;

CREATE TABLE IF NOT EXISTS user_auth_providers (
  id               INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  user_id          INTEGER NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
  provider         VARCHAR(20) NOT NULL CHECK (provider IN ('google')),
  provider_user_id VARCHAR(255) NOT NULL,
  email            VARCHAR(255),
  created_at       TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  UNIQUE (provider, provider_user_id),
  UNIQUE (user_id, provider)
);
```

- `provider_user_id` guarda el `sub` de Google, que es estable; el email puede cambiar.
- `email` es solo informativo (el email con el que se vinculó).
- Para añadir Apple basta con ampliar el `CHECK`.

## Backend

### Configuración

- Nueva variable `GOOGLE_CLIENT_IDS`: client IDs de Web, Android e iOS separados por comas.
- `env_config.js` la expone como `config.google.clientIds` (array, sin vacíos).
- Se documenta en `.env.example`.
- Dependencia nueva: `google-auth-library`.

### Verificación del token

Módulo `backend/src/modules/auth/google.verifier.js` con una sola función
`verifyGoogleIdToken(idToken)`:

- Si `config.google.clientIds` está vacío → `AppError` 500 `AUTH_CONFIG_ERROR`.
- Llama a `OAuth2Client.verifyIdToken({ idToken, audience: clientIds })`.
- Si falla (firma, expiración, audiencia) → `AppError` 401 `INVALID_GOOGLE_TOKEN`.
- Devuelve `{ sub, email, emailVerified, name }`.

Va en un módulo aparte para poder simularlo en los tests.

### Endpoint `POST /api/v1/auth/google`

- Body: `{ idToken: string }`, validado en `validateGoogleLoginRequest` (requerido, string no vacío).
- Middleware: `strictAuthRateLimit`.
- Respuesta 200: `{ token, user, needsProfileSetup }`, con el mismo formato de `user` que `/login`.
- Documentado con `@openapi` en `auth.routes.js` y en `auth.swagger.yaml`.

### `loginWithGoogle({ idToken })` en `auth.service.js`

1. `verifyGoogleIdToken(idToken)`.
2. Si `emailVerified !== true` → 403 `GOOGLE_EMAIL_NOT_VERIFIED`.
3. Busca en `user_auth_providers` por `('google', sub)`:
   - **Existe** → ese es el usuario. Evento `LOGIN` con `metadata.method = 'google'`.
   - **No existe y hay un usuario con ese email** → inserta la fila del proveedor
     (vinculación) y, en la misma transacción, pone su `password` en `NULL` salvo
     que el usuario sea ADMIN. Evento
     `ACCOUNT_LINKED`, y luego `LOGIN`. Si ese usuario ya tiene
     vinculada otra cuenta de Google (otro `sub`, p. ej. una cuenta de Google borrada y
     recreada con el mismo email) → 409 `GOOGLE_ACCOUNT_CONFLICT`; no se sobrescribe.
   - **No existe ninguno** → crea el usuario con `password = NULL`, el `name` de Google
     (si viene vacío, la parte local del email), rol `USER` y plan `FREE`. Crea su
     nevera e inserta la fila del proveedor. Evento `REGISTER` con
     `metadata.method = 'google'`.
   - La creación del usuario y de la fila del proveedor van en una transacción.
     Si dos peticiones simultáneas chocan con el `UNIQUE`, se reintenta la búsqueda una vez.
4. Firma el JWT y devuelve `{ token, user, needsProfileSetup: user.age == null }`.

### Refactor compartido

En `auth.service.js`:

- `issueToken(user)` — arma el payload y firma el JWT. La usan `loginUser` y `loginWithGoogle`.
- `createUserWithDefaults({ name, email, passwordHash, goal })` — busca el rol y el plan
  por defecto, crea el usuario y su nevera. La usan `registerUser` y `loginWithGoogle`.

`findUserByEmail` y la nueva `findUserByProvider(provider, providerUserId)` devuelven
también `age`, para calcular `needsProfileSetup`.

### Cambios en endpoints existentes

- **`POST /auth/login`**
  - Si el usuario existe y `passwordHash` es `NULL` → 409 `USE_GOOGLE_SIGN_IN`, mensaje
    "Esta cuenta usa Google. Toca «Continuar con Google»." Evento `LOGIN_FAILED` con
    `reason: 'USE_GOOGLE_SIGN_IN'`.
  - La respuesta añade `needsProfileSetup`.
- **`GET /users/profile`** — añade `hasPassword: boolean`.
- **`DELETE` de la cuenta**
  - Body: `{ password }` o `{ googleIdToken }`. La validación exige exactamente uno.
  - Si el usuario tiene contraseña, se exige `password` (como ahora).
  - Si no tiene contraseña, se exige `googleIdToken`: se verifica y el `sub` debe coincidir
    con su fila de `user_auth_providers`. Si no coincide → 403 `GOOGLE_ACCOUNT_MISMATCH`.
  - `ON DELETE CASCADE` borra la fila del proveedor.

### Admin

`findUsers` y `findUserDetail` en `admin.repository.js` añaden `authMethod`:

```sql
CASE
  WHEN u.password IS NOT NULL AND EXISTS (SELECT 1 FROM user_auth_providers p WHERE p.user_id = u.user_id) THEN 'BOTH'
  WHEN u.password IS NOT NULL THEN 'EMAIL'
  ELSE 'GOOGLE'
END AS "authMethod"
```

### Errores

| Caso | HTTP | Código |
|---|---|---|
| `idToken` ausente o vacío | 400 | `VALIDATION_ERROR` |
| `idToken` inválido, expirado o de otro client | 401 | `INVALID_GOOGLE_TOKEN` |
| Email de Google no verificado | 403 | `GOOGLE_EMAIL_NOT_VERIFIED` |
| Login con email en una cuenta solo de Google | 409 | `USE_GOOGLE_SIGN_IN` |
| El usuario del email ya tiene vinculada otra cuenta de Google | 409 | `GOOGLE_ACCOUNT_CONFLICT` |
| Borrar la cuenta con el token de otro usuario de Google | 403 | `GOOGLE_ACCOUNT_MISMATCH` |
| Falta `GOOGLE_CLIENT_IDS` | 500 | `AUTH_CONFIG_ERROR` |

### Tests

- Se configura `node --test` en `npm test` (incluido en Node, sin dependencias).
- Tests de `loginWithGoogle` con el verificador y el repositorio simulados: usuario nuevo,
  vinculación por email, usuario ya vinculado, conflicto con otra cuenta de Google,
  email no verificado y token inválido.
- Tests de `loginUser` con contraseña `NULL` (`USE_GOOGLE_SIGN_IN`) y de
  `needsProfileSetup`.
- Tests de `deleteUserAccount` con `googleIdToken` válido y con `sub` distinto.

## App Flutter

### Dependencia y configuración

- `google_sign_in` 7.x.
- `GoogleSignIn.instance.initialize(serverClientId: <client ID web>)` una vez, antes del
  primer uso. Sin `serverClientId`, Android no devuelve `idToken`.
- El client ID web vive en una constante junto a `core/network/api_routes.dart`.

### Código nuevo

- `core/services/google_auth_service.dart` — `Future<String?> getIdToken()`: abre el
  selector y devuelve el `idToken`, o `null` si el usuario cancela. Cualquier otro fallo
  lanza `AuthException` con un mensaje en español.
- `AuthRepository.loginWithGoogle(String idToken)` — llama a `POST /auth/google` y
  devuelve `token`, `user` y `needsProfileSetup`.

### Login (`login_screen.dart`)

Botón "Continuar con Google":

1. Activa el overlay `_isLoading` que ya existe.
2. `getIdToken()`. Si devuelve `null`, quita el overlay y no muestra nada.
3. `loginWithGoogle`, `SessionService.save(...)` y `DioClient.authToken = token`.
4. Si `needsProfileSetup` → `ProfileSetupScreen(userName: user['name'])` con
   `pushAndRemoveUntil`. Si no → `DashboardScreen`, como el login actual.
5. Si hay un error, SnackBar con el `message` del backend.

El login con email aplica la misma regla de `needsProfileSetup` y muestra el mensaje de
`USE_GOOGLE_SIGN_IN` cuando corresponda.

### Borrar la cuenta (`profile_screen.dart`)

- `UserProfile` añade `hasPassword`.
- `hasPassword == true` → el diálogo actual con contraseña.
- `hasPassword == false` → diálogo de confirmación con el botón "Confirmar con Google",
  que llama a `getIdToken()` y luego a `ProfileRepository.deleteAccount(googleIdToken: ...)`.

### Tests

- Test unitario de `AuthRepository.loginWithGoogle` con Dio simulado: lectura de
  `needsProfileSetup` y mensajes de error.
- El selector nativo se prueba a mano en un dispositivo Android y en el IPA de iOS.

## Admin-panel

- `types/admin.ts`: `authMethod: 'EMAIL' | 'GOOGLE' | 'BOTH'` en el usuario de la lista
  y del detalle.
- Etiqueta "Email" / "Google" / "Ambos" en la tabla de usuarios y en `UserDetail.tsx`.
- Comprobar que `lib/modules.ts` muestra `ACCOUNT_LINKED` en Events (categoría `AUTH`).
- El login del panel no cambia.

## Configuración manual (fuera del código)

1. **Google Cloud Console**, pantalla de consentimiento OAuth y tres clients:
   - **Web** — es el `serverClientId` de la app y una de las audiencias del backend.
   - **Android** — paquete `software.oween.nutrilife` y huellas SHA-1 de la llave de debug,
     de la de release y de la de Play App Signing si se usa.
   - **iOS** — bundle ID de la app.
2. **iOS** — en `ios/Runner/Info.plist`, `GIDClientID` y un `CFBundleURLTypes` con el
   client ID invertido.
3. **Backend** — `GOOGLE_CLIENT_IDS` con los tres IDs en cada entorno.

## Orden de despliegue

1. Migración en la base de datos de producción. Es compatible con la app actual.
2. Backend con `GOOGLE_CLIENT_IDS`.
3. Admin-panel.
4. App.

## Fuera de alcance (trabajo futuro)

- Crear una contraseña desde el perfil para usuarios de Google.
- Volver a añadir Sign in with Apple. **Necesario antes de publicar en la App Store**
  (App Review Guideline 4.8).
- "Olvidé mi contraseña".
- Desvincular Google de una cuenta.
- Login con Google en el admin-panel.
- Aplicar `strictAuthRateLimit` a `/auth/login`.
