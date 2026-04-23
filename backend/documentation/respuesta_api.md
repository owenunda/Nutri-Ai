# Contrato de Respuestas API - NutriAI

Este documento define el formato estándar de las respuestas del backend de NutriAI.
Todas las respuestas deben seguir esta estructura para mantener consistencia en el sistema.

---

## Respuesta Exitosa

```json
{
  "success": true,
  "data": {},
  "message": "Operación exitosa"
}
```

### Campos:

* `success`: Indica si la operación fue exitosa (true)
* `data`: Contiene la información solicitada
* `message`: Mensaje opcional descriptivo

---

## Respuesta de Error

```json
{
  "success": false,
  "message": "Descripción del error",
  "error": {
    "code": "ERROR_CODE",
    "details": []
  }
}
```

### Campos:

* `success`: Siempre false
* `message`: Explicación clara del error
* `error.code`: Código interno del error
* `error.details`: Lista de errores específicos (opcional)

---

## Tipos de Errores

### Validación (400)

```json
{
  "success": false,
  "message": "Error de validación",
  "error": {
    "code": "VALIDATION_ERROR",
    "details": [
      {
        "field": "email",
        "message": "El email es inválido"
      }
    ]
  }
}
```

---

### No autorizado (401)

```json
{
  "success": false,
  "message": "No autorizado",
  "error": {
    "code": "UNAUTHORIZED"
  }
}
```

---

### Prohibido (403)

```json
{
  "success": false,
  "message": "Acceso denegado",
  "error": {
    "code": "FORBIDDEN"
  }
}
```

---

### No encontrado (404)

```json
{
  "success": false,
  "message": "Recurso no encontrado",
  "error": {
    "code": "NOT_FOUND"
  }
}
```

---

### Error interno (500)

```json
{
  "success": false,
  "message": "Error interno del servidor",
  "error": {
    "code": "INTERNAL_ERROR"
  }
}
```

---

## Ejemplos Reales

### Login exitoso

```json
{
  "success": true,
  "message": "Login exitoso",
  "data": {
    "token": "jwt_token",
    "user": {
      "id": 1,
      "email": "user@email.com"
    }
  }
}
```

---

### Obtener alimentos

```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "nombre": "Pollo",
      "calorias": 200
    }
  ]
}
```

---

### Error al crear alimento

```json
{
  "success": false,
  "message": "Calorías inválidas",
  "error": {
    "code": "INVALID_CALORIES"
  }
}
```

---

## Reglas Generales

* Todas las respuestas deben tener `success`
* Nunca devolver errores sin `message`
* No exponer errores internos del servidor
* Mantener consistencia en todos los endpoints
* Usar códigos HTTP correctos

---

## Códigos HTTP

| Código | Uso                 |
| ------ | ------------------- |
| 200    | OK                  |
| 201    | Creado              |
| 400    | Error de validación |
| 401    | No autenticado      |
| 403    | Sin permisos        |
| 404    | No encontrado       |
| 500    | Error servidor      |

---

## Implementación y Utilidades

Para mantener este estándar en todo el backend, se deben utilizar las utilidades y clases proveídas en el código:

### Utilidades de Respuesta (`src/utils/response.js`)

En los controladores, se deben retornar las respuestas utilizando las funciones auxiliares:

```javascript
import { successResponse, errorResponse } from '../utils/response.js';

// Respuesta exitosa
export const getSomeData = (req, res) => {
  const data = { id: 1, name: "Test" };
  // status por defecto es 200, message por defecto es 'Success'
  return successResponse(res, data, 'Datos obtenidos exitosamente'); 
};

// Respuesta de error manual (aunque se prefiere usar AppError y throw)
export const doSomethingWrong = (req, res) => {
  return errorResponse(res, 'Mensaje de error', 'ERROR_CODE', 400, ['Detalle 1']);
};
```

### Clase AppError (`src/utils/AppError.js`)

Para manejar errores operacionales o de negocio, se debe lanzar (o pasar a `next()`) una instancia de `AppError` y dejar que el middleware global se encargue de enviar la respuesta al cliente.

```javascript
import { AppError } from '../utils/AppError.js';

export const processAction = (req, res, next) => {
  try {
    const isValid = false;
    if (!isValid) {
      // (message, status, code, details)
      throw new AppError('Error de validación', 400, 'VALIDATION_ERROR', ['Campo requerido']);
    }
    return successResponse(res, null, 'Acción procesada');
  } catch (error) {
    // Pasa el error al middleware global de manejo de errores
    next(error); 
  }
};
```

### Middleware Global de Errores (`src/middleware/error.middleware.js`)

Todo error capturado y enviado a través de `next(error)` es procesado de forma centralizada:
* **Errores Controlados (`AppError`)**: Se formatean y envían con el mensaje, el código y el HTTP status definido en la clase.
* **Errores No Controlados**: Se manejan como errores `500` genéricos.
* **Entornos**: En modo de desarrollo (`NODE_ENV=development`), el stack trace de los errores no manejados se incluye automáticamente dentro del arreglo `details` para facilitar el *debugging*. En producción, los errores no controlados devuelven siempre un mensaje de error opaco y genérico por seguridad.

---

## Objetivo

* Consistencia en el backend
* Fácil integración con frontend
* Mejor manejo de errores
* Escalabilidad del sistema
