# NutriLife

Asistente nutricional con IA: registro de comidas, hidratación, progreso y un Chef IA que arma recetas con lo que tienes. Monetiza con un plan **PRO** por suscripción (RevenueCat).

## Qué hay en este repo

| Carpeta | Qué es |
|---|---|
| [`nutrilife/`](nutrilife/README.md) | La app (Flutter, Android + iOS). |
| [`backend/`](backend/README.md) | API REST (Node + Express + PostgreSQL + Redis). |
| `admin-panel/` | Panel de administración (React + Vite + TS): usuarios, planes, eventos. |
| `landing-page/` | Sitio informativo (React + Vite). |
| `n8n/` | Flujo de n8n del Chat de Recetas (Chef IA). |
| `docs/superpowers/` | Specs (`specs/`) y planes de implementación (`plans/`) de cada funcionalidad. |
| `scripts/` | Utilidades sueltas (por ejemplo `adb_reverse.sh` para probar con un teléfono físico). |
| `nutria_agua/`, `nutrilifeGame/` | Arte de la nutria y recursos gráficos. |

## Cómo encaja todo

```
App (Flutter) ──HTTP──▶ Backend (Express) ──▶ PostgreSQL / Redis
     │                       │  ▲
     │                       │  └── webhook de RevenueCat (renovaciones, cancelaciones)
     │                       └────▶ n8n ──▶ LLM (Chef IA)
     └── RevenueCat SDK ──▶ Google Play / App Store / Test Store
Panel admin ──HTTP──▶ Backend
```

- La API de producción está en `https://api.nutri.oween.software/api/v1`.
- El plan del usuario (`FREE` / `PRO`) vive en el backend. Puede venir de un **regalo** desde el panel o de una **suscripción** de tienda; la regla está en `backend/src/modules/subscription/effectivePlan.js`.

## Despliegue

- **Backend y panel admin:** Dokploy, cada uno como app aparte. Las variables de entorno de producción se configuran en Dokploy (ver [`backend/README.md`](backend/README.md#variables-de-entorno)).
- **Migraciones:** se aplican a mano con `npm run db:apply` **antes** de desplegar código que las necesite.
- **App Android:** AAB subido a Google Play Console (ver [`nutrilife/README.md`](nutrilife/README.md#publicar-en-google-play)).
- **App iOS:** por ahora solo IPA sin firmar desde GitHub Actions (`.github/workflows/ios-unsigned-ipa.yml`), para instalar con Sideloadly.
