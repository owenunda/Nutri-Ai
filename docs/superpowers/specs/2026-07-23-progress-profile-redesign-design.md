# Diseño: Unificación visual de Progreso y Perfil con el sistema "The Mindful Alchemist"

## Contexto

Un audit contra `nutrilife/lib/docs/DESIGN.md` encontró que `progress_screen.dart` y
`profile_screen.dart` no comparten tokens de color/tipografía/sombra/radio con el resto
de la app (p. ej. `dashboard_screen.dart`), y violan reglas explícitas del sistema:

- Cada pantalla define su propia paleta local (`_text`, `_muted`, `_blue` en Progreso;
  `_ProfileColors` en Perfil) con valores distintos entre sí y respecto a `on_surface`
  (`#2c2f31`) ya usado en Dashboard.
- Progreso usa un azul "informativo" (`0xFF1E56F5`) en el gráfico de historial de peso,
  prohibido por la sección 6 del DESIGN.md ("Don't use standard Information blues").
- Perfil usa `Divider(height: 1)` entre filas de ajustes y un borde sólido de 2px en el
  botón de logout, violando la regla "No-Line" (sección 2) y el "Ghost Border fallback"
  (sección 4).
- Ninguna de las dos pantallas usa el componente compartido `PrimaryButton` (gradiente
  135°, sombra difusa) para sus CTAs de error; usan `FilledButton`/`OutlinedButton` planos.
- Los radios de esquina (26px en Progreso, 28-34px en Perfil) no corresponden a los
  tokens `md` (24px) / `lg` (32px) definidos en la sección 4.
- Las sombras (`_softShadow`, `_profileShadow`) no siguen la spec de sombra ambiental
  (`offset 0,20 / blur 40 / alpha(on_surface, 0.06)`).
- No hay tipografía custom declarada en `pubspec.yaml`: toda la app usa la fuente por
  defecto, en vez de Plus Jakarta Sans (headlines) + Inter (body) de la sección 3.

## Objetivo

Que Progreso y Perfil se vean como parte de la misma app que Dashboard, consumiendo un
único set de tokens compartido y los mismos componentes, **sin cambiar la estructura,
el orden de las tarjetas ni la lógica de datos** de ninguna de las dos pantallas.

## Alcance

Incluye:
1. Nuevos tokens de diseño en `AppTheme` (color, radio, sombra).
2. Tipografía Plus Jakarta Sans + Inter vía el paquete `google_fonts`.
3. Refactor de estilos en `progress_screen.dart` y `profile_screen.dart` para consumir
   los tokens y el componente `PrimaryButton`.

Explícitamente fuera de alcance:
- Cambiar el layout/orden/estructura de las tarjetas ("Asimetría Intencional" editorial).
- Tocar `dashboard_screen.dart`, `login_screen.dart` u otras pantallas que ya usan
  `AppTheme.background`/`AppTheme.surface` (no se renombran ni alteran esos valores).
- Cambiar lógica de datos, repositorios o navegación.

## 1. Tokens compartidos — `nutrilife/lib/core/theme/app_theme.dart`

Se agregan campos nuevos a `AppTheme` (no se modifican `background`, `surface`,
`primaryStart`, `primaryEnd`, `onPrimary`, que ya son usados por otras pantallas):

```dart
static const Color onSurface = Color(0xFF2C2F31);
static const Color onSurfaceVariant = Color(0xFF64748B);
static const Color tertiary = Color(0xFF006573);
static const Color primaryContainer = Color(0xFFD5F6E5);
static const Color surfaceContainerLow = Color(0xFFEFF3F5);
static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
static const double radiusMd = 24;
static const double radiusLg = 32;
static const List<BoxShadow> ambientShadow = [
  BoxShadow(color: Color(0x0F2C2F31), offset: Offset(0, 20), blurRadius: 40),
];
```

`AppTheme.lightTheme` gana `textTheme: GoogleFonts.interTextTheme()` como base tipográfica
por defecto de la app (beneficio colateral para el resto de pantallas).

## 2. Tipografía — paquete `google_fonts`

- Se agrega `google_fonts: ^6.x` a `pubspec.yaml` (sin archivos de fuente manuales).
- Regla de aplicación dentro de Progreso y Perfil:
  - **Plus Jakarta Sans** (`GoogleFonts.plusJakartaSans(textStyle: ...)`): saludos/títulos
    de pantalla, títulos de tarjeta, números "hero" (calorías, cambio de peso), nombre del
    usuario en Perfil.
  - **Inter** (`GoogleFonts.inter(textStyle: ...)`): texto de cuerpo, subtítulos,
    etiquetas en mayúsculas, texto de ejes del gráfico.
- Los tamaños/pesos/colores de cada `TextStyle` existente se mantienen; solo se envuelve
  con la familia tipográfica correspondiente.

## 3. `progress_screen.dart`

| Antes | Después |
|---|---|
| `_text = Color(0xFF101418)` | `AppTheme.onSurface` |
| `_muted = Color(0xFF64748B)` | `AppTheme.onSurfaceVariant` |
| `_blue = Color(0xFF1E56F5)` (gráfico historial, punto "actual") | `AppTheme.tertiary` |
| `Colors.white` en `_ProgressCard`, `_WeightInsightCard` | `AppTheme.surfaceContainerLowest` |
| fondo `0xFFEFF3F5` en `_AverageTile` | `AppTheme.surfaceContainerLow` |
| radio de card 26 | `AppTheme.radiusMd` (24) |
| `_softShadow` local | `AppTheme.ambientShadow` |
| `FilledButton` en `_ProgressErrorView` | `PrimaryButton` (icon: `Icons.refresh`) |

`_GoalPill` y `_StatusChip` mantienen su color pero se confirma forma "full"/stadium.

## 4. `profile_screen.dart`

| Antes | Después |
|---|---|
| `_ProfileColors.green/text/muted` | `AppTheme.primaryStart` / `onSurface` / `onSurfaceVariant` |
| chip "ACTIVO" `0xFFD5F6E5` | `AppTheme.primaryContainer` |
| `Colors.white` en cards | `AppTheme.surfaceContainerLowest` |
| radio de cards 28-34 | `AppTheme.radiusLg` (32) |
| `_profileShadow` local | `AppTheme.ambientShadow` |
| `Divider(height: 1)` ×2 entre filas de ajustes | eliminado; padding vertical adicional en `_SettingsRow` |
| borde sólido 2px en `_LogoutButton` | "ghost border": `AppTheme.onSurface.withValues(alpha: 0.15)`, 1px |
| `FilledButton` en `_ProfileErrorView` | `PrimaryButton` (icon: `Icons.refresh`) |

`_LogoutButton` no adopta el gradiente de `PrimaryButton` (acción secundaria/destructiva,
no un CTA principal); solo se corrige su borde a "ghost border".

## Testing

- `flutter analyze` sin nuevos warnings/errores en los archivos tocados.
- Verificación visual manual (`flutter run` o capturas) de ambas pantallas en estado
  normal, loading y error, comparando con Dashboard para consistencia de color/tipografía.
- No hay lógica de negocio nueva que requiera tests unitarios; los repositorios de datos
  no se modifican.
