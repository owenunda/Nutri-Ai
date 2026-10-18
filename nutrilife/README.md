# NutriLife — app

App Flutter (Android + iOS). Habla con la API en `https://api.nutri.oween.software/api/v1` (`lib/core/constants/api_base_url.dart`).

## Correr en desarrollo

```bash
flutter pub get
flutter run
```

Así la app corre, pero **sin compras**: la pantalla premium muestra "Los pagos llegan pronto". Para probar compras en el emulador con la Test Store de RevenueCat:

```bash
flutter run --dart-define=REVENUECAT_ANDROID_KEY=<key test_ de RevenueCat> --dart-define=REVENUECAT_IOS_KEY=<key test_ de RevenueCat>
```

La key `test_…` está en RevenueCat → API keys → SDK API keys → *Test Store*. En la Test Store el "mes" dura unos 5 minutos y no hay página para administrar la suscripción.

## Pruebas

```bash
flutter test
flutter analyze
```

## Textos e idiomas

Todo texto visible va en `lib/l10n/app_es.arb` (plantilla) y `lib/l10n/app_en.arb`. Después de editarlos:

```bash
flutter gen-l10n
```

y commitear también los `lib/l10n/app_localizations*.dart` generados.

## Suscripciones (RevenueCat)

- Solo `lib/core/services/purchase_service.dart` importa `purchases_flutter`; el resto de la app usa `PurchaseService`.
- Las keys de RevenueCat **solo** entran por `--dart-define` (`REVENUECAT_ANDROID_KEY`, `REVENUECAT_IOS_KEY`). Sin key, las compras quedan apagadas.
- Entitlement: `nutrilife_pro`. Offering `default` con los paquetes Monthly (`$rc_monthly`) y Annual (`$rc_annual`).
- **Nunca** subir a una tienda una build con la key `test_…`.

## Publicar en Google Play

1. Subir la versión en `pubspec.yaml` (`version: X.Y.Z+N`; el `+N` tiene que ser mayor que el último subido a Play).
2. Construir el AAB **siempre** con la key de Play:

   ```bash
   flutter build appbundle --dart-define-from-file=dart_defines/play.json
   ```

   `dart_defines/play.json` trae la key pública `goog_…`. Sin ese flag nadie podría comprar.
3. Subir `build/app/outputs/bundle/release/app-release.aab` en Play Console.

La firma de release usa `android/key.properties` (no está en el repo).

## iOS

Mientras no haya cuenta de Apple Developer, el workflow `.github/workflows/ios-unsigned-ipa.yml` compila un IPA sin firmar (se lanza desde la pestaña Actions) para instalarlo con Sideloadly. Ese IPA no lleva key de RevenueCat, así que no puede comprar.
