# Progress/Profile Design Unification Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make `progress_screen.dart` and `profile_screen.dart` consume the same design
tokens, typography, and shared components as the rest of the Nutri-Ai Flutter app,
per `nutrilife/lib/docs/DESIGN.md` and the approved spec at
`docs/superpowers/specs/2026-07-23-progress-profile-redesign-design.md`.

**Architecture:** Add missing design tokens (color/radius/shadow) and a global Inter
`textTheme` to the existing `AppTheme` class. Add the `google_fonts` package for
Plus Jakarta Sans (headlines/hero numbers) and Inter (body/labels). Then edit the two
screen files in place: swap local hardcoded colors for `AppTheme` tokens, swap the
local shadow/radius constants for the new tokens, remove 1px dividers and the solid
logout border in favor of whitespace/ghost-border, and replace the ad-hoc error-retry
`FilledButton` with the existing shared `PrimaryButton` component. No screen layout,
navigation, or data logic changes.

**Tech Stack:** Flutter (Material 3), `google_fonts` package (new dependency).

## Global Constraints

- Do not modify `AppTheme.background`, `AppTheme.surface`, `AppTheme.primaryStart`,
  `AppTheme.primaryEnd`, or `AppTheme.onPrimary` — other screens (Login, Setup, Foods)
  depend on their current values.
- Do not change the layout, card order, or data/repository logic of either screen.
- Do not touch `dashboard_screen.dart` or any file outside
  `app_theme.dart`, `progress_screen.dart`, `profile_screen.dart`, and `pubspec.yaml`.
- This codebase has no existing `test/` directory and no test harness for
  network-backed screens (`ProgressScreen`/`ProfileScreen` fetch data from a live
  repository in `initState`). Verification for this plan is `flutter analyze`
  (must stay clean) plus manual visual confirmation — per the spec's own Testing
  section — not new widget-test infrastructure.

---

### Task 1: Add the `google_fonts` dependency

**Files:**
- Modify: `nutrilife/pubspec.yaml`

**Interfaces:**
- Produces: the `google_fonts` package available for import as
  `package:google_fonts/google_fonts.dart` in Tasks 2-4.

- [ ] **Step 1: Add the dependency**

Edit `nutrilife/pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  dio: ^5.7.0
  http: ^0.13.6
  shared_preferences: ^2.3.0
  url_launcher: ^6.3.0
  google_fonts: ^6.2.1
```

- [ ] **Step 2: Fetch the dependency**

Run (from `nutrilife/`): `flutter pub get`
Expected: exits 0, output ends with `Got dependencies!` (or similar success line),
`pubspec.lock` is updated with a `google_fonts` entry.

- [ ] **Step 3: Commit**

```bash
git add nutrilife/pubspec.yaml nutrilife/pubspec.lock
git commit -m "Add google_fonts dependency for Plus Jakarta Sans + Inter"
```

---

### Task 2: Add design tokens and global typography to `AppTheme`

**Files:**
- Modify: `nutrilife/lib/core/theme/app_theme.dart`

**Interfaces:**
- Consumes: nothing new (only `flutter/material.dart`, plus `google_fonts` from Task 1).
- Produces (consumed by Tasks 3-4):
  - `AppTheme.onSurface` (`Color`), `AppTheme.onSurfaceVariant` (`Color`),
    `AppTheme.tertiary` (`Color`), `AppTheme.primaryContainer` (`Color`),
    `AppTheme.surfaceContainerLow` (`Color`), `AppTheme.surfaceContainerLowest` (`Color`)
  - `AppTheme.radiusMd` (`double`, 24), `AppTheme.radiusLg` (`double`, 32)
  - `AppTheme.ambientShadow` (`List<BoxShadow>`)

- [ ] **Step 1: Edit `app_theme.dart`**

Old (full current file):

```dart
import 'package:flutter/material.dart';

class AppTheme {
  // Paleta de colores principales (Nutri-Ai verde)
  static const Color primaryStart = Color(0xFF0A6B3F);
  static const Color primaryEnd = Color(0xFF1B7D50);
  static const Color onPrimary = Color(0xFFFFFFFF);

  // Colores de fondo y superficies
  static const Color background = Color(0xFFF4F9F6);
  static const Color surface = Color(0xFFFFFFFF);

  // Tema de Flutter configurado con estos colores
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryStart,
        primary: primaryStart,
        onPrimary: onPrimary,
        surface: surface,
      ),
      // Definición personalizada para los botones elevados e interactivos
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          shape: const StadiumBorder(),
        ),
      ),
    );
  }
}
```

