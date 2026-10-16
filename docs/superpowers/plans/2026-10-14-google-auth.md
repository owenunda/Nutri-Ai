# Inicio de sesión con Google — Plan de implementación

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Que un usuario pueda registrarse e iniciar sesión en la app con Google y reciba el mismo JWT propio que el login con email.

**Architecture:** La app obtiene un `idToken` con `google_sign_in` y lo manda a `POST /api/v1/auth/google`. El backend lo verifica con `google-auth-library`, busca o crea al usuario (vinculando por email verificado) usando la tabla nueva `user_auth_providers`, y responde con el JWT de siempre más `needsProfileSetup`. Las cuentas sin contraseña confirman el borrado volviendo a autenticarse con Google. El admin-panel solo muestra el método de acceso de cada usuario.

**Tech Stack:** Node 26 + Express 5 + pg (ESM), `node:test` con `mock.module`; Flutter 3.44 + Dio + `google_sign_in` 7.x; React + TypeScript + Vite (admin-panel).

**Spec:** `docs/superpowers/specs/2026-10-14-google-auth-design.md`

## Global Constraints

- Todo el trabajo va en la rama `feat/google-auth`. No hacer push a `main`.
- Los commits **no** llevan `Co-Authored-By` ni ninguna atribución a Claude.
- Mensajes de error para el usuario en español; códigos de error en inglés y MAYÚSCULAS.
- Códigos de error exactos: `INVALID_GOOGLE_TOKEN`, `GOOGLE_EMAIL_NOT_VERIFIED`, `USE_GOOGLE_SIGN_IN`, `GOOGLE_ACCOUNT_CONFLICT`, `GOOGLE_ACCOUNT_MISMATCH`, `AUTH_CONFIG_ERROR`.
- Proveedor: el string `'google'` (minúsculas) en la base y en el código.
- `needsProfileSetup` = `age == null` del usuario.
- Variable de entorno: `GOOGLE_CLIENT_IDS` (IDs separados por comas).
- `google_sign_in` en la versión 7.x (API `GoogleSignIn.instance.initialize` / `authenticate`).
- Los tests del backend corren con `node --experimental-test-module-mocks --test` (sin dependencias de test nuevas).
- **Desviación consciente del spec:** en `DELETE /user/account` un `idToken` de Google inválido responde **403** `INVALID_GOOGLE_TOKEN`, no 401, porque el `DioClient` de la app cierra la sesión ante cualquier 401 (mismo criterio que `INVALID_PASSWORD`). En `POST /auth/google` sí es 401.
- **Desviación consciente del spec:** los errores del login con Google se muestran en el `_errorMessage` del panel de login (como el login con email), no en un SnackBar.

## Mapa de archivos

**Backend (`backend/`)**
- Create `src/database/backups/update_14_10_2026_google_auth.sql` — migración.
- Create `src/modules/auth/google.verifier.js` — verifica el `idToken` con Google.
- Modify `src/config/env_config.js`, `.env.example`, `package.json` — config, dependencia y script de test.
- Modify `src/modules/auth/auth.repository.js` — consultas por proveedor y creación transaccional.
- Modify `src/modules/auth/auth.service.js` — `loginWithGoogle`, `issueToken`, `buildSession`, `createUserWithDefaults`.
- Modify `src/modules/auth/auth.validation.js`, `auth.controller.js`, `auth.routes.js`, `auth.swagger.yaml` — endpoint nuevo.
- Modify `src/modules/user/user.repository.js`, `user.service.js`, `user.validation.js`, `user.controller.js`, `user.routes.js` — `hasPassword` y borrado con Google.
- Modify `src/modules/admin/admin.repository.js` — `authMethod`.
- Create `test/auth/google.verifier.test.js`, `test/auth/auth.service.test.js`, `test/auth/auth.validation.test.js`, `test/user/user.service.test.js`, `test/user/user.validation.test.js`.

**Admin-panel (`admin-panel/`)**
- Modify `src/types/admin.ts`, `src/components/CategoryBadge.tsx`, `src/pages/Users.tsx`, `src/pages/UserDetail.tsx`.

**App (`nutrilife/`)**
- Create `lib/core/constants/google_auth_config.dart` — client ID web.
- Create `lib/core/services/google_auth_service.dart` — selector de Google → `idToken`.
- Modify `lib/core/services/session_service.dart` — cerrar sesión de Google al hacer logout.
- Modify `lib/core/network/api_routes.dart`, `lib/core/services/auth_service.dart`, `lib/features/auth/data/auth_repository.dart`.
- Modify `lib/features/auth/presentation/screens/login_screen.dart`.
- Modify `lib/features/profile/data/profile_repository.dart`, `lib/features/profile/presentation/screens/profile_screen.dart`.
- Modify `ios/Runner/Info.plist`.
- Create `test/features/auth/auth_repository_google_test.dart`, `test/features/profile/profile_repository_delete_test.dart`.

---

### Task 1: Migración, configuración y verificador de Google (backend)

**Files:**
- Create: `backend/src/database/backups/update_14_10_2026_google_auth.sql`
- Create: `backend/src/modules/auth/google.verifier.js`
- Modify: `backend/src/config/env_config.js`
- Modify: `backend/.env.example`
- Modify: `backend/package.json`
- Test: `backend/test/auth/google.verifier.test.js`

**Interfaces:**
- Produces: `verifyGoogleIdToken(idToken: string) → Promise<{ sub: string, email: string, emailVerified: boolean, name: string|null }>`; lanza `AppError` 401 `INVALID_GOOGLE_TOKEN` o 500 `AUTH_CONFIG_ERROR`.
- Produces: `config.google.clientIds: string[]`.
- Produces: `npm test` corre todos los `backend/test/**/*.test.js`.

- [ ] **Step 1: Instalar la dependencia y configurar el script de test**

```bash
cd backend
npm install google-auth-library
```

En `backend/package.json`, reemplazar la línea de `"test"`:

```json
    "test": "node --experimental-test-module-mocks --test \"test/**/*.test.js\"",
```

- [ ] **Step 2: Escribir la migración**

`backend/src/database/backups/update_14_10_2026_google_auth.sql`:

```sql
-- Inicio de sesión con Google.
-- Los usuarios que se registran con Google no tienen contraseña, así que
-- password pasa a aceptar NULL. Cada cuenta externa vinculada es una fila en
-- user_auth_providers: provider_user_id es el "sub" de Google, que no cambia
-- aunque el usuario cambie de correo. Para añadir Apple basta con ampliar el CHECK.

ALTER TABLE users ALTER COLUMN password DROP NOT NULL;

CREATE TABLE IF NOT EXISTS user_auth_providers (
    id               INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id          INTEGER NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    provider         VARCHAR(20) NOT NULL CHECK (provider IN ('google')),
    provider_user_id VARCHAR(255) NOT NULL,
    email            VARCHAR(255),
    created_at       TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_auth_provider_identity UNIQUE (provider, provider_user_id),
    CONSTRAINT uq_auth_provider_per_user UNIQUE (user_id, provider)
);
```

- [ ] **Step 3: Añadir la configuración**

En `backend/src/config/env_config.js`, después de la línea `const port = ...`:

```js
const googleClientIds = (trim(env.GOOGLE_CLIENT_IDS) || '')
  .split(',')
  .map((id) => id.trim())
  .filter(Boolean);
```

y dentro de `config`, después del bloque `jwt`:

```js
  google: {
    clientIds: googleClientIds,
  },
```

En `backend/.env.example`, después de `JWT_SECRET = ...`:

```
# Client IDs de OAuth de Google (Web, Android, iOS) separados por comas
GOOGLE_CLIENT_IDS = web-id.apps.googleusercontent.com,android-id.apps.googleusercontent.com,ios-id.apps.googleusercontent.com
```

- [ ] **Step 4: Escribir el test que falla**

`backend/test/auth/google.verifier.test.js`:

```js
import { test, mock, beforeEach } from 'node:test';
import assert from 'node:assert/strict';

const src = (path) => new URL(`../../src/${path}`, import.meta.url).href;

let verifyImpl;
const verifyCalls = [];

mock.module('google-auth-library', {
  namedExports: {
    OAuth2Client: class {
      verifyIdToken(options) {
        verifyCalls.push(options);
        return verifyImpl(options);
      }
    },
  },
});

const { config } = await import(src('config/env_config.js'));
const { verifyGoogleIdToken } = await import(src('modules/auth/google.verifier.js'));

const ticket = (payload) => ({ getPayload: () => payload });

beforeEach(() => {
  verifyCalls.length = 0;
  config.google.clientIds = ['web-id', 'android-id'];
  verifyImpl = async () =>
    ticket({ sub: '123', email: 'Ana@Gmail.com', email_verified: true, name: 'Ana' });
});

test('devuelve el perfil con el email en minúsculas', async () => {
  const profile = await verifyGoogleIdToken('token');

  assert.deepEqual(profile, {
    sub: '123',
    email: 'ana@gmail.com',
    emailVerified: true,
    name: 'Ana',
  });
  assert.deepEqual(verifyCalls[0], { idToken: 'token', audience: ['web-id', 'android-id'] });
});

test('email_verified distinto de true cuenta como no verificado', async () => {
  verifyImpl = async () => ticket({ sub: '123', email: 'ana@gmail.com', email_verified: 'true' });

  const profile = await verifyGoogleIdToken('token');

  assert.equal(profile.emailVerified, false);
  assert.equal(profile.name, null);
});

test('token rechazado por Google: 401 INVALID_GOOGLE_TOKEN', async () => {
  verifyImpl = async () => {
    throw new Error('Token used too late');
  };

  await assert.rejects(verifyGoogleIdToken('token'), {
    status: 401,
    code: 'INVALID_GOOGLE_TOKEN',
  });
});

test('payload sin sub o sin email: 401 INVALID_GOOGLE_TOKEN', async () => {
  verifyImpl = async () => ticket({ sub: '123' });

  await assert.rejects(verifyGoogleIdToken('token'), {
    status: 401,
    code: 'INVALID_GOOGLE_TOKEN',
  });
});

test('sin client IDs configurados: 500 AUTH_CONFIG_ERROR', async () => {
  config.google.clientIds = [];

  await assert.rejects(verifyGoogleIdToken('token'), {
    status: 500,
    code: 'AUTH_CONFIG_ERROR',
  });
  assert.equal(verifyCalls.length, 0);
});
```

