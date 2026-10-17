# Racha de agua guardada en el backend

Fecha: 2026-10-17

## Problema

La racha de agua (vasos por día, racha actual, mejor racha, últimos 7 días) vive solo en el teléfono, en `SharedPreferences` con la clave `water_streak_v1_<correo>`. Si el usuario abre su cuenta en otro dispositivo, empieza de cero. Las calorías y las comidas ya se guardan en la base; el agua tiene que hacer lo mismo.

## Decisión

El backend **guarda** los vasos de cada día. La app **calcula** la racha con el código que ya existe (`WaterStreakRepository._snapshot`, `_currentStreak` y `_bestStreak`), que ya tiene tests. Así el cálculo no se duplica en dos lenguajes.

- La meta sigue fija en **4 vasos al día**. La personalización por ml quedó descartada por ahora.
- El "día" es la fecha local del usuario (`YYYY-MM-DD`): la manda la app y el backend la guarda tal cual.
- Sin internet no hay cola offline. Se muestra un error, igual que con las comidas.

## Base de datos

Script `backend/src/database/backups/update_17_10_2026_water_intake.sql`, que se aplica con `npm run db:apply`:

```sql
CREATE TABLE IF NOT EXISTS water_intake (
    user_id     INTEGER NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    day         DATE NOT NULL,
    glasses     SMALLINT NOT NULL CHECK (glasses BETWEEN 1 AND 4),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (user_id, day)
);
```

Un día sin vasos no tiene fila. Al deshacer el último vaso, la fila se borra. Al eliminar la cuenta, `deleteUserAccountData` también borra las filas de `water_intake`.

## Backend: módulo `hydration`

Todas las rutas usan `authenticateToken(['USER', 'ADMIN'])` y se montan en `/api/v1/hydration`.

| Método y ruta | Body o query | Respuesta `data` |
|---|---|---|
| `GET /hydration` | — | `{ goal: 4, history: { "2026-10-17": 3, ... } }` (todos los días del usuario) |
| `POST /hydration/glass` | `{ date }` | `{ date, glasses }` (suma 1, con tope de 4) |
| `POST /hydration/glass/undo` | `{ date }` | `{ date, glasses }` (resta 1; con 0 la fila se borra) |
| `POST /hydration/import` | `{ history: { fecha: vasos } }` | `{ imported }` |

Validación:
- `date` debe ser una fecha `YYYY-MM-DD` real y estar a un día como mucho de la fecha UTC del servidor. Eso cubre todas las zonas horarias y no deja escribir días lejanos.
- `history` en import:
  - debe ser un objeto con 1.000 entradas como máximo;
  - cada clave, una fecha válida que no supere el día UTC del servidor más 1;
  - cada valor, un entero entre 1 y 5.
  - El 5 se acepta porque el historial local viejo permitía 5 vasos; se guarda como 4.

Escrituras atómicas:
- Sumar: `INSERT ... ON CONFLICT (user_id, day) DO UPDATE SET glasses = LEAST(water_intake.glasses + 1, 4)`.
- Deshacer: un CTE que borra la fila si `glasses <= 1` y, si no, le resta 1.
- Import: `INSERT ... SELECT FROM unnest(...) ON CONFLICT DO UPDATE SET glasses = GREATEST(water_intake.glasses, EXCLUDED.glasses)`. Por cada día se queda el mayor valor entre teléfono y servidor: nadie pierde su racha y repetir el import no cambia nada.

Los mensajes de validación van en `SOURCE_MESSAGES`, en español y en inglés.

## App

`WaterStreakRepository({required String accountId, Dio? dio})` mantiene su interfaz: `load`, `addGlass` y `undoGlass` devuelven `WaterStreakSnapshot`. Las pantallas no cambian.

- `load(now)`: sube el historial local si existe (ver abajo), pide `GET /hydration` y arma el snapshot con el historial recibido y `localDateString(now)`.
- `addGlass(now)` y `undoGlass(now)`: piden el historial, hacen el POST y arman el snapshot con el número que devolvió el servidor. Después hacen `WaterStreakState.instance.bump()`, como hoy.
- **Subida única del historial local:** si existe la clave `water_streak_v1_<correo>`, se envía con `POST /hydration/import`. Las entradas inválidas se descartan sin lanzar error. Si el import responde bien, la clave se borra. Si falla, se reintenta en el próximo `load` sin bloquear la pantalla.
- Errores de red: se lanza `Exception` con un texto localizado (`hydrationErrorLoad` es la clave nueva; para guardar se usa `hydrationErrorSave`). Las pantallas ya tienen sus `try/catch`.
- `accountId` sigue usándose solo para la clave del historial local.

Rutas nuevas en `ApiRoutes`: `hydration`, `hydrationGlass`, `hydrationGlassUndo` y `hydrationImport`.

## Pruebas

Backend (`node --test`):
- Validación: fecha válida o inválida, fuera del rango de ±1 día, y import con claves o valores inválidos o con demasiadas entradas.
- Servicio, con el repositorio mockeado: el import recorta 5 a 4 y deja afuera los días futuros, y `glass` y `undo` devuelven el conteo del día.

App (`flutter test`):
- `test/helpers/fake_hydration_server.dart`: un `HttpClientAdapter` con un mapa en memoria que responde las 4 rutas con las mismas reglas (tope de 4 y borrar en 0).
- Los tests de `water_streak_repository_test.dart` pasan a correr contra el servidor falso: mismas expectativas de rachas, tope y deshacer.
- Test nuevo: con historial local guardado, el primer `load` lo sube por import, borra la clave y el snapshot lo refleja.
- Los tests de widgets que usan la racha (pantalla, tarjeta de Inicio, estadísticas, l10n y rachas del perfil) instalan el servidor falso en `DioClient.instance.httpClientAdapter` y lo restauran al terminar.

## Despliegue

1. Aplicar el SQL en producción. **Se le pregunta al usuario antes.**
2. Push del backend.
3. App: commit local y push solo con el OK del usuario. Hasta que el backend nuevo esté en producción, la app nueva muestra error al cargar el agua. Por eso el backend va primero.