New (full replacement file):

```dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Paleta de colores principales (Nutri-Ai verde)
  static const Color primaryStart = Color(0xFF0A6B3F);
  static const Color primaryEnd = Color(0xFF1B7D50);
  static const Color onPrimary = Color(0xFFFFFFFF);

  // Colores de fondo y superficies
  static const Color background = Color(0xFFF4F9F6);
  static const Color surface = Color(0xFFFFFFFF);

  // Tokens del sistema de diseño "The Mindful Alchemist" (docs/DESIGN.md)
  static const Color onSurface = Color(0xFF2C2F31);
  static const Color onSurfaceVariant = Color(0xFF64748B);
  static const Color tertiary = Color(0xFF006573);
  static const Color primaryContainer = Color(0xFFD5F6E5);
  static const Color surfaceContainerLow = Color(0xFFEFF3F5);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);

  static const double radiusMd = 24;
  static const double radiusLg = 32;

  static const List<BoxShadow> ambientShadow = [
    BoxShadow(
      color: Color(0x0F2C2F31),
      offset: Offset(0, 20),
      blurRadius: 40,
    ),
  ];

  // Tema de Flutter configurado con estos colores
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryStart,
        primary: primaryStart,
        onPrimary: onPrimary,
        surface: surface,
      ),
      textTheme: GoogleFonts.interTextTheme(),
      // Definición personalizada para los botones elevados e interactivos
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          shape: const StadiumBorder(),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Verify with static analysis**

Run (from `nutrilife/`): `flutter analyze lib/core/theme/app_theme.dart`
Expected: `No issues found!`

- [ ] **Step 3: Commit**

```bash
git add nutrilife/lib/core/theme/app_theme.dart
git commit -m "Add shared design tokens and Inter text theme to AppTheme"
```

---

### Task 3: Migrate `progress_screen.dart` to shared tokens, typography, and `PrimaryButton`

**Files:**
- Modify: `nutrilife/lib/features/progress/presentation/screens/progress_screen.dart`

**Interfaces:**
- Consumes: `AppTheme.onSurface`, `AppTheme.onSurfaceVariant`, `AppTheme.tertiary`,
  `AppTheme.surfaceContainerLow`, `AppTheme.surfaceContainerLowest`,
  `AppTheme.radiusMd`, `AppTheme.ambientShadow` (Task 2); `PrimaryButton` from
  `nutrilife/lib/core/widgets/primary_button.dart` (constructor params used:
  `textButton`, `icon`, `height`, `onPressed`).
- Produces: no new public API — internal restyle only.

- [ ] **Step 1: Imports and shared color aliases**

Old:

```dart
import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/progress_repository.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({
    super.key,
    this.user,
    this.refreshToken = 0,
  });

  final Map<String, dynamic>? user;
  final int refreshToken;

  static const Color _text = Color(0xFF101418);
  static const Color _muted = Color(0xFF64748B);
  static const Color _green = AppTheme.primaryStart;
  static const Color _mint = Color(0xFF69E7A4);
  static const Color _blue = Color(0xFF1E56F5);
```

New:

```dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../data/progress_repository.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({
    super.key,
    this.user,
    this.refreshToken = 0,
  });

  final Map<String, dynamic>? user;
  final int refreshToken;

  static const Color _text = AppTheme.onSurface;
  static const Color _muted = AppTheme.onSurfaceVariant;
  static const Color _green = AppTheme.primaryStart;
  static const Color _mint = Color(0xFF69E7A4);
  static const Color _blue = AppTheme.tertiary;
```

This keeps every existing `ProgressScreen._text` / `._muted` / `._blue` reference in
the rest of the file working unchanged — only the definitions move to tokens. The
`_blue` swap to `AppTheme.tertiary` also fixes the "Information blue" violation
everywhere it's used (status chip accent, weight-history chart line/dots).

- [ ] **Step 2: Error view — retry button and typography**

Old:

```dart
                const Text(
                  'No se pudo cargar tu progreso',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: ProgressScreen._text,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  message.replaceFirst('Exception: ', ''),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: ProgressScreen._muted.withValues(alpha: 0.9),
                    fontSize: 13,
                    height: 1.35,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 18),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: ProgressScreen._green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 22,
                      vertical: 12,
                    ),
                  ),
                  onPressed: onRetry,
                  child: const Text('Intentar de nuevo'),
                ),
