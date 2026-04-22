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

## Objetivo

* Consistencia en el backend
* Fácil integración con frontend
* Mejor manejo de errores
* Escalabilidad del sistema