- [ ] **Step 5: Correr el test y ver que falla**

Run: `cd backend && npm test`
Expected: FAIL — `Cannot find module ... google.verifier.js`.

- [ ] **Step 6: Implementar el verificador**

`backend/src/modules/auth/google.verifier.js`:

```js
import { OAuth2Client } from 'google-auth-library';
import { config } from '../../config/env_config.js';
import { AppError } from '../../utils/AppError.js';

const client = new OAuth2Client();

const invalidToken = () =>
  new AppError('No se pudo verificar tu cuenta de Google.', 401, 'INVALID_GOOGLE_TOKEN');

// Comprueba firma, expiración y que el token se emitió para alguno de
// nuestros client IDs (Web, Android o iOS).
export const verifyGoogleIdToken = async (idToken) => {
  const audience = config.google.clientIds;

  if (audience.length === 0) {
    throw new AppError('Google client IDs are not configured', 500, 'AUTH_CONFIG_ERROR');
  }

  let payload;
  try {
    const ticket = await client.verifyIdToken({ idToken, audience });
    payload = ticket.getPayload();
  } catch {
    throw invalidToken();
  }

  if (!payload?.sub || !payload?.email) {
    throw invalidToken();
  }

  return {
    sub: payload.sub,
    email: payload.email.toLowerCase(),
    emailVerified: payload.email_verified === true,
    name: payload.name ?? null,
  };
};
```

- [ ] **Step 7: Correr el test y ver que pasa**

Run: `cd backend && npm test`
Expected: PASS — 5 tests.

- [ ] **Step 8: Commit**

```bash
git add backend/package.json backend/package-lock.json backend/.env.example backend/src/config/env_config.js backend/src/database/backups/update_14_10_2026_google_auth.sql backend/src/modules/auth/google.verifier.js backend/test/auth/google.verifier.test.js
git commit -m "feat(auth): migración user_auth_providers y verificador de idToken de Google"
```

---

### Task 2: `loginWithGoogle` y cambios en el login con email (backend)

**Files:**
- Modify: `backend/src/modules/auth/auth.repository.js` (archivo completo)
- Modify: `backend/src/modules/auth/auth.service.js` (archivo completo salvo `getAuthModuleStatus`)
- Test: `backend/test/auth/auth.service.test.js`

**Interfaces:**
- Consumes: `verifyGoogleIdToken` (Task 1).
- Produces (repositorio): `findUserByEmail(email)`, `findUserByProvider(provider, providerUserId)` → usuario `{ userId, name, email, passwordHash, goal, age, role, plan, createdAt, updatedAt } | null`; `findProviderLink(userId, provider)` → `{ providerUserId } | null`; `linkAuthProvider({ userId, provider, providerUserId, email }, client?)`; `createUser(data, client?)`; `createUserWithProvider({ name, email, roleId, planId, provider, providerUserId })`.
- Produces (servicio): `loginWithGoogle({ idToken }) → { token, user, needsProfileSetup }`; `loginUser({ email, password }) → { token, user, needsProfileSetup }`.

- [ ] **Step 1: Escribir los tests que fallan**

`backend/test/auth/auth.service.test.js`:

```js
import { test, mock, beforeEach } from 'node:test';
import assert from 'node:assert/strict';
import bcrypt from 'bcrypt';
import jwt from 'jsonwebtoken';

const src = (path) => new URL(`../../src/${path}`, import.meta.url).href;

const REPO_EXPORTS = [
  'createUser',
  'createUserWithProvider',
  'findProviderLink',
  'findUserByEmail',
  'findUserByProvider',
  'getAuthRepositoryStatus',
  'getDefaultRoleAndPlanIds',
  'linkAuthProvider',
];

const repo = {};
const events = [];
let googleProfile;

mock.module(src('modules/auth/auth.repository.js'), {
  namedExports: Object.fromEntries(
    REPO_EXPORTS.map((name) => [name, (...args) => repo[name](...args)])
  ),
});
mock.module(src('modules/fridge/fridge.service.js'), {
  namedExports: { createFridgeService: async () => {} },
});
mock.module(src('modules/events/events.service.js'), {
  namedExports: {
    logEventService: async (event) => {
      events.push(event);
    },
  },
});
mock.module(src('modules/auth/google.verifier.js'), {
  namedExports: { verifyGoogleIdToken: async () => googleProfile },
});

const { config } = await import(src('config/env_config.js'));
const { loginUser, loginWithGoogle } = await import(src('modules/auth/auth.service.js'));

const ana = {
  userId: 7,
  name: 'Ana',
  email: 'ana@gmail.com',
  passwordHash: 'hash',
  goal: null,
  age: 30,
  role: 'USER',
  plan: 'FREE',
};

const fail = (name) => async () => {
  throw new Error(`${name} no debería llamarse`);
};

beforeEach(() => {
  config.jwt.secret = 'test_secret';
  events.length = 0;
  googleProfile = { sub: 'sub-1', email: 'ana@gmail.com', emailVerified: true, name: 'Ana' };
  Object.assign(repo, {
    createUser: fail('createUser'),
    createUserWithProvider: fail('createUserWithProvider'),
    findProviderLink: async () => null,
    findUserByEmail: async () => null,
    findUserByProvider: async () => null,
    getAuthRepositoryStatus: async () => ({}),
    getDefaultRoleAndPlanIds: async () => ({ roleId: 2, planId: 1 }),
    linkAuthProvider: fail('linkAuthProvider'),
  });
});

const eventTypes = () => events.map((event) => event.eventType);

test('Google: usuario ya vinculado entra sin crear ni vincular nada', async () => {
  repo.findUserByProvider = async (provider, sub) => {
    assert.equal(provider, 'google');
    assert.equal(sub, 'sub-1');
    return ana;
  };

  const session = await loginWithGoogle({ idToken: 'tok' });

  assert.equal(jwt.verify(session.token, 'test_secret').userId, 7);
  assert.equal(session.user.passwordHash, undefined);
  assert.equal(session.user.email, 'ana@gmail.com');
  assert.equal(session.needsProfileSetup, false);
  assert.deepEqual(eventTypes(), ['LOGIN']);
  assert.equal(events[0].metadata.method, 'google');
});

test('Google: email ya registrado con contraseña se vincula', async () => {
  const links = [];
  repo.findUserByEmail = async () => ana;
  repo.linkAuthProvider = async (link) => {
    links.push(link);
  };

  const session = await loginWithGoogle({ idToken: 'tok' });

  assert.deepEqual(links, [
    { userId: 7, provider: 'google', providerUserId: 'sub-1', email: 'ana@gmail.com' },
  ]);
  assert.equal(session.user.userId, 7);
  assert.deepEqual(eventTypes(), ['ACCOUNT_LINKED', 'LOGIN']);
});

test('Google: email vinculado a otra cuenta de Google responde 409', async () => {
  repo.findUserByEmail = async () => ana;
  repo.findProviderLink = async () => ({ providerUserId: 'otro-sub' });

  await assert.rejects(loginWithGoogle({ idToken: 'tok' }), {
    status: 409,
    code: 'GOOGLE_ACCOUNT_CONFLICT',
  });
});

test('Google: usuario nuevo se crea sin contraseña y pide el setup', async () => {
  const created = [];
  let lookups = 0;
  repo.findUserByProvider = async () => {
    lookups += 1;
    return lookups === 1 ? null : { ...ana, userId: 9, passwordHash: null, age: null };
  };
  repo.createUserWithProvider = async (data) => {
    created.push(data);
    return { userId: 9 };
  };

  const session = await loginWithGoogle({ idToken: 'tok' });

  assert.deepEqual(created, [
    {
      name: 'Ana',
      email: 'ana@gmail.com',
      passwordHash: null,
      goal: null,
      roleId: 2,
      planId: 1,
      provider: 'google',
      providerUserId: 'sub-1',
    },
  ]);
  assert.equal(session.user.userId, 9);
  assert.equal(session.needsProfileSetup, true);
  assert.deepEqual(eventTypes(), ['REGISTER', 'LOGIN']);
  assert.equal(events[0].metadata.method, 'google');
});

test('Google: sin nombre usa la parte local del email', async () => {
  googleProfile = { ...googleProfile, name: '  ' };
  const created = [];
  let lookups = 0;
  repo.findUserByProvider = async () => (++lookups === 1 ? null : { ...ana, age: null });
  repo.createUserWithProvider = async (data) => {
    created.push(data);
    return { userId: 7 };
  };

  await loginWithGoogle({ idToken: 'tok' });

  assert.equal(created[0].name, 'ana');
});

test('Google: email no verificado responde 403', async () => {
  googleProfile = { ...googleProfile, emailVerified: false };

  await assert.rejects(loginWithGoogle({ idToken: 'tok' }), {
    status: 403,
    code: 'GOOGLE_EMAIL_NOT_VERIFIED',
  });
});

test('Google: si dos logins chocan con un UNIQUE, se reintenta la búsqueda', async () => {
  let lookups = 0;
  repo.findUserByProvider = async () => (++lookups === 1 ? null : ana);
  repo.createUserWithProvider = async () => {
    throw Object.assign(new Error('duplicate key'), { code: '23505' });
  };

  const session = await loginWithGoogle({ idToken: 'tok' });

  assert.equal(session.user.userId, 7);
  assert.equal(lookups, 2);
});

test('Email: cuenta sin contraseña responde 409 USE_GOOGLE_SIGN_IN', async () => {
  repo.findUserByEmail = async () => ({ ...ana, passwordHash: null });

  await assert.rejects(loginUser({ email: 'ana@gmail.com', password: 'loquesea' }), {
    status: 409,
    code: 'USE_GOOGLE_SIGN_IN',
  });
  assert.deepEqual(eventTypes(), ['LOGIN_FAILED']);
  assert.equal(events[0].metadata.reason, 'USE_GOOGLE_SIGN_IN');
});

test('Email: la respuesta incluye needsProfileSetup', async () => {
  const passwordHash = await bcrypt.hash('secreto123', 4);
  repo.findUserByEmail = async () => ({ ...ana, passwordHash, age: null });

  const session = await loginUser({ email: 'ana@gmail.com', password: 'secreto123' });

  assert.equal(session.needsProfileSetup, true);
  assert.equal(session.user.passwordHash, undefined);
});
```

