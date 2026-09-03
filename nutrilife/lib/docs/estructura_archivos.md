# NutriLife - Estructura de Archivos

NutriLife es una aplicación móvil desarrollada en Flutter para el control nutricional inteligente. La arquitectura propuesta busca que el proyecto sea escalable, modular, fácil de mantener y preparado para crecer sin convertirse en un monolito difícil de manejar.

## Objetivo de la app

La aplicación está pensada para cubrir estas funciones principales:

- Seguimiento de calorías
- Registro de alimentos
- Objetivos nutricionales
- Recetas generadas con IA
- ChatBot nutricional
- Historial de progreso
- Recordatorios
- Gestión de ingredientes disponibles

## Stack recomendado

- Flutter
- Riverpod para estado
- go_router para navegación
- Clean Architecture simplificada
- Feature First

## Estructura general

```text
lib/
├── core/
│   ├── constants/
│   ├── theme/
│   ├── utils/
│   ├── services/
│   ├── network/
│   ├── storage/
│   ├── widgets/
│   └── errors/
│
├── features/
│   ├── auth/
│   │   ├── data/
│   │   ├── domain/
│   │   ├── presentation/
│   │   └── auth_routes.dart
│   ├── home/
│   │   ├── presentation/
│   │   └── home_routes.dart
│   ├── profile/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   ├── nutrition/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   ├── recipes/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   ├── chatbot/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   ├── fridge/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   ├── progress/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   └── notifications/
│       ├── data/
│       ├── domain/
│       └── presentation/
│
├── routes/
│   └── app_routes.dart
│
├── shared/
│   ├── models/
│   ├── components/
│   └── extensions/
│
└── main.dart
```

## Capas del proyecto

### `core/`

Contiene la lógica global y reutilizable del proyecto.

#### `constants/`

Variables constantes como:

- `api_base_url.dart`
- `app_constants.dart`

#### `theme/`

Configuración visual global:

- `app_theme.dart`
- `colors.dart`
- `text_styles.dart`
- DESING.md -> dise;o de dart

#### `network/`

Configuración de consumo de APIs:

- `dio_client.dart`
- `api_routes.dart`

#### `storage/`

Persistencia local:

- `secure_storage_service.dart`
- `shared_preferences_service.dart`

#### `widgets/`

Widgets reutilizables globales:

- `custom_button.dart`
- `custom_input.dart`
- `loading_widget.dart`
- `custom_appbar.dart`

#### `utils/`

Funciones auxiliares:

- `validators.dart`
- `date_formatter.dart`
- `calorie_calculator.dart`

#### `errors/`

Errores y excepciones globales del proyecto.

## `features/`

La aplicación se divide en módulos independientes. Cada módulo contiene:

- `data/`
- `domain/`
- `presentation/`

### Responsabilidad de cada capa

#### `data/`

Manejo de datos:

- `models/`
- `datasources/`
- `repositories/`

Responsabilidades:

- Consumo de APIs
- Conversión JSON
- Manejo HTTP
- Persistencia local

#### `domain/`

Lógica de negocio pura:

- `entities/`
- `usecases/`
- `repositories/`

Responsabilidades:

- Casos de uso
- Reglas de negocio
- Validaciones
- Lógica nutricional

#### `presentation/`

Interfaz de usuario:

- `pages/`
- `widgets/`
- `controllers/`
- `providers/`
- `states/`

Responsabilidades:

- Pantallas
- Formularios
- Widgets
- Estado visual
- Navegación

## Módulos principales

### `auth/`

Manejo de autenticación.

Funciones:

- Registro
- Login
- Logout
- Recuperación de contraseña
- Manejo de JWT

### `home/`

Pantalla principal.

Funciones:

- Resumen diario
- Calorías consumidas
- Objetivo
- Accesos rápidos

### `profile/`

Perfil del usuario.

Funciones:

- Peso
- Altura
- Edad
- Objetivos
- Preferencias

### `nutrition/`

Sistema nutricional.

Funciones:

- Registro de alimentos
- Cálculo calórico
- Historial diario
- Límites diarios

### `recipes/`

Sistema IA de recetas.

Funciones:

- Generar recetas
- Validar recetas
- Aceptar o rechazar
- Regenerar recetas

### `chatbot/`

ChatBot nutricional.

Funciones:

- Conversación IA
- Contexto
- Memoria conversacional
- Recomendaciones

### `fridge/`

Nevera inteligente.

Funciones:

- Ingredientes disponibles
- Inventario
- Cantidades
- Relación con recetas

### `progress/`

Seguimiento del usuario.

Funciones:

- Evolución de peso
- Estadísticas
- Historial
- Gráficas

### `notifications/`

Sistema de recordatorios.

Funciones:

- Horarios de comida
- Alertas
- Push notifications

## Navegación

Se recomienda usar `go_router`.

Archivo principal:

- `routes/app_routes.dart`

Ejemplo:

```dart
GoRoute(
	path: '/login',
	builder: (context, state) => const LoginPage(),
),
```

## Manejo de estado

Se recomienda `Riverpod`.

Ventajas:

- Escalable
- Moderno
- Fácil de mantener
- Menos boilerplate que Bloc

## Dependencias recomendadas

```yaml
dependencies:
	flutter:
		sdk: flutter

	flutter_riverpod: ^2.6.1
	go_router: ^14.2.0
	dio: ^5.7.0
	flutter_secure_storage: ^9.2.2
	shared_preferences: ^2.3.2
	intl: ^0.19.0
```

## Flujo de arquitectura

```text
UI
↓
Controller / Provider
↓
UseCase
↓
Repository
↓
API / Database
```

## Buenas prácticas

- Separar lógica de UI
- Mantener widgets pequeños
- Reutilizar componentes
- Modularizar cada feature
- Evitar que la lógica de negocio viva dentro de la interfaz

## Qué no hacer

- No poner todo en `main.dart`
- No crear una carpeta gigante `screens/`
- No hacer llamadas a API dentro de widgets
- No dispersar variables globales por todo el proyecto
- No crear widgets enormes
- No mezclar lógica nutricional con la UI

## Ambientes recomendados

Preparar desde el inicio:

- `.env`
- `.env.dev`
- `.env.prod`

Ejemplo:

```env
API_URL=https://api.NutriLife.com
```

## MVP inicial recomendado

### Auth

- Login
- Registro
- Logout

### Nutrición

- Registrar alimentos
- Ver calorías

### IA

- Generar recetas

### Perfil

- Peso
- Altura
- Objetivo

### Progreso

- Historial básico

## Recomendación final

NutriLife ya parte con una base funcional amplia: IA, nutrición, calorías, recetas, historial, progreso y recordatorios. Por eso conviene mantener una arquitectura escalable desde el inicio.

La combinación recomendada es:

- Flutter
- Riverpod
- go_router
- Clean Architecture simplificada
- Feature First

Esta estructura permite crecer el proyecto sin convertirlo en un monolito difícil de mantener.
