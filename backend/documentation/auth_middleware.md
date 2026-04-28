# Middleware de Autenticación y Autorización

Este documento describe cómo funciona el middleware `authenticateToken` y cómo aplicarlo en las rutas del sistema NutriAI.

## ¿Qué hace `authenticateToken`?

El middleware `authenticateToken` cumple dos funciones principales:
1.  **Autenticación**: Verifica que el cliente envíe un JSON Web Token (JWT) válido en el encabezado `Authorization`.
2.  **Autorización (Opcional)**: Verifica que el usuario tenga uno de los roles permitidos para acceder a la ruta.

## Importación

```javascript
import authenticateToken from "../../middleware/auth.middleware.js";
```

## Uso en Rutas

El middleware se puede usar de dos maneras dependiendo de si quieres restringir por roles o solo verificar que el usuario esté logueado.

### 1. Solo Autenticación (Cualquier usuario logueado)
Si pasas un array vacío o no pasas argumentos, cualquier usuario con un token válido podrá acceder.

```javascript
router.get('/mi-perfil', authenticateToken(), getProfile);
```

### 2. Autenticación + Autorización por Roles
Si pasas un array de strings, el middleware verificará que el rol del usuario (`user.role`) coincida con alguno de los roles permitidos.

```javascript
// Solo administradores
router.get('/admin/stats', authenticateToken(['ADMIN']), getStats);

// Administradores y Usuarios estándar
router.post('/recipes', authenticateToken(['ADMIN', 'USER']), createRecipe);
```

## Funcionamiento Interno

1.  **Extracción del Token**: Busca el token en `req.headers.authorization` siguiendo el formato `Bearer <token>`.
2.  **Verificación**: Usa `jwt.verify` con el secreto configurado en las variables de entorno.
3.  **Inyección en `req`**: Si el token es válido, la información del usuario decodificada se guarda en `req.user`. Esto permite acceder a `req.user.userId` o `req.user.role` en los controladores.
4.  **Manejo de Errores**:
    -   Si no hay token: Devuelve error `401 Unauthorized`.
    -   Si el token es inválido/expirado: Devuelve error `401 Unauthorized`.
    -   Si el rol no está permitido: Devuelve error `403 Forbidden`.

## Ejemplo en un Controlador

Una vez que el middleware ha validado la petición, puedes acceder a los datos del usuario así:

```javascript
export const getMyRecipes = async (req, res, next) => {
  try {
    const userId = req.user.userId; // Inyectado por el middleware
    const recipes = await getRecipesByUserId(userId);
    res.json(recipes);
  } catch (error) {
    next(error);
  }
};
```