- [ ] **Step 2: Correr los tests y ver que fallan**

Run: `cd backend && npm test`
Expected: FAIL — `loginWithGoogle` no existe (`SyntaxError: ... does not provide an export named 'loginWithGoogle'`).

- [ ] **Step 3: Reescribir el repositorio**

`backend/src/modules/auth/auth.repository.js` (archivo completo):

```js
import pool from '../../database/connection.js';

export const getAuthRepositoryStatus = async () => {
  return {
    layer: 'repository',
    status: 'ready',
  };
};

// Mismo formato de usuario para el login con email y con Google.
const userSelect = `
  SELECT
    u.user_id AS "userId",
    u.name,
    u.email,
    u.password AS "passwordHash",
    u.goal,
    u.age,
    r.name AS role,
    p.name AS plan,
    u.created_at AS "createdAt",
    u.updated_at AS "updatedAt"
  FROM users u
  INNER JOIN roles r ON r.role_id = u.role_id
  INNER JOIN plans p ON p.plan_id = u.plan_id
`;

export const findUserByEmail = async (email) => {
  const { rows } = await pool.query(
    `${userSelect} WHERE LOWER(u.email) = LOWER($1) LIMIT 1`,
    [email]
  );
  return rows[0] ?? null;
};

export const findUserByProvider = async (provider, providerUserId) => {
  const { rows } = await pool.query(
    `${userSelect}
     INNER JOIN user_auth_providers ap ON ap.user_id = u.user_id
     WHERE ap.provider = $1 AND ap.provider_user_id = $2
     LIMIT 1`,
    [provider, providerUserId]
  );
  return rows[0] ?? null;
};

export const findProviderLink = async (userId, provider) => {
  const { rows } = await pool.query(
    `SELECT provider_user_id AS "providerUserId"
     FROM user_auth_providers
     WHERE user_id = $1 AND provider = $2
     LIMIT 1`,
    [userId, provider]
  );
  return rows[0] ?? null;
};

export const linkAuthProvider = async (
  { userId, provider, providerUserId, email },
  client = pool
) => {
  await client.query(
    `INSERT INTO user_auth_providers (user_id, provider, provider_user_id, email)
     VALUES ($1, $2, $3, $4)`,
    [userId, provider, providerUserId, email]
  );
};

export const getDefaultRoleAndPlanIds = async () => {
  const query = `
    SELECT
      (SELECT role_id FROM roles WHERE name = 'USER' LIMIT 1) AS "roleId",
      (SELECT plan_id FROM plans WHERE name = 'FREE' LIMIT 1) AS "planId"
  `;

  const { rows } = await pool.query(query);
  return rows[0] ?? null;
};

export const createUser = async (
  { name, email, passwordHash, goal, roleId, planId },
  client = pool
) => {
  const query = `
    INSERT INTO users (name, email, password, goal, role_id, plan_id)
    VALUES ($1, $2, $3, $4, $5, $6)
    RETURNING
      user_id AS "userId",
      name,
      email,
      goal,
      role_id AS "roleId",
      plan_id AS "planId",
      created_at AS "createdAt",
      updated_at AS "updatedAt"
  `;

  const values = [name, email, passwordHash, goal, roleId, planId];
  const { rows } = await client.query(query, values);

  return rows[0];
};

// El usuario y su cuenta externa se crean juntos: un usuario de Google sin
// la fila del proveedor no podría volver a entrar.
export const createUserWithProvider = async ({ provider, providerUserId, ...userData }) => {
  const client = await pool.connect();

  try {
    await client.query('BEGIN');
    const user = await createUser(userData, client);
    await linkAuthProvider(
      { userId: user.userId, provider, providerUserId, email: userData.email },
      client
    );
    await client.query('COMMIT');
    return user;
  } catch (error) {
    await client.query('ROLLBACK');
    throw error;
  } finally {
    client.release();
  }
};
```

- [ ] **Step 4: Reescribir el servicio**

`backend/src/modules/auth/auth.service.js`. Mantener `getAuthModuleStatus` tal cual; reemplazar los imports, las constantes, `loginUser` y `registerUser`, y añadir lo nuevo:

```js
import bcrypt from 'bcrypt';
import jwt from 'jsonwebtoken';
import { config } from '../../config/env_config.js';
import { AppError } from '../../utils/AppError.js';
import {
  createUser,
  createUserWithProvider,
  findProviderLink,
  findUserByEmail,
  findUserByProvider,
  getAuthRepositoryStatus,
  getDefaultRoleAndPlanIds,
  linkAuthProvider,
} from './auth.repository.js';
import { verifyGoogleIdToken } from './google.verifier.js';
import { createFridgeService } from '../fridge/fridge.service.js';
import { logEventService } from '../events/events.service.js';

const JWT_EXPIRES_IN = '1h';
const SALT_ROUNDS = 10;
const GOOGLE = 'google';
const UNIQUE_VIOLATION = '23505';

// getAuthModuleStatus queda igual.

const issueToken = (user) => {
  if (!config.jwt.secret) {
    throw new AppError('JWT secret is not configured', 500, 'AUTH_CONFIG_ERROR');
  }

  const tokenPayload = {
    userId: user.userId,
    email: user.email,
    role: user.role,
    plan: user.plan,
    name: user.name,
    goal: user.goal,
  };

  return jwt.sign(tokenPayload, config.jwt.secret, { expiresIn: JWT_EXPIRES_IN });
};

// Respuesta común de los logins. Sin edad, el usuario no terminó el setup
// del perfil y la app lo manda ahí en vez de al Dashboard.
const buildSession = (user) => {
  const { passwordHash, ...safeUser } = user;

  return {
    token: issueToken(user),
    user: safeUser,
    needsProfileSetup: user.age == null,
  };
};

// Crea el usuario con el rol y plan por defecto y su nevera. Con `provider`,
// el usuario y su cuenta externa se crean en la misma transacción.
const createUserWithDefaults = async ({
  name,
  email,
  passwordHash = null,
  goal = null,
  provider = null,
}) => {
  const defaults = await getDefaultRoleAndPlanIds();

  if (!defaults?.roleId || !defaults?.planId) {
    throw new AppError('Default role or plan is not configured', 500, 'AUTH_DEFAULTS_NOT_FOUND');
  }

  const userData = {
    name,
    email,
    passwordHash,
    goal,
    roleId: Number(defaults.roleId),
    planId: Number(defaults.planId),
  };

  const newUser = provider
    ? await createUserWithProvider({ ...userData, ...provider })
    : await createUser(userData);

  await createFridgeService(newUser.userId);

  return newUser;
};

export const loginUser = async ({ email, password }) => {
  try {
    const user = await findUserByEmail(email);

    if (!user) {
      await logEventService({
        eventType: 'LOGIN_FAILED',
        category: 'AUTH',
        userId: null,
        metadata: { email, reason: 'USER_NOT_FOUND' },
      });
      throw new AppError('Cuenta no existe', 404, 'USER_NOT_FOUND');
    }

    if (!user.passwordHash) {
      await logEventService({
        eventType: 'LOGIN_FAILED',
        category: 'AUTH',
        userId: user.userId,
        metadata: { email, reason: 'USE_GOOGLE_SIGN_IN' },
      });
      throw new AppError(
        'Esta cuenta usa Google. Toca «Continuar con Google».',
        409,
        'USE_GOOGLE_SIGN_IN'
      );
    }

    const isPasswordValid = await bcrypt.compare(password, user.passwordHash);

    if (!isPasswordValid) {
      await logEventService({
        eventType: 'LOGIN_FAILED',
        category: 'AUTH',
        userId: user.userId,
        metadata: { email, reason: 'INVALID_PASSWORD' },
      });
      throw new AppError('Contraseña incorrecta', 401, 'INVALID_PASSWORD');
    }

    const session = buildSession(user);

    await logEventService({
      eventType: 'LOGIN',
      category: 'AUTH',
      userId: user.userId,
      metadata: { email: user.email, role: user.role },
    });

    return session;
  } catch (error) {
    if (error instanceof AppError) {
      throw error;
    }

    throw new AppError(error.message, 500, 'AUTH_SERVICE_ERROR');
  }
};

export const registerUser = async ({ name, email, password, goal }) => {
  try {
    const existingUser = await findUserByEmail(email);

    if (existingUser) {
      throw new AppError('Email is already registered', 409, 'EMAIL_ALREADY_EXISTS');
    }

    const passwordHash = await bcrypt.hash(password, SALT_ROUNDS);
    const newUser = await createUserWithDefaults({ name, email, passwordHash, goal });

    await logEventService({
      eventType: 'REGISTER',
      category: 'AUTH',
      userId: newUser.userId,
      metadata: { email, name },
    });

    return {
      ...newUser,
      role: 'USER',
      plan: 'FREE',
    };
  } catch (error) {
    if (error instanceof AppError) {
      throw error;
    }

    throw new AppError(error.message, 500, 'AUTH_SERVICE_ERROR');
  }
};

// Busca al usuario de Google por su `sub`; si no existe, lo vincula a la
// cuenta con el mismo email o crea una nueva.
const resolveGoogleUser = async ({ sub, email, name }) => {
  const linkedUser = await findUserByProvider(GOOGLE, sub);
  if (linkedUser) {
    return linkedUser;
  }

  const existingUser = await findUserByEmail(email);
  if (existingUser) {
    // Otra cuenta de Google con el mismo email (p. ej. borrada y recreada):
    // no se sobrescribe el vínculo.
    if (await findProviderLink(existingUser.userId, GOOGLE)) {
      throw new AppError(
        'Este correo ya está vinculado a otra cuenta de Google.',
        409,
        'GOOGLE_ACCOUNT_CONFLICT'
      );
    }

    await linkAuthProvider({ userId: existingUser.userId, provider: GOOGLE, providerUserId: sub, email });
    await logEventService({
      eventType: 'ACCOUNT_LINKED',
      category: 'AUTH',
      userId: existingUser.userId,
      metadata: { provider: GOOGLE },
    });
    return existingUser;
  }

  const displayName = name?.trim() || email.split('@')[0];
  const newUser = await createUserWithDefaults({
    name: displayName,
    email,
    provider: { provider: GOOGLE, providerUserId: sub },
  });

  await logEventService({
    eventType: 'REGISTER',
    category: 'AUTH',
    userId: newUser.userId,
    metadata: { email, name: displayName, method: GOOGLE },
  });

  // Se relee para tener rol, plan y edad con el mismo formato que el login.
  return findUserByProvider(GOOGLE, sub);
};

export const loginWithGoogle = async ({ idToken }) => {
  try {
    const profile = await verifyGoogleIdToken(idToken);

    if (!profile.emailVerified) {
      throw new AppError('Tu correo de Google no está verificado.', 403, 'GOOGLE_EMAIL_NOT_VERIFIED');
    }

    let user;
    try {
      user = await resolveGoogleUser(profile);
    } catch (error) {
      // Dos primeros logins a la vez: el segundo choca con un UNIQUE y, al
      // repetir la búsqueda, encuentra lo que creó el primero.
      if (error?.code !== UNIQUE_VIOLATION) {
        throw error;
      }
      user = await resolveGoogleUser(profile);
    }

    const session = buildSession(user);

    await logEventService({
      eventType: 'LOGIN',
      category: 'AUTH',
      userId: user.userId,
      metadata: { email: user.email, role: user.role, method: GOOGLE },
    });

    return session;
  } catch (error) {
    if (error instanceof AppError) {
      throw error;
    }

    throw new AppError(error.message, 500, 'AUTH_SERVICE_ERROR');
  }
};
```

