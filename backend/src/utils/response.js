/*
    response: Object - Objeto de respuesta
    data: Object|Array|null - Datos a enviar en la respuesta
    message: string - Mensaje de respuesta
    status: number - Código de estado HTTP (por defecto: 200)
*/
export const successResponse = (res, data = null, message = 'Success', status = 200) => {
  return res.status(status).json({
    success: true,
    message,
    data
  });
};

/*
 * response: Object - Objeto de respuesta
 * message: string - Mensaje de error
 * code: string - Código de error de la aplicación
 * status: number - Código de estado HTTP (por defecto: 500)
 * details: Array - Detalles adicionales del error (ej: errores de validación)
*/
export const errorResponse = (res, message = 'Error interno del servidor', code = 'INTERNAL_ERROR', status = 500, details = []) => {
  return res.status(status).json({
    success: false,
    message,
    error: {
      code,
      details
    }
  });
};
