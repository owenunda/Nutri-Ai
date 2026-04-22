
export class AppError extends Error {
  /*
    message: string - Mensjase de error
    status: number - http codigo de estado
    code: string - codigo de error de la aplicacion
    details: Array - detalles adicionales del error
  */
  constructor(message, status = 500, code = 'INTERNAL_ERROR', details = []) {
    super(message);
    this.status = status;
    this.code = code;
    this.details = details;
    this.name = this.constructor.name;
    
    // Captura el stack trace, excluyendo la llamada al constructor
    Error.captureStackTrace(this, this.constructor);
  }
}