- [ ] **Step 5: Correr los tests y ver que pasan**

Run: `cd backend && npm test`
Expected: PASS — 14 tests (5 del verificador + 9 del servicio).

- [ ] **Step 6: Commit**

```bash
git add backend/src/modules/auth/auth.repository.js backend/src/modules/auth/auth.service.js backend/test/auth/auth.service.test.js
git commit -m "feat(auth): loginWithGoogle con vinculación por email y needsProfileSetup"
```

---

### Task 3: Endpoint `POST /api/v1/auth/google` (backend)

**Files:**
- Modify: `backend/src/modules/auth/auth.validation.js`
- Modify: `backend/src/modules/auth/auth.controller.js`
- Modify: `backend/src/modules/auth/auth.routes.js`
- Modify: `backend/src/modules/auth/auth.swagger.yaml`
- Test: `backend/test/auth/auth.validation.test.js`

**Interfaces:**
- Consumes: `loginWithGoogle` (Task 2), `strictAuthRateLimit` (`src/middleware/rateLimit.middleware.js`).
- Produces: `POST /api/v1/auth/google` con body `{ idToken }` → `{ success, message, data: { token, user, needsProfileSetup } }`.

- [ ] **Step 1: Escribir el test que falla**

`backend/test/auth/auth.validation.test.js`:

```js
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { validateGoogleLoginRequest } from '../../src/modules/auth/auth.validation.js';

const run = (body) => {
  const req = { body };
  let nextArg = 'not-called';
  validateGoogleLoginRequest(req, {}, (arg) => {
    nextArg = arg;
  });
  return { req, nextArg };
};

test('idToken válido pasa como req.googleLoginData', () => {
  const { req, nextArg } = run({ idToken: '  abc  ' });

  assert.equal(nextArg, undefined);
  assert.deepEqual(req.googleLoginData, { idToken: 'abc' });
});

for (const body of [{}, { idToken: '' }, { idToken: '   ' }, { idToken: 42 }, undefined]) {
  test(`body inválido ${JSON.stringify(body)} responde 400`, () => {
    const { nextArg } = run(body);

    assert.equal(nextArg.status, 400);
    assert.equal(nextArg.code, 'VALIDATION_ERROR');
    assert.equal(nextArg.details[0].field, 'idToken');
  });
}
```

- [ ] **Step 2: Correr el test y ver que falla**

Run: `cd backend && npm test`
Expected: FAIL — `does not provide an export named 'validateGoogleLoginRequest'`.

- [ ] **Step 3: Implementar la validación**

Al final de `backend/src/modules/auth/auth.validation.js`:

```js
export const validateGoogleLoginRequest = (req, res, next) => {
  const { idToken } = req.body ?? {};

  if (typeof idToken !== 'string' || !idToken.trim()) {
    return next(
      new AppError('Validation error', 400, 'VALIDATION_ERROR', [
        { field: 'idToken', message: 'Google idToken is required' },
      ])
    );
  }

  req.googleLoginData = { idToken: idToken.trim() };
  next();
};
```

- [ ] **Step 4: Controlador y ruta**

En `backend/src/modules/auth/auth.controller.js`, cambiar el import y añadir el controlador:

```js
import { getAuthModuleStatus, loginUser, loginWithGoogle, registerUser } from './auth.service.js';
```

```js
export const googleLogin = async (req, res, next) => {
  try {
    const authData = await loginWithGoogle(req.googleLoginData);
    return successResponse(res, authData, 'Login successful', 200);
  } catch (error) {
    next(error);
  }
};
```

En `backend/src/modules/auth/auth.routes.js`, cambiar los imports:

```js
import { Router } from 'express';
import { getAuthHealth, googleLogin, login, register } from './auth.controller.js';
import {
  validateAuthHealthRequest,
  validateGoogleLoginRequest,
  validateLoginRequest,
  validateRegisterRequest,
} from './auth.validation.js';
import { strictAuthRateLimit } from '../../middleware/rateLimit.middleware.js';
```

y antes de `export default router;`:

```js
/**
 * @openapi
 * /api/v1/auth/google:
 *   post:
 *     tags: [Auth]
 *     summary: Iniciar sesión o registrarse con Google
 *     description: Verifica el idToken de Google. Si el sub ya está vinculado, inicia sesión; si existe una cuenta con el mismo email verificado, la vincula; si no, crea una cuenta sin contraseña.
 *     security: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [idToken]
 *             properties:
 *               idToken:
 *                 type: string
 *     responses:
 *       200:
 *         description: Login exitoso. needsProfileSetup es true si el usuario no ha completado su perfil (edad).
 *         content:
 *           application/json:
 *             schema:
 *               allOf:
 *                 - $ref: '#/components/schemas/ApiResponse'
 *                 - type: object
 *                   properties:
 *                     data:
 *                       type: object
 *                       properties:
 *                         token:
 *                           type: string
 *                         user:
 *                           $ref: '#/components/schemas/User'
 *                         needsProfileSetup:
 *                           type: boolean
 *       400:
 *         $ref: '#/components/responses/BadRequestError'
 *       401:
 *         description: idToken inválido (code INVALID_GOOGLE_TOKEN)
 *       403:
 *         description: Email de Google no verificado (code GOOGLE_EMAIL_NOT_VERIFIED)
 *       409:
 *         description: El email ya está vinculado a otra cuenta de Google (code GOOGLE_ACCOUNT_CONFLICT)
 *       429:
 *         description: Demasiados intentos
 */
router.post('/google', strictAuthRateLimit, validateGoogleLoginRequest, googleLogin);
```

En `backend/src/modules/auth/auth.swagger.yaml`, al final del archivo:

```yaml

/api/v1/auth/google:
  post:
    summary: Login or register with Google
    tags: [Auth]
    requestBody:
      required: true
      content:
        application/json:
          schema:
            type: object
            required: [idToken]
            properties:
              idToken:
                type: string
    responses:
      200:
        description: Successful login (includes needsProfileSetup)
      401:
        description: Invalid Google idToken
      403:
        description: Google email not verified
      409:
        description: Email linked to another Google account
```

- [ ] **Step 5: Correr los tests y comprobar que el servidor arranca**

Run: `cd backend && npm test`
Expected: PASS — 20 tests.

Run: `cd backend && node -e "import('./src/app.js').then(() => { console.log('app ok'); process.exit(0); })"`
Expected: imprime `app ok` (los imports y la ruta cargan sin errores).

- [ ] **Step 6: Commit**

```bash
git add backend/src/modules/auth backend/test/auth/auth.validation.test.js
git commit -m "feat(auth): endpoint POST /auth/google con rate limit estricto"
```

---

### Task 4: `hasPassword` en el perfil y borrado de cuenta con Google (backend)

**Files:**
- Modify: `backend/src/modules/user/user.repository.js` (`profileSelectQuery` y `findUserPasswordHashById`)
- Modify: `backend/src/modules/user/user.service.js` (imports y `deleteUserAccount`)
- Modify: `backend/src/modules/user/user.validation.js` (`validateDeleteAccountRequest`)
- Modify: `backend/src/modules/user/user.controller.js` (`deleteAccount`)
- Modify: `backend/src/modules/user/user.routes.js` (doc de `DELETE /account`)
- Test: `backend/test/user/user.service.test.js`, `backend/test/user/user.validation.test.js`

**Interfaces:**
- Consumes: `verifyGoogleIdToken` (Task 1).
- Produces: `GET /user/profile` incluye `hasPassword: boolean`; `DELETE /user/account` acepta `{ password }` o `{ googleIdToken }`.
- Produces: `findUserCredentialsById(userId) → { passwordHash: string|null, googleSub: string|null } | null`; `deleteUserAccount(userId, { password?, googleIdToken? })`.

- [ ] **Step 1: Escribir los tests que fallan**

`backend/test/user/user.service.test.js`:

