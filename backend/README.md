# NutriAI - Backend

NutriAI es una potente y escalable aplicación de nutrición diseñada para ayudar a los usuarios a gestionar su dieta, realizar un seguimiento de calorías y generar recetas personalizadas de forma inteligente. El núcleo de la aplicación se basa en el concepto de "nevera virtual", permitiendo a los usuarios obtener sugerencias de comidas basadas específicamente en los ingredientes que ya tienen a su disposición.

##  Características

- **Autenticación de Usuarios:** Sistema seguro de registro e inicio de sesión mediante JSON Web Tokens (JWT).
- **Perfil Nutricional:** Gestión de datos personales y establecimiento de objetivos nutricionales personalizados.
- **Gestión de Alimentos:** Catálogo completo de alimentos, tanto globales como creados por el usuario.
- **Nevera Virtual:** Sistema dinámico para gestionar los ingredientes disponibles en el hogar del usuario.
- **Seguimiento de Comidas:** Registro diario de ingestas con cálculo automático de calorías y macronutrientes.
- **Gestión de Recetas:** Creación manual de recetas y generación inteligente asistida por IA.
- **Seguimiento de Progreso:** Historial detallado de medidas corporales (peso, altura) y evolución en el tiempo.
- **Integración con IA:** Preparado para conectar con motores de inteligencia artificial a través de n8n.

##  Stack Tecnológico

- **Runtime:** Node.js
- **Framework:** Express.js
- **Base de Datos:** SQL (Relacional)
- **Autenticación:** JWT (JSON Web Tokens)
- **Seguridad:** Bcrypt para hashing de contraseñas

##  Arquitectura

El proyecto sigue una **Arquitectura Modular**, lo que garantiza que la aplicación sea altamente escalable, mantenible y que cada dominio tenga su propia lógica encapsulada.

**Flujo por módulo:**
`Routes → Controller → Service → Repository → Database`

- **Módulos:** Cada funcionalidad principal (Auth, User, Food, etc.) reside en su propio directorio dentro de `src/modules`.
- **Capas Internas:** Cada módulo gestiona sus propias rutas, controladores, servicios y lógica de acceso a datos.
- **Transversalidad:** Funcionalidades comunes como el middleware global y utilidades residen en la raíz de `src`.

##  Estructura del Proyecto

```text
src/
├── config/             # Configuraciones globales (DB, variables de entorno)
├── database/           # Conexión y configuración de base de datos
├── middleware/         # Middlewares globales (Auth, Validaciones)
├── modules/            # Lógica de negocio dividida por dominios
│   ├── auth/           # Módulo de autenticación
│   ├── user/           # Módulo de gestión de usuarios
│   ├── food/           # Módulo de alimentos
│   ├── fridge/         # Módulo de nevera virtual
│   ├── recipe/         # Módulo de recetas
│   └── meal/           # Módulo de registro de comidas
├── utils/              # Funciones de utilidad y helpers
├── app.js              # Inicialización de Express
└── server.js           # Punto de entrada del servidor
```

*Nota: Cada módulo dentro de `modules/` contiene sus propias carpetas de `controllers`, `services`, `repositories` y `routes`.*

## ⚙️ Instalación

Sigue estos pasos para configurar el entorno de desarrollo localmente:

1. **Clonar el repositorio:**
   ```bash
   git clone https://github.com/owenunda/Nutri-Ai.git
   cd backend
   ```

2. **Instalar dependencias:**
   ```bash
   npm install
   ```

3. **Configurar variables de entorno:**
   Crea un archivo `.env` en la raíz del proyecto y completa los datos (ver sección de variables de entorno).

4. **Ejecutar el servidor:**
   ```bash
   # Modo desarrollo
   npm run dev

   # Modo producción
   npm start
   ```

## 🔑 Variables de Entorno

Debes configurar las siguientes variables en tu archivo `.env`:

```env
PORT=3000
DB_URL=postgresql://usuario:password@localhost:5432/nutriai
JWT_SECRET=tu_clave_secreta_super_segura
N8N_WEBHOOK_URL=https://tu-instancia-n8n.com/webhook/recetas
```

## 🛣️ Resumen de la API

| Endpoint | Descripción |
| :--- | :--- |
| `/auth` | Registro, Login y gestión de tokens |
| `/users` | Perfiles, metas y configuración de usuario |
| `/foods` | Catálogo de alimentos y creación de nuevos ítems |
| `/fridge` | Gestión de los ingredientes en la nevera virtual |
| `/recipes` | Búsqueda, creación y generación de recetas (AI) |
| `/meals` | Registro de comidas diarias y totales calóricos |

## Seguridad

NutriAI implementa las mejores prácticas de seguridad para proteger los datos de los usuarios:
- **Hashing de contraseñas:** Uso de `bcrypt` para asegurar que las contraseñas nunca se almacenen en texto plano.
- **Autenticación Robusta:** JWT para la protección de rutas privadas y gestión de sesiones.
- **Protección Básica:** Implementación de CORS, validación de datos de entrada y manejo controlado de errores.

##  Futuras Mejoras

- [ ] Integración avanzada con **n8n** para automatizaciones de dietas personalizadas.
- [ ] Sistema de **notificaciones** push y por correo electrónico.
- [ ] Planes de suscripción (**FREE / PRO**) con características exclusivas.
- [ ] Escalabilidad hacia una arquitectura de **microservicios** para el procesamiento de IA.

##  Licencia

Este proyecto está bajo la Licencia MIT. Consulta el archivo `LICENSE` para más detalles.