```

New:

```dart
                Text(
                  'No se pudo cargar tu progreso',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    color: ProgressScreen._text,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  message.replaceFirst('Exception: ', ''),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    color: ProgressScreen._muted.withValues(alpha: 0.9),
                    fontSize: 13,
                    height: 1.35,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 18),
                PrimaryButton(
                  textButton: 'Intentar de nuevo',
                  icon: Icons.refresh_rounded,
                  height: 48,
                  onPressed: onRetry,
                ),
```

- [ ] **Step 3: Header brand text and weekly-progress label**

Old:

```dart
                    const Text(
                      'PROGRESO SEMANAL',
                      style: TextStyle(
                        color: ProgressScreen._green,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.3,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      'Buen progreso,\n${data.firstName}!',
                      style: const TextStyle(
                        color: ProgressScreen._text,
                        fontSize: 28,
                        height: 1.05,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
```

New:

```dart
                    Text(
                      'PROGRESO SEMANAL',
                      style: GoogleFonts.inter(
                        color: ProgressScreen._green,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.3,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      'Buen progreso,\n${data.firstName}!',
                      style: GoogleFonts.plusJakartaSans(
                        color: ProgressScreen._text,
                        fontSize: 28,
                        height: 1.05,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
```

Old:

```dart
        const Text(
          'NutriLife',
          style: TextStyle(
            color: ProgressScreen._green,
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
```

New:

```dart
        Text(
          'NutriLife',
          style: GoogleFonts.plusJakartaSans(
            color: ProgressScreen._green,
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
```

- [ ] **Step 4: Goal pill typography**

Old:

```dart
      child: Text(
        'Meta:\n$goal',
        style: const TextStyle(
          color: Color(0xFF064D31),
          fontSize: 12,
          height: 1.25,
          fontWeight: FontWeight.w800,
        ),
      ),
```

New:

```dart
      child: Text(
        'Meta:\n$goal',
        style: GoogleFonts.inter(
          color: const Color(0xFF064D31),
          fontSize: 12,
          height: 1.25,
          fontWeight: FontWeight.w800,
        ),
      ),
```

- [ ] **Step 5: Weight insight card — surface, radius, shadow, and typography**

Old:

```dart
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 164),
      clipBehavior: Clip.antiAlias,
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: _softShadow,
      ),
```

New:

```dart
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 164),
      clipBehavior: Clip.antiAlias,
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        boxShadow: AppTheme.ambientShadow,
      ),
```

Old:

```dart
                  const Text(
                    'Resumen de peso',
                    style: TextStyle(
                      color: ProgressScreen._green,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
```

New:

```dart
                  Text(
                    'Resumen de peso',
                    style: GoogleFonts.plusJakartaSans(
                      color: ProgressScreen._green,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
```

Old:

```dart
              const SizedBox(height: 20),
              if (hasChange)
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(text: mainText.$1),
                      TextSpan(
                        text: highlightedText,
                        style: const TextStyle(color: ProgressScreen._green),
                      ),
                      TextSpan(text: mainText.$2),
                    ],
                  ),
                  style: const TextStyle(
                    color: ProgressScreen._text,
                    fontSize: 22,
                    height: 1.15,
                    fontWeight: FontWeight.w900,
                  ),
                )
              else
                Text.rich(
                  TextSpan(
                    children: [
                      const TextSpan(text: 'Peso actual\n'),
                      TextSpan(
                        text: currentWeight == null
                            ? 'Sin registro'
                            : '${_formatDouble(currentWeight)}kg',
                        style: const TextStyle(color: ProgressScreen._green),
                      ),
                    ],
                  ),
                  style: const TextStyle(
                    color: ProgressScreen._text,
                    fontSize: 22,
                    height: 1.15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              const SizedBox(height: 8),
              Text(
                hasChange
                    ? 'Comparado con tu registro físico anterior.'
                    : 'Registra otro peso más adelante para ver tu evolución.',
                style: TextStyle(
                  color: ProgressScreen._muted.withValues(alpha: 0.88),
                  fontSize: 13,
                  height: 1.25,
                  fontWeight: FontWeight.w500,
                ),
              ),
```

New:

```dart
              const SizedBox(height: 20),
              if (hasChange)
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(text: mainText.$1),
                      TextSpan(
                        text: highlightedText,
                        style: const TextStyle(color: ProgressScreen._green),
                      ),
                      TextSpan(text: mainText.$2),
                    ],
                  ),
                  style: GoogleFonts.plusJakartaSans(
                    color: ProgressScreen._text,
                    fontSize: 22,
                    height: 1.15,
                    fontWeight: FontWeight.w900,
                  ),
                )
              else
                Text.rich(
                  TextSpan(
                    children: [
                      const TextSpan(text: 'Peso actual\n'),
                      TextSpan(
                        text: currentWeight == null
                            ? 'Sin registro'
                            : '${_formatDouble(currentWeight)}kg',
                        style: const TextStyle(color: ProgressScreen._green),
                      ),
                    ],
                  ),
                  style: GoogleFonts.plusJakartaSans(
                    color: ProgressScreen._text,
                    fontSize: 22,
                    height: 1.15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              const SizedBox(height: 8),
              Text(
                hasChange
                    ? 'Comparado con tu registro físico anterior.'
                    : 'Registra otro peso más adelante para ver tu evolución.',
                style: GoogleFonts.inter(
                  color: ProgressScreen._muted.withValues(alpha: 0.88),
                  fontSize: 13,
                  height: 1.25,
                  fontWeight: FontWeight.w500,
                ),
              ),
```

- [ ] **Step 6: Today-calories card and status chip**

Old:

```dart
              const Expanded(
                child: Text(
                  'Calorias de hoy',
                  style: TextStyle(
                    color: ProgressScreen._text,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
```

New:

```dart
              Expanded(
                child: Text(
                  'Calorias de hoy',
                  style: GoogleFonts.plusJakartaSans(
                    color: ProgressScreen._text,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
```

Old:

```dart
              Text(
                _formatInt(data.totalConsumed),
                style: const TextStyle(
                  color: ProgressScreen._green,
                  fontSize: 44,
                  fontWeight: FontWeight.w900,
                  height: 0.95,
                  letterSpacing: -1.2,
                ),
              ),
              const SizedBox(width: 7),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  dailyLimit == null
                      ? 'kcal consumidas'
                      : 'de ${_formatInt(dailyLimit)} kcal',
                  style: TextStyle(
                    color: ProgressScreen._muted.withValues(alpha: 0.9),
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
```

New:

```dart
              Text(
                _formatInt(data.totalConsumed),
                style: GoogleFonts.plusJakartaSans(
                  color: ProgressScreen._green,
                  fontSize: 44,
                  fontWeight: FontWeight.w900,
                  height: 0.95,
                  letterSpacing: -1.2,
                ),
              ),
              const SizedBox(width: 7),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  dailyLimit == null
                      ? 'kcal consumidas'
                      : 'de ${_formatInt(dailyLimit)} kcal',
                  style: GoogleFonts.inter(
                    color: ProgressScreen._muted.withValues(alpha: 0.9),
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
```

Old:

```dart
          Text(
            dailyLimit == null || remaining == null
                ? 'Completa tus datos físicos y tu meta para calcular tu límite diario.'
                : 'Meta diaria: ${_formatInt(dailyLimit)} kcal. Te quedan ${_formatInt(remaining)} kcal disponibles hoy.',
            style: TextStyle(
              color: ProgressScreen._muted.withValues(alpha: 0.9),
              fontSize: 13,
              height: 1.35,
              fontWeight: FontWeight.w500,
            ),
          ),
```

New:

```dart
          Text(
            dailyLimit == null || remaining == null
                ? 'Completa tus datos físicos y tu meta para calcular tu límite diario.'
                : 'Meta diaria: ${_formatInt(dailyLimit)} kcal. Te quedan ${_formatInt(remaining)} kcal disponibles hoy.',
            style: GoogleFonts.inter(
              color: ProgressScreen._muted.withValues(alpha: 0.9),
              fontSize: 13,
              height: 1.35,
              fontWeight: FontWeight.w500,
            ),
          ),
```

Old:

```dart
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
```

New:

```dart
      child: Text(
        status,
        style: GoogleFonts.inter(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
```

- [ ] **Step 7: Weight history card — title, current-weight label, empty state**

Old:

```dart
              const Expanded(
                child: Text(
                  'Historial de peso',
                  style: TextStyle(
                    color: ProgressScreen._text,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
```

New:

```dart
              Expanded(
                child: Text(
                  'Historial de peso',
                  style: GoogleFonts.plusJakartaSans(
                    color: ProgressScreen._text,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
```

Old:

```dart
              Text(
                currentWeight == null
                    ? 'Sin peso actual'
                    : '${_formatDouble(currentWeight!)}kg Actual',
                style: const TextStyle(
                  color: ProgressScreen._muted,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
```

New:

```dart
              Text(
                currentWeight == null
                    ? 'Sin peso actual'
                    : '${_formatDouble(currentWeight!)}kg Actual',
                style: GoogleFonts.inter(
                  color: ProgressScreen._muted,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
```

Old:

```dart
      child: Text(
        'Aún no tienes historial físico.',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: ProgressScreen._muted.withValues(alpha: 0.85),
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
```

New:

```dart
      child: Text(
        'Aún no tienes historial físico.',
        textAlign: TextAlign.center,
        style: GoogleFonts.inter(
          color: ProgressScreen._muted.withValues(alpha: 0.85),
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
```

- [ ] **Step 8: "Resumen nutricional" section title and average tiles**

Old:

```dart
          const Text(
            'Resumen nutricional',
            style: TextStyle(
              color: ProgressScreen._text,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
```

New:

```dart
          Text(
            'Resumen nutricional',
            style: GoogleFonts.plusJakartaSans(
              color: ProgressScreen._text,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
```

Old:

```dart
    return Container(
      height: 104,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xFFEFF3F5),
        borderRadius: BorderRadius.circular(26),
      ),
```

New:

```dart
    return Container(
      height: 104,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
```

Old:

```dart
                Text(
                  label,
                  style: const TextStyle(
                    color: ProgressScreen._muted,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: ProgressScreen._text,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
                if (detail != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    detail!,
                    style: const TextStyle(
                      color: ProgressScreen._green,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ] else ...[
```

New:

```dart
                Text(
                  label,
                  style: GoogleFonts.inter(
                    color: ProgressScreen._muted,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    color: ProgressScreen._text,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
                if (detail != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    detail!,
                    style: GoogleFonts.inter(
                      color: ProgressScreen._green,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ] else ...[
```

- [ ] **Step 9: Generic progress card, axis label, and shadow cleanup**

Old:

```dart
class _ProgressCard extends StatelessWidget {
  const _ProgressCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: _softShadow,
      ),
      child: child,
    );
  }
}

class _AxisLabel extends StatelessWidget {
  const _AxisLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: Color(0xFF9AA4AF),
        fontSize: 9,
        fontWeight: FontWeight.w800,
        letterSpacing: 1,
      ),
    );
  }
}
```

New:

```dart
class _ProgressCard extends StatelessWidget {
  const _ProgressCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        boxShadow: AppTheme.ambientShadow,
      ),
      child: child,
    );
  }
}

class _AxisLabel extends StatelessWidget {
  const _AxisLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: GoogleFonts.inter(
        color: const Color(0xFF9AA4AF),
        fontSize: 9,
        fontWeight: FontWeight.w800,
        letterSpacing: 1,
      ),
    );
  }
}
```

Now remove the now-unused local shadow helper at the bottom of the file:

Old:

```dart
List<BoxShadow> get _softShadow {
  return [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.04),
      blurRadius: 22,
      offset: const Offset(0, 12),
    ),
  ];
}
```

New: delete this function entirely (nothing to replace it with — `AppTheme.ambientShadow`
is used directly at both former call sites, from Steps 5 and 9).

- [ ] **Step 10: Verify with static analysis**

Run (from `nutrilife/`):
`flutter analyze lib/features/progress/presentation/screens/progress_screen.dart`
Expected: `No issues found!` (confirms no leftover references to the deleted
`_softShadow` getter or unused imports).

- [ ] **Step 11: Commit**

```bash
git add nutrilife/lib/features/progress/presentation/screens/progress_screen.dart
git commit -m "Migrate ProgressScreen to shared design tokens, typography, and PrimaryButton"
```

---

### Task 4: Migrate `profile_screen.dart` to shared tokens, typography, and `PrimaryButton`

**Files:**
- Modify: `nutrilife/lib/features/profile/presentation/screens/profile_screen.dart`

**Interfaces:**
- Consumes: same `AppTheme` tokens as Task 3, plus `AppTheme.radiusLg`; `PrimaryButton`
  from `nutrilife/lib/core/widgets/primary_button.dart`.
- Produces: no new public API — internal restyle only.

- [ ] **Step 1: Imports and `_ProfileColors` aliases**

Old:

```dart
import 'package:flutter/material.dart';

import '../../data/profile_repository.dart';
import 'edit_profile_screen.dart';
```

New:

```dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../data/profile_repository.dart';
import 'edit_profile_screen.dart';
```

Old:

```dart
class _ProfileColors {
  const _ProfileColors._();

  static const Color green = Color(0xFF0A6B3F);
  static const Color text = Color(0xFF20252B);
  static const Color muted = Color(0xFF5B626B);
}
```

New:

```dart
class _ProfileColors {
  const _ProfileColors._();

  static const Color green = AppTheme.primaryStart;
  static const Color text = AppTheme.onSurface;
  static const Color muted = AppTheme.onSurfaceVariant;
}
```

As in Task 3, this keeps every existing `_ProfileColors.green/text/muted` reference
in the rest of the file working unchanged.

- [ ] **Step 2: Error view — card surface/radius/shadow, retry button, typography**

Old:

```dart
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: _profileShadow,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE4E2),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.error_outline_rounded,
                  color: Color(0xFFB42318),
                  size: 30,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'No pudimos cargar tu perfil',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _ProfileColors.text,
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message.replaceFirst('Exception: ', ''),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _ProfileColors.muted.withValues(alpha: 0.9),
                  fontSize: 13,
                  height: 1.35,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 18),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: _ProfileColors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 12,
                  ),
                ),
                onPressed: onRetry,
                child: const Text('Intentar de nuevo'),
              ),
            ],
          ),
        ),
```

New:

```dart
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppTheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            boxShadow: AppTheme.ambientShadow,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE4E2),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.error_outline_rounded,
                  color: Color(0xFFB42318),
                  size: 30,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'No pudimos cargar tu perfil',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  color: _ProfileColors.text,
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message.replaceFirst('Exception: ', ''),
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  color: _ProfileColors.muted.withValues(alpha: 0.9),
                  fontSize: 13,
                  height: 1.35,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 18),
              PrimaryButton(
                textButton: 'Intentar de nuevo',
                icon: Icons.refresh_rounded,
                height: 48,
                onPressed: onRetry,
              ),
            ],
          ),
        ),
```

Note the icon-avatar `Container` above (error icon background) is intentionally left
untouched — it is a semantic status color (error red), not a surface token.

- [ ] **Step 3: Top bar brand text**

Old:

```dart
        const Text(
          'NutriLife',
          style: TextStyle(
            color: _ProfileColors.green,
            fontSize: 24,
            fontWeight: FontWeight.w900,
            fontStyle: FontStyle.italic,
          ),
        ),
```

New:

```dart
        Text(
          'NutriLife',
          style: GoogleFonts.plusJakartaSans(
            color: _ProfileColors.green,
            fontSize: 24,
            fontWeight: FontWeight.w900,
            fontStyle: FontStyle.italic,
          ),
        ),
```

- [ ] **Step 4: Name, membership text, stat cards**

Old:

```dart
                Text(
                  profile.name.isEmpty ? widget.userName : profile.name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: _ProfileColors.text,
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.8,
                    height: 1.05,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  profile.membershipText,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _ProfileColors.text.withValues(alpha: 0.72),
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
```

New:

```dart
                Text(
                  profile.name.isEmpty ? widget.userName : profile.name,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    color: _ProfileColors.text,
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.8,
                    height: 1.05,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  profile.membershipText,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    color: _ProfileColors.text.withValues(alpha: 0.72),
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
```

Old (`_ProfileStatCard`):

```dart
    return Container(
      height: 128,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: _profileShadow,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FittedBox(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    color: _ProfileColors.green,
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
                if (unit.isNotEmpty) ...[
                  const SizedBox(width: 3),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 3),
                    child: Text(
                      unit,
                      style: const TextStyle(
                        color: _ProfileColors.green,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFFABB0B6),
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
```

New:

```dart
    return Container(
      height: 128,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        boxShadow: AppTheme.ambientShadow,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FittedBox(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  value,
                  style: GoogleFonts.plusJakartaSans(
                    color: _ProfileColors.green,
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
                if (unit.isNotEmpty) ...[
                  const SizedBox(width: 3),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 3),
                    child: Text(
                      unit,
                      style: GoogleFonts.inter(
                        color: _ProfileColors.green,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            label,
            style: GoogleFonts.inter(
              color: const Color(0xFFABB0B6),
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
```

- [ ] **Step 5: "Objetivo nutricional" section, ACTIVO chip, goal pills**

Old:

```dart
                    const Expanded(
                      child: Text(
                        'Objetivo nutricional',
                        style: TextStyle(
                          color: _ProfileColors.text,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.4,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD5F6E5),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Text(
                        'ACTIVO',
                        style: TextStyle(
                          color: _ProfileColors.green,
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.8,
                        ),
                      ),
                    ),
```

New:

```dart
                    Expanded(
                      child: Text(
                        'Objetivo nutricional',
                        style: GoogleFonts.plusJakartaSans(
                          color: _ProfileColors.text,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.4,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryContainer,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        'ACTIVO',
                        style: GoogleFonts.inter(
                          color: _ProfileColors.green,
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.8,
                        ),
                      ),
                    ),
```

Old:

```dart
                const Text(
                  'Ajustes y recordatorios',
                  style: TextStyle(
                    color: _ProfileColors.text,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.4,
                  ),
                ),
```

New:

```dart
                Text(
                  'Ajustes y recordatorios',
                  style: GoogleFonts.plusJakartaSans(
                    color: _ProfileColors.text,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.4,
                  ),
                ),
```

Old (`_GoalPill` inside `_NutritionGoalSelector`):

```dart
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      height: 136,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
      decoration: BoxDecoration(
        color: isActive ? Colors.white : Colors.transparent,
        borderRadius: BorderRadius.circular(32),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
              ]
            : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            option.icon,
            color: isActive ? _ProfileColors.green : _ProfileColors.muted,
            size: 25,
          ),
          const SizedBox(height: 16),
          Text(
            option.label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isActive ? _ProfileColors.green : _ProfileColors.muted,
              fontSize: 16,
              fontWeight: FontWeight.w900,
              height: 1.15,
            ),
          ),
        ],
      ),
    );
```

New:

```dart
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      height: 136,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
      decoration: BoxDecoration(
        color: isActive ? AppTheme.surfaceContainerLowest : Colors.transparent,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
              ]
            : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            option.icon,
            color: isActive ? _ProfileColors.green : _ProfileColors.muted,
            size: 25,
          ),
          const SizedBox(height: 16),
          Text(
            option.label,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: isActive ? _ProfileColors.green : _ProfileColors.muted,
              fontSize: 16,
              fontWeight: FontWeight.w900,
              height: 1.15,
            ),
          ),
        ],
      ),
    );
```

The active-tab shadow above is intentionally left as-is (small selector-affordance
shadow, distinct from the card-level `ambientShadow`).

- [ ] **Step 6: Settings card — remove dividers, add whitespace, retitle radius/shadow**

Old:

```dart
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(34),
        boxShadow: _profileShadow,
      ),
      child: Column(
        children: [
          _SettingsRow(
            icon: Icons.access_time_filled_rounded,
            iconColor: const Color(0xFF066D82),
            iconBackground: const Color(0xFFA8F1F6),
            title: 'Recordatorios de comida',
            subtitle: 'Alertas diarias para 4 comidas',
            trailing: Switch(
              value: mealRemindersEnabled,
              activeThumbColor: _ProfileColors.green,
              activeTrackColor: const Color(0xFF69E7A4),
              onChanged: onMealReminderChanged,
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE9EEF2)),
          const _SettingsRow(
            icon: Icons.notifications_active_rounded,
            iconColor: Color(0xFF1D4ED8),
            iconBackground: Color(0xFFE7EAFF),
            title: 'Configuración de notificaciones',
            subtitle: 'Push, correo y SMS',
            trailing: Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFFADB4BC),
              size: 30,
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE9EEF2)),
          _SettingsRow(
            icon: Icons.tune_rounded,
            iconColor: _ProfileColors.green,
            iconBackground: const Color(0xFFE7F7EF),
            title: 'Configuración',
            subtitle: 'Edad, altura, sexo, objetivo y correo',
            trailing: const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFFADB4BC),
              size: 30,
            ),
            onTap: onOpenConfiguration,
          ),
        ],
      ),
    );
```

New:

```dart
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        boxShadow: AppTheme.ambientShadow,
      ),
      child: Column(
        children: [
          _SettingsRow(
            icon: Icons.access_time_filled_rounded,
            iconColor: const Color(0xFF066D82),
            iconBackground: const Color(0xFFA8F1F6),
            title: 'Recordatorios de comida',
            subtitle: 'Alertas diarias para 4 comidas',
            trailing: Switch(
              value: mealRemindersEnabled,
              activeThumbColor: _ProfileColors.green,
              activeTrackColor: const Color(0xFF69E7A4),
              onChanged: onMealReminderChanged,
            ),
          ),
          const _SettingsRow(
            icon: Icons.notifications_active_rounded,
            iconColor: Color(0xFF1D4ED8),
            iconBackground: Color(0xFFE7EAFF),
            title: 'Configuración de notificaciones',
            subtitle: 'Push, correo y SMS',
            trailing: Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFFADB4BC),
              size: 30,
            ),
          ),
          _SettingsRow(
            icon: Icons.tune_rounded,
            iconColor: _ProfileColors.green,
            iconBackground: const Color(0xFFE7F7EF),
            title: 'Configuración',
            subtitle: 'Edad, altura, sexo, objetivo y correo',
            trailing: const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFFADB4BC),
              size: 30,
            ),
            onTap: onOpenConfiguration,
          ),
        ],
      ),
    );
```

Old (`_SettingsRow` padding — widens the whitespace that replaces the removed
dividers, and applies the row typography):

```dart
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: iconBackground,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 28),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: _ProfileColors.text,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: _ProfileColors.text.withValues(alpha: 0.72),
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              trailing,
            ],
          ),
        ),
```

New:

```dart
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 26),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: iconBackground,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 28),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.plusJakartaSans(
                        color: _ProfileColors.text,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        color: _ProfileColors.text.withValues(alpha: 0.72),
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              trailing,
            ],
          ),
        ),