```js
import { test, mock, beforeEach } from 'node:test';
import assert from 'node:assert/strict';
import bcrypt from 'bcrypt';

const src = (path) => new URL(`../../src/${path}`, import.meta.url).href;

const { AppError } = await import(src('utils/AppError.js'));

const REPO_EXPORTS = [
  'createPhysicalRecord',
  'deleteUserAccountData',
  'findPhysicalHistoryByUserId',
  'findUserCredentialsById',
  'findUserProfileById',
  'updateUserProfileData',
];

const repo = {};
let verifyImpl;

mock.module(src('modules/user/user.repository.js'), {
  namedExports: Object.fromEntries(
    REPO_EXPORTS.map((name) => [name, (...args) => repo[name](...args)])
  ),
});
mock.module(src('modules/events/events.service.js'), {
  namedExports: { logEventService: async () => {} },
});
mock.module(src('modules/auth/google.verifier.js'), {
  namedExports: { verifyGoogleIdToken: (...args) => verifyImpl(...args) },
});

const { deleteUserAccount } = await import(src('modules/user/user.service.js'));

const passwordHash = await bcrypt.hash('secreto123', 4);
let deletedIds;

beforeEach(() => {
  deletedIds = [];
  repo.deleteUserAccountData = async (userId) => {
    deletedIds.push(userId);
    return true;
  };
  verifyImpl = async () => ({ sub: 'sub-1', email: 'ana@gmail.com', emailVerified: true, name: 'Ana' });
});

test('cuenta con contraseña: borra con la contraseña correcta', async () => {
  repo.findUserCredentialsById = async () => ({ passwordHash, googleSub: null });

  await deleteUserAccount(7, { password: 'secreto123' });

  assert.deepEqual(deletedIds, [7]);
});

test('cuenta con contraseña: contraseña incorrecta responde 403', async () => {
  repo.findUserCredentialsById = async () => ({ passwordHash, googleSub: 'sub-1' });

  await assert.rejects(deleteUserAccount(7, { password: 'otra' }), {
    status: 403,
    code: 'INVALID_PASSWORD',
  });
  assert.deepEqual(deletedIds, []);
});

test('cuenta con contraseña: con googleIdToken en vez de contraseña responde 400', async () => {
  repo.findUserCredentialsById = async () => ({ passwordHash, googleSub: 'sub-1' });

  await assert.rejects(deleteUserAccount(7, { googleIdToken: 'tok' }), {
    status: 400,
    code: 'VALIDATION_ERROR',
  });
  assert.deepEqual(deletedIds, []);
});

test('cuenta solo de Google: borra si el sub coincide', async () => {
  repo.findUserCredentialsById = async () => ({ passwordHash: null, googleSub: 'sub-1' });

  await deleteUserAccount(7, { googleIdToken: 'tok' });

  assert.deepEqual(deletedIds, [7]);
});

test('cuenta solo de Google: otro sub responde 403 GOOGLE_ACCOUNT_MISMATCH', async () => {
  repo.findUserCredentialsById = async () => ({ passwordHash: null, googleSub: 'sub-1' });
  verifyImpl = async () => ({ sub: 'sub-2', email: 'otro@gmail.com', emailVerified: true, name: null });

  await assert.rejects(deleteUserAccount(7, { googleIdToken: 'tok' }), {
    status: 403,
    code: 'GOOGLE_ACCOUNT_MISMATCH',
  });
  assert.deepEqual(deletedIds, []);
});

test('cuenta solo de Google: token inválido responde 403, no 401', async () => {
  repo.findUserCredentialsById = async () => ({ passwordHash: null, googleSub: 'sub-1' });
  verifyImpl = async () => {
    throw new AppError('No se pudo verificar tu cuenta de Google.', 401, 'INVALID_GOOGLE_TOKEN');
  };

  await assert.rejects(deleteUserAccount(7, { googleIdToken: 'tok' }), {
    status: 403,
    code: 'INVALID_GOOGLE_TOKEN',
  });
});

test('cuenta solo de Google: sin googleIdToken responde 400', async () => {
  repo.findUserCredentialsById = async () => ({ passwordHash: null, googleSub: 'sub-1' });

  await assert.rejects(deleteUserAccount(7, { password: 'secreto123' }), {
    status: 400,
    code: 'VALIDATION_ERROR',
  });
});

test('usuario inexistente responde 404', async () => {
  repo.findUserCredentialsById = async () => null;

  await assert.rejects(deleteUserAccount(7, { password: 'secreto123' }), {
    status: 404,
    code: 'USER_NOT_FOUND',
  });
});
```

`backend/test/user/user.validation.test.js`:

```js
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { validateDeleteAccountRequest } from '../../src/modules/user/user.validation.js';

const run = (body) => {
  const req = { body };
  let nextArg = 'not-called';
  validateDeleteAccountRequest(req, {}, (arg) => {
    nextArg = arg;
  });
  return { req, nextArg };
};

test('acepta solo contraseña', () => {
  const { req, nextArg } = run({ password: 'secreto123' });

  assert.equal(nextArg, undefined);
  assert.deepEqual(req.accountDeletionData, { password: 'secreto123' });
});

test('acepta solo googleIdToken', () => {
  const { req, nextArg } = run({ googleIdToken: 'tok' });

  assert.equal(nextArg, undefined);
  assert.deepEqual(req.accountDeletionData, { googleIdToken: 'tok' });
});

for (const body of [{}, { password: '' }, { password: 'a', googleIdToken: 'b' }, undefined]) {
  test(`rechaza ${JSON.stringify(body)} con 400`, () => {
    const { nextArg } = run(body);

    assert.equal(nextArg.status, 400);
    assert.equal(nextArg.code, 'VALIDATION_ERROR');
  });
}
```

- [ ] **Step 2: Correr los tests y ver que fallan**

Run: `cd backend && npm test`
Expected: FAIL — `user.repository.js` no exporta `findUserCredentialsById` / la validación rechaza `googleIdToken`.

- [ ] **Step 3: Repositorio**

En `backend/src/modules/user/user.repository.js`, dentro de `profileSelectQuery`, después de `u.goal,`:

```sql
    (u.password IS NOT NULL) AS "hasPassword",
```

Reemplazar `findUserPasswordHashById` por:

```js
// Lo necesario para confirmar el borrado: la contraseña, o la cuenta de
// Google vinculada si el usuario no tiene contraseña.
export const findUserCredentialsById = async (userId) => {
  const { rows } = await pool.query(
    `SELECT
       u.password AS "passwordHash",
       ap.provider_user_id AS "googleSub"
     FROM users u
     LEFT JOIN user_auth_providers ap
       ON ap.user_id = u.user_id AND ap.provider = 'google'
     WHERE u.user_id = $1
     LIMIT 1`,
    [userId]
  );
  return rows[0] ?? null;
};
```

Comprobar que no queda ningún uso de `findUserPasswordHashById`:

Run: `cd backend && grep -rn "findUserPasswordHashById" src`
Expected: solo el import de `user.service.js`, que se cambia en el paso siguiente.

- [ ] **Step 4: Servicio**

En `backend/src/modules/user/user.service.js`, en el import del repositorio cambiar `findUserPasswordHashById` por `findUserCredentialsById`, y añadir:

```js
import { verifyGoogleIdToken } from '../auth/google.verifier.js';
```

Reemplazar `deleteUserAccount` por:

```js
const missingField = (field, message) =>
  new AppError('Validation error', 400, 'VALIDATION_ERROR', [{ field, message }]);

// Se pide la contraseña aunque el token sea válido: un teléfono desbloqueado
// en manos de otro no debería bastar para borrar la cuenta. Quien no tiene
// contraseña confirma volviendo a autenticarse con Google.
// Los rechazos son 403 y no 401: el token es válido, y la app cierra sesión ante un 401.
const confirmAccountOwnership = async (credentials, { password, googleIdToken }) => {
  if (credentials.passwordHash) {
    if (!password) {
      throw missingField('password', 'Password is required');
    }

    const isPasswordValid = await bcrypt.compare(password, credentials.passwordHash);
    if (!isPasswordValid) {
      throw new AppError('Contraseña incorrecta', 403, 'INVALID_PASSWORD');
    }
    return;
  }

  if (!googleIdToken) {
    throw missingField('googleIdToken', 'Google idToken is required');
  }

  let profile;
  try {
    profile = await verifyGoogleIdToken(googleIdToken);
  } catch (error) {
    if (error?.code === 'INVALID_GOOGLE_TOKEN') {
      throw new AppError(error.message, 403, 'INVALID_GOOGLE_TOKEN');
    }
    throw error;
  }

  if (profile.sub !== credentials.googleSub) {
    throw new AppError(
      'Esa cuenta de Google no corresponde a este perfil.',
      403,
      'GOOGLE_ACCOUNT_MISMATCH'
    );
  }
};

export const deleteUserAccount = async (userId, confirmation) => {
  try {
    const credentials = await findUserCredentialsById(userId);

    if (!credentials) {
      throw new AppError('User not found', 404, 'USER_NOT_FOUND');
    }

    await confirmAccountOwnership(credentials, confirmation);

    const deleted = await deleteUserAccountData(userId);

    if (!deleted) {
      throw new AppError('User not found', 404, 'USER_NOT_FOUND');
    }

    // Sin userId ni correo: el evento solo cuenta que hubo un borrado.
    await logEventService({
      eventType: 'ACCOUNT_DELETED',
      category: 'AUTH',
      userId: null,
      metadata: {},
    });
  } catch (error) {
    if (error instanceof AppError) {
      throw error;
    }

    throw new AppError(error.message, 500, 'USER_SERVICE_ERROR');
  }
};
```

- [ ] **Step 5: Validación, controlador y doc**

En `backend/src/modules/user/user.validation.js`, reemplazar `validateDeleteAccountRequest`:

```js
// Exactamente una forma de confirmar: contraseña, o idToken de Google para
// las cuentas sin contraseña. El servicio decide cuál corresponde.
export const validateDeleteAccountRequest = (req, res, next) => {
  const { password, googleIdToken } = req.body ?? {};
  const hasPassword = typeof password === 'string' && password.length > 0;
  const hasGoogleToken = typeof googleIdToken === 'string' && googleIdToken.trim().length > 0;

  if (hasPassword === hasGoogleToken) {
    return next(
      new AppError('Validation error', 400, 'VALIDATION_ERROR', [
        { field: 'password', message: 'Send either password or googleIdToken' },
      ])
    );
  }

  req.accountDeletionData = hasPassword ? { password } : { googleIdToken: googleIdToken.trim() };
  next();
};
```

En `backend/src/modules/user/user.controller.js`, dentro de `deleteAccount`:

```js
    await deleteUserAccount(req.user.userId, req.accountDeletionData);
```

En `backend/src/modules/user/user.routes.js`, en la doc de `DELETE /api/v1/user/account`, reemplazar el `description`, el `schema` y el `403`:

```js
 *     description: Borra de forma permanente el usuario, sus comidas, nevera, registros físicos, chats, recetas y alimentos personalizados. Exige la contraseña actual, o un idToken de Google si la cuenta no tiene contraseña.
```

```js
 *           schema:
 *             type: object
 *             properties:
 *               password:
 *                 type: string
 *                 example: MiContraseña123
 *               googleIdToken:
 *                 type: string
 *                 description: Solo para cuentas sin contraseña
```

```js
 *       403:
 *         description: Confirmación incorrecta (code INVALID_PASSWORD, INVALID_GOOGLE_TOKEN o GOOGLE_ACCOUNT_MISMATCH)
```

- [ ] **Step 6: Correr los tests y ver que pasan**

Run: `cd backend && npm test`
Expected: PASS — 34 tests.

- [ ] **Step 7: Commit**

```bash
git add backend/src/modules/user backend/test/user
git commit -m "feat(user): hasPassword en el perfil y borrado de cuenta confirmado con Google"
```

---

### Task 5: Método de acceso en el admin-panel

**Files:**
- Modify: `backend/src/modules/admin/admin.repository.js` (`findUsers`, `findUserDetail`)
- Modify: `admin-panel/src/types/admin.ts`
- Modify: `admin-panel/src/components/CategoryBadge.tsx`
- Modify: `admin-panel/src/pages/Users.tsx`
- Modify: `admin-panel/src/pages/UserDetail.tsx`

**Interfaces:**
- Produces: `authMethod: 'EMAIL' | 'GOOGLE' | 'BOTH'` en cada usuario de `GET /admin/users` y en `profile` de `GET /admin/users/:id`.
- Produces: `AuthMethodBadge({ method })` y `authMethodLabel(method)` en `CategoryBadge.tsx`.

Los eventos `ACCOUNT_LINKED` no necesitan cambios en el panel: `moduleSql` ya clasifica los eventos `AUTH` sin ruta como módulo `auth`, y la página Events los lista igual que `LOGIN` o `REGISTER`.

- [ ] **Step 1: SQL en el backend**

En `backend/src/modules/admin/admin.repository.js`, antes de `findUsers`:

```js
// Cómo entra el usuario: solo contraseña, solo Google, o ambos.
const authMethodSql = (alias) => `
  CASE
    WHEN ${alias}.password IS NULL THEN 'GOOGLE'
    WHEN EXISTS (
      SELECT 1 FROM user_auth_providers ap WHERE ap.user_id = ${alias}.user_id
    ) THEN 'BOTH'
    ELSE 'EMAIL'
  END`;
```

En el `SELECT` de `findUsers` y en `profileQuery` de `findUserDetail`, después de `p.name AS plan,`:

```js
      ${authMethodSql('u')} AS "authMethod",
```

- [ ] **Step 2: Tipos del panel**

En `admin-panel/src/types/admin.ts`, después de `export type Plan = ...`:

```ts
export type AuthMethod = 'EMAIL' | 'GOOGLE' | 'BOTH';
```

En `AdminUser` y en `UserDetail['profile']`, después de `plan: Plan;`:

```ts
  authMethod: AuthMethod;
```

- [ ] **Step 3: Etiqueta**

Al final de `admin-panel/src/components/CategoryBadge.tsx`:

```tsx
const AUTH_METHOD_LABEL: Record<string, string> = {
  EMAIL: 'Email',
  GOOGLE: 'Google',
  BOTH: 'Ambos',
};

/** Cómo inicia sesión el usuario: Email, Google o Ambos. */
export function authMethodLabel(method: string) {
  return AUTH_METHOD_LABEL[method] ?? method;
}

export function AuthMethodBadge({ method }: { method: string }) {
  return (
    <Badge variant={method === 'EMAIL' ? 'outline' : 'info'}>{authMethodLabel(method)}</Badge>
  );
}
```

- [ ] **Step 4: Lista de usuarios**

En `admin-panel/src/pages/Users.tsx`, cambiar el import:

```tsx
import { AuthMethodBadge, PlanBadge } from '../components/CategoryBadge';
```

Después de `<TableHead>Plan</TableHead>`:

```tsx
                  <TableHead className="hidden md:table-cell">Acceso</TableHead>
```

Después de la celda que contiene `<PlanBadge plan={u.plan} />`:

```tsx
                    <TableCell className="hidden md:table-cell">
                      <AuthMethodBadge method={u.authMethod} />
                    </TableCell>
```

- [ ] **Step 5: Detalle de usuario**

En `admin-panel/src/pages/UserDetail.tsx`, cambiar el import:

```tsx
import { ModuleBadge, PlanBadge, StatusBadge, authMethodLabel } from '../components/CategoryBadge';
```

En la cabecera, después de `<PlanBadge plan={profile.plan} />`:

```tsx
                <span className="rounded-full bg-white/20 px-2 py-0.5 text-xs font-bold">
                  {authMethodLabel(profile.authMethod)}
                </span>
```

- [ ] **Step 6: Verificar compilación y lint**

Run: `cd admin-panel && npm run build && npm run lint`
Expected: build sin errores de TypeScript; lint sin errores nuevos.

Run: `cd backend && npm test`
Expected: PASS — 34 tests (no se rompió nada).

- [ ] **Step 7: Commit**

```bash
git add backend/src/modules/admin/admin.repository.js admin-panel/src
git commit -m "feat(admin): mostrar el método de acceso de cada usuario"
```

---

### Task 6: Servicio de Google y `loginWithGoogle` en la app

**Files:**
- Modify: `nutrilife/pubspec.yaml`, `nutrilife/pubspec.lock`
- Create: `nutrilife/lib/core/constants/google_auth_config.dart`
- Create: `nutrilife/lib/core/services/google_auth_service.dart`
- Modify: `nutrilife/lib/core/services/session_service.dart`
- Modify: `nutrilife/lib/core/network/api_routes.dart`
- Modify: `nutrilife/lib/core/services/auth_service.dart`
- Modify: `nutrilife/lib/features/auth/data/auth_repository.dart`
- Test: `nutrilife/test/features/auth/auth_repository_google_test.dart`

**Interfaces:**
- Produces: `GoogleAuthService.getIdToken() → Future<String?>` (null si el usuario cancela; lanza `GoogleAuthException`), `GoogleAuthService.signOut() → Future<void>`.
- Produces: `AuthRepository.loginWithGoogle(String idToken) → Future<GoogleLoginResult>` con `token`, `user`, `needsProfileSetup`; lanza `AuthException`.
- Produces: `AuthService.login(...)` añade la clave `'needsProfileSetup'` (bool) al mapa de éxito.
- Produces: `ApiRoutes.authGoogle = '/auth/google'`.

- [ ] **Step 1: Dependencia**

```bash
cd nutrilife
flutter pub add google_sign_in:^7.0.0
```

Expected: `pubspec.yaml` contiene `google_sign_in: ^7.x.x`.

- [ ] **Step 2: Escribir el test que falla**

`nutrilife/test/features/auth/auth_repository_google_test.dart`:

```dart
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutrilife/core/network/api_routes.dart';
import 'package:nutrilife/features/auth/data/auth_repository.dart';

/// Responde siempre lo mismo y guarda la última petición.
class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.statusCode, this.body);

  final int statusCode;
  final Object body;
  RequestOptions? lastRequest;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastRequest = options;
    return ResponseBody.fromString(
      jsonEncode(body),
      statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

AuthRepository repoWith(_FakeAdapter adapter) {
  final dio = Dio(BaseOptions(baseUrl: 'https://test.local'))
    ..httpClientAdapter = adapter;
  return AuthRepository(dio: dio);
}

void main() {
  test('manda el idToken y lee token, usuario y needsProfileSetup', () async {
    final adapter = _FakeAdapter(200, {
      'success': true,
      'message': 'Login successful',
      'data': {
        'token': 'jwt-123',
        'user': {'userId': 9, 'name': 'Ana'},
        'needsProfileSetup': true,
      },
    });

    final result = await repoWith(adapter).loginWithGoogle('google-token');

    expect(adapter.lastRequest!.path, ApiRoutes.authGoogle);
    expect(adapter.lastRequest!.method, 'POST');
    expect(adapter.lastRequest!.data, {'idToken': 'google-token'});
    expect(result.token, 'jwt-123');
    expect(result.user['name'], 'Ana');
    expect(result.needsProfileSetup, isTrue);
  });

  test('sin needsProfileSetup cuenta como false', () async {
    final adapter = _FakeAdapter(200, {
      'success': true,
      'data': {
        'token': 'jwt-123',
        'user': {'userId': 9},
      },
    });

    final result = await repoWith(adapter).loginWithGoogle('google-token');

    expect(result.needsProfileSetup, isFalse);
  });

  test('error del backend: lanza AuthException con su mensaje', () async {
    final adapter = _FakeAdapter(409, {
      'success': false,
      'message': 'Este correo ya está vinculado a otra cuenta de Google.',
      'error': {'code': 'GOOGLE_ACCOUNT_CONFLICT', 'details': <Object>[]},
    });

    expect(
      () => repoWith(adapter).loginWithGoogle('google-token'),
      throwsA(
        isA<AuthException>().having(
          (error) => error.message,
          'message',
          'Este correo ya está vinculado a otra cuenta de Google.',
        ),
      ),
    );
  });
}
```

- [ ] **Step 3: Correr el test y ver que falla**

Run: `cd nutrilife && flutter test test/features/auth/auth_repository_google_test.dart`
Expected: FAIL — `The getter 'authGoogle' isn't defined` / `loginWithGoogle` no existe.

- [ ] **Step 4: Ruta y repositorio**

En `nutrilife/lib/core/network/api_routes.dart`, después de `authRegister`:

```dart
  static const String authGoogle = '/auth/google';
```

En `nutrilife/lib/features/auth/data/auth_repository.dart`, después de la clase `AuthException`:

```dart
class GoogleLoginResult {
  const GoogleLoginResult({
    required this.token,
    required this.user,
    required this.needsProfileSetup,
  });

  final String token;
  final Map<String, dynamic> user;

  /// true si el usuario no completó su perfil: hay que mandarlo al setup.
  final bool needsProfileSetup;
}
```

y dentro de `AuthRepository`, después de `register`:

```dart
  Future<GoogleLoginResult> loginWithGoogle(String idToken) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiRoutes.authGoogle,
        data: {'idToken': idToken},
      );

      final body = response.data;
      final data = body?['data'];
      if (body != null && body['success'] == true && data is Map<String, dynamic>) {
        return GoogleLoginResult(
          token: data['token'] as String,
          user: Map<String, dynamic>.from(data['user'] as Map),
          needsProfileSetup: data['needsProfileSetup'] == true,
        );
      }

      throw AuthException(
        _extractFriendlyMessage(body) ??
            'No se pudo iniciar sesión con Google.',
      );
    } on DioException catch (error) {
      throw AuthException(
        _extractFriendlyMessage(error.response?.data) ??
            _fallbackMessage(error),
      );
    } on AuthException {
      rethrow;
    } catch (_) {
      throw const AuthException(
        'No se pudo iniciar sesión con Google. Inténtalo de nuevo.',
      );
    }
  }
```