```

- [ ] **Step 7: Logout button — ghost border and typography**

Old:

```dart
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.logout_rounded, size: 24),
        label: const Text(
          'Cerrar sesión',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: _ProfileColors.muted,
          side: const BorderSide(color: Color(0xFFE0E5EA), width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
        ),
      ),
```

New:

```dart
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.logout_rounded, size: 24),
        label: Text(
          'Cerrar sesión',
          style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: _ProfileColors.muted,
          side: BorderSide(
            color: AppTheme.onSurface.withValues(alpha: 0.15),
            width: 1,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
        ),
      ),
```

The logout action intentionally stays a plain outlined button (no gradient) — it is
a secondary/destructive action, not a primary CTA, so `PrimaryButton`'s gradient
treatment does not apply here. Only its border is fixed to the spec's "ghost border"
(15% opacity, 1px).

- [ ] **Step 8: Remove the now-unused local shadow helper**

Old (at the bottom of the file):

```dart
List<BoxShadow> get _profileShadow {
  return [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.05),
      blurRadius: 22,
      offset: const Offset(0, 12),
    ),
  ];
}
```

New: delete this function entirely (`AppTheme.ambientShadow` is used directly at all
three former call sites, from Steps 2, 4, and 6).

- [ ] **Step 9: Verify with static analysis**

Run (from `nutrilife/`):
`flutter analyze lib/features/profile/presentation/screens/profile_screen.dart`
Expected: `No issues found!` (confirms no leftover references to the deleted
`_profileShadow` getter, no unused imports, and the `const` removals above didn't
leave any stray `const` keywords on now-non-const `GoogleFonts.*` expressions).

- [ ] **Step 10: Commit**

```bash
git add nutrilife/lib/features/profile/presentation/screens/profile_screen.dart
git commit -m "Migrate ProfileScreen to shared design tokens, typography, and PrimaryButton"
```

---

### Task 5: Full verification pass

**Files:** none (verification only).

- [ ] **Step 1: Analyze the whole project**

Run (from `nutrilife/`): `flutter analyze`
Expected: `No issues found!` across the whole `lib/` tree (confirms Tasks 2-4 didn't
regress any other file, e.g. `dashboard_screen.dart` still compiles against the
unmodified `AppTheme` fields it uses).

- [ ] **Step 2: Manual visual check**

Use the `run` skill (or `flutter run`) to launch the app, log in, and open the
**Progreso** and **Perfil** tabs from the bottom nav in `dashboard_screen.dart`.
Confirm against `nutrilife/lib/docs/DESIGN.md`:
- No blue accents remain in the weight-history chart or status labels (teal instead).
- No 1px divider lines are visible between the three settings rows in Perfil.
- The logout button shows a faint (not solid-gray) 1px border.
- The error state's "Intentar de nuevo" button shows the green gradient pill (trigger
  it by temporarily disabling network, or note as visually confirmed by code review
  if the error path can't be triggered live).
- Headline-style text (greeting, card titles, hero numbers, profile name) reads in a
  visibly different typeface from the small labels/body copy.

- [ ] **Step 3: Report results**

Summarize the manual check results (pass/fail per bullet above) back to the user
before considering this plan complete.