- [ ] **Step 5: Correr el test y ver que pasa**

Run: `cd nutrilife && flutter test test/features/auth/auth_repository_google_test.dart`
Expected: PASS — 3 tests.

- [ ] **Step 6: `needsProfileSetup` en el login con email**

En `nutrilife/lib/core/services/auth_service.dart`, en el mapa de éxito de `login`, después de `'user': ...`:

```dart
          'needsProfileSetup':
              responseData['data']['needsProfileSetup'] == true,
```

- [ ] **Step 7: Configuración y servicio de Google**

`nutrilife/lib/core/constants/google_auth_config.dart`:

```dart
class GoogleAuthConfig {
  /// Client ID **web** de Google Cloud (termina en .apps.googleusercontent.com).
  /// Android lo necesita como serverClientId para devolver un idToken, y el
  /// backend lo acepta como audiencia. No es un secreto.
  /// Vacío hasta completar la Tarea 9; mientras tanto el botón muestra un error.
  static const String serverClientId = '';
}
```

`nutrilife/lib/core/services/google_auth_service.dart`:

```dart
import 'package:google_sign_in/google_sign_in.dart';

import '../constants/google_auth_config.dart';

class GoogleAuthException implements Exception {
  const GoogleAuthException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Envuelve google_sign_in: abre el selector de cuentas y devuelve el idToken
/// que el backend verifica. Lo usan el login y el borrado de la cuenta.
class GoogleAuthService {
  GoogleAuthService._();

  static Future<void>? _initialization;

  static Future<void> _ensureInitialized() async {
    _initialization ??= GoogleSignIn.instance.initialize(
      serverClientId: GoogleAuthConfig.serverClientId,
    );
    try {
      await _initialization;
    } catch (_) {
      // Permite reintentar si falló (p. ej. sin Google Play Services).
      _initialization = null;
      rethrow;
    }
  }

  /// Devuelve el idToken, o null si el usuario cierra el selector.
  static Future<String?> getIdToken() async {
    if (GoogleAuthConfig.serverClientId.isEmpty) {
      throw const GoogleAuthException(
        'El inicio de sesión con Google no está configurado.',
      );
    }

    try {
      await _ensureInitialized();
      final account = await GoogleSignIn.instance.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken == null) {
        throw const GoogleAuthException(
          'Google no devolvió tus datos. Inténtalo de nuevo.',
        );
      }
      return idToken;
    } on GoogleSignInException catch (error) {
      if (error.code == GoogleSignInExceptionCode.canceled) {
        return null;
      }
      throw const GoogleAuthException(
        'No se pudo iniciar sesión con Google. Inténtalo de nuevo.',
      );
    }
  }

  /// Olvida la cuenta elegida para que el próximo inicio muestre el selector.
  static Future<void> signOut() async {
    if (_initialization == null) return;
    try {
      await _initialization;
      await GoogleSignIn.instance.signOut();
    } catch (_) {
      // Cerrar la sesión de la app no debe fallar por Google.
    }
  }
}
```

En `nutrilife/lib/core/services/session_service.dart`, añadir el import y la llamada al principio de `clear()`:

```dart
import 'google_auth_service.dart';
```

```dart
  static Future<void> clear() async {
    DioClient.authToken = null;
    await GoogleAuthService.signOut();
```

- [ ] **Step 8: Analizar y correr toda la suite**

Run: `cd nutrilife && flutter analyze && flutter test`
Expected: `No issues found!` y todos los tests en PASS.

- [ ] **Step 9: Commit**

```bash
git add nutrilife/pubspec.yaml nutrilife/pubspec.lock nutrilife/lib/core nutrilife/lib/features/auth/data/auth_repository.dart nutrilife/test/features/auth/auth_repository_google_test.dart
git commit -m "feat(app): servicio de Google y loginWithGoogle en AuthRepository"
```

---

### Task 7: Botón "Continuar con Google" en el login

**Files:**
- Modify: `nutrilife/lib/features/auth/presentation/screens/login_screen.dart`

**Interfaces:**
- Consumes: `GoogleAuthService.getIdToken`, `GoogleAuthException` (Task 6); `AuthRepository.loginWithGoogle`, `AuthException` (Task 6); `AuthService.login` con `'needsProfileSetup'` (Task 6); `ProfileSetupScreen({String? userName})` (`lib/features/setup/presentation/screens/profile_setup_screen.dart`).

- [ ] **Step 1: Imports**

En `login_screen.dart`, añadir:

```dart
import '../../../../core/services/google_auth_service.dart';
import '../../../setup/presentation/screens/profile_setup_screen.dart';
import '../../data/auth_repository.dart';
```

- [ ] **Step 2: Navegación común y manejo de Google en `_LoginPanelState`**

Añadir el campo junto a los demás:

```dart
  final _authRepository = AuthRepository();
```

Añadir estos métodos después de `dispose()`:

```dart
  /// Tras iniciar sesión: al setup del perfil si falta, si no al Dashboard.
  void _goToApp(Map<String, dynamic> user, {required bool needsProfileSetup}) {
    final Widget destination = needsProfileSetup
        ? ProfileSetupScreen(userName: user['name']?.toString())
        : DashboardScreen(user: user);

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => destination),
      (route) => false,
    );
  }

  void _showError(String message) {
    if (!mounted) return;
    setState(() {
      _errorMessage = message;
      _isLoading = false;
    });
  }

  Future<void> _handleGoogleLogin() async {
    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });

    try {
      final idToken = await GoogleAuthService.getIdToken();
      if (idToken == null) {
        // El usuario cerró el selector: no es un error.
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      final result = await _authRepository.loginWithGoogle(idToken);
      await SessionService.save(token: result.token, user: result.user);

      if (!mounted) return;
      _goToApp(result.user, needsProfileSetup: result.needsProfileSetup);
    } on GoogleAuthException catch (error) {
      _showError(error.message);
    } on AuthException catch (error) {
      _showError(error.message);
    }
  }
```

- [ ] **Step 3: Usar `_goToApp` en el login con email**

En `_handleLogin`, reemplazar el bloque `Navigator.of(context).pushReplacement(...)` por:

```dart
        _goToApp(
          result['user'] as Map<String, dynamic>,
          needsProfileSetup: result['needsProfileSetup'] == true,
        );
```

- [ ] **Step 4: Conectar el botón**

En `build`, el botón de Google queda:

```dart
                // Login con Apple retirado temporalmente.
                _SocialButton(
                  semanticsLabel: 'Continuar con Google',
                  onPressed: _isLoading ? null : _handleGoogleLogin,
                  child: SvgPicture.asset(
                    'assets/images/google_wordmark.svg',
                    height: 20,
                  ),
                ),
```

En `_SocialButton`:

```dart
  const _SocialButton({
    required this.semanticsLabel,
    required this.onPressed,
    required this.child,
  });

  final String semanticsLabel;
  final VoidCallback? onPressed;
  final Widget child;
```

y en su `TextButton`, cambiar `onPressed: () {},` por:

```dart
        onPressed: onPressed,
```

- [ ] **Step 5: Analizar y correr la suite**

Run: `cd nutrilife && flutter analyze && flutter test`
Expected: `No issues found!` y todos los tests en PASS.

- [ ] **Step 6: Commit**

```bash
git add nutrilife/lib/features/auth/presentation/screens/login_screen.dart
git commit -m "feat(app): login con Google y envío al setup si falta el perfil"
```

---

### Task 8: Borrar la cuenta confirmando con Google

**Files:**
- Modify: `nutrilife/lib/features/profile/data/profile_repository.dart` (`UserProfile`, `deleteAccount`)
- Modify: `nutrilife/lib/features/profile/presentation/screens/profile_screen.dart` (`_deleteAccount`, `_DeleteAccountDialog`)
- Test: `nutrilife/test/features/profile/profile_repository_delete_test.dart`

**Interfaces:**
- Consumes: `GoogleAuthService.getIdToken`, `GoogleAuthException` (Task 6); backend `hasPassword` y `DELETE /user/account` con `googleIdToken` (Task 4).
- Produces: `UserProfile.hasPassword` (bool); `ProfileRepository.deleteAccount({String? password, String? googleIdToken, required String email})`.

- [ ] **Step 1: Escribir los tests que fallan**

`nutrilife/test/features/profile/profile_repository_delete_test.dart`:

```dart
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutrilife/features/profile/data/profile_repository.dart';

class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.statusCode, this.body);

  final int statusCode;
  final Object body;
  RequestOptions? lastRequest;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastRequest = options;
    return ResponseBody.fromString(
      jsonEncode(body),
      statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

ProfileRepository repoWith(_FakeAdapter adapter) {
  final dio = Dio(BaseOptions(baseUrl: 'https://test.local'))
    ..httpClientAdapter = adapter;
  return ProfileRepository(dio: dio);
}

void main() {
  test('hasPassword viene del backend y si falta se asume true', () {
    expect(UserProfile.fromJson({'hasPassword': false}).hasPassword, isFalse);
    expect(UserProfile.fromJson({}).hasPassword, isTrue);
  });

  test('borrar con Google manda googleIdToken y no la contraseña', () async {
    final adapter = _FakeAdapter(200, {'success': true, 'data': null});

    await repoWith(adapter).deleteAccount(googleIdToken: 'tok', email: '');

    expect(adapter.lastRequest!.method, 'DELETE');
    expect(adapter.lastRequest!.data, {'googleIdToken': 'tok'});
  });

  test('otra cuenta de Google: mensaje claro', () async {
    final adapter = _FakeAdapter(403, {
      'success': false,
      'message': 'Esa cuenta de Google no corresponde a este perfil.',
      'error': {'code': 'GOOGLE_ACCOUNT_MISMATCH', 'details': <Object>[]},
    });

    expect(
      () => repoWith(adapter).deleteAccount(googleIdToken: 'tok', email: ''),
      throwsA(
        isA<ProfileException>().having(
          (error) => error.message,
          'message',
          'Esa cuenta de Google no corresponde a este perfil.',
        ),
      ),
    );
  });
}
```

- [ ] **Step 2: Correr los tests y ver que fallan**

Run: `cd nutrilife && flutter test test/features/profile/profile_repository_delete_test.dart`
Expected: FAIL — `hasPassword` no existe / `password` es obligatorio.

- [ ] **Step 3: `UserProfile.hasPassword`**

En `UserProfile` (`profile_repository.dart`):
- Constructor: añadir `required this.hasPassword,`.
- Campo: `final bool hasPassword;` con el comentario `/// false si la cuenta solo entra con Google.`
- `fromJson`: `hasPassword: json['hasPassword'] != false,`
- `copyWith`: parámetro `bool? hasPassword` y `hasPassword: hasPassword ?? this.hasPassword,`

Run: `cd nutrilife && grep -rn "UserProfile(" lib test`
Expected: si aparece otra construcción directa de `UserProfile(` además de `fromJson` y `copyWith`, añadirle `hasPassword: true`.

- [ ] **Step 4: `deleteAccount` con contraseña o Google**

Reemplazar la firma y el `data` de `deleteAccount`:

```dart
  // Borra la cuenta en el backend y lo que la app guardó de ella en el
  // dispositivo. La sesión la limpia quien llama, igual que al cerrar sesión.
  // Se confirma con la contraseña o, si la cuenta no tiene, con Google.
  Future<void> deleteAccount({
    String? password,
    String? googleIdToken,
    required String email,
  }) async {
    assert(
      (password == null) != (googleIdToken == null),
      'Pasa la contraseña o el idToken de Google, no ambos',
    );

    try {
      final response = await _dio.delete<Map<String, dynamic>>(
        ApiRoutes.userAccount,
        data: password != null
            ? {'password': password}
            : {'googleIdToken': googleIdToken},
      );
```

(el resto del cuerpo de éxito no cambia). En el `on DioException`, después del `if (code == 'INVALID_PASSWORD')`:

```dart
      if (code == 'GOOGLE_ACCOUNT_MISMATCH') {
        throw const ProfileException(
          'Esa cuenta de Google no corresponde a este perfil.',
        );
      }
      if (code == 'INVALID_GOOGLE_TOKEN') {
        throw const ProfileException(
          'No se pudo confirmar con Google. Inténtalo de nuevo.',
        );
      }
```

- [ ] **Step 5: Correr los tests y ver que pasan**

Run: `cd nutrilife && flutter test test/features/profile/profile_repository_delete_test.dart`
Expected: PASS — 3 tests.

- [ ] **Step 6: Pantalla de perfil**

En `profile_screen.dart`, añadir el import:

```dart
import '../../../../core/services/google_auth_service.dart';
```

Reemplazar el `showDialog` de `_deleteAccount` y añadir `_confirmDeletion`:

```dart
    final deleted = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _DeleteAccountDialog(
        requiresPassword: profile.hasPassword,
        onConfirm: (password) => _confirmDeletion(profile, password),
      ),
    );
```

```dart
  /// Devuelve false si el usuario cerró el selector de Google sin elegir.
  Future<bool> _confirmDeletion(UserProfile profile, String? password) async {
    if (profile.hasPassword) {
      await _profileRepository.deleteAccount(
        password: password,
        email: profile.email,
      );
      return true;
    }

    final String? idToken;
    try {
      idToken = await GoogleAuthService.getIdToken();
    } on GoogleAuthException catch (error) {
      throw ProfileException(error.message);
    }
    if (idToken == null) return false;

    await _profileRepository.deleteAccount(
      googleIdToken: idToken,
      email: profile.email,
    );
    return true;
  }
```

En `_DeleteAccountDialog`:

```dart
class _DeleteAccountDialog extends StatefulWidget {
  const _DeleteAccountDialog({
    required this.requiresPassword,
    required this.onConfirm,
  });

  /// false en cuentas que solo entran con Google: se confirma con Google.
  final bool requiresPassword;

  /// Devuelve false si el usuario canceló la confirmación.
  final Future<bool> Function(String? password) onConfirm;
```

Reemplazar `_confirm`:

```dart
  Future<void> _confirm() async {
    final password = _passwordController.text;
    if (widget.requiresPassword && password.isEmpty) {
      setState(() => _error = 'Escribe tu contraseña para confirmar.');
      return;
    }

    setState(() {
      _isDeleting = true;
      _error = null;
    });

    try {
      final deleted = await widget.onConfirm(
        widget.requiresPassword ? password : null,
      );
      if (!mounted) return;
      if (deleted) {
        Navigator.of(context).pop(true);
      } else {
        setState(() => _isDeleting = false);
      }
    } on ProfileException catch (error) {
      if (!mounted) return;
      setState(() {
        _isDeleting = false;
        _error = error.message;
      });
    }
  }
```

En `build`, reemplazar el `TextField(...)` por:

```dart
          if (widget.requiresPassword)
            TextField(
              controller: _passwordController,
              obscureText: true,
              enabled: !_isDeleting,
              autofillHints: const [AutofillHints.password],
              decoration: InputDecoration(
                labelText: 'Contraseña',
                errorText: _error,
                border: const OutlineInputBorder(),
              ),
              onSubmitted: (_) => _confirm(),
            )
          else ...[
            const Text('Para confirmar, elige tu cuenta de Google.'),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(
                _error!,
                style: const TextStyle(color: _ProfileColors.danger),
              ),
            ],
          ],
```

y el texto del botón de borrar:

```dart
          child: Text(
            _isDeleting
                ? 'Eliminando...'
                : widget.requiresPassword
                    ? 'Eliminar'
                    : 'Confirmar con Google',
          ),
```

- [ ] **Step 7: Analizar y correr la suite**

Run: `cd nutrilife && flutter analyze && flutter test`
Expected: `No issues found!` y todos los tests en PASS.

- [ ] **Step 8: Commit**

```bash
git add nutrilife/lib/features/profile nutrilife/test/features/profile/profile_repository_delete_test.dart
git commit -m "feat(app): borrar la cuenta confirmando con Google si no tiene contraseña"
```

---

### Task 9: Configuración de Google Cloud, migración y prueba de punta a punta

Esta tarea necesita al dueño del proyecto (cuenta de Google Cloud, llaves de firma, base de datos). Quien ejecute el plan debe pedirle cada valor; no inventarlos.

**Files:**
- Modify: `nutrilife/lib/core/constants/google_auth_config.dart`
- Modify: `nutrilife/ios/Runner/Info.plist`
- Modify: `backend/.env` (local, no se commitea)

- [ ] **Step 1: Crear los clients en Google Cloud (manual, dueño del proyecto)**

En Google Cloud Console → APIs & Services:
1. Configurar la pantalla de consentimiento OAuth (tipo External, nombre "NutriLife").
2. Crear un OAuth client **Web application**. Anotar su client ID (`WEB_ID`).
3. Crear un OAuth client **Android**: paquete `software.oween.nutrilife` y la SHA-1 de la llave de debug. Obtenerla con:

```bash
cd nutrilife/android && ./gradlew signingReport
```

   Crear un client Android más por cada SHA-1 adicional (llave de release y, si se usa, la de Play App Signing que muestra Play Console).
4. Crear un OAuth client **iOS** con bundle ID `software.oween.nutrilife`. Anotar su client ID (`IOS_ID`) y su "iOS URL scheme" (`IOS_URL_SCHEME`, empieza por `com.googleusercontent.apps.`).

- [ ] **Step 2: Poner los IDs en la app**

En `google_auth_config.dart`, reemplazar `''` por el `WEB_ID` y quitar la frase "Vacío hasta completar la Tarea 9…".

En `nutrilife/ios/Runner/Info.plist`, antes del `</dict>` final:

```xml
	<key>GIDClientID</key>
	<string>IOS_ID</string>
	<key>GIDServerClientID</key>
	<string>WEB_ID</string>
	<key>CFBundleURLTypes</key>
	<array>
		<dict>
			<key>CFBundleTypeRole</key>
			<string>Editor</string>
			<key>CFBundleURLSchemes</key>
			<array>
				<string>IOS_URL_SCHEME</string>
			</array>
		</dict>
	</array>
```

con los valores reales del paso 1.

- [ ] **Step 3: Configurar el backend y aplicar la migración en desarrollo**

En `backend/.env`: `GOOGLE_CLIENT_IDS = WEB_ID,ANDROID_ID_1[,ANDROID_ID_2...],IOS_ID`.

Ver contra qué base se va a aplicar **antes** de ejecutar:

```bash
cd backend && npm run db:apply -- update_14_10_2026_google_auth.sql
```

Confirmar con el dueño que el host mostrado es el de desarrollo. Solo entonces:

```bash
cd backend && npm run db:apply -- update_14_10_2026_google_auth.sql --yes
```

- [ ] **Step 4: Prueba de punta a punta en Android (manual)**

Con el backend local apuntando a la base de desarrollo y la app apuntando a ese backend:
1. Cuenta de Google nueva → "Continuar con Google" → llega a `ProfileSetupScreen` con su nombre. Completar el setup.
2. Cerrar sesión y volver a entrar con Google → llega al Dashboard.
3. Cuenta existente con email y contraseña cuyo correo es de Google → "Continuar con Google" → entra a su cuenta de siempre. En el admin-panel aparece como "Ambos" y en Events hay un `ACCOUNT_LINKED`.
4. Con la cuenta del punto 1, intentar el login con email → mensaje "Esta cuenta usa Google…".
5. Cerrar el selector de Google sin elegir → no aparece ningún error.
6. Perfil de la cuenta del punto 1 → Eliminar cuenta → "Confirmar con Google" → la cuenta se borra y vuelve al login.

- [ ] **Step 5: Prueba en iOS (manual)**

Generar el IPA sin firmar con GitHub Actions e instalarlo con Sideloadly. Repetir los puntos 1, 2 y 5.

- [ ] **Step 6: Commit**

```bash
git add nutrilife/lib/core/constants/google_auth_config.dart nutrilife/ios/Runner/Info.plist
git commit -m "chore(app): client IDs de Google para Android e iOS"
```

- [ ] **Step 7: Antes de desplegar a producción**

Seguir el orden del spec: migración en la base de producción (repitiendo el paso 3 con el `.env` de producción), backend con `GOOGLE_CLIENT_IDS`, admin-panel, y por último la app. Recordar que publicar en la App Store requiere añadir Sign in with Apple primero.
